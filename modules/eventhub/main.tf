locals {
  function_name = "Coralogix-functionapp-${random_string.this.result}"
  coralogix_regions = {
    Europe    = "api.coralogix.com"
    Europe2   = "api.eu2.coralogix.com"
    India     = "api.app.coralogix.in"
    Singapore = "api.coralogixsg.com"
    US        = "api.coralogix.us"
  }
}

resource "random_string" "this" {
  length  = 6
  special = false
  lower = true
  upper = false
}

data "azurerm_resource_group" "main-resource-group" {
  name = var.azure_resource_group
}

resource "azurerm_storage_account" "crx-storage" {
  name                     = "coralogixstorage${random_string.this.result}"
  resource_group_name      = var.azure_resource_group
  location                 = data.azurerm_resource_group.main-resource-group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "crx-deployments" {
    name = "coralogix-function-releases-${random_string.this.result}"
    storage_account_name = "${azurerm_storage_account.crx-storage.name}"
    container_access_type = "private"
}

resource "azurerm_storage_blob" "crx-appcode" {
    name = "functionapp.zip"
    storage_account_name = "${azurerm_storage_account.crx-storage.name}"
    storage_container_name = "${azurerm_storage_container.crx-deployments.name}"
    type = "Block"
    source = coalesce(var.package_path, "${path.module}/dist/package.zip")
    content_md5 = filemd5(coalesce(var.package_path, "${path.module}/dist/package.zip"))

}

resource "azurerm_service_plan" "crx-function-plan" {
  name                = "coralogix-plan-${random_string.this.result}"
  resource_group_name = var.azure_resource_group
  location            = data.azurerm_resource_group.main-resource-group.location
  os_type             = "Linux"
  sku_name            = "Y1"
}

data "azurerm_storage_account_sas" "crx-sas" {
    connection_string = "${azurerm_storage_account.crx-storage.primary_connection_string}"
    https_only = true
    start = "2019-01-01"
    expiry = "2099-12-31"
    resource_types {
        object = true
        container = false
        service = false
    }
    services {
        blob = true
        queue = false
        table = false
        file = false
    }
    permissions {
        read = true
        write = false
        delete = false
        list = false
        add = false
        create = false
        update = false
        process = false
        tag = false
        filter = false
    }
}

resource "azurerm_linux_function_app" "crx-function" {
  name                = "coralogix-func-${random_string.this.result}"
  resource_group_name = var.azure_resource_group
  location            = data.azurerm_resource_group.main-resource-group.location
  storage_account_name = azurerm_storage_account.crx-storage.name
  storage_account_access_key = azurerm_storage_account.crx-storage.primary_access_key
  service_plan_id      = azurerm_service_plan.crx-function-plan.id
  functions_extension_version = "~3"
  site_config {
    application_stack {
      node_version = 12
    }
  }
  app_settings = {
    # Environment variable
    CORALOGIX_PRIVATE_KEY = var.private_key
    CORALOGIX_APP_NAME = var.application_name
    CORALOGIX_SUB_SYSTEM = var.subsystem_name
    EventHubConnection = var.azure_eventhub_namespace_connection_string_primary
    AzureWebJobsStorage = azurerm_storage_account.crx-storage.primary_connection_string
    CORALOGIX_URL = "https://${lookup(local.coralogix_regions, var.coralogix_region, "Europe")}/api/v1/logs"
    FUNCTIONS_WORKER_RUNTIME = "node"
    WEBSITE_NODE_DEFAULT_VERSION = "~12"
    FUNCTION_APP_EDIT_MODE = "readonly"
    HASH = "${base64encode(filesha256("${coalesce(var.package_path, "${path.module}/dist/package.zip")}"))}"
    WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.crx-storage.name}.blob.core.windows.net/${azurerm_storage_container.crx-deployments.name}/${azurerm_storage_blob.crx-appcode.name}${data.azurerm_storage_account_sas.crx-sas.sas}"
  }
}