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
  description = "Numerical identifier for resources"
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

variable "public_subnet_id" {
  description = "Public subnet id"
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

variable "username" {
  description = "Username for accounts"
  type        = string
}

variable "vm_private_ip" {
  description = "Static private IP address for the VM"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault to store SSH keys"
  type        = string
}

variable "log_analytics_id" {
  description = "id of the main log workspace"
  type        = string
}

variable "log_location" {
  description = "Location of the Log Analytics workspace for Data Collection Rule"
  type        = string
}
