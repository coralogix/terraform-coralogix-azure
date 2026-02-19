#!/usr/bin/env bash
#
# E2E test for DiagnosticData Terraform module.
#
# Order of execution:
#   1. Deploy Terraform (RG, Event Hub, storage + diagnostic setting, function storage, DiagnosticData module).
#   2. Upload blobs to generate storage transactions (diagnostic setting streams to Event Hub).
#   3. Wait 2 min, then poll Coralogix Data Usage API until subsystem units > 0.
#   4. Clean up all resources.
#
# Prerequisites: Azure CLI, Terraform >= 1.7.4, jq.
# Environment: OTEL_ENDPOINT, CORALOGIX_API_KEY; optional: CORALOGIX_QUERY_API_KEY, CORALOGIX_APPLICATION, CORALOGIX_SUBSYSTEM, NUM_BLOBS, WAIT_INITIAL, MAX_ATTEMPTS
#
# Usage:
#   export OTEL_ENDPOINT="https://ingress.eu1.coralogix.com"
#   export CORALOGIX_API_KEY="your-send-your-data-key"
#   export CORALOGIX_QUERY_API_KEY="your-query-key"
#   ./e2e.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"
NUM_BLOBS="${NUM_BLOBS:-8}"

: "${OTEL_ENDPOINT:?Set OTEL_ENDPOINT (e.g. https://ingress.coralogix.com)}"
: "${CORALOGIX_API_KEY:?Set CORALOGIX_API_KEY (Send your data / Private key for the function)}"

CORALOGIX_QUERY_API_KEY="${CORALOGIX_QUERY_API_KEY:-${CORALOGIX_API_KEY}}"

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
  export TF_VAR_coralogix_subsystem="${CORALOGIX_SUBSYSTEM:-diagnosticdata-e2e}"
  export TF_VAR_function_app_service_plan_type="${FUNCTION_APP_SERVICE_PLAN_TYPE:-Consumption}"
  terraform destroy -input=false -auto-approve 2>/dev/null || true
}
trap cleanup_after_failure EXIT

# --- Step 1: Deploy Terraform (prereqs + module) ---
log "Step 1: Deploying Terraform (RG, Event Hub, storage + diagnostic setting, DiagnosticData module)..."
cd "$TERRAFORM_DIR"
export TF_VAR_coralogix_custom_domain="$CUSTOM_DOMAIN"
export TF_VAR_coralogix_private_key="$CORALOGIX_API_KEY"
export TF_VAR_coralogix_application="${CORALOGIX_APPLICATION:-azure}"
export TF_VAR_coralogix_subsystem="${CORALOGIX_SUBSYSTEM:-diagnosticdata-e2e}"
export TF_VAR_function_app_service_plan_type="${FUNCTION_APP_SERVICE_PLAN_TYPE:-Consumption}"

terraform init -input=false

# Apply 1: create RG and prereqs only (-refresh=false so module data sources are not evaluated yet).
log "Step 1a: Creating RG, Event Hub, storage, diagnostic setting, function storage..."
terraform apply -refresh=false -input=false -auto-approve \
  -target=azurerm_resource_group.e2e \
  -target=random_string.suffix \
  -target=azurerm_eventhub_namespace.ns \
  -target=azurerm_eventhub.hub \
  -target=azurerm_eventhub_namespace_authorization_rule.listen \
  -target=azurerm_eventhub_namespace_authorization_rule.send \
  -target=azurerm_storage_account.diag_source \
  -target=azurerm_storage_container.uploads \
  -target=azurerm_monitor_diagnostic_setting.storage_to_eventhub \
  -target=azurerm_storage_account.function

# Apply 2: full apply (DiagnosticData module; data sources now find existing resources).
log "Step 1b: Creating DiagnosticData module..."
terraform apply -input=false -auto-approve

RG_NAME=$(terraform output -raw resource_group_name)
EVENTHUB_NAMESPACE=$(terraform output -raw eventhub_namespace)
EVENTHUB_NAME=$(terraform output -raw eventhub_name)
STORAGE_CONNECTION_STRING=$(terraform output -raw storage_account_connection_string)
CONTAINER_NAME=$(terraform output -raw blob_container_name)

