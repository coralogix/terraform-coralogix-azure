variable "OtelEndpoint" {
  description = "Your OTLP endpoint URL (example: https://my-api-endpoint:443)."
  type        = string
}

variable "CoralogixDirectMode" {
  description = "Whether to use Coralogix as an OTLP endpoint."
  type        = string
  default     = "false"
  validation {
    condition     = contains(["true", "false"], var.CoralogixDirectMode)
    error_message = "The coralogix direct mode must be either 'true' or 'false'."
  }
}

variable "CoralogixApiKey" {
  description = "Your Coralogix Send Your Data - API Key. Used in case of using Coralogix as an OTLP endpoint."
  type        = string
  default     = ""
  sensitive   = true
}

variable "CoralogixApplication" {
  description = "The name of the Application in Coralogix."
  type        = string
  default     = "azure"
}

variable "CoralogixSubsystem" {
  description = "The name of the Subsystem in Coralogix."
  type        = string
  default     = "blob-storage-logs"
}

variable "NewlinePattern" {
  description = "The pattern that separates the lines in the blob."
  type        = string
  default     = "(?:\r\n|\r|\n)"
}

variable "PrefixFilter" {
  description = "The prefix filter to apply to the blob container. Use 'NoFilter' to not filter by prefix. Wildcards are not allowed. Use the following format 'subfolder1/subfolder2/'."
  type        = string
  default     = "NoFilter"
}

variable "SuffixFilter" {
  description = "The suffix filter to apply to the blob container. Use 'NoFilter' to not filter by suffix. Wildcards are not allowed. Use the following format '.log'."
  type        = string
  default     = "NoFilter"
}

variable "FunctionResourceGroupName" {
  description = "The name of the resource group into which to deploy the Function App"
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

variable "EventHubNamespace" {
  description = "The name of the Event Hub Namespace."
  type        = string
}

variable "EventHubName" {
  description = "The name of the Event Hub."
  type        = string
}

variable "EventHubResourceGroup" {
  description = "The name of the resource group that contains the Event Hub Namespace."
  type        = string
}

variable "BlobContainerStorageAccount" {
  description = "The name of the Storage Account containing the Blob Container."
  type        = string
}

variable "BlobContainerResourceGroupName" {
  description = "The name of the resource group that contains the Storage Account"
  type        = string
}

variable "VirtualNetworkName" {
  description = "Name of the Virtual Network (leave empty if VNet integration is not needed)"
  type        = string
  default     = ""
}

variable "SubnetName" {
  description = "Name of the Subnet (leave empty if VNet integration is not needed)"
  type        = string
  default     = ""
}

variable "VirtualNetworkResourceGroup" {
  description = "The name of the resource group that contains the Virtual Network"
  type        = string
  default     = ""
}
