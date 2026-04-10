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

## Change Log

### 2026-04-10

**Added NAT Gateway for jumpbox outbound internet access**

The jump VM deployed via Bastion previously had no outbound internet connectivity, limiting its usefulness for development teams who need to access the Azure Portal, install tooling, or work on AI POC use cases.

**Files changed:**

- `variables.networking.tf` — Added `nat_gateway_definition` variable with `deploy`, `name`, `resource_group_name`, `tags`, `enable_telemetry`, `idle_timeout_in_minutes`, and `zones` options. Defaults to `deploy = false` (opt-in).
- `locals.networking.tf` — Added `nat_gateway_name` local for consistent naming. Added `nat_gateway` association to the `JumpboxSubnet` definition. Added guard to exclude the firewall route table from `JumpboxSubnet` when the NAT Gateway is deployed, since UDRs with `0.0.0.0/0` next hop override NAT Gateway per Azure documentation.
- `main.networking.tf` — Added `module "nat_gateway"` using `Azure/avm-res-network-natgateway/azurerm` v0.2.1 (matching the existing pattern in `modules/example_hub_vnet`). Creates the NAT Gateway with a public IP, gated by `count`.
- `outputs.networking.tf` — Added `nat_gateway` output exposing the deployed resource.
- `examples/standalone/main.tf` — Enabled the NAT Gateway in the standalone example with `nat_gateway_definition = { deploy = true }`.
- `_header.md` — Added documentation for the NAT Gateway feature, access pattern, and firewall routing behavior.
