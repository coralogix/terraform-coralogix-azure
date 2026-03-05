locals {
  function_name = join("-", ["BlobToOtel", substr(var.BlobContainerStorageAccount, 0, 27), random_string.this.result])
  storage_name  = lower(substr(replace(join("", ["fn", var.BlobContainerStorageAccount, random_string.this.result]), "-", ""), 0, 24))
  sku           = var.FunctionAppServicePlanType == "Consumption" ? "Y1" : "EP1"
}

resource "random_string" "this" {
  length  = 5
  special = false
  lower   = true
  upper   = false
}

# ------------------------------------------------ Blob Storage ------------------------------------------------

data "azurerm_resource_group" "blobtootel-resourcegroup" {
  name = var.BlobContainerResourceGroupName
}

data "azurerm_storage_account" "blobtootel-storageaccount" {
  name                = var.BlobContainerStorageAccount
  resource_group_name = var.BlobContainerResourceGroupName
}

# ------------------------------------------------ EventHub ------------------------------------------------

data "azurerm_eventhub_namespace" "eventhub-namespace" {
  name                = var.EventHubNamespace
  resource_group_name = var.EventHubResourceGroup
}

data "azurerm_eventhub" "eventhub" {
  name                = var.EventHubName
  namespace_name      = var.EventHubNamespace
  resource_group_name = var.EventHubResourceGroup
}

data "azurerm_eventhub_namespace_authorization_rule" "eventhub-namespace-auth" {
  name                = "RootManageSharedAccessKey" # This is the default rule name
  namespace_name      = var.EventHubNamespace
  resource_group_name = var.EventHubResourceGroup
}

resource "azurerm_eventhub_consumer_group" "eventhub-consumergroup" {
  name                = local.function_name
  namespace_name      = var.EventHubNamespace
  eventhub_name       = var.EventHubName
  resource_group_name = var.EventHubResourceGroup
}

# ------------------------------------------------ vNet Integration ------------------------------------------------

# Add data source for subnet (only if Premium plan is selected)
data "azurerm_subnet" "function_subnet" {
  count                = var.FunctionAppServicePlanType == "Premium" ? 1 : 0
  name                 = var.SubnetName
  virtual_network_name = var.VirtualNetworkName
  resource_group_name  = var.VirtualNetworkResourceGroup
}

# ------------------------------------------------ Function App ------------------------------------------------

data "azurerm_resource_group" "functionRG" {
  name = var.FunctionResourceGroupName
}

resource "azurerm_storage_account" "functionSA" {
  name                     = local.storage_name
  resource_group_name      = var.FunctionResourceGroupName
  location                 = data.azurerm_resource_group.functionRG.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
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

resource "azurerm_linux_function_app" "blobtootel-function" {
  name                        = local.function_name
  resource_group_name         = var.FunctionResourceGroupName
  location                    = data.azurerm_resource_group.functionRG.location
  storage_account_name        = azurerm_storage_account.functionSA.name
  storage_account_access_key  = azurerm_storage_account.functionSA.primary_access_key
  service_plan_id             = azurerm_service_plan.service-plan.id
  functions_extension_version = "~4"
  virtual_network_subnet_id   = var.FunctionAppServicePlanType == "Premium" ? data.azurerm_subnet.function_subnet[0].id : null
  site_config {
    application_stack {
      node_version = 20
    }
  }
  app_settings = {
    OTEL_EXPORTER_OTLP_ENDPOINT              = var.OtelEndpoint
    CORALOGIX_DIRECT_MODE                    = var.CoralogixDirectMode
    CORALOGIX_API_KEY                        = var.CoralogixApiKey
    CORALOGIX_APPLICATION                    = var.CoralogixApplication
    CORALOGIX_SUBSYSTEM                      = var.CoralogixSubsystem
    EVENT_HUB_NAME                           = var.EventHubName
    NEWLINE_PATTERN                          = var.NewlinePattern
    PREFIX_FILTER                            = var.PrefixFilter
    SUFFIX_FILTER                            = var.SuffixFilter
    BLOB_STORAGE_ACCOUNT_CONNECTION_STRING   = data.azurerm_storage_account.blobtootel-storageaccount.primary_connection_string
    EVENT_HUB_NAMESPACE_CONNECTION_STRING    = data.azurerm_eventhub_namespace_authorization_rule.eventhub-namespace-auth.primary_connection_string
    AzureWebJobsStorage                      = azurerm_storage_account.functionSA.primary_connection_string
    APPLICATIONINSIGHTS_CONNECTION_STRING    = azurerm_application_insights.crx-appinsights.connection_string
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.functionSA.primary_connection_string
    WEBSITE_CONTENTSHARE                     = lower(local.function_name)
    FUNCTIONS_EXTENSION_VERSION              = "~4"
    FUNCTIONS_WORKER_RUNTIME                 = "node"
    WEBSITE_RUN_FROM_PACKAGE                 = "https://coralogix-public.s3.eu-west-1.amazonaws.com/azure-functions-repo/BlobToOtel.zip"
  }
}

# ------------------------------------------------ Output ------------------------------------------------

output "RegionCheck" {
  value = data.azurerm_resource_group.functionRG.location == data.azurerm_resource_group.blobtootel-resourcegroup.location ? "[Info] Azure Function WAS deployed in the same region as the Storage Blob" : "[Notice] Azure Function WAS NOT deployed in the same region as the Storage Blob"
}

output "SyncTriggerCommand" {
  value = "Run this command to sync your StorageQueue Triggers:\n\taz resource invoke-action -g ${var.FunctionResourceGroupName} -n ${local.function_name} --action syncfunctiontriggers --resource-type Microsoft.Web/sites"
}
