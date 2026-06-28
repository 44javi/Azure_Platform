# Versioning — networking modules

These modules are versioned independently with git tags and consumed via a
pinned `?ref=`. This works on any git host (GitHub, GitLab, or whatever the repo
is migrated to) because it relies only on plain git, not a module registry.

## Modules

| Module    | Path                          | Changelog                  |
| --------- | ----------------------------- | -------------------------- |
| `vnets`   | `tf_modules/networking/vnets` | `vnets/CHANGELOG.md`       |
| `subnets` | `tf_modules/networking/subnets` | `subnets/CHANGELOG.md`   |

## Tag convention

```
<module>-vMAJOR.MINOR.PATCH
```

Examples: `vnets-v1.0.0`, `subnets-v1.2.1`.

Tags are repo-global, so the short name (`vnets`, `subnets`) must stay unique
across the whole monorepo. Add a category prefix (e.g. `networking-vnets-...`)
only if a name could collide with a module in another category.

### SemVer meaning for a Terraform module

- **major** — breaking: a variable or output removed/renamed, a type changed, or
  default behaviour callers relied on changed.
- **minor** — additive and backward compatible: a new optional variable, a new
  output, a new opt-in resource.
- **patch** — a fix with no interface change.

## Consuming a module

All consumers, including those inside this monorepo, reference modules via an
HTTPS git source pinned to a tag. This gives every consumer an explicit, pinned
version instead of "whatever is on disk". The `//` separates the repo from the
module subdirectory; `?ref=` pins the tag:

```hcl
module "vnet" {
  source = "git::https://<git-host>/<org>/azure-platform.git//tf_modules/networking/vnets?ref=vnets-v1.0.0"
  # ...
}
```

Tradeoffs to be aware of when sourcing this way instead of local paths:

- **No atomic refactors.** A module change is not picked up by a consumer just by
  editing files. You must commit, tag, and push the module first, then bump the
  consumer's `?ref=` and run `terraform init -upgrade`. Module and consumer can no
  longer change in a single apply.
- **The code must be pushed and tagged before it can be consumed**, even though it
  lives in the same working tree. `terraform init` clones the repo from the remote
  into `.terraform/modules`; it does not read the local files.

## Cutting a release

The changelog is a manual edit included in the same commit as the code change.

```bash
# 1. make the code change
# 2. add an entry to the module's CHANGELOG.md by hand
git add tf_modules/networking/vnets/        # code + changelog together
git commit -m "vnets: add ddos_protection_plan_id input"
git push                                     # publish the commit

git tag vnets-v1.1.0                         # lightweight tag; notes live in CHANGELOG.md
git push origin vnets-v1.1.0                 # publish the version (both remotes, dual push URLs)
```

## Rules

- **Never move or delete a published tag.** Once a consumer pins
  `?ref=vnets-v1.0.0`, that tag must point at the same commit forever. To ship a
  fix, cut a new patch (`vnets-v1.0.1`); do not re-point an existing tag.
- **New commits and new tags do not affect existing consumers.** A pinned
  consumer stays on its `?ref=` until someone edits the source string and runs
  `terraform init -upgrade`. Upgrades are always deliberate.
- **Keep the changelog and the tag in sync.** The version at the top of
  `CHANGELOG.md` should match the tag you push.
