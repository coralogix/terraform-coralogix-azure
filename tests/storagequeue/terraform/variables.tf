# Passed by e2e.sh via TF_VAR_ or .tfvars

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
  description = "Coralogix application name."
  type        = string
  default     = "azure"
}

variable "coralogix_subsystem" {
  description = "Coralogix subsystem name (e.g. storage-queue-e2e)."
  type        = string
  default     = "storage-queue-e2e"
}

variable "function_app_service_plan_type" {
  description = "Function App service plan type."
  type        = string
  default     = "Consumption"
}
