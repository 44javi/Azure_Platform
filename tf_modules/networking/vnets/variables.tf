# network module variables

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "The full resource ID of the resource group"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
  default     = []
}

variable "region" {
  description = "Region where resources will be created"
  type        = string
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment for resources"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "private_dns_zones" {
  description = "Private DNS zone names to create (e.g. privatelink.blob.core.windows.net). Add new zones here without changing module code."
  type        = list(string)
  default     = []
}