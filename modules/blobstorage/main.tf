locals {
  function_name = join("-", ["BlobStorage", substr(var.BlobContainerName, 0, 27), random_string.this.result])
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

# ------------------------------------------------ BlobStorage ------------------------------------------------

data "azurerm_resource_group" "blobstorage-resourcegroup" {
  name = var.BlobContainerResourceGroupName
}

data "azurerm_storage_account" "blobstorage-storageaccount" {
  name                = var.BlobContainerStorageAccount
  resource_group_name = var.BlobContainerResourceGroupName
}

# ------------------------------------------------ EventGrid ------------------------------------------------

data "azurerm_eventgrid_system_topic" "eventgrid-systemtopic" {
  name                = var.EventGridSystemTopicName
  resource_group_name = var.BlobContainerResourceGroupName
}

resource "azurerm_eventgrid_system_topic_event_subscription" "eventgrid-subscription" {
  name                = local.function_name
  system_topic        = var.EventGridSystemTopicName
  resource_group_name = var.BlobContainerResourceGroupName
  azure_function_endpoint {
    function_id                       = "${azurerm_linux_function_app.blobstorage-function.id}/functions/BlobViaEventGrid"
    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }
  included_event_types = ["Microsoft.Storage.BlobCreated"]
  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440
  }
  depends_on = [azurerm_linux_function_app.blobstorage-function]
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

resource "azurerm_linux_function_app" "blobstorage-function" {
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
    CORALOGIX_APP_NAME                     = var.CoralogixApplication
    CORALOGIX_PRIVATE_KEY                  = var.CoralogixPrivateKey
    CORALOGIX_SUB_SYSTEM                   = var.CoralogixSubsystem
    CORALOGIX_URL                          = "https://${local.coralogix_regions[var.CoralogixRegion]}/api/v1/logs"
    BLOB_STORAGE_ACCOUNT_CONNECTION_STRING = data.azurerm_storage_account.blobstorage-storageaccount.primary_connection_string
    WEBSITE_RUN_FROM_PACKAGE               = "https://coralogix-public.s3.eu-west-1.amazonaws.com/azure-functions-repo/BlobViaEventGrid.zip"
    NEWLINE_PATTERN                        = var.NewlinePattern
    DEBUG_ENABLED                          = var.DebugEnabled
    ENABLE_BLOB_METADATA                   = var.EnableBlobMetadata
  }
}

output "SyncTriggerCommand" {
  value = "Run this command to sync your EventGrid Triggers:\n\taz resource invoke-action -g ${var.FunctionResourceGroupName} -n ${local.function_name} --action syncfunctiontriggers --resource-type Microsoft.Web/sites"
}
