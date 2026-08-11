# storagequeue

Manage the function app which reads logs from `storagequeue` and sends them to your *Coralogix* account.

## Pre-requisites

A Resource Group and Storage Account to be used by your Function App must be provided as inputs to the Terraform module.

The StorageQueue to be monitored must be pre-existing. The Storage Account associated with the StorageQueue must be configured for Public Access.

## Usage

```hcl
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.93"
    }
  }
}

provider "azurerm" {
  features {}
}

module "storagequeue" {
  source = "coralogix/azure/coralogix//modules/storagequeue"

  CoralogixRegion = "EU1"
  CustomDomain = < Custom FQDN if applicable >
  CoralogixPrivateKey = < Private Key >
  CoralogixApplication = "Azure"
  CoralogixSubsystem = "EventHub"
  FunctionResourceGroupName = < Function ResourceGroup Name >
  FunctionStorageAccountName = < Function StorageAccount Name >
  FunctionAppServicePlanType = "Consumption"
  StorageQueueName = < Name of the StorageQueue >
  StorageQueueStorageAccount = < Name of the StorageQueue Storage Account >
  StorageQueueResourceGroupName = < Name of the StorageQueue Resource Group >
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
| <a name="input_CoralogixRegion"></a> [CoralogixRegion](#input\_CoralogixRegion) | The Coralogix location region, possible options are [`EU1`, `EU2`, `US1`, `US2`, `US3`, `AP1`, `AP2`, `AP3`]. The legacy names [`Europe`, `Europe2`, `India`, `Singapore`, `US`, `US2`] are still accepted. | `string` | n/a | yes |
| <a name="input_CustomDomain"></a> [CustomDomain](#input\_CustomDomain) | Your Custom URL for the Coralogix account. Ignore unless you have a custom URL. Just the FQDN, not the whole URL. | `string` | n/a | no |
| <a name="input_CoralogixPrivateKey"></a> [CoralogixPrivateKey](#input\_CoralogixPrivateKey) | The Coralogix private key which is used to validate your authenticity | `string` | n/a | yes |
| <a name="input_CoralogixApplication"></a> [CoralogixApplication](#input\_CoralogixApplication) | The name of your application | `string` | n/a | yes |
| <a name="input_CoralogixSubsystem"></a> [CoralogixSubsystem](#input\_CoralogixSubsystem) | The subsystem name of your application | `string` | n/a | yes |
| <a name="input_FunctionResourceGroupName"></a> [FunctionResourceGroupName](#input\_FunctionResourceGroupName) | The name of the resource group into which to deploy the Function App | `string` | n/a | yes |
| <a name="input_FunctionStorageAccountName"></a> [FunctionStorageAccountName](#input\_FunctionStorageAccountName) | The name of the storage account that the Function App will use | `string` | n/a | yes |
| <a name="input_FunctionAppServicePlanType"></a> [FunctionAppServicePlanType](#input\_FunctionAppServicePlanType) | The type of the App Service Plan to use for the Function App. Choose Premium if you need vNet support. | `string` | `Consumption` | yes |
| <a name="input_StorageQueueName"></a> [StorageQueueName](#input\_StorageQueueName) | The name of the StorageQueue | `string` | n/a | yes |
| <a name="input_StorageQueueStorageAccount"></a> [StorageQueueStorageAccount](#input\_StorageQueueStorageAccount) | The name of the Storage Account containing the StorageQueue | `string` | n/a | yes |
| <a name="input_StorageQueueResourceGroupName"></a> [StorageQueueResourceGroupName](#input\_StorageQueueResourceGroupName) | The name of the resource group that contains the Storage Account | `string` | n/a | yes |

## Coralogix regions
| Coralogix region | Cloud Region | Coralogix Domain |
|------|------------|------------|
| `EU1` | AWS `eu-west-1` | eu1.coralogix.com |
| `EU2` | AWS `eu-north-1` | eu2.coralogix.com |
| `US1` | AWS `us-east-2` | us1.coralogix.com |
| `US2` | AWS `us-west-2` | us2.coralogix.com |
| `US3` | GCP `us-central1` | us3.coralogix.com |
| `AP1` | AWS `ap-south-1` | ap1.coralogix.com |
| `AP2` | AWS `ap-southeast-1` | ap2.coralogix.com |
| `AP3` | AWS `ap-southeast-3` | ap3.coralogix.com |

### Legacy region names

The names below are deprecated but still accepted, so existing configurations keep working. New configurations should use the names above.

| Legacy name | Use instead |
|------|------------|
| `Europe` | `EU1` |
| `Europe2` | `EU2` |
| `India` | `AP1` |
| `Singapore` | `AP2` |
| `US` | `US1` |
| `US2` | `US2` (unchanged) |