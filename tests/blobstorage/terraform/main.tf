# E2E test: deploy Terraform BlobStorage (BlobViaEventGrid) module (same parameters as ARM).
# Prereqs: RG, StorageV2 account, container, Event Grid system topic for the storage account, function storage.
# The module creates the Event Grid subscription to the function.

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
  name_prefix = "blobviaeg-e2e"
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
  account_kind             = "StorageV2"
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.blob.name
  container_access_type = "private"
}

# Event Grid system topic for the storage account (required by blobstorage module)
resource "azurerm_eventgrid_system_topic" "storage" {
  name                   = "cxEventGridTopic"
  resource_group_name    = azurerm_resource_group.e2e.name
  location               = azurerm_resource_group.e2e.location
  source_arm_resource_id = azurerm_storage_account.blob.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}

resource "azurerm_storage_account" "function" {
  name                     = lower(replace("${local.name_prefix}fn${random_string.suffix.result}", "-", ""))
  resource_group_name      = azurerm_resource_group.e2e.name
  location                 = azurerm_resource_group.e2e.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  account_kind             = "StorageV2"
}

module "blobstorage" {
  source = "../../../modules/blobstorage"

  CoralogixRegion              = "Custom"
  CustomDomain                 = var.coralogix_custom_domain
  CoralogixPrivateKey         = var.coralogix_private_key
  CoralogixApplication        = var.coralogix_application
  CoralogixSubsystem          = var.coralogix_subsystem
  FunctionResourceGroupName   = azurerm_resource_group.e2e.name
  FunctionStorageAccountName  = azurerm_storage_account.function.name
  FunctionAppServicePlanType  = var.function_app_service_plan_type
  BlobContainerName           = azurerm_storage_container.logs.name
  BlobContainerStorageAccount = azurerm_storage_account.blob.name
  BlobContainerResourceGroupName = azurerm_resource_group.e2e.name
  EventGridSystemTopicName    = azurerm_eventgrid_system_topic.storage.name
  NewlinePattern              = var.newline_pattern
  DebugEnabled                = var.debug_enabled
  EnableBlobMetadata          = var.enable_blob_metadata
}
