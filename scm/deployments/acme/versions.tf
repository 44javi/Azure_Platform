terraform {
  required_version = ">= 1.5"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 17.0"
    }
  }

  # Reuse the same remote backend pattern as the Azure roots. Supply the
  # concrete values with -backend-config at init time, e.g.:
  #   terraform init -backend-config=backend/prod.azurerm.tfbackend
  # backend "azurerm" {}
}
