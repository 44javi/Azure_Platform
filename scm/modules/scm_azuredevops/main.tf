# STUB: same interface as scm_gitlab, not yet implemented.
#
# Provider auth (set before running terraform):
#   AZDO_ORG_SERVICE_URL = https://dev.azure.com/<org>
#   AZDO_PERSONAL_ACCESS_TOKEN = <pat>   (or use a service connection / OIDC)
#
# Mapping note: an ADO "project" is a container (repos + boards + pipelines),
# which is coarser than a GitLab subgroup. A department becomes one ADO project;
# its repos become git repos inside that project.
#
# Reference implementation to fill in:
#
# resource "azuredevops_project" "department" {
#   for_each           = var.departments
#   name               = each.value.name
#   visibility         = var.group_visibility
#   version_control    = "Git"
#   work_item_template = "Agile"
# }
#
# locals {
#   repos = merge([
#     for dk, d in var.departments : {
#       for rk, r in d.repos : "${dk}/${rk}" => merge(r, { dept_key = dk, name = rk })
#     }
#   ]...)
# }
#
# resource "azuredevops_git_repository" "repo" {
#   for_each   = local.repos
#   project_id = azuredevops_project.department[each.value.dept_key].id
#   name       = each.value.name
#   initialization { init_type = "Clean" }
# }
#
# resource "azuredevops_branch_policy_min_reviewers" "reviewers" {
#   for_each = { for k, r in local.repos : k => r if r.reviewers > 0 }
#   ...
# }
#
# resource "azuredevops_variable_group" "department" { ... }  # for ci_variables
