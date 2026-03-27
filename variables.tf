# root variables.tf

variable "client" {
  description = "Client name for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment for the resources"
  type        = string
}

variable "region" {
  description = "Region where resources will be created"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
}


variable "subnets" {
  description = "Subnet configurations for the network module. See modules/network/variables.tf for the full schema."
  type = map(object({
    address_prefix           = string
    name_override            = optional(string)
    disable_default_outbound = optional(bool, true)
    attach_nat_gateway       = optional(bool, false)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = optional(string)
      source_address_prefixes    = optional(list(string))
      destination_address_prefix = optional(string, "*")
    })), [])
  }))
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for Databricks-managed subnets (used by the dbx_workspace module)"
  type        = map(string)
}

variable "vm_private_ip" {
  description = "Static private IP address for the VM"
  type        = string
}

variable "alert_email" {
  description = "Email used for monitoring alerts"
  type        = string
}

variable "owner" {
  description = "Owner of the project or resources"
  type        = string
}

variable "project" {
  description = "Main project associated with this deployment"
  type        = string
}

variable "created_by" {
  description = "Tag showing Terraform created this resource"
  type        = string
}

variable "containers" {
  description = "Storage containers for data lake"
  type        = list(any)
}

variable "schemas" {
  description = "Schema names for dbx catalog"
  type        = list(any)
}

variable "dbx_logs" {
  description = "List of Databricks logs to enable"
  type        = list(string)
  default     = []
}

variable "adls_logs" {
  description = "List of Data Lake logs to enable"
  type        = list(string)
  default     = []
}

variable "username" {
  description = "Username for accounts"
  type        = string
}

variable "kv_rbac" {
  description = "Map of group based role assignments for Key Vault"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
}

variable "adls_rbac" {
  description = "Map of group based role assignments for ADLS"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
}

variable "dbx_rbac" {
  description = "Map of group based role assignments for dbx workspace"
  type = map(object({
    group_name           = string
    role_definition_name = string
  }))
}

variable "deploy_compute" {
  description = "Whether to deploy the compute module"
  type        = bool
}

variable "deploy_automation" {
  description = "Whether to deploy the compute module"
  type        = bool
}

variable "st_retention_days" {
  description = "Number of days to retain deleted blobs and containers"
  type        = number
  default     = 30
}

variable "vm_schedules" {
  description = "VM start/stop schedules"
  type = map(object({
    frequency   = string
    start_time  = string
    week_days   = list(string)
    description = string
    vm_names    = string
    action      = string
  }))
  default = {}
}

variable "system_schemas" {
  description = "List of Databricks system schemas to enable"
  type        = list(string)
  default     = []
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