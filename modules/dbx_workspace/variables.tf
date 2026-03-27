# /modules/databricks_workspace/variables.tf

variable "project" {
  description = "project name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "region" {
  description = "Region for deployment"
  type        = string
}

variable "environment" {
  description = "Environment for naming"
  type        = string
}

variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
}

variable "vnet_id" {
  description = "The ID of the Virtual Network where the Databricks workspace will be deployed"
  type        = string
}


variable "subnet_id" {
  description = "Private subnet id"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "subnet_address_prefixes" {
  description = "A map of address prefixes for each subnet"
  type        = map(string)
}

variable "nat_gateway_id" {
  description = "nat gateway id"
  type        = string
}

variable "public_ip_id" {
  description = "id of gateway public ip"
  type        = string
}

variable "dbx_logs" {
  description = "List of Databricks log categories to enable"
  type        = list(string)
  default     = []
}

variable "log_analytics_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "dbx_rbac" {
  description = "Map of group based role assignments for dbx workspace"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
}

variable "sku" {
  description = "SKU for the Databricks workspace. Premium enables job clusters, private endpoints, RBAC, audit logs, and cluster policies."
  type        = string
  default     = "premium"
}

variable "no_public_ip" {
  description = "Whether to disable public IP addresses on Databricks cluster nodes (secure cluster connectivity)"
  type        = bool
  default     = true
}

variable "default_outbound_access_enabled" {
  description = "Whether to enable default outbound access for Databricks subnets"
  type        = bool
  default     = false
}
