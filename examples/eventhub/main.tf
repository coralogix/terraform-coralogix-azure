terraform {
  required_version = ">= 1.7.4"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

# Use existing resource group for the function app
data "azurerm_resource_group" "function_rg" {
  name = var.function_resource_group
}

# Use existing storage account for the function app
data "azurerm_storage_account" "function_storage" {
  name                = var.function_storage_account_name
  resource_group_name = var.function_resource_group
}

# Deploy the EventHub module
module "eventhub" {
  source = "../../modules/eventhub"

  # Coralogix Configuration
  CoralogixRegion      = var.coralogix_region
  CoralogixPrivateKey  = var.coralogix_private_key
  CoralogixApplication = var.coralogix_application
  CoralogixSubsystem   = var.coralogix_subsystem

  # Function App Configuration
  FunctionResourceGroupName  = data.azurerm_resource_group.function_rg.name
  FunctionStorageAccountName = data.azurerm_storage_account.function_storage.name
  FunctionAppServicePlanType = var.function_app_service_plan_type
  FunctionAppName            = var.function_app_name # Optional: leave empty for auto-generated name

  # EventHub Configuration
  EventhubResourceGroupName = var.eventhub_resource_group
  EventhubNamespace         = var.eventhub_namespace
  EventhubInstanceName      = var.eventhub_instance_name
  EventhubConsumerGroup     = var.eventhub_consumer_group
}

output "sync_trigger_command" {
  description = "Command to sync function triggers"
  value       = module.eventhub.SyncTriggerCommand
}

output "region_check" {
  description = "Region deployment information"
  value       = module.eventhub.RegionCheck
}

