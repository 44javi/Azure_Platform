# Same interface as scm_gitlab so a deployment can switch providers by changing
# only the module source. Mapping for Azure DevOps:
#   top_level_group -> organization (pre-existing, referenced not created)
#   department      -> ADO project (a container holding repos/boards/pipelines)
#   repo            -> git repo inside the department project
#   ci_variables    -> variable group linked to pipelines
variable "org" {
  description = "Client/org identifier. Used for naming and outputs only."
  type        = string
}

variable "top_level_group" {
  description = "Azure DevOps organization (pre-existing). Referenced, never created."
  type        = string
}

variable "group_visibility" {
  description = "Project visibility: private or public."
  type        = string
  default     = "private"
}

variable "prevent_forking_outside_group" {
  description = "Accepted for interface parity with scm_gitlab. Maps to ADO repo/fork policy."
  type        = bool
  default     = true
}

variable "commit_author_name" {
  type    = string
  default = "platform-automation"
}

variable "commit_author_email" {
  type    = string
  default = "platform-automation@example.com"
}

variable "departments" {
  description = "Department -> ADO project mapping, with repos and CI variables."
  type = map(object({
    name = string
    path = string
    repos = optional(map(object({
      description    = optional(string, "")
      default_branch = optional(string, "main")
      protected      = optional(bool, true)
      reviewers      = optional(number, 0)
      cicd_template  = optional(string, null)
    })), {})
    ci_variables = optional(map(object({
      value             = string
      masked            = optional(bool, false)
      protected         = optional(bool, true)
      environment_scope = optional(string, "*")
    })), {})
  }))
}
