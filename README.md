# Azure Architecture Labs

This repository contains Azure Bicep templates for architecture practice, AZ-305
study, and authorized security lab deployments.

> Legal notice: use security-testing templates only on environments where you
> have explicit permission to perform security testing.

## What It Deploys

- `az305-reference-architecture.bicep`: reference architecture covering AZ-305
  design areas: identity, governance, monitoring, storage, continuity,
  compute, networking, messaging, eventing, and deployment automation.
- `az305-subscription-governance.bicep`: subscription-scope governance with a
  resource group, custom tag policy, and budget.
- `pentest.bicep`: secured Linux VM lab for authorized testing.
- `pentest2.bicep`: compatibility wrapper around `pentest.bicep`.

## Repository Contents

| Path | Purpose |
| --- | --- |
| `az305-reference-architecture.bicep` | Resource-group scoped AZ-305 reference architecture. |
| `az305-subscription-governance.bicep` | Subscription-scoped governance and budget template. |
| `modules/az305-monitoring-governance.bicep` | Log Analytics, Application Insights, Action Group, and alert example. |
| `modules/az305-networking.bicep` | Segmented VNet, NSGs, optional NAT Gateway, Bastion, and Application Gateway WAF. |
| `modules/az305-identity-security.bicep` | Managed identity, Key Vault, diagnostics, and optional private endpoint. |
| `modules/az305-compute-app.bicep` | App Service, autoscale, optional VM, ACR, diagnostics, and optional private endpoint. |
| `modules/az305-data-platform.bicep` | Storage, Azure SQL, retention, auditing, diagnostics, and optional private endpoints. |
| `modules/az305-integration.bicep` | Service Bus, Event Grid, Data Factory, and diagnostics. |
| `modules/az305-business-continuity.bicep` | Recovery Services vault, backup policy, and diagnostics. |
| `pentest.bicep` | Hardened VM template for an authorized security lab. |
| `pentest2.bicep` | Wrapper kept for compatibility with older commands. |
| `docs/az-305-coverage.md` | Mapping between AZ-305 design objectives and repo assets. |
| `scripts/` | PowerShell deployment and what-if helpers. |
| `Resume/` | Static resume site assets. |
| `.github/workflows/bicep-validate.yml` | CI check that builds all Bicep templates. |

## Prerequisites

- Azure CLI installed and authenticated.
- Permission to create resource groups and Azure resources.
- Subscription contributor or equivalent rights for `az305-subscription-governance.bicep`.
- SSH public key for VM deployments.

## AZ-305 Reference Deployment

Preview the deployment:

```powershell
.\scripts\whatif-az305.ps1 -ResourceGroupName rg-az305-reference-dev
```

Deploy governance at subscription scope:

```powershell
.\scripts\deploy-governance.ps1 `
  -SubscriptionId <subscription-id> `
  -BudgetContactEmail you@example.com
```

Deploy the resource-group architecture:

```powershell
.\scripts\deploy-az305.ps1 -ResourceGroupName rg-az305-reference-dev
```

Deploy a more secure network/data scenario:

```powershell
.\scripts\deploy-az305.ps1 `
  -ResourceGroupName rg-az305-secure-dev `
  -DeployPrivateEndpoints `
  -DeployNatGateway `
  -DeploySql
```

Deploy with VM administration through Bastion:

```powershell
.\scripts\deploy-az305.ps1 `
  -ResourceGroupName rg-az305-vm-dev `
  -DeployVm `
  -DeployBastion `
  -SshPublicKeyPath "$HOME\.ssh\id_rsa.pub"
```

Deploy an ingress/WAF scenario:

```powershell
.\scripts\deploy-az305.ps1 `
  -ResourceGroupName rg-az305-waf-dev `
  -DeployApplicationGatewayWaf `
  -AlertEmailAddress you@example.com
```

For details, see [`docs/az-305-coverage.md`](docs/az-305-coverage.md).

## Pentest VM Deployment

```bash
az login
az account set --subscription <subscription-id-or-name>

az deployment group create \
  --resource-group <resource-group-name> \
  --template-file pentest.bicep \
  --parameters adminUsername=<admin-user> \
               sshPublicKey="$(cat ~/.ssh/id_rsa.pub)" \
               adminSourceAddressPrefix="<your-public-ip>/32"
```

Get the public IP:

```bash
az network public-ip show \
  --resource-group <resource-group-name> \
  --name pentest-ip \
  --query "ipAddress" \
  --output tsv
```

Connect:

```bash
ssh <admin-user>@<public-ip>
```

## Validate Locally

```bash
az bicep build --file az305-reference-architecture.bicep
az bicep build --file az305-subscription-governance.bicep
az bicep build --file pentest.bicep
az bicep build --file pentest2.bicep
```

Or run the local validation helper:

```powershell
.\scripts\validate-az305.ps1
```

## Security Notes

- Keep `adminSourceAddressPrefix` restricted to your own IP range.
- Prefer Bastion or private administration for VM access.
- Rotate SSH keys and delete unused public IPs.
- Patch the VM after deployment.
- Remove the resource group when the lab is no longer needed.

## Cleanup

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

## License

Use at your own risk and only for authorized testing.
