variable "coralogix_region" {
  description = "The Coralogix location region, possible options are [Europe, Europe2, India, Singapore, US]"
  type        = string
  default     = "Europe"
}

variable "private_key" {
  description = "The Coralogix private key which is used to validate your authenticity"
  type        = string
  sensitive   = true
}

variable "application_name" {
  description = "The name of your application"
  type        = string
}

variable "subsystem_name" {
  description = "The subsystem name of your application"
  type        = string
}

variable "package_path" {
  description = "The path to a custom function's bundle"
  type        = string
  default     = null
}

variable "azure_resource_group" {
  description = "The resource group name that the eventhub belong to"
  type = string
}

variable "azure_eventhub_namespace_connection_string_primary" {
  description = "The eventhub-namespace primary connection string with read capabilities"
  type = string
}