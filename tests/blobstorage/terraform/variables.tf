variable "coralogix_custom_domain" {
  description = "Coralogix ingress FQDN (e.g. ingress.eu2.coralogix.com), no protocol or path."
  type        = string
  default     = "" # Not used by destroy; set TF_VAR_* or -var for apply.
}

variable "coralogix_private_key" {
  description = "Coralogix Send your data / Private key."
  type        = string
  default     = ""
  sensitive   = true
}

variable "coralogix_application" {
  type    = string
  default = "azure"
}

variable "coralogix_subsystem" {
  type    = string
  default = "blob-storage-eventgrid-e2e"
}

variable "function_app_service_plan_type" {
  type    = string
  default = "Consumption"
}

variable "newline_pattern" {
  type    = string
  default = "(?:\\r\\n|\\r|\\n)"
}

variable "debug_enabled" {
  type    = bool
  default = false
}

variable "enable_blob_metadata" {
  type    = bool
  default = false
}
