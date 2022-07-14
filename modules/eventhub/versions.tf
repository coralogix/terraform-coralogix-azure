terraform {
  required_version = ">= 0.13.1"

  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}


