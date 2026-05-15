# for tags
locals {
  default_tags = {
    owner       = var.owner
    environment = var.environment
    project     = var.project
    region      = var.region
    created_by  = "Terraform"
  }
}

variable "root_management_group_id" {
  description = "The ID of the Root Management Group"
  type        = string
}

variable "subscription_id" {
  description = "subscription id is required even for tenant level resources"
  type        = string
}

variable "project" {
  description = "project name for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment for the resources"
  type        = string
}

variable "region" {
  description = "Region where resources will be created"
  type        = string

  validation {
    condition = contains([
      "centralus",
      "eastus",
      "eastus2",
      "westus2",
      "westus3",
      "southcentralus",
      "northcentralus"
    ], var.region)
    error_message = "Region must be an approved Azure region."
  }
}

variable "alert_email" {
  description = "Email used for monitoring alerts"
  type        = string
}

variable "owner" {
  description = "Owner of the project or resources"
  type        = string
}

variable "regions" {
  description = "Azure regions the Change Tracking policy targets"
  type        = list(string)
  default     = ["centralus", "westus2"]
}

variable "created_by" {
  description = "Tag showing Terraform created this resource"
  type        = string
}

variable "policies" {
  description = "Map of short name to policy definition reference ID for each policy in the assigned initiative"
  type        = map(string)
  default = {
    "assign-uami-vm"   = "adduserassignedmanagedidentity_vm"
    "ext-linux-vm"     = "deploychangetrackingextensionlinuxvm"
    "dcra-linux-vm"    = "dcralinuxvmchangetrackingandinventory"
    "ama-linux-vm-uai" = "deployamalinuxvmwithuaichangetrackingandinventory"
    "ext-windows-vm"   = "deploychangetrackingextensionwindowsvm"
    "dcra-windows-vm"  = "dcrawindowsvmchangetrackingandinventory"
    "ama-windows-vm-uai" = "deployamawindowsvmwithuaichangetrackingandinventory"
  }
}
