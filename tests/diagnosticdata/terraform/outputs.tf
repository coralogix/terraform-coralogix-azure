output "resource_group_name" {
  value = azurerm_resource_group.e2e.name
}

output "resource_group_location" {
  value = azurerm_resource_group.e2e.location
}

output "eventhub_namespace" {
  value = azurerm_eventhub_namespace.ns.name
}

output "eventhub_name" {
  value = azurerm_eventhub.hub.name
}

output "eventhub_resource_group" {
  value = azurerm_resource_group.e2e.name
}

output "storage_account_name" {
  value = azurerm_storage_account.diag_source.name
}

output "storage_account_connection_string" {
  value     = azurerm_storage_account.diag_source.primary_connection_string
  sensitive = true
}

output "blob_container_name" {
  value = azurerm_storage_container.uploads.name
}
