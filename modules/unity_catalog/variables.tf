# /modules/unity_catalog/variables.tf

variable "project" {
  description = "project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment for resource naming"
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
  description = "The region where resources will be created"
  type        = string
}

variable "workspace_id" {
  description = "The ID of the Databricks workspace"
  type        = string
}

variable "datalake_name" {
  description = "The name of the Azure Data Lake Storage account"
  type        = string
}

variable "datalake_id" {
  description = "The resource ID of the Azure Data Lake Storage account"
  type        = string
}

variable "containers" {
  description = "Storage containers in the data lake"
  type        = list(any)
}

variable "schemas" {
  description = "Schema names for dbx catalog"
  type        = list(any)
}

variable "system_schemas" {
  description = "List of Databricks system schemas to enable"
  type        = list(string)
  default     = []
}

variable "sqlw_name" {
  description = "Name of the SQL warehouse. Leave empty to auto-generate with current user"
  type        = string
  default     = ""
}

variable "sqlw_cluster_size" {
  description = "Size of the SQL warehouse clusters (2X-Small, X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large)"
  type        = string
  default     = "2X-Small"

  validation {
    condition     = contains(["2X-Small", "X-Small", "Small", "Medium", "Large", "X-Large", "2X-Large", "3X-Large", "4X-Large"], var.sqlw_cluster_size)
    error_message = "Cluster size must be one of: 2X-Small, X-Small, Small, Medium, Large, X-Large, 2X-Large, 3X-Large, 4X-Large"
  }
}

variable "sqlw_min_clusters" {
  description = "Minimum number of clusters for the SQL warehouse"
  type        = number
  default     = 1
}

variable "sqlw_max_clusters" {
  description = "Maximum number of clusters for the SQL warehouse"
  type        = number
  default     = 1
}

variable "sqlw_auto_stop_mins" {
  description = "Time in minutes until idle SQL warehouse stops (0 to disable auto-stop)"
  type        = number
  default     = 10
}

variable "sqlw_spot_policy" {
  description = "Spot instance policy for SQL warehouse (COST_OPTIMIZED or RELIABILITY_OPTIMIZED)"
  type        = string
  default     = "COST_OPTIMIZED"
}

variable "sqlw_enable_photon" {
  description = "Enable Photon acceleration for the SQL warehouse"
  type        = bool
  default     = true
}

variable "sqlw_enable_serverless" {
  description = "Enable serverless compute for the SQL warehouse"
  type        = bool
  default     = true
}

variable "sqlw_type" {
  description = "SQL warehouse type (PRO or CLASSIC)"
  type        = string
  default     = "PRO"
}

variable "sqlw_channel" {
  description = "SQL warehouse channel name"
  type        = string
  default     = "CHANNEL_NAME_CURRENT"
}
