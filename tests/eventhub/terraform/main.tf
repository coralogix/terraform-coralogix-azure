# E2E test: deploy Terraform EventHub module (same parameters as ARM in coralogix-azure-serverless).
# Prereqs: resource group, Event Hub namespace, hub, consumer group, auth rules, function app storage.
# Step 2 in e2e.sh is replaced by this Terraform applying the module (no ARM).

terraform {
  required_version = ">= 1.7.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
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
  name_prefix = "cx-eventhub-e2e"
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

resource "azurerm_eventhub_namespace" "ns" {
  name                = "${local.name_prefix}-ehns-${random_string.suffix.result}"
  location            = azurerm_resource_group.e2e.location
  resource_group_name = azurerm_resource_group.e2e.name
  sku                 = "Standard"
  capacity            = 1
}

resource "azurerm_eventhub" "hub" {
  name                = "logs"
  namespace_name      = azurerm_eventhub_namespace.ns.name
  resource_group_name = azurerm_resource_group.e2e.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_consumer_group" "coralogix" {
  name                = "coralogix-e2e"
  namespace_name      = azurerm_eventhub_namespace.ns.name
  eventhub_name       = azurerm_eventhub.hub.name
  resource_group_name = azurerm_resource_group.e2e.name
}

resource "azurerm_eventhub_namespace_authorization_rule" "listen" {
  name                = "coralogix-e2e-listen"
  namespace_name      = azurerm_eventhub_namespace.ns.name
  resource_group_name = azurerm_resource_group.e2e.name
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_eventhub_namespace_authorization_rule" "send" {
  name                = "e2e-send"
  namespace_name      = azurerm_eventhub_namespace.ns.name
  resource_group_name = azurerm_resource_group.e2e.name
  listen              = false
  send                = true
  manage              = false
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

module "eventhub" {
  source = "../../../modules/eventhub"

  CoralogixRegion             = "Custom"
  CustomDomain                = var.coralogix_custom_domain
  CoralogixPrivateKey         = var.coralogix_private_key
  CoralogixApplication       = var.coralogix_application
  CoralogixSubsystem          = var.coralogix_subsystem
  FunctionResourceGroupName   = azurerm_resource_group.e2e.name
  FunctionStorageAccountName  = azurerm_storage_account.function.name
  FunctionAppServicePlanType  = var.function_app_service_plan_type
  EventhubResourceGroupName   = azurerm_resource_group.e2e.name
  EventhubNamespace           = azurerm_eventhub_namespace.ns.name
  EventhubInstanceName        = azurerm_eventhub.hub.name
  EventhubConsumerGroup       = azurerm_eventhub_consumer_group.coralogix.name
  NewlinePattern              = var.newline_pattern
  BlockingPattern             = var.blocking_pattern
  CoralogixApplicationSelector = var.coralogix_application_selector
  CoralogixSubsystemSelector   = var.coralogix_subsystem_selector
}
