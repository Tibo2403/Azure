# Cloud Adoption Framework Alignment

This repo uses the Microsoft Cloud Adoption Framework as a practical structure
for architecture labs and deployment scenarios.

| CAF area | Repo implementation |
| --- | --- |
| Strategy | AZ-305 coverage documentation and scenario-based architecture modules. |
| Plan | Parameter files grouped by workload theme and environment intent. |
| Ready | Management-group landing zone, subscription governance, policies, budgets, tags. |
| Adopt | Migration toolkit, compute platform options, app integration patterns. |
| Govern | Policy initiatives, FinOps baseline, cost allocation tags, resource locks. |
| Manage | Observability, Sentinel, runbooks, backup, DR, cleanup scripts. |
| Secure | Defender for Cloud, Key Vault, managed identities, WAF, private endpoints. |

## Landing-Zone Notes

- Use `modules/az305-management-group-landing-zone.bicep` for management-group
  policy examples.
- Use `modules/az305-finops-governance.bicep` for subscription-level budget and
  cost allocation tagging.
- Use `modules/az305-policy-initiative.bicep` for resource-group landing-zone
  controls suitable for labs.

## Production Gaps To Decide Per Workload

- Naming standard and subscription topology.
- Identity model and privileged access process.
- Network topology, DNS ownership, and hybrid connectivity.
- Central logging workspace and Sentinel onboarding model.
- Backup scope, restore testing schedule, and DR exercise cadence.
