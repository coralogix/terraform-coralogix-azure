# AZURE Coralogix Terraform module

## Usage

configuration: 

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
```

`eventhub`:

```hcl
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

`blobstorage`:

```hcl
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
## Authors

Module is maintained by [Coralogix](https://github.com/coralogix).

## License

Apache 2 Licensed. See [LICENSE](https://github.com/coralogix/terraform-coralogix-aws/tree/master/LICENSE) for full details.