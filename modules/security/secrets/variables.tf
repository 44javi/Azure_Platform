
variable "project" {
  description = "project name"
  type        = string
}

variable "environment" {
  description = "environment for naming"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault to store secrets in"
  type        = string
}

variable "default_tags" {
  description = "Tags to apply to all secrets"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  type = map(object({
    length          = optional(number, 32)
    special         = optional(bool, true)
    expiration_date = optional(string, null)
    rotation_key    = optional(string, "v1")

    min_upper   = optional(number, 3)
    min_lower   = optional(number, 3)
    min_numeric = optional(number, 3)
    min_special = optional(number, 2)
  }))
  default = {}
}
