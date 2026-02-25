variable "coralogix_custom_domain" {
  description = "Coralogix ingress FQDN (e.g. ingress.eu2.coralogix.com), no protocol or path. Used for /azure/events/v1."
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
  default = "diagnosticdata-e2e"
}

variable "function_app_service_plan_type" {
  type    = string
  default = "Consumption"
}
