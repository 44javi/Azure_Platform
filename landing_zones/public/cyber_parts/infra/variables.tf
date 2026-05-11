# for tags
locals {
  default_tags = {
    owner       = var.owner
    environment = var.environment
    project     = var.project
    region      = var.region
    created_by  = "Terraform"
  }
}

variable "default_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "subscription_id" {
  description = "subscription id for resource groups and resources"
  type        = string
}

variable "management_subscription_id" {
  description = "Subscription ID for management resources"
  type        = string
}

variable "connectivity_subscription_id" {
  description = "Subscription ID for connectivity resources"
  type        = string
}

variable "project" {
  description = "project name for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment for the resources"
  type        = string
}

variable "region" {
  description = "Region where resources will be created"
  type        = string
}

# variable "resource_group_name" {
#   description = "Resource group name"
#   type        = string
# }

variable "owner" {
  description = "Owner of the project or resources"
  type        = string
}

variable "created_by" {
  description = "Tag showing Terraform created this resource"
  type        = string
}

# Networking — hub VNet lookup (management subscription)
variable "hub_vnet_name" {
  description = "Name of the hub VNet in the management subscription"
  type        = string
}

variable "hub_vnet_resource_group_name" {
  description = "Resource group containing the hub VNet in the management subscription"
  type        = string
}

variable "appservice_integration_subnet_name" {
  description = "Name of the subnet delegated to Microsoft.Web/serverFarms for App Service VNet integration"
  type        = string
  default     = ""
}

# SKUs
variable "app_service_plan_sku" {
  description = "App Service Plan SKU. Use P0v3 or P1v3 for private endpoint support."
  type        = string
  default     = "P0v3"
}

variable "search_sku" {
  description = "AI Search SKU"
  type        = string
  default     = "standard"
}

variable "openai_model_deployments" {
  description = "Map of OpenAI model deployments to create in the Foundry account"
  type = map(object({
    model_name    = string
    model_version = string
    sku_name      = string
    sku_capacity  = number
  }))
  default = {
    chat = {
      model_name    = "gpt-4o-mini"
      model_version = "2024-07-18"
      sku_name      = "GlobalStandard"
      sku_capacity  = 50
    }
    embed = {
      model_name    = "text-embedding-3-small"
      model_version = "1"
      sku_name      = "GlobalStandard"
      sku_capacity  = 50
    }
  }
}

# Front Door / custom domain
variable "custom_domain" {
  description = "Custom hostname served by Front Door, e.g. chat.cyberneticparts.com"
  type        = string
  default     = ""
}

variable "law_name" {
  description = "Name of the Log Analytics workspace in the management subscription"
  type        = string
}

variable "law_resource_group_name" {
  description = "Resource group containing the Log Analytics workspace in the management subscription"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the existing Key Vault to reference"
  type        = string
}

variable "key_vault_resource_group_name" {
  description = "Resource group containing the Key Vault"
  type        = string
}

variable "adls_logs" {
  description = "List of Data Lake logs to enable"
  type        = list(string)
  default     = []
}