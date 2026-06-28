# Same interface as scm_gitlab so a deployment can switch providers by changing
# only the module source. Mapping for GitHub:
#   top_level_group -> organization (pre-existing, referenced not created)
#   department      -> repo name prefix + a GitHub team (no project-container layer)
#   repo            -> repo in the org, named "<department>-<repo>"
#   ci_variables    -> org or repo Actions variables
variable "org" {
  description = "GitHub organization (pre-existing). Used for naming and as the owner."
  type        = string
}

variable "top_level_group" {
  description = "GitHub organization. Same value as org; kept for interface parity."
  type        = string
}

variable "group_visibility" {
  description = "Repo visibility: private, internal, or public."
  type        = string
  default     = "private"
}

variable "prevent_forking_outside_group" {
  description = "Maps to org/repo allow_forking setting."
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
  description = "Department -> repo-prefix + team mapping, with repos and CI variables."
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
