# AZ-305 Study Notes

## Identity, Governance, and Monitoring

| Decision | Prefer | Watch for |
| --- | --- | --- |
| Managed identity vs client secret | Managed identity | Cross-tenant and external workloads may need federation. |
| RBAC vs Key Vault access policies | RBAC | Requires clear scope and role ownership. |
| Azure Policy vs manual review | Azure Policy | Deny effects can block deployments if not tested. |
| Sentinel vs Log Analytics | Sentinel for SOC workflows | Cost and onboarding scope. |

## Data Storage

| Decision | Prefer | Watch for |
| --- | --- | --- |
| Azure SQL vs Cosmos DB | SQL for relational consistency, Cosmos DB for global NoSQL | Partitioning and consistency model. |
| GRS vs ZRS | GRS for regional durability, ZRS for zone availability | Cost and failover behavior. |
| Private endpoint vs public network | Private endpoint for sensitive data | DNS operations. |
| Immutable storage | Compliance retention | Deletion and legal hold implications. |

## Business Continuity

| Decision | Prefer | Watch for |
| --- | --- | --- |
| Backup restore vs active failover | Active failover for low RTO/RPO | Higher cost and operational testing. |
| Front Door vs Traffic Manager | Front Door for HTTP global entry and WAF | Non-HTTP needs another pattern. |
| ASR vs rebuild from IaC | ASR for stateful IaaS, IaC for stateless workloads | Replication cost and test failover cadence. |

## Infrastructure

| Decision | Prefer | Watch for |
| --- | --- | --- |
| App Service vs Container Apps vs AKS | Match operational maturity | AKS needs platform operations. |
| Hub-spoke vs flat VNet | Hub-spoke for shared services | Routing and DNS complexity. |
| Firewall vs NSG only | Firewall for central egress/ingress control | Cost and rule lifecycle. |
| API Management vs direct API | APIM for API governance | Adds gateway and policy management. |
