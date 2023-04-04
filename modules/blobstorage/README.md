# blobstorage

Manage the function app which reads logs from `Blobs` in your account storage and sends them to your *Coralogix* account.

## Pre-requisites

A Resource Group and Storage Account to be used by your Function App must be provided as inputs to the Terraform module.

The Blob Container must be pre-existing. The Storage Account associated with the Blob Container must be configured for Public Access. Additionally, a configured "Storage Accounts (Blob & GPv2)" EventGrid System Topic must be configured for the Storage Account.

## Usage

```hcl
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.50"
    }
  }
}

provider "azurerm" {
  features {}
}

module "bloblstorage" {
  source = "coralogix/azure/coralogix//modules/blobstorage"

  CoralogixRegion = "Europe"
  CoralogixPrivateKey = < Private Key >
  CoralogixApplication = "Azure"
  CoralogixSubsystem = "EventHub"
  FunctionResourceGroupName = < Function ResourceGroup Name >
  FunctionStorageAccountName = < Function StorageAccount Name >
  BlobContainerName = < Blob Container Name>
  BlobContainerStorageAccount = < Blob Container Storage Account Name >
  BlobContainerResourceGroupName = < Blob Container Resource Group Name>
  EventGridSystemTopicName = < EventGrid System Topic Name >
  NewlinePattern = < Newline Pattern >
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.50 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.4.3 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_CoralogixRegion"></a> [CoralogixRegion](#input\_CoralogixRegion) | The Coralogix location region, possible options are [`Europe`, `Europe2`, `India`, `Singapore`, `US`] | `string` | `Europe` | no |
| <a name="input_CoralogixPrivateKey"></a> [CoralogixPrivateKey](#input\_CoralogixPrivateKey) | The Coralogix private key which is used to validate your authenticity | `string` | n/a | yes |
| <a name="input_CoralogixApplication"></a> [CoralogixApplication](#input\_CoralogixApplication) | The name of your application | `string` | n/a | yes |
| <a name="input_CoralogixSubsystem"></a> [CoralogixSubsystem](#input\_CoralogixSubsystem) | The subsystem name of your application | `string` | n/a | yes |
| <a name="input_FunctionResourceGroupName"></a> [FunctionResourceGroupName](#input\_FunctionResourceGroupName) | The name of the resource group into which to deploy the Function App | `string` | n/a | yes |
| <a name="input_FunctionStorageAccountName"></a> [FunctionStorageAccountName](#input\_FunctionStorageAccountName) | The name of the storage account that the Function App will use | `string` | n/a | yes |
| <a name="input_BlobContainerName"></a> [BlobContainerName](#input\_BlobContainerName) | The name of the Blob Container | `string` | n/a | yes
| <a name="input_BlobContainerStorageAccount"></a> [BlobContainerStorageAccount](#input\_BlobContainerStorageAccount) | The name of the Storage Account containing the Blob Container | `string` | n/a | yes
| <a name="input_BlobContainerResourceGroupName"></a> [BlobContainerResourceGroupName](#input\_BlobContainerResourceGroupName) | The name of the resource group that contains the Storage Account | `string` | n/a | yes
| <a name="input_EventGridSystemTopicName"></a> [EventGridSystemTopicName](#input\_EventGridSystemTopicName) | The name of the Event Grid System Topic | `string` | n/a | yes
| <a name="input_NewlinePattern"></a> [NewlinePattern](#input\_NewlinePattern) | The pattern to use to split the blob into lines | `string` | (?:\r\n|\r|\n) | yes
