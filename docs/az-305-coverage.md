# AZ-305 Architecture Coverage

This repo is not an exam dump. It is a hands-on reference lab that maps Azure
architecture design concerns to deployable Bicep examples.

Microsoft's AZ-305 study guide currently groups the exam around four areas:
identity/governance/monitoring, data storage, business continuity, and
infrastructure design. The templates in this repo are organized around those
same architecture decisions.

## Identity, Governance, and Monitoring

| AZ-305 concern | Repo implementation |
| --- | --- |
| Logging and monitoring | `modules/az305-monitoring-governance.bicep` deploys Log Analytics, workspace-based Application Insights, an Action Group, and an example scheduled query alert. |
| Diagnostic settings | The thematic modules attach diagnostic settings for Key Vault, App Service, ACR, Storage, Azure SQL, Service Bus, Event Grid, Data Factory, Recovery Services, and VM metrics where applicable. |
| Identity and authorization | `modules/az305-identity-security.bicep` creates a user-assigned identity; compute resources also use managed identities. |
| Secrets, certificates, keys | Key Vault with RBAC authorization, soft delete, purge protection, diagnostics, and optional private endpoint. |
| Governance | `az305-subscription-governance.bicep` creates a resource group, custom tag policy assignment, and monthly budget. |
| Tagging | All templates merge standard tags: `environment`, `certification`, `managedBy`, and workload tags. |

## Data Storage

| AZ-305 concern | Repo implementation |
| --- | --- |
| Semi-structured and unstructured data | StorageV2 account with HTTPS-only traffic, TLS 1.2 minimum, no public blob access, GRS replication, blob versioning, change feed, delete retention, diagnostics, and optional private endpoint. |
| Relational data | Azure SQL server and database reference resources with TLS, auditing, diagnostics, and optional private endpoint. |
| Data protection and durability | Storage redundancy and retention controls demonstrate protection tradeoffs. |
| Data integration | Data Factory is included as the integration and analytics orchestration example. |

## Business Continuity

| AZ-305 concern | Repo implementation |
| --- | --- |
| Backup and disaster recovery | Recovery Services vault, geo-redundant backup storage configuration, VM backup policy, and diagnostics. |
| High availability design | App Service, Storage GRS, and optional Bastion are included as design examples. |
| Cost-aware continuity | Expensive resources are parameterized so labs can run with minimal defaults. |

## Infrastructure

| AZ-305 concern | Repo implementation |
| --- | --- |
| Compute | Optional Linux VM, App Service with autoscale settings, and Container Registry examples. |
| Network design | Segmented VNet with app, data, private endpoint, App Gateway, and Bastion subnets. |
| Network security | NSGs, closed-by-default SSH source CIDR, no VM public IP by default, optional Bastion, optional NAT Gateway, and optional private endpoints. |
| Load balancing and routing | Optional Application Gateway WAF v2 scenario. |
| Messaging and eventing | Service Bus queue and Event Grid topic examples. |
| Automated deployment | PowerShell deployment and what-if scripts under `scripts/`, plus CI Bicep validation. |

## Recommended Lab Flow

1. Deploy governance at subscription scope:

   ```powershell
   .\scripts\deploy-governance.ps1 `
     -SubscriptionId "<subscription-id>" `
     -BudgetContactEmail "you@example.com"
   ```

2. Preview the resource-group deployment:

   ```powershell
   .\scripts\whatif-az305.ps1 -ResourceGroupName rg-az305-reference-dev
   ```

3. Deploy the minimal reference architecture:

   ```powershell
   .\scripts\deploy-az305.ps1 -ResourceGroupName rg-az305-reference-dev
   ```

4. For VM administration, prefer Bastion:

   ```powershell
   .\scripts\deploy-az305.ps1 `
     -ResourceGroupName rg-az305-reference-dev `
     -DeployVm `
     -DeployBastion `
     -SshPublicKeyPath "$HOME\.ssh\id_rsa.pub"
   ```

5. For a secure data path scenario, add private endpoints, NAT Gateway, and SQL:

   ```powershell
   .\scripts\deploy-az305.ps1 `
     -ResourceGroupName rg-az305-reference-dev `
     -DeployPrivateEndpoints `
     -DeployNatGateway `
     -DeploySql
   ```

## Notes

- Defaults are designed to be safer than the original pentest lab: no public VM
  IP by default in the AZ-305 template and SSH CIDR defaults to a closed value.
- Some services are reference resources rather than full production platforms.
  The goal is to practice design tradeoffs and deployment patterns.
- For production, replace example SQL credentials with Key Vault secret
  references or Microsoft Entra authentication, add workload-specific route
  tables/firewall policy, and tune alert thresholds.
