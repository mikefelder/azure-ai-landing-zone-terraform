# Examples

## Standalone

The `standalone` example deploys the full AI Landing Zone into an isolated Azure subscription with `flag_platform_landing_zone = false`. It provisions Azure Bastion and a Jumpbox VM so that users with subscription access can reach all privately-networked resources without requiring VPN, ExpressRoute, or VNet peering to any existing network.

See [`standalone/`](standalone/) for the full configuration.
