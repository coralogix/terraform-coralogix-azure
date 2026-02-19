variable "coralogix_custom_domain" {
  description = "Coralogix OTLP endpoint as hostname:port (e.g. ingress.eu1.coralogix.com:443)."
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
  default = "eventhub-e2e"
}

variable "function_app_service_plan_type" {
  type    = string
  default = "Consumption"
}

variable "newline_pattern" {
  type    = string
  default = "(?:\\\\r\\\\n|\\\\r|\\\\n)"
}

variable "blocking_pattern" {
  type    = string
  default = ""
}

variable "coralogix_application_selector" {
  type    = string
  default = ""
}

variable "coralogix_subsystem_selector" {
  type    = string
  default = ""
}
