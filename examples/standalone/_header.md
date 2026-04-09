# Standalone Example

This example deploys the full AI Landing Zone into a standalone Azure subscription with `flag_platform_landing_zone = false`. No VNet peering, ExpressRoute, or connectivity to existing networks is required.

## What Gets Deployed

- **Virtual Network** with dedicated subnets for all services
- **Azure Bastion** (Standard SKU) with a dedicated NSG containing all required inbound/outbound rules
- **Jumpbox VM** for accessing privately-networked resources via Bastion
- **AI Foundry** with GPT-4.1 model deployment, AI Search, Cosmos DB, Key Vault, and Storage
- **API Management**, **Application Gateway** with WAF, and **Container App Environment**
- **Private DNS Zones** linked to the VNet for private endpoint resolution

## Accessing Resources

Once deployed, a user with subscription access can:

1. Navigate to **Azure Portal → Bastion** on the deployed Bastion resource
2. Connect to the Jumpbox VM over HTTPS (no VPN or peering needed)
3. Retrieve Jumpbox credentials from the deployed Key Vault
4. Access all private-endpoint-protected resources from the Jumpbox
