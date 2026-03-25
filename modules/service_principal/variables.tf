variable "project" {
  description = "project name for Key Vault naming"
  type        = string
}

variable "environment" {
  description = "Environment name for Key Vault naming"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where Key Vault is located"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "datalake_id" {
  description = "The resource ID of the Azure Data Lake Storage account"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store SSH keys"
  type        = string
}

variable "role_assignments" {
  description = "Map of role assignments for the service principal"
  type = map(object({
    scope                = string
    role_definition_name = string
  }))
  default = {}
}
