# terraform-azurerm-avm-ptn-aiml-landing-zone

This pattern module creates the full AI landing zone for foundry. For more details on AI Landing Zones please see the [AI Landing Zone documentation](https://aka.ms/ailz/website) including the deployment guide for terraform deployments: [AI Landing Zone Terraform Deployment Guide](https://azure.github.io/AI-Landing-Zones/terraform/).

## Jumpbox and Outbound Internet Access

The landing zone deploys a jump VM accessible via Azure Bastion for managing resources within the private network. By default, the jumpbox subnet has no outbound internet access — all Azure PaaS services (AI Foundry, Key Vault, Storage, etc.) are reached over private endpoints.

To enable the development team to access the Azure Portal, install tooling, and work on AI POC use cases from within the jump VM, an optional **Azure NAT Gateway** can be deployed.

### Enabling the NAT Gateway

```hcl
nat_gateway_definition = {
  deploy = true
}
```

When enabled, the NAT Gateway:

- Creates a public IP and NAT Gateway resource associated with the **JumpboxSubnet**
- Provides SNAT-based outbound internet connectivity for the jump VM
- Allows access to the Azure Portal, package managers, documentation, and other internet resources

### Access pattern

```
Developer laptop
    │
    ▼
Azure Bastion (AzureBastionSubnet)
    │  RDP / SSH over TLS
    ▼
Jump VM (JumpboxSubnet + NSG)
    │
    ├──► Private Endpoints ──► AI Foundry, Key Vault, Storage, AI Search, Cosmos DB, ACR
    │    (no internet needed)
    │
    └──► NAT Gateway ──► Internet (Azure Portal, tools, packages)
         (outbound only, no inbound)
```

### Routing behavior with Azure Firewall

When `flag_platform_landing_zone = true`, the module deploys an Azure Firewall with a UDR routing `0.0.0.0/0` through the firewall for all subnets. Because [UDRs with 0.0.0.0/0 override NAT Gateway](https://learn.microsoft.com/en-us/azure/nat-gateway/nat-gateway-resource), enabling the NAT Gateway automatically removes the firewall route table from the JumpboxSubnet so that outbound traffic flows through the NAT Gateway. The NSG remains applied. All other subnets continue to route through the firewall.

If you require firewall inspection on the jumpbox outbound traffic instead, keep `nat_gateway_definition.deploy = false` (the default) and configure the appropriate firewall application rules for the required destinations.
