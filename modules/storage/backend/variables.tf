variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = null
}

variable "resource_group_id" {
  description = "The full resource ID of the resource group"
  type        = string
  default     = null
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

variable "st_retention_days" {
  description = "Retention period in days for deleted blobs and containers"
  type        = number
  default     = 30
}

variable "account_tier" {
  description = "Performance tier of the storage account (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "account_kind" {
  description = "Kind of storage account (StorageV2 recommended for most use cases)"
  type        = string
  default     = "StorageV2"
}

variable "account_replication_type" {
  description = "Replication strategy for the storage account (e.g. LRS, GRS, RAGRS)"
  type        = string
  default     = "GRS"
}

variable "https_traffic_only_enabled" {
  description = "Restrict all traffic to HTTPS only"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version required for requests to the storage account"
  type        = string
  default     = "TLS1_2"
}

variable "shared_access_key_enabled" {
  description = "Allow authorization via storage account access keys"
  type        = bool
  default     = true
}

variable "default_to_oauth_authentication" {
  description = "Default to Entra ID (OAuth) authentication in the Azure portal"
  type        = bool
  default     = true
}

variable "infrastructure_encryption_enabled" {
  description = "Enable a second layer of encryption at the infrastructure level"
  type        = bool
  default     = false
}

variable "allow_nested_items_to_be_public" {
  description = "Allow blobs and containers to be made publicly accessible"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Allow access to the storage account from public networks"
  type        = bool
  default     = true
}

variable "versioning_enabled" {
  description = "Enable blob versioning to automatically maintain previous blob versions"
  type        = bool
  default     = true
}

variable "change_feed_enabled" {
  description = "Enable the blob change feed to log create, modify, and delete events"
  type        = bool
  default     = true
}

variable "change_feed_retention_in_days" {
  description = "Number of days to retain blob change feed logs"
  type        = number
  default     = 30
}

variable "last_access_time_enabled" {
  description = "Track the last access time for blobs (used for lifecycle management)"
  type        = bool
  default     = true
}

variable "sas_expiration_period" {
  description = "Maximum lifetime of a SAS token in DD.HH:MM:SS format"
  type        = string
  default     = "00.02:00:00"
}

variable "sas_expiration_action" {
  description = "Action taken when a SAS token exceeds the expiration policy (Log or Block)"
  type        = string
  default     = "Log"
}

variable "container_access_type" {
  description = "Public access level for the state container (private disables anonymous access)"
  type        = string
  default     = "private"
}
