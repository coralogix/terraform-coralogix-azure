# eventhub

Manage the function app which reads logs from `eventhub` and sends them to your *Coralogix* account.

## Pre-requisites

A Resource Group and Storage Account to be used by your Function App must be provided as inputs to the Terraform module.

The EventHub Namespace and Instance must be pre-existing, though a SAS Policy will be created by the Terraform module to allow LISTEN access to the EventHub Instance by the Function App.

## Usage

```hcl
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "eventhub" {
  source = "coralogix/azure/coralogix//modules/eventhub"

  CoralogixRegion = "EU1"
  CustomDomain = < Custom OTLP endpoint if applicable >
  CoralogixPrivateKey = < Private Key >
  CoralogixApplication = "Azure"
  CoralogixSubsystem = "EventHub"
  FunctionResourceGroupName = < Function ResourceGroup Name >
  FunctionStorageAccountName = < Function StorageAccount Name >
  FunctionAppServicePlanType = "Consumption"
  EventhubInstanceName = < Name of EventHub Instance >
  EventhubNamespace = < Name of Eventhub Namespace >
  EventhubResourceGroupName = < Name of Eventhub ResourceGroup >
  EventhubConsumerGroup = "$Default"
  FunctionAppName = ""  # Optional: Custom function app name (auto-generated if not provided)
  NewlinePattern = ""   # Optional: Regex to split multi-line logs (e.g., "\\n")
  BlockingPattern = ""  # Optional: Regex to filter/block logs (e.g., "\\[DEBUG\\]")
  CoralogixApplicationSelector = ""  # Optional: Dynamic app name selector (e.g., "{{ $.category }}")
  CoralogixSubsystemSelector = ""    # Optional: Dynamic subsystem selector (e.g., "{{ $.operationName }}")
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.93 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.4.3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_CoralogixRegion"></a> [CoralogixRegion](#input\_CoralogixRegion) | The Coralogix location region: EU1 (Ireland), EU2 (Stockholm), US1 (Ohio), US2 (Oregon), AP1 (Mumbai), AP2 (Singapore), AP3 (Jakarta) | `string` | n/a | yes |
| <a name="input_CustomDomain"></a> [CustomDomain](#input\_CustomDomain) | Your Custom OTLP endpoint for the Coralogix account. Format: hostname:port | `string` | `ingress.customsubdomain.coralogix.com:443` | no |
| <a name="input_CoralogixPrivateKey"></a> [CoralogixPrivateKey](#input\_CoralogixPrivateKey) | The Coralogix private key which is used to validate your authenticity | `string` | n/a | yes |
| <a name="input_CoralogixApplication"></a> [CoralogixApplication](#input\_CoralogixApplication) | The name of your application. Supports dynamic extraction using templates `{{ $.field }}` or regex `/pattern/` | `string` | n/a | yes |
| <a name="input_CoralogixSubsystem"></a> [CoralogixSubsystem](#input\_CoralogixSubsystem) | The subsystem name of your application. Supports dynamic extraction using templates `{{ $.field }}` or regex `/pattern/` | `string` | n/a | yes |
| <a name="input_FunctionResourceGroupName"></a> [FunctionResourceGroupName](#input\_FunctionResourceGroupName) | The name of the resource group into which to deploy the Function App | `string` | n/a | yes |
| <a name="input_FunctionStorageAccountName"></a> [FunctionStorageAccountName](#input\_FunctionStorageAccountName) | The name of the storage account that the Function App will use | `string` | n/a | yes |
| <a name="input_FunctionAppServicePlanType"></a> [FunctionAppServicePlanType](#input\_FunctionAppServicePlanType) | The type of the App Service Plan to use for the Function App. Choose Premium if you need vNet support. | `string` | `Consumption` | yes |
| <a name="input_EventhubInstanceName"></a> [EventhubInstanceName](#input\_EventhubInstanceName) | The name of the EventHub Instance | `string` | n/a | yes |
| <a name="input_EventhubNamespace"></a> [EventhubNamespace](#input\_EventhubNamespace) | The name of the EventHub Namespace | `string` | n/a | yes |
| <a name="input_EventhubResourceGroupName"></a> [EventhubResourceGroupName](#input\_EventhubResourceGroupName) | The name of the resource group that the eventhub belong to | `string` | n/a | yes |
| <a name="input_EventhubConsumerGroup"></a> [EventhubConsumerGroup](#input\_EventhubConsumerGroup) | The name of the EventHub Consumer Group | `string` | `$Default` | no |
| <a name="input_FunctionAppName"></a> [FunctionAppName](#input\_FunctionAppName) | Optional: Custom name for the Azure Function. If not provided, defaults to `coralogix-eventhub-func-{uniqueId}` | `string` | `""` (auto-generated) | no |
| <a name="input_NewlinePattern"></a> [NewlinePattern](#input\_NewlinePattern) | Optional: Regex pattern to split multi-line text logs into separate entries. Example: `\\n` | `string` | `""` | no |
| <a name="input_BlockingPattern"></a> [BlockingPattern](#input\_BlockingPattern) | Optional: Regex pattern to filter/block logs. Logs matching this pattern will not be sent to Coralogix. Example: `\\[DEBUG\\]` | `string` | `""` | no |
| <a name="input_CoralogixApplicationSelector"></a> [CoralogixApplicationSelector](#input\_CoralogixApplicationSelector) | Optional: Dynamic application name selector. Supports template syntax `{{ $.field }}` for JSON or regex `/pattern/` for plain text. Falls back to CoralogixApplication when selector doesn't match. | `string` | `""` | no |
| <a name="input_CoralogixSubsystemSelector"></a> [CoralogixSubsystemSelector](#input\_CoralogixSubsystemSelector) | Optional: Dynamic subsystem name selector. Supports template syntax `{{ $.field }}` for JSON or regex `/pattern/` for plain text. Falls back to CoralogixSubsystem when selector doesn't match. | `string` | `""` | no |

## Dynamic Application and Subsystem Names

Use `CoralogixApplicationSelector` and `CoralogixSubsystemSelector` for dynamic extraction from log content. These selectors support templates or regex patterns and fall back to the static `CoralogixApplication`/`CoralogixSubsystem` values when no match is found.

### JSON Logs (Template Syntax)

For JSON-formatted logs, use the template syntax with `{{ }}`:

```hcl
# Simple field extraction from JSON body
CoralogixApplicationSelector = "{{ $.category }}"
CoralogixSubsystemSelector   = "{{ $.operationName }}"

