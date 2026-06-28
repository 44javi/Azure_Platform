variable "org" {
  description = "Client/org identifier. Used for naming and outputs only."
  type        = string
}

variable "top_level_group" {
  description = "Full path of the existing top-level GitLab group (created at signup, tied to billing/SAML). Referenced via data source, never created or destroyed."
  type        = string
}

variable "group_visibility" {
  description = "Visibility applied to created subgroups and projects."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["private", "internal", "public"], var.group_visibility)
    error_message = "group_visibility must be one of: private, internal, public."
  }
}

variable "prevent_forking_outside_group" {
  description = "Block forking projects to namespaces outside the top-level group."
  type        = bool
  default     = true
}

variable "commit_author_name" {
  description = "Author name used when seeding scaffolded files (e.g. CI pipelines)."
  type        = string
  default     = "platform-automation"
}

variable "commit_author_email" {
  description = "Author email used when seeding scaffolded files."
  type        = string
  default     = "platform-automation@example.com"
}

# The org structure. One map entry per department subgroup. To scale down for a
# small org, delete the entries you do not need (e.g. "security", "networking")
# in the deployment tfvars and re-apply. Nothing else has to change.
variable "departments" {
  description = "Department subgroups created under the top-level group, with their repos and CI/CD variables."
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

    # Group-level CI/CD variables, inherited by every project in the subgroup.
    # Use for Azure workload identity federation (ARM_TENANT_ID,
    # ARM_SUBSCRIPTION_ID, ARM_USE_OIDC) so pipelines auth without stored secrets.
    ci_variables = optional(map(object({
      value             = string
      masked            = optional(bool, false)
      protected         = optional(bool, true)
      environment_scope = optional(string, "*")
    })), {})
  }))
}
