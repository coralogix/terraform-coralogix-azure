# E2E test: deploy Terraform DiagnosticData module (same parameters as ARM in coralogix-azure-serverless).
# Prereqs: RG, Event Hub namespace/hub, auth rules, storage account + diagnostic setting, function storage.
# Flow: Upload blobs → storage transactions → Diagnostic Setting streams to Event Hub → function → Coralogix.

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
  name_prefix = "cx-diagdata-e2e"
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
  name                = "insights-operational-logs"
  namespace_name      = azurerm_eventhub_namespace.ns.name
  resource_group_name = azurerm_resource_group.e2e.name
  partition_count     = 2
  message_retention   = 1
}

resource "azurerm_eventhub_namespace_authorization_rule" "listen" {
  name                = "diagnosticdata-e2e-listen"
  namespace_name      = azurerm_eventhub_namespace.ns.name
  resource_group_name = azurerm_resource_group.e2e.name
  listen              = true
  send                = false
  manage              = false
}

resource "azurerm_eventhub_namespace_authorization_rule" "send" {
  name                = "diagnosticdata-e2e-send"
  namespace_name      = azurerm_eventhub_namespace.ns.name
  resource_group_name = azurerm_resource_group.e2e.name
  listen              = false
  send                = true
  manage              = false
}

resource "azurerm_storage_account" "diag_source" {
  name                     = lower(replace("${local.name_prefix}st${random_string.suffix.result}", "-", ""))
  resource_group_name      = azurerm_resource_group.e2e.name
  location                 = azurerm_resource_group.e2e.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  account_kind             = "StorageV2"
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.diag_source.name
  container_access_type = "private"
}

resource "azurerm_monitor_diagnostic_setting" "storage_to_eventhub" {
  name                           = "diagdata-e2e-stream-to-eventhub"
  target_resource_id             = azurerm_storage_account.diag_source.id
  eventhub_authorization_rule_id  = azurerm_eventhub_namespace_authorization_rule.send.id
  eventhub_name                  = azurerm_eventhub.hub.name

  metric {
    category = "Transaction"
    enabled  = true
  }
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

module "diagnosticdata" {
  source = "../../../modules/diagnosticdata"

  CoralogixRegion            = "Custom"
  CustomDomain               = var.coralogix_custom_domain
  CoralogixPrivateKey       = var.coralogix_private_key
  CoralogixApplication      = var.coralogix_application
  CoralogixSubsystem        = var.coralogix_subsystem
  FunctionResourceGroupName  = azurerm_resource_group.e2e.name
  FunctionStorageAccountName = azurerm_storage_account.function.name
  FunctionAppServicePlanType = var.function_app_service_plan_type
  EventhubResourceGroupName  = azurerm_resource_group.e2e.name
  EventhubNamespace          = azurerm_eventhub_namespace.ns.name
  EventhubInstanceName       = azurerm_eventhub.hub.name
}
