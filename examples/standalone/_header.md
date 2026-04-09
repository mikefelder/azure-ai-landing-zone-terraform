# Standalone Example

Deploys a fully self-contained Azure AI Landing Zone into a single subscription. No VPN, ExpressRoute, VNet peering, or connectivity to any existing network is needed.

## Migrating From the Original Repo

If you previously deployed from the upstream `Azure/terraform-azurerm-avm-ptn-aiml-landing-zone` repo, copy these files from the **original** clone into this repo's `examples/standalone/` directory before running any Terraform commands:

```bash
# From the original repo to this one
cp <original-repo>/examples/standalone/terraform.tfstate        <this-repo>/examples/standalone/
cp <original-repo>/examples/standalone/terraform.tfstate.backup <this-repo>/examples/standalone/
cp <original-repo>/examples/standalone/.terraform.lock.hcl      <this-repo>/examples/standalone/

# Copy any variable override files if they exist
cp <original-repo>/examples/standalone/*.tfvars <this-repo>/examples/standalone/ 2>/dev/null
```

| File | Required? | Purpose |
|---|---|---|
| `terraform.tfstate` | **Critical** | Tracks all deployed resources. Without it, Terraform treats everything as new. |
| `terraform.tfstate.backup` | Recommended | Safety net if the primary state is corrupted. |
| `.terraform.lock.hcl` | Recommended | Pins exact provider versions from the original deployment. |
| `*.tfvars` / `*.tfvars.json` | If they exist | Any variable overrides (location, custom settings). |

Then run:

```bash
cd examples/standalone
terraform init
terraform plan   # Should show Bastion NSG + jumpbox as additions, not a full rebuild
terraform apply
```

## Prerequisites

| Requirement | Details |
|---|---|
| Terraform | >= 1.9, < 2.0 |
| Azure subscription | Owner or Contributor + User Access Administrator |
| Encryption at Host | Must be [registered](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/disks-enable-host-based-encryption-cli) on the subscription |

## Quick Start

```bash
cd examples/standalone
terraform init
terraform apply -var="location=australiaeast"
```

To deploy to a different region, change the `location` value:

```bash
terraform apply -var="location=swedencentral"
```

## What Gets Deployed

### Networking & Access

| Resource | Purpose |
|---|---|
| Virtual Network | Single VNet with dedicated subnets for each service |
| Azure Bastion (Standard) | Secure browser-based access to the Jumpbox — no public IPs on VMs |
| Bastion NSG | Dedicated network security group with all [required rules](https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg) |
| Jumpbox VM | Windows VM for accessing private resources from inside the VNet |

### AI & Application Services

| Resource | Purpose |
|---|---|
| AI Foundry | Hub with GPT-4.1 model deployment and AI agent service |
| AI Search | Search service connected to the AI Foundry project |
| Cosmos DB | NoSQL database with session consistency |
| Key Vault | Secrets, keys, and Jumpbox credentials |
| Storage Account | Blob storage for AI Foundry and application data |
| API Management | API gateway for backend services |
| Application Gateway + WAF | Layer 7 load balancer with web application firewall |
| Container App Environment | Managed environment for container workloads |
| Private DNS Zones | Name resolution for all private endpoints |

## Connecting to Resources After Deployment

1. Open the **Azure Portal** and navigate to the deployed **Bastion** resource
2. Click **Connect** and select the **Jumpbox VM**
3. Retrieve the VM credentials from the deployed **Key Vault** (stored automatically during provisioning)
4. From the Jumpbox desktop, access all privately-networked services — AI Foundry portal, Key Vault, Storage, Cosmos DB, AI Search — through their private endpoints

> **No VPN or network peering is required.** Bastion connects your browser to the Jumpbox over HTTPS (port 443) through the Azure backbone. The Jumpbox sits on the same VNet as all private endpoints.

## Variables

| Name | Type | Default | Description |
|---|---|---|---|
| `location` | `string` | `"australiaeast"` | Azure region for all resources |
| `enable_telemetry` | `bool` | `true` | Enable/disable module telemetry |
