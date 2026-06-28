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
  description = "ID of the Key Vault used to store certificate or secret credentials. Not required when credential_type is 'federated'."
  type        = string
  default     = null

  validation {
    condition     = var.credential_type == "federated" || var.key_vault_id != null
    error_message = "key_vault_id is required when credential_type is 'certificate' or 'secret'."
  }
}

variable "credential_type" {
  description = "Type of credential to create for the service principal: 'certificate', 'secret', or 'federated'"
  type        = string
  default     = "secret"

  validation {
    condition     = contains(["certificate", "secret", "federated"], var.credential_type)
    error_message = "credential_type must be one of 'certificate', 'secret', or 'federated'."
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

variable "federated_identity_credentials" {
  description = "Map of federated identity credentials to create when credential_type is 'federated'. For GitLab, issuer is the GitLab instance URL and subject is usually project_path:<group>/<project>:ref_type:<branch-or-tag>:ref:<ref-name>."
  type = map(object({
    display_name = optional(string)
    description  = optional(string)
    issuer       = string
    subject      = string
    audiences    = optional(list(string), ["api://AzureADTokenExchange"])
  }))
  default = {}

  validation {
    condition     = var.credential_type != "federated" || length(var.federated_identity_credentials) > 0
    error_message = "federated_identity_credentials must contain at least one credential when credential_type is 'federated'."
  }
}
