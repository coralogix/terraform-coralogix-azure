variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "coralogix_region" {
  description = "The Coralogix region: EU1 (Ireland), EU2 (Stockholm), US1 (Ohio), US2 (Oregon), AP1 (Mumbai), AP2 (Singapore), AP3 (Jakarta)"
  type        = string
  default     = "EU1"
}

variable "coralogix_private_key" {
  description = "The Coralogix private key"
  type        = string
  sensitive   = true
}

variable "coralogix_application" {
  description = "The Coralogix application name"
  type        = string
  default     = "Azure"
}

variable "coralogix_subsystem" {
  description = "The Coralogix subsystem name"
  type        = string
  default     = "EventHub"
}

variable "coralogix_application_selector" {
  description = "Optional: Dynamic application name selector. Supports template syntax '{{ $.field }}' for JSON or regex '/pattern/' for plain text."
  type        = string
  default     = ""
}

variable "coralogix_subsystem_selector" {
  description = "Optional: Dynamic subsystem name selector. Supports template syntax '{{ $.field }}' for JSON or regex '/pattern/' for plain text."
  type        = string
  default     = ""
}

variable "function_resource_group" {
  description = "The resource group for the function app (using existing resource group)"
  type        = string
}

variable "function_storage_account_name" {
  description = "The name of the existing storage account for the function app"
  type        = string
}

variable "function_app_service_plan_type" {
  description = "The type of the App Service Plan to use for the Function App"
  type        = string
  default     = "Consumption"
  validation {
    condition     = contains(["Consumption", "Premium"], var.function_app_service_plan_type)
    error_message = "The function app service plan type must be one of: Consumption, Premium"
  }
}

variable "function_app_name" {
  description = "Optional: Custom name for the Azure Function. If empty, defaults to coralogix-eventhub-func-{uniqueId}"
  type        = string
  default     = ""
}

variable "eventhub_resource_group" {
  description = "The EventHub resource group name"
  type        = string
}

variable "eventhub_namespace" {
  description = "The EventHub namespace"
  type        = string
}

variable "eventhub_instance_name" {
  description = "The EventHub instance name"
  type        = string
}

variable "eventhub_consumer_group" {
  description = "The EventHub consumer group"
  type        = string
  default     = "$Default"
}

variable "newline_pattern" {
  description = "Optional: Regex pattern to split multi-line text logs into separate entries"
  type        = string
  default     = ""
}

variable "blocking_pattern" {
  description = "Optional: Regex pattern to filter/block logs"
  type        = string
  default     = ""
}

