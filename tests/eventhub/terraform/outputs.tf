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

output "eventhub_consumer_group_name" {
  value = azurerm_eventhub_consumer_group.coralogix.name
}

output "eventhub_send_connection_string" {
  value       = "${azurerm_eventhub_namespace_authorization_rule.send.primary_connection_string};EntityPath=${azurerm_eventhub.hub.name}"
  description = "Connection string for sending events to the Event Hub (used by e2e script)."
  sensitive   = true
}
