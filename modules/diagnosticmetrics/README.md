# Diagnostic Metrics

Manage the function app which reads "Disagnostic Settings" metrics from an `eventhub` and sends them to your *Coralogix* account.

## Pre-requisites

A Resource Group and Storage Account to be used by your Function App must be provided as inputs to the Terraform module.

The EventHub Namespace and Instance must be pre-existing, though a SAS Policy will be created by the Terraform module to allow LISTEN access to the EventHub Instance by the Function App.

Metrics configured in a resource's "Diagnostic Settings" must be submitted to the above EventHub. Presently, only "allMetrics" metrics categories are supported. We are working on adding support for additional Azure Metrics categories.

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

module "diagnosticmetrics" {
  source = "coralogix/azure/coralogix//modules/diagnosticmetrics"

  CoralogixRegion = "Europe"
  CoralogixPrivateKey = < Private Key >
  CoralogixApplication = "Azure"
  CoralogixSubsystem = "DiagnosticMetrics"
  FunctionResourceGroupName = < Function ResourceGroup Name >
  FunctionStorageAccountName = < Function StorageAccount Name >
  EventhubInstanceName = < Name of EventHub Instance >
  EventhubNamespace = < Name of Eventhub Namespace >
  EventhubResourceGroupName = < Name of Eventhub ResourceGroup >
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.50.0 |
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
| <a name="input_EventhubInstanceName"></a> [EventhubInstanceName](#input\_EventhubInstanceName) | The name of the EventHub Instance | `string` | n/a | yes |
| <a name="input_EventhubNamespace"></a> [EventhubNamespace](#input\_EventhubNamespace) | The name of the EventHub Namespace | `string` | n/a | yes |
| <a name="input_EventhubResourceGroupName"></a> [EventhubResourceGroupName](#input\_EventhubResourceGroupName) | The name of the resource group that the eventhub belong to. | `string` | n/a | yes |