# E2E test: deploy Terraform StorageQueue module (same parameters as ARM in coralogix-azure-serverless).
# Prereqs: resource group, StorageV2 account + queue, and a separate storage account for the function app.
# Step 2 in e2e.sh is replaced by this Terraform applying the module (no ARM).

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
  name_prefix = "storagequeue-e2e"
  location    = "eastus"
}

# Single resource group for the e2e test
resource "azurerm_resource_group" "e2e" {
  name     = "${local.name_prefix}-rg"
  location = local.location
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Storage account containing the queue (StorageV2 per Coralogix docs)
resource "azurerm_storage_account" "queue" {
  name                     = lower(replace("${local.name_prefix}st${random_string.suffix.result}", "-", ""))
  resource_group_name      = azurerm_resource_group.e2e.name
  location                 = azurerm_resource_group.e2e.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  account_kind             = "StorageV2"
}

resource "azurerm_storage_queue" "logs" {
  name                 = "coralogix-logs"
  storage_account_name = azurerm_storage_account.queue.name
}

# Function app storage account (required by the module)
resource "azurerm_storage_account" "function" {
  name                     = lower(replace("${local.name_prefix}fn${random_string.suffix.result}", "-", ""))
  resource_group_name      = azurerm_resource_group.e2e.name
  location                 = azurerm_resource_group.e2e.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  account_kind             = "StorageV2"
}

# Deploy the Terraform module (replaces ARM deployment)
module "storagequeue" {
  source = "../../../modules/storagequeue"

  CoralogixRegion             = "Custom"
  CustomDomain                = var.coralogix_custom_domain
  CoralogixPrivateKey        = var.coralogix_private_key
  CoralogixApplication       = var.coralogix_application
  CoralogixSubsystem         = var.coralogix_subsystem
  FunctionResourceGroupName  = azurerm_resource_group.e2e.name
  FunctionStorageAccountName = azurerm_storage_account.function.name
  FunctionAppServicePlanType = var.function_app_service_plan_type
  StorageQueueName           = azurerm_storage_queue.logs.name
  StorageQueueStorageAccount = azurerm_storage_account.queue.name
  StorageQueueResourceGroupName = azurerm_resource_group.e2e.name
}
