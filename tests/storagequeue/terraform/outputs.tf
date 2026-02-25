output "resource_group_name" {
  value       = azurerm_resource_group.e2e.name
  description = "Resource group name for cleanup and test."
}

output "resource_group_location" {
  value       = azurerm_resource_group.e2e.location
  description = "Resource group location."
}

output "storage_account_name" {
  value       = azurerm_storage_account.queue.name
  description = "Storage account name containing the queue."
}

output "storage_account_resource_group" {
  value       = azurerm_resource_group.e2e.name
  description = "Resource group of the storage account."
}

output "storage_queue_name" {
  value       = azurerm_storage_queue.logs.name
  description = "Storage queue name for sending test messages."
}

output "storage_account_connection_string" {
  value       = azurerm_storage_account.queue.primary_connection_string
  description = "Storage account connection string for putting test messages into the queue."
  sensitive   = true
}
