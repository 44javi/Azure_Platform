# The top-level group already exists on gitlab.com (created at signup, tied to
# billing and SAML/SCIM). We reference it, never create or destroy it.
data "gitlab_group" "top" {
  full_path = local.top_path
}

# One subgroup per department, nested under the top-level group.
resource "gitlab_group" "department" {
  for_each = var.departments

  name      = each.value.name
  path      = each.value.path
  parent_id = data.gitlab_group.top.id

  visibility_level              = var.group_visibility
  request_access_enabled        = false
  prevent_forking_outside_group = var.prevent_forking_outside_group
}

# Department SAML links: map an Entra ID group to a role within the subgroup.
# Membership comes from the IdP (SAML/SCIM); this only defines what the mapped
# group can do. Do not also add direct members here or they will fight on drift.
resource "gitlab_group_saml_link" "department" {
  for_each = var.enable_saml_group_links ? local.department_saml_links : {}

  group           = gitlab_group.department[each.value.dept_key].id
  access_level    = each.value.access_level
  saml_group_name = each.value.saml_group_name
}

# Top-level SAML links (platform admins, read-only security audit). Attached to
# the top-level group so the grant inherits into every department subgroup.
resource "gitlab_group_saml_link" "top_level" {
  for_each = var.enable_saml_group_links ? var.top_level_saml_links : {}

  group           = data.gitlab_group.top.id
  access_level    = each.value.access_level
  saml_group_name = "${local.prefix}-${var.system_segment}-${each.value.saml_token}-${each.value.role}"
}

# Per-department CI/CD variables, inherited by every project in the subgroup.
# Use for Azure workload identity federation (ARM_CLIENT_ID, ARM_TENANT_ID,
# ARM_SUBSCRIPTION_ID, ARM_USE_OIDC) so pipelines auth without stored secrets.
resource "gitlab_group_variable" "department" {
  for_each = local.department_ci_variables

  group             = gitlab_group.department[each.value.dept_key].id
  key               = each.value.var_key
  value             = each.value.value
  masked            = each.value.masked
  protected         = each.value.protected
  environment_scope = each.value.environment_scope
}
