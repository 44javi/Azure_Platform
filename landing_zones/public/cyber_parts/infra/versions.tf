terraform {
  backend "azurerm" {} # Settings come from backend.hcl

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.76.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.8.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.10.0"
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
    cognitive_account {
      # Skip soft-delete on destroy so the name is immediately reusable on the next apply
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azurerm" {
  alias           = "management"
  subscription_id = var.management_subscription_id
  features {}
}

provider "azurerm" {
  alias           = "connectivity"
  subscription_id = var.connectivity_subscription_id
  features {}
}

provider "azuread" {
  # Configuration options
}

provider "azapi" {
  # Configuration options
}