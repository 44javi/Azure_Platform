# =============================================================================
# Tenant identity
# =============================================================================

variable "company_abbr" {
  description = "Organization prefix / company abbreviation (2-5 chars). Prefixes every Entra ID group name, e.g. ACME -> ACME-GL-CLOUD-ENG. Namespaces these groups and avoids collisions with pre-existing groups in the tenant."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{1,4}$", var.company_abbr))
    error_message = "company_abbr must be 2-5 alphanumeric characters starting with a letter."
  }
}

variable "top_level_group_path" {
  description = "Full path of the EXISTING top-level group on gitlab.com (created at signup, tied to billing). Defaults to lower(company_abbr). This module references it as a data source and never creates or destroys it."
  type        = string
  default     = null
  validation {
    condition = (
      var.top_level_group_path == null ||
      (
        can(regex("^[A-Za-z0-9_.-]+$", var.top_level_group_path)) &&
        var.top_level_group_path != "replace-with-gitlab-top-level-group-slug"
      )
    )
    error_message = "top_level_group_path must be the existing top-level GitLab group URL slug, for example acme, not the placeholder value."
  }
}

variable "gitlab_base_url" {
  description = "GitLab API base URL. Default is gitlab.com SaaS."
  type        = string
  default     = "https://gitlab.com/api/v4"
}

variable "system_segment" {
  description = "SYSTEM segment of the group naming convention. GL = GitLab access, AZ = Azure RBAC. Keeps GitLab role groups distinct from Azure RBAC groups."
  type        = string
  default     = "GL"
}

# =============================================================================
# Department / subgroup definitions
# =============================================================================
# Each entry becomes a subgroup under the top-level group, plus one Entra ID
# SAML group link per role. saml_token is the DOMAIN segment of the group name
# (e.g. NET), kept separate from the GitLab path (networking).

variable "departments" {
  description = "Department subgroups and the role tiers to provision SAML links for."
  type = map(object({
    name       = string
    path       = string
    saml_token = string
    roles      = list(string)
  }))
  default = {
    iam        = { name = "iam", path = "iam", saml_token = "IAM", roles = ["LEAD", "ENG"] }
    cloud      = { name = "cloud", path = "cloud", saml_token = "CLOUD", roles = ["LEAD", "ENG"] }
    networking = { name = "networking", path = "networking", saml_token = "NET", roles = ["LEAD", "ENG"] }
    security   = { name = "security", path = "security", saml_token = "SEC", roles = ["LEAD", "ENG"] }
    data       = { name = "data", path = "data", saml_token = "DATA", roles = ["LEAD", "ENG"] }
  }
}

variable "role_to_access" {
  description = "Maps a ROLE tier to a GitLab access level. ADMIN=owner, LEAD=maintainer, ENG=developer, AUDIT=reporter."
  type        = map(string)
  default = {
    ADMIN = "owner"
    LEAD  = "maintainer"
    ENG   = "developer"
    AUDIT = "reporter"
  }
}

variable "top_level_saml_links" {
  description = "SAML group links attached to the TOP-LEVEL group (inherited by every department). Use for org-wide platform admins and read-only security audit. saml_group_name is built as {PREFIX}-{SYSTEM}-{saml_token}-{role}."
  type = map(object({
    saml_token   = string
    role         = string
    access_level = string
  }))
  default = {
    platform_admin = { saml_token = "PLATFORM", role = "ADMIN", access_level = "owner" }
    security_audit = { saml_token = "SEC", role = "AUDIT", access_level = "reporter" }
  }
}

variable "enable_saml_group_links" {
  description = "Whether to manage GitLab SAML Group Links. Requires GitLab Premium/Ultimate and SAML SSO enabled on the top-level group. Keep false for Free-tier testing, then set true for licensed environments."
  type        = bool
  default     = false
}

# =============================================================================
# Group settings
# =============================================================================

variable "group_visibility" {
  description = "Visibility for created subgroups: private, internal, or public. Keep private unless there is a reason to expose them."
  type        = string
  default     = "private"
  validation {
    condition     = contains(["private", "internal", "public"], var.group_visibility)
    error_message = "group_visibility must be one of: private, internal, public."
  }
}

variable "prevent_forking_outside_group" {
  description = "Block forking projects to namespaces outside the group. Recommended on for tenant isolation."
  type        = bool
  default     = true
}

# =============================================================================
# CI/CD variables (inherited downward, e.g. Azure WIF/OIDC config)
# =============================================================================
# Keyed by department key, then by variable name. Set the Azure workload
# identity federation values per department so each subgroup's pipelines
# authenticate to that department's Azure subscription without stored secrets.

variable "department_ci_variables" {
  description = "Per-department GitLab group CI/CD variables, inherited by all projects in that subgroup."
  type = map(map(object({
    value             = string
    masked            = optional(bool, true)
    protected         = optional(bool, false)
    environment_scope = optional(string, "*")
  })))
  default = {}
}
