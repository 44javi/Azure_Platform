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
  default     = ""
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store SSH keys"
  type        = string
}

variable "credential_type" {
  description = "Type of credential to create for the service principal: 'certificate' or 'secret'"
  type        = string
  default     = "secret"

  validation {
    condition     = contains(["certificate", "secret"], var.credential_type)
    error_message = "credential_type must be either 'certificate' or 'secret'."
  }
}

variable "secret_rotation_days" {
  description = "Number of days before the service principal secret is rotated"
  type        = number
  default     = 90
}

variable "role_assignments" {
  description = "Map of role assignments for the service principal"
  type = map(object({
    scope                = string
    role_definition_name = string
  }))
  default = {}
}
