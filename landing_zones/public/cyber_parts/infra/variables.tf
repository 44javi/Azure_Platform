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

# Networking — hub VNet lookup (connectivity subscription)
variable "hub_vnet_name" {
  description = "Name of the hub VNet in the connectivity subscription"
  type        = string
}

variable "hub_vnet_resource_group_name" {
  description = "Resource group containing the hub VNet in the connectivity subscription"
  type        = string
}

variable "enable_vpn" {
  description = "Set to true when the hub VPN Gateway is deployed. Enables gateway transit on the hub→spoke peering and use_remote_gateways on the spoke→hub peering so VPN clients can reach this spoke."
  type        = bool
  default     = false
}

# Networking — foundry spoke VNet (this subscription)
variable "spoke_vnet_address_space" {
  description = "Address space for the foundry spoke VNet (e.g. 10.80.0.0/21)"
  type        = string
}

variable "subnets" {
  description = "Subnet configurations for the foundry spoke VNet. Matches the network module schema."
  type = map(object({
    address_prefix                    = string
    name_override                     = optional(string)
    disable_default_outbound          = optional(bool, true)
    attach_nat_gateway                = optional(bool, false)
    private_endpoint_network_policies = optional(string, "Disabled")
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = optional(string)
      source_address_prefixes    = optional(list(string))
      destination_address_prefix = optional(string, "*")
    })), [])
    delegation = optional(object({
      service_name = string
      actions      = optional(list(string), ["Microsoft.Network/virtualNetworks/subnets/action"])
    }))
  }))
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

variable "foundry_rbac_groups" {
  description = "Map of AAD groups to assign roles on the Foundry account"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
  default = {}
}

variable "foundry_rbac_users" {
  description = "Map of users (by email/UPN) to assign roles on the Foundry account"
  type = map(object({
    email                = string
    role_definition_name = string
  }))
  default = {}
}

variable "replication" {
  description = "Storage account replication type (LRS, ZRS, GRS, GZRS)"
  type        = string
  default     = "LRS"
}