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
| `modules/az305-hub-spoke-network.bicep` | Enterprise hub-spoke with firewall policy, peering, route tables, and private DNS zones. |
| `modules/az305-multiregion-frontdoor.bicep` | Multi-region App Service, Azure Front Door, WAF, and SQL failover group. |
| `modules/az305-advanced-data.bicep` | Cosmos DB, Redis, immutable storage, lifecycle management. |
| `modules/az305-policy-initiative.bicep` | Subscription-scope policy initiative for location, tags, public IP, and storage public access. |
| `modules/az305-defender-monitoring.bicep` | Defender for Cloud plans and security contact. |
| `modules/az305-identity-access.bicep` | Managed identities, scoped RBAC examples, Key Vault, and customer-managed key. |
| `modules/az305-observability-advanced.bicep` | Central Log Analytics, archive storage, Event Hub log routing, Action Group, and activity log alert. |
| `modules/az305-backup-dr-advanced.bicep` | Recovery Services vault, VM backup retention, Data Protection vault, ASR policy, and automation account. |
| `modules/az305-compute-platform.bicep` | AKS, Container Apps, and Azure Functions compute decision examples. |
| `modules/az305-app-integration-advanced.bicep` | API Management, App Configuration, Service Bus topics, and Event Hubs. |
| `modules/az305-migration-toolkit.bicep` | Azure Migrate, Database Migration Service, migration workspace, storage, and move collection. |
| `modules/az305-sentinel-soc.bicep` | Microsoft Sentinel workspace onboarding, analytics rule, automation rule, and Logic App playbook. |
| `modules/az305-finops-governance.bicep` | Subscription budget, cost allocation tags, and FinOps policy initiative. |
| `modules/az305-management-group-landing-zone.bicep` | Management-group landing-zone policy initiative and assignment. |
| `params/*.bicepparam` | Scenario files for minimal, secure, hub-spoke, multi-region, and data-platform deployments. |
| `pentest.bicep` | Hardened VM template for an authorized security lab. |
| `pentest2.bicep` | Wrapper kept for compatibility with older commands. |
| `docs/az-305-coverage.md` | Mapping between AZ-305 design objectives and repo assets. |
| `docs/well-architected-matrix.md` | Azure Well-Architected Framework mapping. |
| `docs/cloud-adoption-framework.md` | Cloud Adoption Framework alignment and landing-zone notes. |
| `docs/runbooks/` | Operational runbooks for incident response, restore, failover, secret rotation, and cleanup. |
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

Deploy enterprise hub-spoke:

```powershell
.\scripts\deploy-hubspoke.ps1 -ResourceGroupName rg-az305-hubspoke-prod
```

Deploy multi-region Front Door and SQL failover:

```powershell
.\scripts\deploy-multiregion.ps1 -ResourceGroupName rg-az305-multiregion-prod
```

Deploy advanced data platform:

```powershell
.\scripts\deploy-data-platform.ps1 -ResourceGroupName rg-az305-data-prod
```

Deploy identity and scoped access scenario:

```powershell
.\scripts\deploy-identity-access.ps1 `
  -ResourceGroupName rg-az305-identity-prod `
  -AdminPrincipalObjectId "<entra-object-id>"
```

Deploy advanced observability and log routing:

```powershell
.\scripts\deploy-observability.ps1 `
  -ResourceGroupName rg-az305-observability-prod `
  -AlertEmailAddress you@example.com
```

Deploy backup and disaster recovery scenario:

```powershell
.\scripts\deploy-backup-dr.ps1 -ResourceGroupName rg-az305-dr-prod
```

Deploy compute platform comparison:

```powershell
.\scripts\deploy-compute-platform.ps1 -ResourceGroupName rg-az305-compute-dev
```

Deploy application integration scenario:

```powershell
.\scripts\deploy-app-integration.ps1 -ResourceGroupName rg-az305-appint-prod
```

Deploy migration toolkit scenario:

```powershell
.\scripts\deploy-migration-toolkit.ps1 -ResourceGroupName rg-az305-migrate-prod
```

Deploy Sentinel/SOC scenario:

```powershell
.\scripts\deploy-sentinel-soc.ps1 -ResourceGroupName rg-az305-soc-prod
```

Deploy subscription-level FinOps controls:

```powershell
.\scripts\deploy-finops.ps1 `
  -SubscriptionId "<subscription-id>" `
  -BudgetContactEmail you@example.com `
  -MonthlyBudgetAmount 100
```

Deploy management-group landing-zone controls:

```powershell
.\scripts\deploy-management-group-landing-zone.ps1 `
  -ManagementGroupId "<management-group-id>"
```

Export a migration readiness inventory:

```powershell
.\scripts\assess-migration-readiness.ps1 `
  -SubscriptionId "<subscription-id>" `
  -OutputPath .\migration-readiness.csv
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

Run repository tests:

```powershell
.\scripts\run-tests.ps1
```

GitHub Actions also validates Bicep files, parameter files, PowerShell syntax,
and repository structure on push and pull request. The `Azure What-If` workflow
can be run manually after configuring `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and
`AZURE_SUBSCRIPTION_ID` repository secrets for OIDC login.

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