log "Terraform outputs: RG=$RG_NAME, EventHub=$EVENTHUB_NAMESPACE/$EVENTHUB_NAME, Storage container=$CONTAINER_NAME"

# --- Step 2: Upload blobs to generate storage transactions ---
log "Step 2: Uploading $NUM_BLOBS blobs to container $CONTAINER_NAME to trigger diagnostic data..."
PAYLOAD_FILE="${SCRIPT_DIR}/.e2e-diagdata-payload.tmp"
printf 'e2e diagnostic data test payload - %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$PAYLOAD_FILE"

uploaded=0
for i in $(seq 1 "$NUM_BLOBS"); do
  blob_name="e2e-diagdata-$(date +%s)-$i.txt"
  if az storage blob upload \
    --connection-string "$STORAGE_CONNECTION_STRING" \
    --container-name "$CONTAINER_NAME" \
    --name "$blob_name" \
    --file "$PAYLOAD_FILE" \
    --type block \
    --content-type "text/plain" \
    --no-progress 2>/dev/null; then
    uploaded=$((uploaded + 1))
  fi
done
rm -f "$PAYLOAD_FILE"

if [[ $uploaded -eq 0 ]]; then
  err "Step 2: No blobs uploaded. Check storage connection string and container."
  exit 1
fi
log "Uploaded $uploaded blobs. Diagnostic setting will stream Transaction metric to Event Hub (may take 1–2 min)."

# --- Step 3: Verify data in Coralogix (Data Usage API) ---
CX_API_HOST="${OTEL_ENDPOINT#*://}"
CX_API_HOST="${CX_API_HOST%%:*}"
CX_API_HOST="${CX_API_HOST%%/*}"
CX_API_HOST="${CX_API_HOST/#ingress./api.}"
CX_DATA_USAGE_URL="https://${CX_API_HOST}/mgmt/openapi/latest/dataplans/data-usage/v2"
CX_SUBSYS="${CORALOGIX_SUBSYSTEM:-diagnosticdata-e2e}"

now_minus_60m() {
  if date -u -d '60 min ago' +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null; then
    return
  fi
  date -u -v-60M +%Y-%m-%dT%H:%M:%S.000Z
}

fetch_data_usage_units() {
  local from to
  from=$(now_minus_60m)
  to=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
  curl -s -G "$CX_DATA_USAGE_URL" \
    --data-urlencode "date_range.fromDate=$from" \
    --data-urlencode "date_range.toDate=$to" \
    --data-urlencode "resolution=1h" \
    --data-urlencode "aggregate=AGGREGATE_BY_SUBSYSTEM" \
    -H "Authorization: Bearer $CORALOGIX_QUERY_API_KEY" 2>/dev/null | head -1 | \
    jq -r --arg sub "$CX_SUBSYS" '(.result.entries // []) | map(select(any(.dimensions[]?; .genericDimension? | select(.key == "subsystem_name" and .value == $sub)))) | map(.units) | add // 0'
}

WAIT_INITIAL="${WAIT_INITIAL:-120}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-15}"

log "Step 3: Waiting ${WAIT_INITIAL}s for diagnostic data to flow, then verifying data in Coralogix (subsystem=$CX_SUBSYS)..."
sleep "$WAIT_INITIAL"

attempt=0
while true; do
  attempt=$((attempt + 1))
  units=$(fetch_data_usage_units)
  echo "Data units: $units"
  if [[ -n "$units" ]] && awk -v n="$units" 'BEGIN{exit (n+0>0)?0:1}'; then
    log "Step 3: Data verified in Coralogix (units=$units)."
    break
  fi
  if [[ $attempt -ge "$MAX_ATTEMPTS" ]]; then
    err "Step 3: No data received in Coralogix after $MAX_ATTEMPTS attempts (last units=${units:-unknown})."
    exit 1
  fi
  log "Step 3: No data yet (attempt $attempt/$MAX_ATTEMPTS), retrying in 30s..."
  sleep 30
done

# --- Step 4: Clean up ---
log "Step 4: Cleaning up resources..."
trap - EXIT
cd "$TERRAFORM_DIR"
terraform destroy -input=false -auto-approve
log "E2E test finished."
