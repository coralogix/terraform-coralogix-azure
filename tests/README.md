# E2E tests for Terraform Coralogix Azure modules

These tests validate the **terraform-coralogix-azure** modules by deploying each module (with the same parameters as the equivalent ARM templates in [coralogix-azure-serverless](https://github.com/coralogix/coralogix-azure-serverless)), triggering the function with a test payload, and verifying data in Coralogix. Unlike the serverless repo, deployment is done **entirely via Terraform** (no ARM): the test Terraform config provisions prerequisites and then calls the module under test. This ensures the **latest working version of the Terraform modules** is exercised.

## Test suites

| Directory        | Module        | Trigger                    | Verification        |
|------------------|---------------|----------------------------|---------------------|
| `storagequeue/` | StorageQueue  | Message in storage queue   | Logs count API      |
| `eventhub/`     | EventHub      | Event sent to Event Hub    | Logs count API      |
| `diagnosticdata/` | DiagnosticData | Blob uploads → diagnostic → Event Hub | Data usage (metrics) API |
| `blobstorage/`  | BlobStorage (BlobViaEventGrid) | Blob upload → Event Grid | Logs count API      |
| `blobtootel/`    | BlobToOtel    | Blob upload → Event Grid → Event Hub | Logs count API      |

## Prerequisites

- **Azure CLI** installed and logged in (`az login`), or service principal env vars for CI.
- **Terraform** >= 1.7.4.
- **jq** (for Coralogix API responses).
- **Python 3** with `azure-eventhub` only for the **EventHub** test: `pip install -r eventhub/requirements.txt`.

## Environment variables

Set before running any e2e script:

- **OTEL_ENDPOINT** (required) – Coralogix ingress base URL, e.g. `https://ingress.eu2.coralogix.com`.
- **CORALOGIX_API_KEY** (required for all except BlobToOtel when using OTLP only) – Send your data / Private key for the function.
- **CORALOGIX_QUERY_API_KEY** (optional) – For verification step (Data Usage read). Defaults to `CORALOGIX_API_KEY` if unset.

Optional overrides (defaults are per-test):

- **CORALOGIX_APPLICATION** – e.g. `azure`.
- **CORALOGIX_SUBSYSTEM** – e.g. `storage-queue-e2e`, `eventhub-e2e`, etc.
- **FUNCTION_APP_SERVICE_PLAN_TYPE** – `Consumption` or `Premium`.

## Usage

From the repo root or from each test directory:

```bash
export OTEL_ENDPOINT="https://ingress.eu2.coralogix.com"
export CORALOGIX_API_KEY="your-send-your-data-key"
export CORALOGIX_QUERY_API_KEY="your-query-key"

# Run a single test (from repo root)
./tests/storagequeue/e2e.sh
./tests/eventhub/e2e.sh
./tests/diagnosticdata/e2e.sh
./tests/blobstorage/e2e.sh
./tests/blobtootel/e2e.sh
```

Each `e2e.sh`:

1. Deploys Terraform (prereqs + module) in the test’s `terraform/` directory.
2. Triggers the function (queue message, event, or blob upload).
3. Waits and polls the Coralogix API until data is present (or times out).
4. Deletes the resource group and clears Terraform state.

## Difference from coralogix-azure-serverless e2e

- **Serverless e2e**: Terraform only provisions prerequisites (e.g. RG, queue, Event Hub); the **ARM template** is deployed via `az deployment group create` to deploy the function.
- **These e2e tests**: Terraform provisions prerequisites **and** calls the **Terraform module** (e.g. `module "storagequeue" { source = "../../modules/storagequeue" ... }`) with the same logical parameters as the ARM template. No ARM deployment. This tests the Terraform modules with the latest working version.

## Optional: run check scripts only

After a manual deploy, you can run the check scripts to verify logs/metrics without re-running the full e2e:

- `storagequeue/check_logs.sh`
- `eventhub/check_logs.sh`
- `diagnosticdata/check_metrics.sh`
- `blobstorage/check_logs.sh`
- `blobtootel/check_logs.sh`

Set `OTEL_ENDPOINT` and `CORALOGIX_QUERY_API_KEY` (or `CORALOGIX_API_KEY`) as above.
