# /modules/security/variables.tf

variable "project" {
  description = "project name"
  type        = string
}

variable "environment" {
  description = "Unique environment for naming"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "The ID of the resource group"
  type        = string
}

variable "region" {
  description = "Region for deployment"
  type        = string
}

variable "default_tags" {
  description = "Default tags for resources"
  type        = map(string)
}

variable "kv_sku_name" {
  description = "SKU name for the Key Vault"
  type        = string
  default     = "standard"
}

variable "kv_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault items"
  type        = number
  default     = 30
}

variable "kv_purge_protection_enabled" {
  description = "Whether purge protection is enabled on the Key Vault"
  type        = bool
  default     = false
}

variable "kv_rbac_authorization_enabled" {
  description = "Whether RBAC authorization is enabled on the Key Vault"
  type        = bool
  default     = true
}

variable "kv_rbac" {
  description = "Map of group based role assignments for Key Vault"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
  default = {}
}
