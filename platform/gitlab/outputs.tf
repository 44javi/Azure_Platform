output "top_level_group_id" {
  description = "ID of the existing top-level group this module manages under."
  value       = data.gitlab_group.top.id
}

output "department_group_ids" {
  description = "Map of department key to created subgroup ID."
  value       = { for k, g in gitlab_group.department : k => g.id }
}

output "department_full_paths" {
  description = "Map of department key to full GitLab path."
  value       = { for k, g in gitlab_group.department : k => g.full_path }
}

output "required_entra_groups" {
  description = "Entra ID security group display names that must exist and be emitted in the SAML groups claim for access to work. Create these in your IdP (or via the azuread provider)."
  value       = local.expected_entra_groups
}
