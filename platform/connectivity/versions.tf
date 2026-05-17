terraform {
  backend "azurerm" {} # Settings come from backend.hcl

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.66.0"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  subscription_id     = var.subscription_id
  features {
    resource_group {
      # Allow destroy even when the RG contains resources not tracked by Terraform
      prevent_deletion_if_contains_resources = false
    }
  }
}