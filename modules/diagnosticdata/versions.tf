terraform {
  required_version = ">= 1.7.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.93"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }
  }
}
