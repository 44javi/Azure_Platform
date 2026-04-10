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
  }))
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for Databricks-managed subnets (used by the dbx_workspace module)"
  type        = map(string)
}

variable "alert_email" {
  description = "Email used for monitoring alerts"
  type        = string
}

variable "management_subscription_id" {
  description = "Subscription ID for management resources"
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the existing Log Analytics Workspace"
  type        = string
}

variable "log_analytics_resource_group" {
  description = "Resource group of the existing Log Analytics Workspace"
  type        = string
}

variable "containers" {
  description = "Storage containers for data lake"
  type        = list(any)
}

variable "schemas" {
  description = "Schema names for dbx catalog"
  type        = list(any)
}

variable "adls_rbac" {
  description = "Map of group based role assignments for ADLS"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
}

variable "adls_logs" {
  description = "List of Data Lake logs to enable"
  type        = list(string)
  default     = []
}

variable "dbx_rbac" {
  description = "Map of group based role assignments for dbx workspace"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
}

variable "dbx_logs" {
  description = "List of Databricks logs to enable"
  type        = list(string)
  default     = []
}

variable "sqlw_max_clusters" {
  description = "Maximum number of clusters for the SQL warehouse"
  type        = number
  default     = 1
}

variable "sqlw_min_clusters" {
  description = "Minimum number of clusters for the SQL warehouse"
  type        = number
  default     = 1
}

variable "account_id" {
  description = "Databricks account id"
  type        = string
}



# Ingress fields are pending provider support (not yet in v1.112.0 schema).
# Variables are defined now so tfvars is ready
variable "network_policy_ingress_allow_rules" {
  description = "Ingress allow rules: restrict workspace access by IP range, identity, and destination. Pending databricks provider support."
  type = list(object({
    label             = optional(string)
    ip_ranges         = optional(list(string)) # CIDR notation, e.g. ["10.0.0.0/8", "203.0.113.0/24"]
    all_ip_ranges     = optional(bool, false)
    identity_type     = optional(string)       # IDENTITY_TYPE_ALL_USERS | IDENTITY_TYPE_ALL_SERVICE_PRINCIPALS | IDENTITY_TYPE_SELECTED_IDENTITIES
    all_destinations  = optional(bool, false)
  }))
  default = []
}

variable "network_policy_ingress_deny_rules" {
  description = "Ingress deny rules: block workspace access by IP range, identity, and destination. Pending databricks provider support."
  type = list(object({
    label            = optional(string)
    ip_ranges        = optional(list(string))
    all_ip_ranges    = optional(bool, false)
    identity_type    = optional(string)
    all_destinations = optional(bool, false)
  }))
  default = []
}