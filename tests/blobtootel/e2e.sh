#!/usr/bin/env bash
#
# E2E test for BlobToOtel Terraform module.
#
# Order of execution:
#   1. Deploy Terraform (RG, storage, container, Event Hub, Event Grid subscription, BlobToOtel module).
#   2. Upload a test blob to trigger Event Grid → Event Hub → function.
#   3. Wait 30s, then poll Coralogix Get Logs Count API until count > 0.
#   4. Clean up all resources.
#
# Prerequisites: Azure CLI, Terraform >= 1.7.4, jq.
# Environment: OTEL_ENDPOINT (required); optional: CORALOGIX_API_KEY, CORALOGIX_QUERY_API_KEY, CORALOGIX_DIRECT_MODE, CORALOGIX_APPLICATION, CORALOGIX_SUBSYSTEM
#
# Usage:
#   export OTEL_ENDPOINT="https://ingress.eu1.coralogix.com"
#   export CORALOGIX_QUERY_API_KEY="your-query-key"   # for Step 3 verification
#   ./e2e.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

: "${OTEL_ENDPOINT:?Set OTEL_ENDPOINT (e.g. https://ingress.coralogix.com)}"

# BlobToOtel can run without Coralogix API key (OTLP to Coralogix endpoint); verification needs query key
CORALOGIX_QUERY_API_KEY="${CORALOGIX_QUERY_API_KEY:-${CORALOGIX_API_KEY}}"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
err() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; }

cleanup_after_failure() {
  log "Cleaning up after failure..."
  cd "$TERRAFORM_DIR" || return 0
  export TF_VAR_otel_endpoint="${OTEL_ENDPOINT:-}"
  export TF_VAR_coralogix_direct_mode="${CORALOGIX_DIRECT_MODE:-false}"
  export TF_VAR_coralogix_api_key="${CORALOGIX_API_KEY:-}"
  export TF_VAR_coralogix_application="${CORALOGIX_APPLICATION:-azure}"
  export TF_VAR_coralogix_subsystem="${CORALOGIX_SUBSYSTEM:-blob-storage-eventhub-e2e}"
  export TF_VAR_function_app_service_plan_type="${FUNCTION_APP_SERVICE_PLAN_TYPE:-Consumption}"
  export TF_VAR_prefix_filter="${PREFIX_FILTER:-NoFilter}"
  export TF_VAR_suffix_filter="${SUFFIX_FILTER:-NoFilter}"
  terraform destroy -input=false -auto-approve 2>/dev/null || true
}
trap cleanup_after_failure EXIT

# --- Step 1: Deploy Terraform (prereqs + module) ---
log "Step 1: Deploying Terraform (RG, storage, container, Event Hub, Event Grid subscription, BlobToOtel module)..."
cd "$TERRAFORM_DIR"
export TF_VAR_otel_endpoint="$OTEL_ENDPOINT"
export TF_VAR_coralogix_direct_mode="${CORALOGIX_DIRECT_MODE:-false}"
export TF_VAR_coralogix_api_key="${CORALOGIX_API_KEY:-}"
export TF_VAR_coralogix_application="${CORALOGIX_APPLICATION:-azure}"
export TF_VAR_coralogix_subsystem="${CORALOGIX_SUBSYSTEM:-blob-storage-eventhub-e2e}"
export TF_VAR_function_app_service_plan_type="${FUNCTION_APP_SERVICE_PLAN_TYPE:-Consumption}"
export TF_VAR_prefix_filter="${PREFIX_FILTER:-NoFilter}"
export TF_VAR_suffix_filter="${SUFFIX_FILTER:-NoFilter}"

terraform init -input=false

# Apply 1: create RG and prereqs only (-refresh=false so module data sources are not evaluated yet).
log "Step 1a: Creating RG, storage, container, Event Hub..."
terraform apply -refresh=false -input=false -auto-approve \
  -target=azurerm_resource_group.e2e \
  -target=random_string.suffix \
  -target=azurerm_storage_account.blob \
  -target=azurerm_storage_container.logs \
  -target=azurerm_eventhub_namespace.ns \
  -target=azurerm_eventhub.hub

