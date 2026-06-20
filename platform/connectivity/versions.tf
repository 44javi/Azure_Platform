terraform {
  backend "azurerm" {} 

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.66.0"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  subscription_id     = var.connectivity_subscription_id
  features {
    resource_group {
      # Allow destroy even when the RG contains resources not tracked by Terraform
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "management"
  subscription_id = var.management_subscription_id
  features {}
}