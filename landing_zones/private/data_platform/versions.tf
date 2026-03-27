terraform {
  backend "azurerm" {} # Settings come from backend.hcl

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.25.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.87.0"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  subscription_id     = var.subscription_id
  features {}
}

provider "azurerm" {
  alias           = "management"
  subscription_id = var.management_subscription_id
  features {}
}

provider "azuread" {
  # configuration options
}

provider "databricks" {
  alias = "create_workspace"
}

provider "databricks" {
  alias                       = "workspace_resources"
  host                        = module.dbx_workspace.workspace_url
  azure_workspace_resource_id = module.dbx_workspace.workspace_id
  /*
  azure_client_id            = module.entra_id.client_id
  azure_client_secret        = module.entra_id.client_secret
  azure_tenant_id            = module.entra_id.tenant_id
  */
}