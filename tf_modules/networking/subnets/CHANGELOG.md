# Changelog — subnets

All notable changes to the `subnets` module. Versions follow `subnets-vMAJOR.MINOR.PATCH`
git tags. See `../VERSIONING.md` for the release process.

## [1.0.0] - 2026-06-28
### Added
- Subnets from the `subnets` map (`azurerm_subnet`), with optional name
  override, default outbound control, private endpoint network policies, and
  service delegation.
- Per-subnet network security groups and associations, created only for subnets
  that declare `nsg_rules`.
- NAT gateway with a Standard public IP, created only when at least one subnet
  sets `attach_nat_gateway = true`, plus the subnet associations.
- Takes `virtual_network_name` as input so it can be wired to a separately
  managed VNet (e.g. the `vnets` module).
- Outputs: `subnet_ids`, `nsg_ids`, `nat_gateway_id`.
