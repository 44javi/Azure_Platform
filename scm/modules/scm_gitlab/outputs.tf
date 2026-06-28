output "top_group_id" {
  description = "ID of the referenced top-level group."
  value       = data.gitlab_group.top.id
}

output "department_group_ids" {
  description = "Department key -> subgroup ID."
  value       = { for k, g in gitlab_group.department : k => g.id }
}

output "department_group_urls" {
  description = "Department key -> subgroup web URL."
  value       = { for k, g in gitlab_group.department : k => g.web_url }
}

output "repo_urls" {
  description = "Repo key (department/repo) -> project web URL."
  value       = { for k, p in gitlab_project.repo : k => p.web_url }
}

output "repo_ssh_urls" {
  description = "Repo key (department/repo) -> SSH clone URL. Use these as git remotes."
  value       = { for k, p in gitlab_project.repo : k => p.ssh_url_to_repo }
}
