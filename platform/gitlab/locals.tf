locals {
  prefix   = upper(var.company_abbr)
  top_path = coalesce(var.top_level_group_path, lower(var.company_abbr))

  # Department SAML links, keyed "{dept_key}-{role}".
  # saml_group_name is the Entra ID group the IdP must emit in its groups claim.
  department_saml_links = merge([
    for dept_key, dept in var.departments : {
      for role in dept.roles :
      "${dept_key}-${role}" => {
        dept_key        = dept_key
        access_level    = var.role_to_access[role]
        saml_group_name = "${local.prefix}-${var.system_segment}-${dept.saml_token}-${role}"
      }
    }
  ]...)

  # Department CI/CD variables flattened to "{dept_key}|{key}".
  department_ci_variables = merge([
    for dept_key, vars in var.department_ci_variables : {
      for key, cfg in vars :
      "${dept_key}|${key}" => merge(cfg, { dept_key = dept_key, var_key = key })
    }
  ]...)

  # Every Entra ID security group name this module expects to exist.
  expected_entra_groups = sort(concat(
    [for k, v in local.department_saml_links : v.saml_group_name],
    [for k, v in var.top_level_saml_links : "${local.prefix}-${var.system_segment}-${v.saml_token}-${v.role}"],
  ))
}
