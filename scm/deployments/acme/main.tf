provider "gitlab" {
  # Auth comes from the environment, nothing is committed:
  #   GITLAB_TOKEN    = <group access token or PAT with api scope>
  #   GITLAB_BASE_URL = https://gitlab.example.com/api/v4   (self-managed only)
}

# Swap the source to ../../modules/scm_azuredevops or ../../modules/scm_github
# to target another provider. The variable interface is identical.
module "scm" {
  source = "../../modules/scm_gitlab"

  org              = var.org
  top_level_group  = var.top_level_group
  group_visibility = var.group_visibility
  departments      = var.departments
}

output "repo_ssh_urls" {
  description = "Clone URLs for every provisioned repo."
  value       = module.scm.repo_ssh_urls
}

output "department_group_urls" {
  value = module.scm.department_group_urls
}