# Multiple fallbacks - tries each field until one matches
CoralogixApplicationSelector = "{{ $.category || $.metricName }}"
CoralogixSubsystemSelector   = "{{ $.operationName || $.ApiName }}"

# Use enriched Azure metadata from attributes
CoralogixSubsystemSelector = "{{ attributes.azure.resource_group }}"

# Extract with regex pipe operator
CoralogixSubsystemSelector = "{{ $.resourceId | r'/resourcegroups/([^/]+)/i' }}"
```

### Plain Text Logs (Regex Syntax)

For plain text logs, use the regex-only syntax with `/pattern/`:

```hcl
# Extract from plain text like: "APP=payment-service ENV=production STATUS=ok"
CoralogixApplicationSelector = "/APP=([^\\s]+)/"
CoralogixSubsystemSelector   = "/ENV=([^\\s]+)/"
```

### Fallback Behavior

When a selector doesn't match, the function follows this fallback chain:
1. **Selector** (`CoralogixApplicationSelector` / `CoralogixSubsystemSelector`) - Dynamic extraction from log body
2. **Static value** (`CoralogixApplication` / `CoralogixSubsystem`) - Terraform variables
3. **Default** (`coralogix-azure-eventhub` / `azure`) - Built-in defaults

## Coralogix regions
| Coralogix region | Azure Region | Coralogix OTLP Endpoint |
|------|------------|------------|
| `EU1` | Ireland | ingress.eu1.coralogix.com:443 |
| `EU2` | Stockholm | ingress.eu2.coralogix.com:443 |
| `US1` | Ohio | ingress.us1.coralogix.com:443 |
| `US2` | Oregon | ingress.us2.coralogix.com:443 |
| `AP1` | Mumbai | ingress.ap1.coralogix.com:443 |
| `AP2` | Singapore | ingress.ap2.coralogix.com:443 |
| `AP3` | Jakarta | ingress.ap3.coralogix.com:443 |