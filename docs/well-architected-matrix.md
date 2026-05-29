# Azure Well-Architected Matrix

This matrix maps the repository scenarios to the Azure Well-Architected
Framework pillars. It is meant as an architecture review aid, not a replacement
for workload-specific design reviews.

| Pillar | Repo assets | Review focus |
| --- | --- | --- |
| Reliability | `az305-multiregion-frontdoor.bicep`, `az305-backup-dr-advanced.bicep`, `az305-business-continuity.bicep` | RTO/RPO, failover testing, backup restore validation, regional dependency mapping. |
| Security | `az305-identity-access.bicep`, `az305-defender-monitoring.bicep`, `az305-sentinel-soc.bicep`, `az305-policy-initiative.bicep` | Least privilege, Key Vault controls, Defender posture, Sentinel detections, private access. |
| Cost Optimization | `az305-finops-governance.bicep`, `az305-subscription-governance.bicep`, scenario toggles | Budgets, cost tags, SKU selection, lab cleanup, workload right-sizing. |
| Operational Excellence | GitHub workflows, `scripts/validate-az305.ps1`, `scripts/run-tests.ps1`, runbooks | CI validation, what-if reviews, incident handling, repeatable deployments. |
| Performance Efficiency | `az305-compute-platform.bicep`, `az305-advanced-data.bicep`, `az305-app-integration-advanced.bicep` | Scale strategy, caching, partitioning, async messaging, API throttling. |

## Review Checklist

- Confirm the workload has explicit RTO and RPO targets.
- Confirm every production resource has diagnostic settings or a documented exception.
- Confirm public exposure is intentional and protected by WAF, private endpoint, or access policy.
- Confirm cost owner and cost center tags exist before production deployment.
- Confirm backup restore and failover procedures have been tested, not only configured.
- Confirm secrets and keys have documented rotation ownership.
