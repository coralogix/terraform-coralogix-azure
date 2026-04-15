# Changelog

## v2.3.0
#### **eventhub**
### 💡 Enhancements 💡
- Upgrade to EventHub v3.8.0 Function App with optional metadata attributes support
- Added `IncludeMetadata` variable (default: `false`) - When enabled, attaches additional OTel attributes per log record: `threadId`, `message.index`, `azure.subscription_id`, `azure.resource_group`, and `azure.provider`
- `function.name` is always included regardless of the setting
- Backwards compatible: existing deployments unaffected by default

## v2.2.0
#### **eventhub**
### 💡 Enhancements 💡
- Upgrade to EventHub v3.6.0 Function App with dynamic Application/Subsystem selector support
- Added `CoralogixApplicationSelector` variable - Dynamic application name selector with template `{{ $.field }}` or regex `/pattern/` syntax
- Added `CoralogixSubsystemSelector` variable - Dynamic subsystem name selector with template `{{ $.field }}` or regex `/pattern/` syntax
- Selectors support fallback expressions with `||` operator (e.g., `{{ $.category || $.metricName }}`)
- Falls back to static `CoralogixApplication`/`CoralogixSubsystem` when selector doesn't match
- Updated Function App package to v3.6.1

## v2.1.0
#### **eventhub**
### 💡 Enhancements 💡
- Upgrade to EventHub v3.5.0 Function App with dynamic app/subsystem name and log filtering support
- Added `NewlinePattern` variable - Regex pattern to split multi-line text logs into separate entries
- Added `BlockingPattern` variable - Regex pattern to filter/block logs (e.g., `\[DEBUG\]` to block debug logs)
- Updated Function App package to v3.5.0

## v2.0.0
#### **eventhub**
### ⚠️ Breaking Change ⚠️
- Upgrade to EventHub v3.0.0 Function App with BREAKING CHANGES:
  - Updated Node.js runtime from 18 to 22
  - Updated Azure provider requirement to ~> 4.0 for Node.js 22 support (requires explicit subscription_id in provider configuration)
  - Migrated from S3 bucket deployment to GitHub releases
  - Replaced REST API with OpenTelemetry (OTLP) protocol for log ingestion
  - Updated region naming convention (Europe → EU1, Europe2 → EU2, India → AP1, Singapore → AP2, US → US1)
  - Added new regions: US2 (Oregon) and AP3 (Jakarta)
  - Added EventHub Consumer Group support with configurable consumer group variable
  - Added Function App Name customization support (optional, auto-generated if not provided)
  - Changed default function name pattern to match ARM template: `coralogix-eventhub-func-{uniqueId}`
  - Updated environment variables to use OTEL format (OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_EXPORTER_OTLP_HEADERS)
  - Changed variable names: CORALOGIX_APP_NAME → CORALOGIX_APPLICATION, CORALOGIX_SUB_SYSTEM → CORALOGIX_SUBSYSTEM

## v1.0.14
#### **Multiple Modules**
### 🔧 Maintenance 🔧
- ci: add terraform validate steps

## v1.0.13
#### **blobstorage**
### 💡 Enhancements 💡
- CDS-2391 rewrite the function to otel-logs-sdk

## v1.0.12
#### **blobstorage**
### 💡 Enhancements 💡
- Add EnableBlobMetadata variable to enable logging metadata including the blob name and path.

## v1.0.11
#### **blobstorage**
### 💡 Enhancements 💡
- Add DebugEnabled variable to enable debug logging in the Function App.

## v1.0.10
#### **blobstorage**, **diagnosticdata**, **eventhub**, **storagequeue**
### ⚠️ Breaking Change ⚠️
- Replacing "Classic" Application Insights with Workspace-Based Application Insights.

#### **diagnosticdata**
### 💡 Enhancements 💡
- Add missing FunctionAppServicePlanType to variables.tf

## v1.0.0
#### **blobtootel**
### 🚀 New components 🚀
- Initial release.
