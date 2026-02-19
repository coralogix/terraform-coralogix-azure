output "resource_group_name" {
  value = azurerm_resource_group.e2e.name
}

output "resource_group_location" {
  value = azurerm_resource_group.e2e.location
}

output "storage_account_name" {
  value = azurerm_storage_account.blob.name
}

output "storage_account_resource_group" {
  value = azurerm_resource_group.e2e.name
}

output "blob_container_name" {
  value = azurerm_storage_container.logs.name
}

output "storage_account_connection_string" {
  value     = azurerm_storage_account.blob.primary_connection_string
  sensitive = true
}
