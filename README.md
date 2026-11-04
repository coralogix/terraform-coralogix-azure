# AZURE Coralogix Terraform module

## Usage

`configuration`: 

```hcl
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.93"
    }
    azapi = {
      source = "Azure/azapi"
      version = "~> 2.3"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}
```

> `eventhub` and `blobtootel` require the `azapi` provider in addition to `azurerm` (used to apply `WEBSITE_RUN_FROM_PACKAGE` after the function app is created, since Linux Consumption rejects it at create time).

`eventhub`:

```hcl
module "eventhub" {
  source  = "coralogix/azure/coralogix//modules/eventhub"
  version = "~> 3.0"

  CoralogixRegion            = "EU1"
  CustomDomain               = < Custom FQDN if applicable >
  CoralogixPrivateKey        = < Private Key >
  CoralogixApplication       = "Azure"
  CoralogixSubsystem         = "EventHub"
  FunctionResourceGroupName  = < Function ResourceGroup Name >
  FunctionStorageAccountName = < Function StorageAccount Name >
  FunctionAppServicePlanType = "Consumption"
  EventhubInstanceName       = < Name of EventHub Instance >
  EventhubNamespace          = < Name of Eventhub Namespace >
  EventhubResourceGroupName  = < Name of Eventhub ResourceGroup >
}
```

`blobtootel`:

```hcl
module "blobtootel" {
  source  = "coralogix/azure/coralogix//modules/blobtootel"
  version = "~> 3.0"

  OtelEndpoint                   = < OTLP Endpoint >
  FunctionResourceGroupName      = < Function ResourceGroup Name >
  FunctionAppServicePlanType     = "Consumption"
  EventHubNamespace              = < Name of Eventhub Namespace >
  EventHubName                   = < Name of EventHub Instance >
  EventHubResourceGroup          = < Name of Eventhub ResourceGroup >
  BlobContainerStorageAccount    = < Blob Container Storage Account Name >
  BlobContainerResourceGroupName = < Blob Container Resource Group Name >
}
```

`blobstorage`:

```hcl
module "blobstorage" {
  source  = "coralogix/azure/coralogix//modules/blobstorage"
  version = "~> 3.0"

  OtelEndpoint                   = < OTLP endpoint URL, e.g. https://ingress.eu2.coralogix.com >
  CoralogixPrivateKey            = < Private Key >
  CoralogixApplication           = "Azure"
  CoralogixSubsystem             = "BlobStorage"
  FunctionResourceGroupName      = < Function ResourceGroup Name >
  FunctionStorageAccountName     = < Function StorageAccount Name >
  FunctionAppServicePlanType     = "Consumption"
  BlobContainerName              = < Blob Container Name>
  BlobContainerStorageAccount    = < Blob Container Storage Account Name >
  BlobContainerResourceGroupName = < Blob Container Resource Group Name>
  EventGridSystemTopicName       = < EventGrid System Topic Name >
  NewlinePattern                 = < Newline Pattern >
}
```

`storagequeue`:

```hcl
module "storagequeue" {
  source  = "coralogix/azure/coralogix//modules/storagequeue"
  version = "~> 3.0"

  CoralogixRegion               = "EU1"
  CustomDomain                  = < Custom FQDN if applicable >
  CoralogixPrivateKey           = < Private Key >
  CoralogixApplication          = "Azure"
  CoralogixSubsystem            = "StorageQueue"
  FunctionResourceGroupName     = < Function ResourceGroup Name >
  FunctionStorageAccountName    = < Function StorageAccount Name >
  FunctionAppServicePlanType    = "Consumption"
  StorageQueueName              = < Name of the StorageQueue >
  StorageQueueStorageAccount    = < Name of the StorageQueue Storage Account >
  StorageQueueResourceGroupName = < Name of the StorageQueue Resource Group >
}
```

`DiagnosticData`:

```hcl
module "diagnosticdata" {
  source  = "coralogix/azure/coralogix//modules/diagnosticdata"
  version = "~> 3.0"

  CoralogixRegion            = "EU1"
  CustomDomain               = < Custom FQDN if applicable >
  CoralogixPrivateKey        = < Private Key >
  CoralogixApplication       = "Azure"
  CoralogixSubsystem         = "DiagnosticData"
  FunctionResourceGroupName  = < Function ResourceGroup Name >
  FunctionStorageAccountName = < Function StorageAccount Name >
  FunctionAppServicePlanType = "Consumption"
  EventhubInstanceName       = < Name of EventHub Instance >
  EventhubNamespace          = < Name of Eventhub Namespace >
  EventhubResourceGroupName  = < Name of Eventhub ResourceGroup >
}
```


## Upgrading from v2.x to v3.0

Only the `eventhub` and `blobtootel` modules changed; `blobstorage`, `storagequeue` and `diagnosticdata` need no action. Module inputs are unchanged (only new optional variables were added), and existing function apps are updated in place, not recreated.

1. **Add the `azapi` provider** (`Azure/azapi ~> 2.3`) to `required_providers` and a `provider "azapi" {}` block, as shown above.
2. **Run `terraform init -upgrade`**, so the new provider is added to `.terraform.lock.hcl`.
3. **Give `azapi` the same credentials as `azurerm`.** With environment-based authentication (`ARM_*` variables, or `az login`), an empty `provider "azapi" {}` block is enough. If your `azurerm` provider block sets credentials or `subscription_id` explicitly, set the same values in the `azapi` block.
4. **Expect a one-time function restart** on the first `apply`, when the new function package and settings are applied. Event Hub messages received during the restart are processed afterwards.
5. **EventHub retry behaviour changed** (function v3.8.6): a failed export to Coralogix now fails the invocation and is retried until delivered, instead of the logs being dropped silently. During a Coralogix outage or with an invalid API key, failed invocations increase and the affected partition pauses until delivery succeeds.

## Authors

Module is maintained by [Coralogix](https://github.com/coralogix).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/coralogix/terraform-coralogix-aws/tree/master/LICENSE) for full details.
