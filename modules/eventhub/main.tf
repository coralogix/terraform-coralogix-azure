locals {
  function_name           = var.FunctionAppName != "" ? var.FunctionAppName : "coralogix-eventhub-func-${random_string.this.result}"
  coralogix_regions = {
    EU1    = "ingress.eu1.coralogix.com:443"
    EU2    = "ingress.eu2.coralogix.com:443"
    US1    = "ingress.us1.coralogix.com:443"
    US2    = "ingress.us2.coralogix.com:443"
    AP1    = "ingress.ap1.coralogix.com:443"
    AP2    = "ingress.ap2.coralogix.com:443"
    AP3    = "ingress.ap3.coralogix.com:443"
    Custom = var.CustomDomain
  }
  sku = var.FunctionAppServicePlanType == "Consumption" ? "Y1" : "EP1"
}

resource "random_string" "this" {
  length  = 13
  special = false
  lower   = true
  upper   = false
}

# ------------------------------------------------ Eventhub ------------------------------------------------
data "azurerm_eventhub_namespace" "eventhub-namespace" {
  name                = var.EventhubNamespace
  resource_group_name = var.EventhubResourceGroupName
}

data "azurerm_resource_group" "eventhub-resourcegroup" {
  name = var.EventhubResourceGroupName
}

data "azurerm_eventhub" "EventhubInstance" {
  name                = var.EventhubInstanceName
  namespace_name      = var.EventhubNamespace
  resource_group_name = var.EventhubResourceGroupName
}

resource "azurerm_eventhub_authorization_rule" "instance_sas" {
  name                = "${local.function_name}-SAS"
  namespace_name      = var.EventhubNamespace
  eventhub_name       = var.EventhubInstanceName
  resource_group_name = var.EventhubResourceGroupName
  listen              = true
  send                = false
  manage              = false
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

resource "azurerm_linux_function_app" "eventhub-function" {
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
      node_version = 22
    }
  }
  app_settings = {
    # Environment variable
    CORALOGIX_APPLICATION          = var.CoralogixApplication
    CORALOGIX_PRIVATE_KEY          = var.CoralogixPrivateKey
    CORALOGIX_SUBSYSTEM            = var.CoralogixSubsystem
    OTEL_EXPORTER_OTLP_ENDPOINT    = local.coralogix_regions[var.CoralogixRegion]
    OTEL_EXPORTER_OTLP_HEADERS     = "Authorization=Bearer ${var.CoralogixPrivateKey}"
    EVENTHUB_CONNECT_STRING        = azurerm_eventhub_authorization_rule.instance_sas.primary_connection_string
    EVENTHUB_INSTANCE_NAME         = var.EventhubInstanceName
    EVENTHUB_CONSUMER_GROUP        = var.EventhubConsumerGroup
    FUNCTION_APP_NAME              = local.function_name
    WEBSITE_RUN_FROM_PACKAGE       = "https://github.com/coralogix/coralogix-azure-serverless/releases/download/EventHub-v3.0.0/EventHub-FunctionApp.zip"
  }
}

# ------------------------------------------------ Output ------------------------------------------------
output "RegionCheck" {
  value = data.azurerm_resource_group.functionRG.location == data.azurerm_resource_group.eventhub-resourcegroup.location ? "[Info] Azure Function WAS deployed in the same region as the EventHub" : "[Notice] Azure Function WAS NOT deployed in the same region as the EventHub"
}

output "SyncTriggerCommand" {
  value = "Run this command to sync your Eventhub Triggers:\n\taz resource invoke-action -g ${var.FunctionResourceGroupName} -n ${local.function_name} --action syncfunctiontriggers --resource-type Microsoft.Web/sites"
}