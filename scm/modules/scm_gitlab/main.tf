locals {
  # Flatten departments -> repos into a single map keyed "department/repo".
  repos = merge([
    for dk, d in var.departments : {
      for rk, r in d.repos : "${dk}/${rk}" => merge(r, {
        dept_key = dk
        name     = rk
      })
    }
  ]...)

  protected_repos = { for k, r in local.repos : k => r if r.protected }
  approval_repos  = { for k, r in local.repos : k => r if r.reviewers > 0 }
  ci_repos        = { for k, r in local.repos : k => r if r.cicd_template != null }

  # Flatten departments -> ci_variables into a single map keyed "department/KEY".
  department_ci_variables = merge([
    for dk, d in var.departments : {
      for vk, v in d.ci_variables : "${dk}/${vk}" => merge(v, {
        dept_key = dk
        var_key  = vk
      })
    }
  ]...)
}

# The top-level group already exists (created at signup, tied to billing and
# SAML/SCIM). We reference it, never create or destroy it.
data "gitlab_group" "top" {
  full_path = var.top_level_group
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

# One project (repo) per entry, in its department subgroup. Initialized with a
# README so the default branch exists for protection rules and CI seeding.
resource "gitlab_project" "repo" {
  for_each = local.repos

  name                   = each.value.name
  description            = each.value.description
  namespace_id           = gitlab_group.department[each.value.dept_key].id
  default_branch         = each.value.default_branch
  visibility_level       = var.group_visibility
  initialize_with_readme = true
}

# Policy: protect the default branch.
resource "gitlab_branch_protection" "default" {
  for_each = local.protected_repos

  project            = gitlab_project.repo[each.key].id
  branch             = each.value.default_branch
  push_access_level  = "maintainer"
  merge_access_level = "developer"
}

# Policy: required merge-request approvals.
resource "gitlab_project_level_mr_approvals" "this" {
  for_each = local.approval_repos

  project = gitlab_project.repo[each.key].id
}

resource "gitlab_project_approval_rule" "reviewers" {
  for_each = local.approval_repos

  project            = gitlab_project.repo[each.key].id
  name               = "default-reviewers"
  approvals_required = each.value.reviewers

  depends_on = [gitlab_project_level_mr_approvals.this]
}

# CI/CD scaffolding: seed a starter pipeline. Ownership transfers to the team
# after creation (ignore_changes), so this does not fight their edits.
resource "gitlab_repository_file" "ci" {
  for_each = local.ci_repos

  project        = gitlab_project.repo[each.key].id
  branch         = each.value.default_branch
  file_path      = ".gitlab-ci.yml"
  content        = file("${path.module}/templates/${each.value.cicd_template}.gitlab-ci.yml")
  encoding       = "text"
  commit_message = "Seed ${each.value.cicd_template} CI/CD pipeline"
  author_name    = var.commit_author_name
  author_email   = var.commit_author_email

  lifecycle {
    ignore_changes = [content]
  }
}

# Per-department CI/CD variables, inherited by every project in the subgroup.
resource "gitlab_group_variable" "department" {
  for_each = local.department_ci_variables

  group             = gitlab_group.department[each.value.dept_key].id
  key               = each.value.var_key
  value             = each.value.value
  masked            = each.value.masked
  protected         = each.value.protected
  environment_scope = each.value.environment_scope
}
