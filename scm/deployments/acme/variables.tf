variable "org" {
  type = string
}

variable "top_level_group" {
  type = string
}

variable "group_visibility" {
  type    = string
  default = "private"
}

variable "departments" {
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
