# Changelog

## EventHub
<!-- To add a new entry write: -->
<!-- ### version / full date -->
<!-- * [Update/Bug fix] message that describes the changes that you apply -->

### 2.0.0 / 20 Nov 2024
[BREAKING CHANGE] Upgrade to EventHub v3.0.0 Function App with the following changes:
* Updated Node.js runtime from 18 to 22
* Updated Azure provider requirement to ~> 4.0 for Node.js 22 support (requires explicit subscription_id in provider configuration)
* Migrated from S3 bucket deployment to GitHub releases
* Replaced REST API with OpenTelemetry (OTLP) protocol for log ingestion
* Updated region naming convention (Europe - EU1, Europe2 - EU2, India - AP1, Singapore - AP2, US - US1)
* Added new regions: US2 (Oregon) and AP3 (Jakarta)
* Added EventHub Consumer Group support with configurable consumer group variable
* Added Function App Name customization support (optional, auto-generated if not provided)
* Changed default function name pattern to match ARM template: `coralogix-eventhub-func-{uniqueId}` (was: `Eventhub-{eventhub-name}-{random}`)
* Updated environment variables to use OTEL format (OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_EXPORTER_OTLP_HEADERS)
* Changed variable names: CORALOGIX_APP_NAME - CORALOGIX_APPLICATION, CORALOGIX_SUB_SYSTEM - CORALOGIX_SUBSYSTEM

**BREAKING CHANGES:** This is a MAJOR version update. Existing deployments will need to:
1. Update region parameters to use the new naming convention (e.g., "Europe" - "EU1")
2. Update Azure provider to ~> 4.0 and explicitly set `subscription_id` in the provider configuration
3. Function app names will follow a new naming pattern (if using auto-generated names)

### 1.0.10 / 23 Feb 2024
[Update/Breaking] Replacing "Classic" Application Insights with Workspace-Based Application Insights.