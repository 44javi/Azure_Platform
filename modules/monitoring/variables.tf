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
  description = "Environment for resources"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
}

variable "alert_email" {
  description = "Email used for monitoring alerts"
  type        = string
}

variable "action_group_short_name" {
  description = "Short name for the monitor action group (max 12 chars)"
  type        = string
  default     = "alerts"
}

variable "log_analytics_sku" {
  description = "SKU for the Log Analytics workspace (Free, PerGB2018, Standalone, CapacityReservation)"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_days" {
  description = "Retention period for logs in days (30-730)"
  type        = number
  default     = 30
}

variable "log_daily_quota_gb" {
  description = "Daily quota in GB for Log Analytics workspace (-1 for unlimited)"
  type        = number
  default     = 1
}

variable "internet_ingestion_enabled" {
  description = "Whether internet ingestion is enabled for the Log Analytics workspace"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Whether internet query is enabled for the Log Analytics workspace"
  type        = bool
  default     = true
}
