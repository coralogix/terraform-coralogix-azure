variable "CoralogixRegion" {
  description = "The Coralogix location region: EU1 (Ireland), EU2 (Stockholm), US1 (Ohio), US2 (Oregon), AP1 (Mumbai), AP2 (Singapore), AP3 (Jakarta)"
  type        = string
  validation {
    condition     = contains(["EU1", "EU2", "US1", "US2", "AP1", "AP2", "AP3", "Custom"], var.CoralogixRegion)
    error_message = "The coralogix region must be one of these values: [EU1, EU2, US1, US2, AP1, AP2, AP3, Custom]."
  }
}

variable "CustomDomain" {
  description = "Your Custom OTLP endpoint for the Coralogix account. Ignore unless you have a custom endpoint. Format: hostname:port (e.g., ingress.customsubdomain.coralogix.com:443)"
  type        = string
  default     = "ingress.customsubdomain.coralogix.com:443"
}

variable "CoralogixPrivateKey" {
  description = "The Coralogix private key which is used to validate your authenticity"
  type        = string
  sensitive   = true
}

variable "CoralogixApplication" {
  description = "The name of your application"
  type        = string
}

variable "CoralogixSubsystem" {
  description = "The subsystem name of your application"
  type        = string
}

variable "FunctionResourceGroupName" {
  description = "The name of the resource group into which to deploy the Function App"
  type        = string
}

variable "FunctionStorageAccountName" {
  description = "The name of the storage account that the Function App will use"
  type        = string
}

variable "FunctionAppServicePlanType" {
  description = "The type of the App Service Plan to use for the Function App"
  type        = string
  default     = "Consumption"
  validation {
    condition     = contains(["Consumption", "Premium"], var.FunctionAppServicePlanType)
    error_message = "The function app service plan type must be on of these values: [Consumption, Premium]."
  }
}

variable "EventhubResourceGroupName" {
  description = "The name of the resource group that the eventhub belong to"
  type        = string
}

variable "EventhubNamespace" {
  description = "The name of the EventHub Namespace."
  type        = string
}

variable "EventhubInstanceName" {
  description = "The name of the EventHub Instance."
  type        = string
}

variable "EventhubConsumerGroup" {
  description = "The name of the EventHub Consumer Group."
  type        = string
  default     = "$Default"
}

variable "FunctionAppName" {
  description = "Optional: Custom name for the Azure Function. If not provided, a name will be auto-generated."
  type        = string
  default     = ""
}
