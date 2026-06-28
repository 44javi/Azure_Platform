# STUB: same interface as scm_gitlab, not yet implemented.
#
# Provider auth (set before running terraform):
#   GITHUB_OWNER = <org>
#   GITHUB_TOKEN = <pat>   (prefer a GitHub App installation token for rotation)
#
# Mapping note: GitHub has no project-container layer between org and repo. A
# department becomes a naming prefix plus a team that owns its repos. Repos are
# named "<department>-<repo>".
#
# Reference implementation to fill in:
#
# locals {
#   repos = merge([
#     for dk, d in var.departments : {
#       for rk, r in d.repos : "${dk}/${rk}" => merge(r, { dept_key = dk, name = "${d.path}-${rk}" })
#     }
#   ]...)
# }
#
# resource "github_team" "department" {
#   for_each = var.departments
#   name     = each.value.name
# }
#
# resource "github_repository" "repo" {
#   for_each   = local.repos
#   name       = each.value.name
#   visibility = var.group_visibility
#   auto_init  = true
# }
#
# resource "github_branch_protection" "default" {
#   for_each      = { for k, r in local.repos : k => r if r.protected }
#   repository_id = github_repository.repo[each.key].node_id
#   pattern       = each.value.default_branch
#   required_pull_request_reviews { required_approving_review_count = each.value.reviewers }
# }
#
# resource "github_actions_variable" "department" { ... }  # for ci_variables
