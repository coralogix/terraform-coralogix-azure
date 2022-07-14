output "function_app_name" {
  description = "The name of the function app"
  value       = azurerm_linux_function_app.crx-function.name
}

output "function_plan_name" {
  description = "The name of the plan created for the function"
  value       = azurerm_service_plan.crx-function-plan.name
}

output "storage_account_name" {
    description = "The name of the storage account created"
    value = azurerm_storage_account.crx-storage.name
}