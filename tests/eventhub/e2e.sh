#!/usr/bin/env bash
#
# E2E test for EventHub Terraform module.
#
# Order of execution:
#   1. Deploy Terraform (RG, Event Hub namespace/hub/consumer group/auth rules, function storage, EventHub module).
#   2. Send test events to the Event Hub to trigger the function.
#   3. Wait 30s, then poll Coralogix Get Logs Count API until count > 0.
#   4. Clean up all resources.
#
# Prerequisites: Azure CLI, Terraform >= 1.7.4, jq, Python 3 with azure-eventhub (pip install azure-eventhub).
# Environment: OTEL_ENDPOINT, CORALOGIX_API_KEY; optional: CORALOGIX_QUERY_API_KEY, CORALOGIX_APPLICATION, CORALOGIX_SUBSYSTEM
#
# Usage:
#   export OTEL_ENDPOINT="https://ingress.eu1.coralogix.com"
#   export CORALOGIX_API_KEY="your-send-your-data-key"
#   ./e2e.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/terraform"

: "${OTEL_ENDPOINT:?Set OTEL_ENDPOINT (e.g. https://ingress.eu1.coralogix.com)}"
: "${CORALOGIX_API_KEY:?Set CORALOGIX_API_KEY (Send your data / Private key for the function)}"

CORALOGIX_QUERY_API_KEY="${CORALOGIX_QUERY_API_KEY:-${CORALOGIX_API_KEY}}"

# CustomDomain for EventHub module: hostname:port
CUSTOM_DOMAIN="${OTEL_ENDPOINT#*://}"
CUSTOM_DOMAIN="${CUSTOM_DOMAIN%%/*}"
if [[ "$CUSTOM_DOMAIN" != *:* ]]; then
  CUSTOM_DOMAIN="${CUSTOM_DOMAIN}:443"
fi

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*"; }
err() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ERROR: $*" >&2; }

cleanup_after_failure() {
  log "Cleaning up after failure..."
  cd "$TERRAFORM_DIR" || return 0
  export TF_VAR_coralogix_custom_domain="${CUSTOM_DOMAIN:-}"
  export TF_VAR_coralogix_private_key="${CORALOGIX_API_KEY:-}"
  export TF_VAR_coralogix_application="${CORALOGIX_APPLICATION:-azure}"
  export TF_VAR_coralogix_subsystem="${CORALOGIX_SUBSYSTEM:-eventhub-e2e}"
  export TF_VAR_function_app_service_plan_type="${FUNCTION_APP_SERVICE_PLAN_TYPE:-Consumption}"
  terraform destroy -input=false -auto-approve 2>/dev/null || true
}
trap cleanup_after_failure EXIT

# --- Step 1: Deploy Terraform (prereqs + module) ---
log "Step 1: Deploying Terraform (Event Hub + EventHub module)..."
cd "$TERRAFORM_DIR"
export TF_VAR_coralogix_custom_domain="$CUSTOM_DOMAIN"
export TF_VAR_coralogix_private_key="$CORALOGIX_API_KEY"
export TF_VAR_coralogix_application="${CORALOGIX_APPLICATION:-azure}"
export TF_VAR_coralogix_subsystem="${CORALOGIX_SUBSYSTEM:-eventhub-e2e}"
export TF_VAR_function_app_service_plan_type="${FUNCTION_APP_SERVICE_PLAN_TYPE:-Consumption}"

terraform init -input=false

# Apply 1: create RG and prereqs only (-refresh=false so module data sources are not evaluated yet).
log "Step 1a: Creating RG, Event Hub namespace/hub/consumer group/auth rules, function storage..."
terraform apply -refresh=false -input=false -auto-approve \
  -target=azurerm_resource_group.e2e \
  -target=random_string.suffix \
  -target=azurerm_eventhub_namespace.ns \
  -target=azurerm_eventhub.hub \
  -target=azurerm_eventhub_consumer_group.coralogix \
  -target=azurerm_eventhub_namespace_authorization_rule.listen \
  -target=azurerm_eventhub_namespace_authorization_rule.send \
  -target=azurerm_storage_account.function

# Apply 2: full apply (EventHub module; data sources now find existing resources).
log "Step 1b: Creating EventHub module..."
terraform apply -input=false -auto-approve

RG_NAME=$(terraform output -raw resource_group_name)
EVENTHUB_NAMESPACE=$(terraform output -raw eventhub_namespace)
EVENTHUB_NAME=$(terraform output -raw eventhub_name)
EVENTHUB_CONSUMER_GROUP=$(terraform output -raw eventhub_consumer_group_name)
EVENTHUB_SEND_CONNECTION_STRING=$(terraform output -raw eventhub_send_connection_string)

log "Terraform outputs: RG=$RG_NAME, EventHub=$EVENTHUB_NAMESPACE/$EVENTHUB_NAME, ConsumerGroup=$EVENTHUB_CONSUMER_GROUP"

# --- Step 2: Send test events to Event Hub ---
log "Step 2: Sending test event (JSON payload) to Event Hub..."
TEST_MESSAGE='{"vendorID":"5","tpepPickupDateTime":1528119858000,"tpepDropoffDateTime":1528121148000,"passengerCount":2,"tripDistance":4.62,"puLocationId":"186","doLocationId":"230","rateCodeId":1,"storeAndFwdFlag":"N","paymentType":2,"fareAmount":13.5,"extra":0,"mtaTax":0.5,"improvementSurcharge":"0.3","tipAmount":2.86,"tollsAmount":0,"totalAmount":17.16}'
if ! python3 "${SCRIPT_DIR}/send_event.py" "$EVENTHUB_SEND_CONNECTION_STRING" "$TEST_MESSAGE"; then
  err "Failed to send event to Event Hub. Install: pip install azure-eventhub"
  exit 1
fi
log "Sent test event to Event Hub: $EVENTHUB_NAMESPACE/$EVENTHUB_NAME"

# --- Step 3: Verify logs in Coralogix ---
CX_API_HOST="${OTEL_ENDPOINT#*://}"
CX_API_HOST="${CX_API_HOST%%:*}"
CX_API_HOST="${CX_API_HOST%%/*}"
CX_API_HOST="${CX_API_HOST/#ingress./api.}"
CX_LOGS_COUNT_URL="https://${CX_API_HOST}/mgmt/openapi/latest/dataplans/data-usage/v2/logs:count"
CX_APP="${CORALOGIX_APPLICATION:-azure}"
CX_SUBSYS="${CORALOGIX_SUBSYSTEM:-eventhub-e2e}"

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
    --data-urlencode "filters.application=$CX_APP" \
    --data-urlencode "filters.subsystem=$CX_SUBSYS" \
    --data-urlencode "subsystem_aggregation=true" \
    -H "Authorization: Bearer $CORALOGIX_QUERY_API_KEY" | head -1 | jq -r '(.result.logsCount // []) | map(.logsCount | tonumber) | add // 0'
}

log "Step 3: Waiting 30s, then verifying logs in Coralogix (app=$CX_APP, subsystem=$CX_SUBSYS)..."
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
