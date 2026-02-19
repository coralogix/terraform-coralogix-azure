# E2E test: deploy Terraform BlobToOtel module (same parameters as ARM in coralogix-azure-serverless).
# Prereqs: RG, storage account, container, Event Hub namespace + hub, Event Grid subscription (blob created → Event Hub).
# The module creates the function app (and its own function storage and consumer group).

terraform {
  required_version = ">= 1.7.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.93"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  name_prefix = "blobtootel-e2e"
  location    = "eastus"
}

resource "azurerm_resource_group" "e2e" {
  name     = "${local.name_prefix}-rg"
  location = local.location
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "blob" {
  name                     = lower(replace("${local.name_prefix}st${random_string.suffix.result}", "-", ""))
  resource_group_name      = azurerm_resource_group.e2e.name
  location                 = azurerm_resource_group.e2e.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name   = azurerm_storage_account.blob.name
  container_access_type = "private"
}

resource "azurerm_eventhub_namespace" "ns" {
  name                = "${local.name_prefix}-ehns-${random_string.suffix.result}"
  location            = azurerm_resource_group.e2e.location
  resource_group_name = azurerm_resource_group.e2e.name
  sku                 = "Standard"
  capacity            = 1
}

resource "azurerm_eventhub" "hub" {
  name                = "blob-events"
  namespace_name      = azurerm_eventhub_namespace.ns.name
  resource_group_name = azurerm_resource_group.e2e.name
  partition_count     = 2
  message_retention   = 1
}

# Route blob-created events from storage to Event Hub (triggers the function via module-created consumer group)
resource "azurerm_eventgrid_event_subscription" "storage_to_eventhub" {
  name                 = "${local.name_prefix}-storage-to-eh"
  scope                = azurerm_storage_account.blob.id
  eventhub_endpoint_id = azurerm_eventhub.hub.id
  included_event_types  = ["Microsoft.Storage.BlobCreated"]
}

module "blobtootel" {
  source = "../../../modules/blobtootel"

  OtelEndpoint                  = var.otel_endpoint
  CoralogixDirectMode            = var.coralogix_direct_mode
  CoralogixApiKey               = var.coralogix_api_key
  CoralogixApplication          = var.coralogix_application
  CoralogixSubsystem            = var.coralogix_subsystem
  NewlinePattern                = var.newline_pattern
  PrefixFilter                  = var.prefix_filter
  SuffixFilter                  = var.suffix_filter
  FunctionResourceGroupName     = azurerm_resource_group.e2e.name
  FunctionAppServicePlanType    = var.function_app_service_plan_type
  EventHubNamespace             = azurerm_eventhub_namespace.ns.name
  EventHubName                  = azurerm_eventhub.hub.name
  EventHubResourceGroup         = azurerm_resource_group.e2e.name
  BlobContainerStorageAccount   = azurerm_storage_account.blob.name
  BlobContainerResourceGroupName = azurerm_resource_group.e2e.name
  VirtualNetworkName            = var.virtual_network_name
  SubnetName                    = var.subnet_name
  VirtualNetworkResourceGroup   = var.virtual_network_resource_group
}
