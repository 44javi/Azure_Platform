terraform {
  backend "azurerm" {} 

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.76.0"
    }
  }
}

# The policy targets whatever subscription this provider points at. Set
# var.subscription_id to the cyber parts subscription to scope it there.
provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}
