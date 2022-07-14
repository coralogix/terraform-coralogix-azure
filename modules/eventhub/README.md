# eventhub

Manage the function app which reads logs from `eventhub` and sends them to your *Coralogix* account.

## Usage

```hcl
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.11"
    }
  }
}

provider "azurerm" {
  features {}
}

module "eventhub" {
  source = "coralogix/azure/coralogix//modules/eventhub"

  coralogix_region   = "Europe"
  private_key        = "2f55c873-c0cf-4523-82d4-c3b68ee6cb46"
  application_name   = "azure"
  subsystem_name     = "eventhub-coralogix"
  azure_resource_group = "basic-resource-group"
  azure_eventhub_namespace_connection_string_primary = "Endpoint=sb://eventbutnamespace.servicebus.windows.net/;SharedAccessKeyName=readonly;SharedAccessKey=YBtHnn3X8jGQ+GNjCFGE7CYVHBy0JgLsfTDKYsKL8TI="
}
```
## Important

The function app will search for a specific eventhub called `coralogix`.
to replace into a different eventhub name:

* extract the package.zip
* change the value of 'eventHubName' field inside Eventhub/function.json into the desired eventhub name.
* zip all the contents of the app.
* provide the input 'package_path' to the newly created zip file.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.11.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_coralogix_region"></a> [coralogix\_region](#input\_coralogix\_region) | The Coralogix location region, possible options are [`Europe`, `Europe2`, `India`, `Singapore`, `US`] | `string` | `Europe` | no |
| <a name="input_private_key"></a> [private\_key](#input\_private\_key) | The Coralogix private key which is used to validate your authenticity | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | The name of your application | `string` | n/a | yes |
| <a name="input_subsystem_name"></a> [subsystem\_name](#input\_subsystem\_name) | The subsystem name of your application | `string` | n/a | yes |
| <a name="input_package_path"></a> [package\_path](#input\_package\_path) | The path to a custom function's bundle | `string` | n/a | no |
| <a name="input_azure_resource_group"></a> [azure\_resource\_group](#input\_azure\_resource\_group) | The resource group name that the eventhub belong to | `string` | n/a | yes |
| <a name="input_azure_eventhub_namespace_connection_string_primary"></a> [azure\_eventhub\_connection\_string](#input\_azure\_eventhub\_namespace\_connection\_string\_primary) | The eventhub-namespace primary connection string with read capabilities | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function_app_name"></a> [function\_app\_name](#output\_function\_app\_name) | The name of the function app |
| <a name="output_function_plan_name"></a> [function\_plan\_name](#output\_function\_plan\_name) | The name of the plan created for the function |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | The name of the storage account created |
