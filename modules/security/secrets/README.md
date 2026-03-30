# secrets

Generates cryptographically secure passwords and stores them in Azure Key Vault.

Secret names follow the pattern: `{project}-{environment}-{key}`

---

## Inputs

| Variable | Default | Description |
|---|---|---|
| `project` | required | Prefix used in secret names |
| `environment` | required | Environment label |
| `key_vault_id` | required | Resource ID of the target Key Vault |
| `default_tags` | `{}` | Tags applied to every secret |
| `secrets` | `{}` | See below |

### Secret Attributes

| Attribute | Default | Description |
|---|---|---|
| `length` | `32` | Minimum 16 |
| `special` | `true` | Includes `!#%&*()-_=+[]<>:?` |
| `expiration_date` | `null` | RFC3339 e.g. `"2027-01-01T00:00:00Z"` |
| `rotation_key` | `"v1"` | Increment to rotate |
| `min_upper` | `3` | |
| `min_lower` | `3` | |
| `min_numeric` | `3` | |
| `min_special` | `2` | Ignored when `special = false` |

## Outputs

| Output | Use for |
|---|---|
| `secret_ids` | Terraform-to-Terraform — pinned to exact version |
| `secret_versionless_ids` | Runtime consumers — always resolves to latest (Databricks, AKS, App Service) |
| `secret_versions` | Rotation auditing. Sensitive. |

---

### Example tfvars secrets with variance

```hcl
secrets = {

  # All defaults produces: 32-char password, special chars included, no expiry.
  databricks-sp-client-secret = {}

  # Longer, stricter, expires
  synapse-admin-password = {
    length          = 64
    min_upper       = 6
    min_lower       = 6
    min_numeric     = 6
    min_special     = 4
    expiration_date = "2026-06-01T00:00:00Z"
  }

  # No special chars — legacy system
  legacy-api-key = {
    length      = 48
    special     = false
    min_special = 0
  }

  # Alphanumeric only, rotated once, expires
  sql-admin-password = {
    length          = 64
    special         = false
    min_special     = 0
    min_upper       = 8
    min_numeric     = 8
    expiration_date = "2026-03-01T00:00:00Z"
    rotation_key    = "v2"
  }

  # Minimal — internal tooling
  n8n-admin-password = {
    length = 16
  }
}
```

### Rotation

Increment `rotation_key` for the target secret and apply. Only that secret gets a new password.

```hcl
secrets = {
  databricks-sp-client-secret = {
    rotation_key = "v2"
  }
}
```

---