# Apply 2: full apply (Event Grid subscription + BlobToOtel module; data sources now find existing resources).
log "Step 1b: Creating Event Grid subscription and BlobToOtel module..."
terraform apply -input=false -auto-approve

RG_NAME=$(terraform output -raw resource_group_name)
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)
STORAGE_RG=$(terraform output -raw storage_account_resource_group)
CONTAINER_NAME=$(terraform output -raw blob_container_name)
STORAGE_CONNECTION_STRING=$(terraform output -raw storage_account_connection_string)

log "Terraform outputs: RG=$RG_NAME, Storage=$STORAGE_ACCOUNT, Container=$CONTAINER_NAME"

# --- Step 2: Upload test blob to trigger function ---
log "Step 2: Uploading test blob to trigger the function..."
TEST_BLOB_NAME="e2e-test-$(date +%s).log"
TEST_BLOB_FILE="${SCRIPT_DIR}/.e2e-test-payload.tmp"
printf 'e2e test line 1\ne2e test line 2\ne2e test line 3\n' > "$TEST_BLOB_FILE"
az storage blob upload \
  --connection-string "$STORAGE_CONNECTION_STRING" \
  --container-name "$CONTAINER_NAME" \
  --name "$TEST_BLOB_NAME" \
  --file "$TEST_BLOB_FILE" \
  --type block \
  --content-type "text/plain" \
  --no-progress
rm -f "$TEST_BLOB_FILE"

log "Uploaded test blob: $CONTAINER_NAME/$TEST_BLOB_NAME"

# --- Step 3: Verify logs in Coralogix (subsystem=blob-storage-logs from module default / e2e var) ---
CX_SUBSYS="${CORALOGIX_SUBSYSTEM:-blob-storage-eventhub-e2e}"
CX_API_HOST="${OTEL_ENDPOINT#*://}"
CX_API_HOST="${CX_API_HOST%%:*}"
CX_API_HOST="${CX_API_HOST/#ingress./api.}"
CX_LOGS_COUNT_URL="https://${CX_API_HOST}/mgmt/openapi/latest/dataplans/data-usage/v2/logs:count"

if [[ -z "${CORALOGIX_QUERY_API_KEY:-}" ]]; then
  log "Step 3: Skipping Coralogix verification (no CORALOGIX_QUERY_API_KEY or CORALOGIX_API_KEY)."
else
  now_minus_10m() {
    if date -u -d '10 min ago' +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null; then
      return
    fi
    date -u -v-10M +%Y-%m-%dT%H:%M:%S.000Z
  }

  fetch_logs_count() {
    local from to
    from=$(now_minus_10m)
    to=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
    curl -s -G "$CX_LOGS_COUNT_URL" \
      --data-urlencode "date_range.fromDate=$from" \
      --data-urlencode "date_range.toDate=$to" \
      --data-urlencode "resolution=10m" \
      --data-urlencode "filters.application=azure" \
      --data-urlencode "filters.subsystem=$CX_SUBSYS" \
      --data-urlencode "subsystem_aggregation=true" \
      -H "Authorization: Bearer $CORALOGIX_QUERY_API_KEY" | head -1 | jq -r '(.result.logsCount // []) | map(.logsCount | tonumber) | add // 0'
  }

  log "Step 3: Waiting 30s, then verifying logs in Coralogix (app=azure, subsystem=$CX_SUBSYS)..."
  sleep 30

  attempt=0
  while true; do
    attempt=$((attempt + 1))
    count=$(fetch_logs_count)
    if [[ -n "$count" && "$count" -gt 0 ]]; then
      log "Step 3: Logs verified in Coralogix (count=$count)."
      break
    fi
    if [[ $attempt -ge 10 ]]; then
      err "Step 3: No logs received in Coralogix after 10 attempts (last count=${count:-unknown})."
      exit 1
    fi
    log "Step 3: No logs yet (attempt $attempt/10), retrying in 30s..."
    sleep 30
  done
fi

# --- Step 4: Clean up ---
log "Step 4: Cleaning up resources..."
trap - EXIT
cd "$TERRAFORM_DIR"
terraform destroy -input=false -auto-approve
log "E2E test finished."
