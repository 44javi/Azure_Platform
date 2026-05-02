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

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "owner" {
  description = "Owner of the project or resources"
  type        = string
}

variable "created_by" {
  description = "Tag showing Terraform created this resource"
  type        = string
}

# Networking inputs (assumes VNet/subnets exist in your landing zone)
variable "vnet_id" {
  description = "ID of the spoke VNet hosting this workload"
  type        = string
}

variable "private_endpoints_subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
}

variable "appservice_integration_subnet_id" {
  description = "Subnet ID delegated to Microsoft.Web/serverFarms for App Service VNet integration"
  type        = string
}

# Private DNS zones (typically centralized in a hub/connectivity sub)
variable "private_dns_zone_ids" {
  description = "Map of private DNS zone IDs keyed by service"
  type = object({
    app_service     = string # privatelink.azurewebsites.net
    search          = string # privatelink.search.windows.net
    cognitive       = string # privatelink.cognitiveservices.azure.com
    openai          = string # privatelink.openai.azure.com
    blob            = string # privatelink.blob.core.windows.net
    key_vault       = string # privatelink.vaultcore.azure.net
  })
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
    model_name     = string
    model_version  = string
    sku_name       = string
    sku_capacity   = number
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
      sku_name      = "Standard"
      sku_capacity  = 50
    }
  }
}

# Front Door / custom domain
variable "custom_domain" {
  description = "Custom hostname served by Front Door, e.g. chat.cyberneticparts.com"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace for diagnostics"
  type        = string
}