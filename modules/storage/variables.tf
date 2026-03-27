# Data_resources module variables

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "The full resource ID of the resource group"
  type        = string
}

variable "region" {
  description = "Region where resources will be created"
  type        = string
}

variable "project" {
  description = "project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment for resources"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
}

variable "subnet_id" {
  description = "Private subnet id"
  type        = string
}

variable "vnet_id" {
  description = "Hub virtual network id"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "log_analytics_id" {
  description = "ID of the Log Analytics workspace"
  type        = string
}

variable "adls_logs" {
  description = "List of Data Lake logs to enable"
  type        = list(string)
  default     = []
}

variable "containers" {
  description = "Storage containers for data lake"
  type        = list(any)
}

variable "adls_rbac" {
  description = "Map of group based role assignments for ADLS"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
}

variable "st_retention_days" {
  description = "Number of days to retain deleted blobs and containers"
  type        = number
  default     = 30
}

variable "min_tls_version" {
  description = "Minimum TLS version for the storage account"
  type        = string
  default     = "TLS1_2"
}

variable "https_traffic_only_enabled" {
  description = "Require HTTPS traffic only"
  type        = bool
  default     = true
}

variable "account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "is_hns_enabled" {
  description = "Enable hierarchical namespace (ADLS Gen2)"
  type        = bool
  default     = true
}

variable "allow_nested_items_to_be_public" {
  description = "Allow nested items (blobs) to be public"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the storage account"
  type        = bool
  default     = true
}

variable "container_access_type" {
  description = "Access type for storage containers"
  type        = string
  default     = "private"
}

variable "pe_subresource_names" {
  description = "Subresource names for the private endpoint connection"
  type        = list(string)
  default     = ["dfs"]
}

variable "is_manual_connection" {
  description = "Whether the private endpoint connection is manual"
  type        = bool
  default     = false
}
