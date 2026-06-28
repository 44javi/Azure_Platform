# Changelog — vnets

All notable changes to the `vnets` module. Versions follow `vnets-vMAJOR.MINOR.PATCH`
git tags. See `../VERSIONING.md` for the release process.

## [1.0.0] - 2026-06-28
### Added
- Virtual network (`azurerm_virtual_network`).
- Private DNS zones from `private_dns_zones` (`azurerm_private_dns_zone`).
- VNet links for each private DNS zone so resources in the VNet resolve via the
  zones (`azurerm_private_dns_zone_virtual_network_link`).
- Outputs: `vnet_id`, `vnet_name`, `private_dns_zone_ids`.
