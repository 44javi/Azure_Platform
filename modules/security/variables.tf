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

variable "kv_rbac" {
  description = "Map of group based role assignments for Key Vault"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
}
