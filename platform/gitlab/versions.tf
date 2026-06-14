terraform {
  backend "azurerm" {} # Settings come from backend.hcl / -backend-config

  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
      version = "~> 19.0.0"
    }
  }
}

provider "gitlab" {
  base_url = var.gitlab_base_url

  # Authentication: export GITLAB_TOKEN in the environment (a group access
  # token scoped to the top-level group, `api` scope). Never hardcode the
  # token here or commit it. In CI it is a masked/protected CI/CD variable.
}
