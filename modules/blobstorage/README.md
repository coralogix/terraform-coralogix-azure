# blobstorage

Manage the function app which reads logs from files in your account storage and sends them to your *Coralogix* account.

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

module "bloblstorage" {
  source = "coralogix/azure/coralogix//modules/blobstorage"

  coralogix_region   = "Europe"
  private_key        = "3e3a63fc-9e5b-4ca2-a89d-17287c565ddf"
  application_name   = "azure"
  subsystem_name     = "blobstorage-coralogix"
  azure_resource_group = "basic-resource-group"
  azure_account_storage_connection_string = "DefaultEndpointsProtocol=https;AccountName=accountstorage;AccountKey=lFlEx8EsrgiTcZPL5PnRRXRD-rm3ltZ/ih3gjSkbf1B/fZh+H26sJ2YN7lN1cQNiXrg9wBbanckU+ASteBjl0A==;EndpointSuffix=core.windows.net"
}
```
## Important

The function app will search for a specific container called `logs`.
to replace into a different container name:

* extract the package.zip
* change the value of 'bindings.path' field inside BlobStorage/function.json into the desired container name (keep the '/{name}' at the end).
* zip all the contents of the app.
* provide the input 'package_path' to the newly created zip file.

example: 

```json
{
  "scriptFile": "../dist/BlobStorage/index.js",
  "disabled": false,
  "bindings": [
    {
      "name": "blob",
      "type": "blobTrigger",
      "direction": "in",
      "path": "<YOUR_CONTAINER_NAME>/{name}",
      "connection":"InputStorage"
    }
  ]
}
```

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
| <a name="input_azure_resource_group"></a> [azure\_resource\_group](#input\_azure\_resource\_group) | The resource group name that your account-storage belong to | `string` | n/a | yes |
| <a name="azure_account_storage_connection_string"></a> [azure\_account\_storage\_connection\_string](#input\_azure\account\storage\_connection\_string) | The account-storage key connection string | `string` | n/a | yes |
| <a name="azure_function_newline_pattern"></a> [azure\_function\_newline\_pattern](#input\_azure\_function\_newline\_pattern) | The new line pattern in your log files. will be used by the function to split the lines. | `string` | (?:\r\n\|\r\|\n) | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function_app_name"></a> [function\_app\_name](#output\_function\_app\_name) | The name of the function app |
| <a name="output_function_plan_name"></a> [function\_plan\_name](#output\_function\_plan\_name) | The name of the plan created for the function |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | The name of the storage account created |