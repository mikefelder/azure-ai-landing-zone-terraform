# Examples

## Updating an Existing Deployment

This repo is a fork of `Azure/terraform-azurerm-avm-ptn-aiml-landing-zone` with Bastion and Jumpbox fixes applied. If you previously ran `terraform apply` from the original repo, follow these steps to adopt this fork without recreating your infrastructure.

### 1. Clone this repo

```bash
git clone git@github.com:mikefelder/azure-ai-landing-zone-terraform.git
cd azure-ai-landing-zone-terraform
```

### 2. Copy Terraform state and artifacts from the original repo

**macOS / Linux:**

```bash
ORIGINAL=~/Code/terraform-azurerm-avm-ptn-aiml-landing-zone
UPDATED=~/Code/azure-ai-landing-zone-terraform

cp "$ORIGINAL/examples/standalone/terraform.tfstate" "$UPDATED/examples/standalone/"
cp "$ORIGINAL/examples/standalone/terraform.tfstate.backup" "$UPDATED/examples/standalone/" 2>/dev/null
cp "$ORIGINAL/examples/standalone/.terraform.lock.hcl" "$UPDATED/examples/standalone/" 2>/dev/null
cp "$ORIGINAL/examples/standalone/"*.tfvars "$UPDATED/examples/standalone/" 2>/dev/null
cp "$ORIGINAL/examples/standalone/"*.tfvars.json "$UPDATED/examples/standalone/" 2>/dev/null
```

**Windows (PowerShell):**

```powershell
$Original = "$HOME\Code\terraform-azurerm-avm-ptn-aiml-landing-zone\examples\standalone"
$Updated  = "$HOME\Code\azure-ai-landing-zone-terraform\examples\standalone"

Copy-Item "$Original\terraform.tfstate" -Destination $Updated
Copy-Item "$Original\terraform.tfstate.backup" -Destination $Updated -ErrorAction SilentlyContinue
Copy-Item "$Original\.terraform.lock.hcl" -Destination $Updated -ErrorAction SilentlyContinue
Copy-Item "$Original\*.tfvars" -Destination $Updated -ErrorAction SilentlyContinue
Copy-Item "$Original\*.tfvars.json" -Destination $Updated -ErrorAction SilentlyContinue
```

### 3. Initialize and apply

```bash
cd "$UPDATED/examples/standalone"
terraform init
terraform plan    # Review — should show Bastion NSG and Jumpbox as additions, not a full rebuild
terraform apply
```

> **Important:** Do not skip the `terraform plan` step. Verify it shows only the expected additions (Bastion NSG, NSG rules, Jumpbox VM) and no unexpected destroys of existing resources.

---

## [Standalone](standalone/)

Deploys the full AI Landing Zone into an isolated Azure subscription with no external network dependencies. Includes Azure Bastion and a Jumpbox VM so that users with subscription access can securely reach all privately-networked resources from their browser — no VPN, ExpressRoute, or VNet peering required.

```bash
cd standalone
terraform init
terraform apply -var="location=australiaeast"
```

See the [standalone README](standalone/README.md) for full details on what gets deployed and how to connect.
