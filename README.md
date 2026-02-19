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
  }
}

provider "azurerm" {
  features {}
}
```

`eventhub`:

```hcl
module "eventhub" {
  source  = "coralogix/azure/coralogix//modules/eventhub"
  version = "1.0.13"

  CoralogixRegion            = "Europe"
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
  version = "1.0.13"

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
  version = "1.0.13"

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
  version = "1.0.13"

  CoralogixRegion               = "Europe"
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
  version = "1.0.13"

  CoralogixRegion            = "Europe"
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


## Authors

Module is maintained by [Coralogix](https://github.com/coralogix).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/coralogix/terraform-coralogix-aws/tree/master/LICENSE) for full details.
