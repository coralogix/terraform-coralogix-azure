locals {
  function_name = join("-", ["StorageQueue", substr(var.StorageQueueName, 0, 27), random_string.this.result])
  coralogix_regions = {
    Europe    = "ingress.coralogix.com"
    Europe2   = "ingress.eu2.coralogix.com"
    India     = "ingress.coralogix.in"
    Singapore = "ingress.coralogixsg.com"
    US        = "ingress.coralogix.us"
    US2       = "ingress.cx498.coralogix.com"
    Custom    = var.CustomDomain
  }
    sku = var.FunctionAppServicePlanType == "Consumption" ? "Y1" : "EP1"
}

resource "random_string" "this" {
  length  = 13
  special = false
  lower   = true
  upper   = false
}

# ------------------------------------------------ StorageQueue ------------------------------------------------
data "azurerm_resource_group" "storagequeue-resourcegroup" {
  name = var.StorageQueueResourceGroupName
}

data "azurerm_storage_account" "storagequeue-storageaccount" {
  name                = var.StorageQueueStorageAccount
  resource_group_name = var.StorageQueueResourceGroupName
}

# ------------------------------------------------ Function App ------------------------------------------------
data "azurerm_resource_group" "functionRG" {
  name = var.FunctionResourceGroupName
}

data "azurerm_storage_account" "functionSA" {
  name                = var.FunctionStorageAccountName
  resource_group_name = var.FunctionResourceGroupName
}

resource "azurerm_service_plan" "service-plan" {
  name                = "${local.function_name}-plan"
  resource_group_name = var.FunctionResourceGroupName
  location            = data.azurerm_resource_group.functionRG.location
  os_type             = "Linux"
  sku_name            = local.sku
}

resource "azurerm_log_analytics_workspace" "crx-workspace" {
  name                = "${local.function_name}-workspace"
  location            = data.azurerm_resource_group.functionRG.location
  resource_group_name = var.FunctionResourceGroupName
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

resource "azurerm_application_insights" "crx-appinsights" {
  name                = "${local.function_name}-appinsights"
  resource_group_name = var.FunctionResourceGroupName
  location            = data.azurerm_resource_group.functionRG.location
  workspace_id        = azurerm_log_analytics_workspace.crx-workspace.id
  application_type    = "web"
}

resource "azurerm_linux_function_app" "storagequeue-function" {
  name                        = local.function_name
  resource_group_name         = var.FunctionResourceGroupName
  location                    = data.azurerm_resource_group.functionRG.location
  storage_account_name        = var.FunctionStorageAccountName
  storage_account_access_key  = data.azurerm_storage_account.functionSA.primary_access_key
  service_plan_id             = azurerm_service_plan.service-plan.id
  functions_extension_version = "~4"
  site_config {
    application_insights_key               = azurerm_application_insights.crx-appinsights.instrumentation_key
    application_insights_connection_string = azurerm_application_insights.crx-appinsights.connection_string
    application_stack {
      node_version = 18
    }
  }
  app_settings = {
    # Environment variable
    CORALOGIX_APP_NAME           = var.CoralogixApplication
    CORALOGIX_PRIVATE_KEY        = var.CoralogixPrivateKey
    CORALOGIX_SUB_SYSTEM         = var.CoralogixSubsystem
    CORALOGIX_URL                = "https://${local.coralogix_regions[var.CoralogixRegion]}/api/v1/logs"
    STORAGE_QUEUE_CONNECT_STRING = data.azurerm_storage_account.storagequeue-storageaccount.primary_connection_string
    STORAGE_QUEUE_NAME           = var.StorageQueueName
    WEBSITE_RUN_FROM_PACKAGE     = "https://coralogix-public.s3.eu-west-1.amazonaws.com/azure-functions-repo/StorageQueue.zip"
  }
}

# ------------------------------------------------ Output ------------------------------------------------
output "RegionCheck" {
  value = data.azurerm_resource_group.functionRG.location == data.azurerm_resource_group.storagequeue-resourcegroup.location ? "[Info] Azure Function WAS deployed in the same region as the StorageQueue" : "[Notice] Azure Function WAS NOT deployed in the same region as the StorageQueue"
}

output "SyncTriggerCommand" {
  value = "Run this command to sync your StorageQueue Triggers:\n\taz resource invoke-action -g ${var.FunctionResourceGroupName} -n ${local.function_name} --action syncfunctiontriggers --resource-type Microsoft.Web/sites"
}