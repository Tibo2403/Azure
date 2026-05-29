# Scenario Catalog

| Scenario | AZ-305 theme | Cost profile | Resources | Deploy | Cleanup |
| --- | --- | --- | --- | --- | --- |
| Minimal reference | Core architecture | Low | VNet, Log Analytics, App Service, ACR, Key Vault, integration basics | `scripts/deploy-minimal.ps1` | `scripts/destroy-lab.ps1` |
| Secure private endpoints | Security and data access | Medium | Private endpoints, NAT Gateway, SQL, Key Vault, Storage | `scripts/deploy-secure.ps1` | `scripts/destroy-lab.ps1` |
| Hub-spoke | Infrastructure and network | Medium to high | Hub VNet, spokes, Firewall, route tables, private DNS | `scripts/deploy-hubspoke.ps1` | `scripts/destroy-lab.ps1` |
| Multi-region | Business continuity | Medium to high | Front Door, WAF, primary/secondary apps, SQL failover group | `scripts/deploy-multiregion.ps1` | `scripts/destroy-lab.ps1` |
| Advanced data | Data storage | Medium | Cosmos DB, Redis, immutable Storage, lifecycle management | `scripts/deploy-data-platform.ps1` | `scripts/destroy-lab.ps1` |
| Identity access | Identity and governance | Low | Managed identities, Key Vault, RBAC assignments, CMK | `scripts/deploy-identity-access.ps1` | `scripts/destroy-lab.ps1` |
| Observability | Monitoring | Medium | Log Analytics, Event Hub, archive storage, alerts | `scripts/deploy-observability.ps1` | `scripts/destroy-lab.ps1` |
| Backup and DR | Business continuity | Medium | Recovery Services, Data Protection vault, ASR policy, Automation | `scripts/deploy-backup-dr.ps1` | `scripts/destroy-lab.ps1` |
| Compute platform | Infrastructure | Medium to high | AKS, Container Apps, Functions | `scripts/deploy-compute-platform.ps1` | `scripts/destroy-lab.ps1` |
| App integration | Infrastructure and integration | Medium | API Management, App Configuration, Service Bus, Event Hubs | `scripts/deploy-app-integration.ps1` | `scripts/destroy-lab.ps1` |
| Migration toolkit | Migration design | Medium | Azure Migrate, DMS, move collection, migration workspace | `scripts/deploy-migration-toolkit.ps1` | `scripts/destroy-lab.ps1` |
| Sentinel SOC | Security operations | Medium to high | Sentinel, Log Analytics, analytics rule, playbook | `scripts/deploy-sentinel-soc.ps1` | `scripts/destroy-lab.ps1` |
| FinOps governance | Cost governance | Low | Budget, cost tags, policy initiative | `scripts/deploy-finops.ps1` | Remove assignment/policies manually or redeploy baseline |
| Zero public access | Production security | Low | Subscription policy definitions and RG assignment | `scripts/deploy-zero-public-access.ps1` | Remove policy assignment if no longer needed |

## Suggested Demo Path

1. Run `scripts/validate-az305.ps1`.
2. Run `scripts/run-tests.ps1`.
3. Run `scripts/whatif-az305.ps1` for the minimal scenario.
4. Deploy only one low-cost scenario first.
5. Run `scripts/list-costly-lab-resources.ps1`.
6. Clean up with `scripts/destroy-lab.ps1`.
