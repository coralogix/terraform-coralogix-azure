variable "coralogix_region" {
  description = "The Coralogix location region, possible options are [Europe, Europe2, India, Singapore, US]"
  type        = string
  default     = "Europe"
    validation {
    condition = contains(["Europe","Europe2","India","Singapore","US"], var.coralogix_region)
    error_message = "The coralogix region must be on of these values: [Europe, Europe2, India, Singapore, US]."
  }
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
  description = "The resource group name that your account-storage belong to"
  type = string
}

variable "azure_account_storage_connection_string" {
  description = "The account-storage key connection string"
  type = string
}

variable "azure_function_newline_pattern" {
  description = "The new line pattern in your log files. will be used by the function to split the lines. default: (?:\r\n|\r|\n)"
  type = string
  default = "(?:\r\n|\r|\n)"
}