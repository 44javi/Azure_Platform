variable "project" {
  description = "Project name used in resource naming"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, qa, prod)"
  type        = string
}

variable "region" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Id of the Log Analytics workspace in the management subscription"
  type        = string
  default     = null
}

variable "log_analytics_resource_group" {
  description = "Resource group of the Log Analytics workspace in the management subscription"
  type        = string
  default = ""
}

variable "logs_destination" {
  description = "Where logs will be sent to with possible vaules being log-analytics or azure-monitor" 
  type        = string
  default = ""
}

variable "docker_usr" {
  description = "Docker Hub username used to construct the container image reference"
  type        = string
}

variable "container_image" {
  description = "Container image tag appended to docker_usr (e.g. portfolio:latest)"
  type        = string
}

variable "cpu" {
  description = "vCPU allocation per container replica (e.g. 0.25, 0.5, 1.0)"
  type        = number
  default     = 0.25
}

variable "memory" {
  description = "Memory allocation per container replica (e.g. 0.5Gi, 1Gi, 2Gi)"
  type        = string
  default     = "0.5Gi"
}

variable "port" {
  description = "Port the container listens on, exposed via ingress"
  type        = number
  default     = 80
}

variable "min_replicas" {
  description = "Minimum number of running replicas (0 allows scale to zero)"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of running replicas for horizontal scaling"
  type        = number
  default     = 1
}

variable "revision_mode" {
  description = "Controls how traffic is split: Single keeps one active revision, Multiple allows gradual rollout"
  type        = string
  default     = "Single"
}

variable "external_ingress" {
  description = "Whether ingress is accessible from the public internet"
  type        = bool
  default     = true
}

variable "enable_custom_domain" {
  description = "Set to false to skip custom domain binding (useful for initial deploy before DNS is ready)"
  type        = bool
  default     = true
}

variable "custom_domain" {
  description = "Apex custom domain to bind to the container app (e.g. example.com)"
  type        = string
}

variable "custom_domain_www" {
  description = "WWW subdomain to bind to the container app (e.g. www.example.com)"
  type        = string
}

variable "certificate_binding_type" {
  description = "SniEnabled uses the Azure free managed certificate, Disabled skips TLS binding"
  type        = string
  default     = "SniEnabled"
}

variable "default_tags" {
  description = "Tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
