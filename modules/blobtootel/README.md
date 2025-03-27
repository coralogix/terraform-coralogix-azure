# Blob to OTEL

Manage the function app which reads logs from `Blobs` in your account storage and sends them to your OTEL endpoint.

## Pre-requisites

A Resource Group, Storage Account and EventHub must be provided as inputs to the Terraform module. Additionally, event notifications to the EventHub must be configured for the Storage Account.

If you are using a Premium App Service Plan, you must also provide a vNet and subnet ID.

Resource Groups for the Storage Account, EventHub and Function App must be provided as inputs to the Terraform module in separate variables.

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

# Standard version without vNet integration
module "blobtootel-standard" {
  source = "coralogix/azure/coralogix//modules/blobtootel"

  OtelEndpoint                   = "my-otel-endpoint.com:4318"
  FunctionResourceGroupName      = "my-function-resource-group"
  FunctionAppServicePlanType     = "Consumption"
  EventHubNamespace              = "my-eventhub-namespace"
  EventHubName                   = "my-eventhub-name"
  EventHubResourceGroup          = "my-eventhub-resource-group"
  BlobContainerStorageAccount    = "my-blob-container-storage-account"
  BlobContainerResourceGroupName = "my-blob-container-resource-group"
}

# Premium version with vNet integration
module "blobtootel-vnet" {
  source = "coralogix/azure/coralogix//modules/blobtootel"

  OtelEndpoint                   = "my-otel-endpoint.com:4318"
  FunctionResourceGroupName      = "my-function-resource-group"
  FunctionAppServicePlanType     = "Premium"
  EventHubNamespace              = "my-eventhub-namespace"
  EventHubName                   = "my-eventhub-name"
  EventHubResourceGroup          = "my-eventhub-resource-group"
  BlobContainerStorageAccount    = "my-blob-container-storage-account"
  BlobContainerResourceGroupName = "my-blob-container-resource-group"
  VirtualNetworkName             = "my-virtual-network"
  SubnetName                     = "my-subnet"
  VirtualNetworkResourceGroup    = "my-virtual-network-resource-group"
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
| <a name="input_OtelEndpoint"></a> [OtelEndpoint](#input\_OtelEndpoint) | The OTLP endpoint to send the logs to. | `string` | n/a | yes |
| <a name="input_CoralogixDirectMode"></a> [CoralogixDirectMode](#input\_CoralogixDirectMode) | Whether to use Coralogix direct mode or not. | `string` | `"false"` | no |
| <a name="input_CoralogixApiKey"></a> [CoralogixApiKey](#input\_CoralogixApiKey) | Your Coralogix Send Your Data - API Key. Used in case of using Coralogix as an OTLP endpoint. | `string` | `""` | no |
| <a name="input_CoralogixApplication"></a> [CoralogixApplication](#input\_CoralogixApplication) | The name of the Application in Coralogix. | `string` | `"azure"` | no |
| <a name="input_CoralogixSubsystem"></a> [CoralogixSubsystem](#input\_CoralogixSubsystem) | The name of the Subsystem in Coralogix. | `string` | `"blob-storage-logs"` | no |
| <a name="input_NewlinePattern"></a> [NewlinePattern](#input\_NewlinePattern) | The pattern that separates the lines in the blob. | `string` | `"(?:\r\n|\r|\n)"` | no |
| <a name="input_PrefixFilter"></a> [PrefixFilter](#input\_PrefixFilter) | The prefix filter to apply to the blob container. Use 'NoFilter' to not filter by prefix. Wildcards are not allowed. Use the following format 'subfolder1/subfolder2/'. | `string` | `"NoFilter"` | no |
| <a name="input_SuffixFilter"></a> [SuffixFilter](#input\_SuffixFilter) | The suffix filter to apply to the blob container. Use 'NoFilter' to not filter by suffix. Wildcards are not allowed. Use the following format '.log'. | `string` | `"NoFilter"` | no |
| <a name="input_FunctionResourceGroupName"></a> [FunctionResourceGroupName](#input\_FunctionResourceGroupName) | The name of the resource group into which to deploy the Function App | `string` | n/a | yes |
| <a name="input_FunctionAppServicePlanType"></a> [FunctionAppServicePlanType](#input\_FunctionAppServicePlanType) | The type of the App Service Plan to use for the Function App | `string` | `"Consumption"` | no |
| <a name="input_EventHubNamespace"></a> [EventHubNamespace](#input\_EventHubNamespace) | The name of the Event Hub Namespace. | `string` | n/a | yes |
| <a name="input_EventHubName"></a> [EventHubName](#input\_EventHubName) | The name of the Event Hub. | `string` | n/a | yes |
| <a name="input_EventHubResourceGroup"></a> [EventHubResourceGroup](#input\_EventHubResourceGroup) | The name of the resource group that contains the Event Hub Namespace. | `string` | n/a | yes |
| <a name="input_BlobContainerStorageAccount"></a> [BlobContainerStorageAccount](#input\_BlobContainerStorageAccount) | The name of the Storage Account containing the Blob Container. | `string` | n/a | yes |
| <a name="input_BlobContainerResourceGroupName"></a> [BlobContainerResourceGroupName](#input\_BlobContainerResourceGroupName) | The name of the resource group that contains the Storage Account | `string` | n/a | yes |
| <a name="input_VirtualNetworkName"></a> [VirtualNetworkName](#input\_VirtualNetworkName) | Name of the Virtual Network (leave empty if VNet integration is not needed) | `string` | `""` | no |
| <a name="input_SubnetName"></a> [SubnetName](#input\_SubnetName) | Name of the Subnet (leave empty if VNet integration is not needed) | `string` | `""` | no |
| <a name="input_VirtualNetworkResourceGroup"></a> [VirtualNetworkResourceGroup](#input\_VirtualNetworkResourceGroup) | The name of the resource group that contains the Virtual Network | `string` | `""` | no |
