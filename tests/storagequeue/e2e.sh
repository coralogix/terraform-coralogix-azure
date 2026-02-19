#!/usr/bin/env bash
#
# E2E test for StorageQueue Terraform module.
#
# Order of execution:
#   1. Deploy Terraform (resource group, StorageV2 + queue, function storage, and the StorageQueue module).
#   2. Send a test payload (put a JSON message into the storage queue to trigger the function).
#   3. Wait 30s, then poll Coralogix Get Logs Count API until count > 0 (retry every 30s, up to 10 times).
#   4. Clean up all resources.
#
# Prerequisites:
#   - Azure CLI installed and logged in (az login).
#   - Terraform >= 1.7.4.
#   - jq (for parsing Coralogix API response).
#   - Environment variables: OTEL_ENDPOINT, CORALOGIX_API_KEY; optional: CORALOGIX_QUERY_API_KEY, CORALOGIX_APPLICATION, CORALOGIX_SUBSYSTEM
#
# Usage:
#   export OTEL_ENDPOINT="https://ingress.eu2.coralogix.com"
#   export CORALOGIX_API_KEY="your-send-your-data-key"
#   export CORALOGIX_QUERY_API_KEY="your-query-key"
#   ./e2e.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

# Required
: "${OTEL_ENDPOINT:?Set OTEL_ENDPOINT (e.g. https://ingress.coralogix.com)}"
: "${CORALOGIX_API_KEY:?Set CORALOGIX_API_KEY (Send your data / Private key for the function)}"

CORALOGIX_QUERY_API_KEY="${CORALOGIX_QUERY_API_KEY:-${CORALOGIX_API_KEY}}"

# CustomDomain: FQDN only (no https, no path)
CUSTOM_DOMAIN="${OTEL_ENDPOINT#*://}"
CUSTOM_DOMAIN="${CUSTOM_DOMAIN%%/*}"
CUSTOM_DOMAIN="${CUSTOM_DOMAIN%%:*}"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
err() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; }

cleanup_after_failure() {
  log "Cleaning up after failure..."
  cd "$TERRAFORM_DIR" || return 0
  export TF_VAR_coralogix_custom_domain="${CUSTOM_DOMAIN:-}"
  export TF_VAR_coralogix_private_key="${CORALOGIX_API_KEY:-}"
  export TF_VAR_coralogix_application="${CORALOGIX_APPLICATION:-azure}"
  export TF_VAR_coralogix_subsystem="${CORALOGIX_SUBSYSTEM:-storage-queue-e2e}"
  export TF_VAR_function_app_service_plan_type="${FUNCTION_APP_SERVICE_PLAN_TYPE:-Consumption}"
  terraform destroy -input=false -auto-approve 2>/dev/null || true
}
trap cleanup_after_failure EXIT

# --- Step 1: Deploy Terraform (prereqs + module) ---
log "Step 1: Deploying Terraform (RG, StorageV2, queue, function storage, StorageQueue module)..."
cd "$TERRAFORM_DIR"
export TF_VAR_coralogix_custom_domain="$CUSTOM_DOMAIN"
export TF_VAR_coralogix_private_key="$CORALOGIX_API_KEY"
export TF_VAR_coralogix_application="${CORALOGIX_APPLICATION:-azure}"
export TF_VAR_coralogix_subsystem="${CORALOGIX_SUBSYSTEM:-storage-queue-e2e}"
export TF_VAR_function_app_service_plan_type="${FUNCTION_APP_SERVICE_PLAN_TYPE:-Consumption}"

terraform init -input=false

# Apply 1: create RG and prereqs only (-refresh=false so module data sources are not evaluated yet).
log "Step 1a: Creating RG, storage account, queue, function storage..."
terraform apply -refresh=false -input=false -auto-approve \
  -target=azurerm_resource_group.e2e \
  -target=random_string.suffix \
  -target=azurerm_storage_account.queue \
  -target=azurerm_storage_queue.logs \
  -target=azurerm_storage_account.function

# Apply 2: full apply (StorageQueue module; data sources now find existing resources).
log "Step 1b: Creating StorageQueue module..."
terraform apply -input=false -auto-approve

RG_NAME=$(terraform output -raw resource_group_name)
STORAGE_ACCOUNT=$(terraform output -raw storage_account_name)
STORAGE_RG=$(terraform output -raw storage_account_resource_group)
STORAGE_QUEUE_NAME=$(terraform output -raw storage_queue_name)
STORAGE_CONNECTION_STRING=$(terraform output -raw storage_account_connection_string)

log "Terraform outputs: RG=$RG_NAME, Storage=$STORAGE_ACCOUNT, Queue=$STORAGE_QUEUE_NAME"

# --- Step 2: Send test payload (put JSON message into queue) ---
log "Step 2: Putting JSON test message into storage queue to trigger the function..."
TEST_MSG="{\"e2e\":\"storage-queue\",\"source\":\"e2e-test\",\"ts\":$(date +%s)}"
MSG_B64=$(echo -n "$TEST_MSG" | base64)
az storage message put \
  --queue-name "$STORAGE_QUEUE_NAME" \
  --content "$MSG_B64" \
  --connection-string "$STORAGE_CONNECTION_STRING" \
  --output none

log "Put test message into queue: $STORAGE_QUEUE_NAME"

# --- Step 3: Verify logs in Coralogix ---
CX_API_HOST="${OTEL_ENDPOINT#*://}"
CX_API_HOST="${CX_API_HOST%%:*}"
CX_API_HOST="${CX_API_HOST/#ingress./api.}"
CX_LOGS_COUNT_URL="https://${CX_API_HOST}/mgmt/openapi/latest/dataplans/data-usage/v2/logs:count"
CX_SUBSYSTEM="${CORALOGIX_SUBSYSTEM:-storage-queue-e2e}"

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
    --data-urlencode "filters.subsystem=$CX_SUBSYSTEM" \
    --data-urlencode "subsystem_aggregation=true" \
    -H "Authorization: Bearer $CORALOGIX_QUERY_API_KEY" | head -1 | jq -r '(.result.logsCount // []) | map(.logsCount | tonumber) | add // 0'
}

log "Step 3: Waiting 30s, then verifying logs in Coralogix (app=azure, subsystem=$CX_SUBSYSTEM)..."
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

# --- Step 4: Clean up ---
log "Step 4: Cleaning up resources..."
trap - EXIT
cd "$TERRAFORM_DIR"
terraform destroy -input=false -auto-approve
log "E2E test finished."
