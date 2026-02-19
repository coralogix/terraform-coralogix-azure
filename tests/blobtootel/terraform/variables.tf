variable "otel_endpoint" {
  description = "OTLP endpoint URL (e.g. https://ingress.eu1.coralogix.com)."
  type        = string
}

variable "coralogix_direct_mode" {
  type    = string
  default = "false"
}

variable "coralogix_api_key" {
  description = "Coralogix Send Your Data API key (when using Coralogix as OTLP endpoint)."
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
  default = "blob-storage-eventhub-e2e"
}

variable "newline_pattern" {
  type    = string
  default = "(?:\\r\\n|\\r|\\n)"
}

variable "prefix_filter" {
  type    = string
  default = "NoFilter"
}

variable "suffix_filter" {
  type    = string
  default = "NoFilter"
}

variable "function_app_service_plan_type" {
  type    = string
  default = "Consumption"
}

variable "virtual_network_name" {
  type    = string
  default = ""
}

variable "subnet_name" {
  type    = string
  default = ""
}

variable "virtual_network_resource_group" {
  type    = string
  default = ""
}
