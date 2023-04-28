variable "CoralogixRegion" {
  description = "The Coralogix location region, possible options are [Europe, Europe2, India, Singapore, US]"
  type        = string
  validation {
    condition     = contains(["Europe", "Europe2", "India", "Singapore", "US"], var.CoralogixRegion)
    error_message = "The coralogix region must be on of these values: [Europe, Europe2, India, Singapore, US]."
  }
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
