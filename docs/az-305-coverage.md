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
| Policy initiative | `modules/az305-policy-initiative.bicep` defines a secure landing-zone initiative for allowed locations, required tags, public IP denial, and storage public access denial. |
| Defender for Cloud | `modules/az305-defender-monitoring.bicep` enables Defender pricing plans and creates a security contact. |
| Tagging | All templates merge standard tags: `environment`, `certification`, `managedBy`, and workload tags. |

## Data Storage

| AZ-305 concern | Repo implementation |
| --- | --- |
| Semi-structured and unstructured data | StorageV2 account with HTTPS-only traffic, TLS 1.2 minimum, no public blob access, GRS replication, blob versioning, change feed, delete retention, diagnostics, and optional private endpoint. |
| Relational data | Azure SQL server and database reference resources with TLS, auditing, diagnostics, and optional private endpoint. |
| Globally distributed data | `modules/az305-advanced-data.bicep` includes Cosmos DB with multi-region failover and periodic geo-redundant backups. |
| Caching | `modules/az305-advanced-data.bicep` includes Azure Cache for Redis with TLS-only access. |
| Compliance storage | Immutable blob container and lifecycle management demonstrate retention and archive design. |
| Data protection and durability | Storage redundancy and retention controls demonstrate protection tradeoffs. |
| Data integration | Data Factory is included as the integration and analytics orchestration example. |

## Business Continuity

| AZ-305 concern | Repo implementation |
| --- | --- |
| Backup and disaster recovery | Recovery Services vault, geo-redundant backup storage configuration, VM backup policy, and diagnostics. |
| High availability design | App Service, Storage GRS, and optional Bastion are included as design examples. |
| Multi-region application continuity | `modules/az305-multiregion-frontdoor.bicep` deploys primary/secondary App Services behind Azure Front Door and WAF. |
| SQL continuity | `modules/az305-multiregion-frontdoor.bicep` includes an Azure SQL failover group. |
| Cost-aware continuity | Expensive resources are parameterized so labs can run with minimal defaults. |

## Infrastructure

| AZ-305 concern | Repo implementation |
| --- | --- |
| Compute | Optional Linux VM, App Service with autoscale settings, and Container Registry examples. |
| Network design | Segmented VNet with app, data, private endpoint, App Gateway, and Bastion subnets. |
| Network security | NSGs, closed-by-default SSH source CIDR, no VM public IP by default, optional Bastion, optional NAT Gateway, and optional private endpoints. |
| Load balancing and routing | Optional Application Gateway WAF v2 scenario. |
| Enterprise network topology | `modules/az305-hub-spoke-network.bicep` provides hub, app spoke, data spoke, peering, Azure Firewall, UDRs, and centralized private DNS. |
| Global routing and WAF | `modules/az305-multiregion-frontdoor.bicep` provides Azure Front Door Standard and WAF policy. |
| Messaging and eventing | Service Bus queue and Event Grid topic examples. |
| Automated deployment | PowerShell deployment and what-if scripts under `scripts/`, plus CI Bicep validation. |

## Recommended Lab Flow

1. Deploy governance at subscription scope:

   ```powershell
   .\scripts\deploy-governance.ps1 `
     -SubscriptionId "<subscription-id>" `
     -BudgetContactEmail "you@example.com"
   ```

## Scenario Files

| Scenario | File | Script |
| --- | --- | --- |
| Minimal dev architecture | `params/minimal.dev.bicepparam` | `scripts/deploy-minimal.ps1` |
| Secure private endpoint dev architecture | `params/secure.dev.bicepparam` | `scripts/deploy-secure.ps1` |
| Hub-spoke production topology | `params/hubspoke.prod.bicepparam` | `scripts/deploy-hubspoke.ps1` |
| Multi-region production topology | `params/multiregion.prod.bicepparam` | `scripts/deploy-multiregion.ps1` |
| Advanced data platform | `params/data-platform.prod.bicepparam` | `scripts/deploy-data-platform.ps1` |

## Design Decision Matrix

| Decision | Prefer | Tradeoff |
| --- | --- | --- |
| Private Endpoint vs Service Endpoint | Private Endpoint for sensitive data services | More DNS and network management, stronger isolation |
| Bastion vs public SSH | Bastion | Higher cost, better exposure reduction |
| Front Door vs Application Gateway | Front Door for global entry, Application Gateway for regional L7 | Different scopes and WAF placements |
| App Service vs Container Apps vs AKS | App Service for simple web workloads, Container Apps for event-driven containers, AKS for platform teams | Control and complexity increase toward AKS |
| LRS/ZRS/GRS | LRS for cost, ZRS for zone availability, GRS/RA-GRS for regional durability | Higher resiliency costs more |
| Azure SQL failover group vs backup restore | Failover group for lower RTO/RPO | Requires secondary region and more cost |

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
