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

variable "subscription_id" {
  description = "subscription id for resource groups and resources"
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

variable "owner" {
  description = "Owner of the project or resources"
  type        = string
}

variable "created_by" {
  description = "Tag showing Terraform created this resource"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "Subnet configurations for the network module. See modules/network/variables.tf for the full schema."
  type = map(object({
    address_prefix           = string
    name_override            = optional(string)
    disable_default_outbound = optional(bool, true)
    attach_nat_gateway       = optional(bool, false)
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

variable "private_dns_zones" {
  description = "Private DNS zone names to create in the connectivity hub (e.g. privatelink.blob.core.windows.net)."
  type        = list(string)
  default     = []
}

# ---- VPN Gateway (Point-to-Site) ----

variable "enable_vpn_gateway" {
  description = "Deploy an Azure VPN Gateway for Point-to-Site (P2S) client access."
  type        = bool
  default     = false
}

variable "vpn_gateway_sku" {
  description = "VPN Gateway SKU. P2S session limits: VpnGw1AZ, VpnGw2AZ, VpnGw3AZ, VpnGw3AZ, VpnGw4AZ, VpnGw5AZ, HighPerformance (For Active-Active)."
  type        = string
  default     = "VpnGw1AZ"
}

variable "vpn_gateway_type" {
  description = "Gateway type. Vpn or ExpressRoute."
  type        = string
  default     = "Vpn"
}

variable "vpn_gateway_bgp_enabled" {
  description = "Enable BGP on the gateway. May be required for active-active mode and S2S connections that use dynamic routing."
  type        = bool
  default     = false
}

variable "vpn_gateway_active_active" {
  description = "Enable active-active mode for higher availability."
  type        = bool
  default     = false
}

variable "vpn_client_protocols" {
  description = "Tunnel protocols offered to P2S clients. OpenVPN is required for Entra ID auth. Valid values: OpenVPN, IkeV2, SSTP."
  type        = list(string)
  default     = ["OpenVPN"]
  validation {
    condition     = length([for p in var.vpn_client_protocols : p if !contains(["OpenVPN", "IkeV2", "SSTP"], p)]) == 0
    error_message = "Valid vpn_client_protocols values: OpenVPN, IkeV2, SSTP."
  }
}

variable "vpn_auth_types" {
  description = "Authentication methods for P2S. AAD (Entra ID) requires OpenVPN protocol. Valid values: AAD, Certificate, Radius."
  type        = list(string)
  default     = ["AAD"]
  validation {
    condition     = length([for a in var.vpn_auth_types : a if !contains(["AAD", "Certificate", "Radius"], a)]) == 0
    error_message = "Valid vpn_auth_types values: AAD, Certificate, Radius."
  }
}

variable "vpn_client_address_pool" {
  description = "CIDR block assigned to P2S VPN clients. Must not overlap with the hub VNet or any peered spoke VNets."
  type        = string
  default     = "172.16.201.0/24"
}

variable "tenant_id" {
  description = "Entra ID tenant ID. Required when vpn_auth_types includes 'AAD'"
  type        = string
  default     = null
}

variable "vpn_aad_audience" {
  description = "Azure VPN application (client) ID in Entra ID. Default is the well-known app ID for Azure Public cloud. Tenant admin consent is required."
  type        = string
  default     = "c632b3df-fb67-4d84-bdcf-b95ad541b5c8"
}

variable "vpn_root_cert_data" {
  description = "Base64-encoded public key of the root certificate (no PEM header/footer). Required when vpn_auth_types includes 'Certificate'."
  type        = string
  default     = null
}

# ---- Azure DNS Private Resolver ----

variable "enable_dns_resolver" {
  description = "Deploy an Azure DNS Private Resolver inbound endpoint in the hub VNet. Required for P2S VPN clients to resolve private endpoint FQDNs. Needs a dns_resolver subnet in var.subnets."
  type        = bool
  default     = false
}
