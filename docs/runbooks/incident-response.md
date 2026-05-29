# Incident Response Runbook

## Trigger

Use this runbook when Azure Monitor, Defender for Cloud, or Microsoft Sentinel
raises a security or availability incident.

## Steps

1. Confirm the incident scope, severity, affected subscription, and affected workload.
2. Assign an incident owner and open an incident record in the team's tracking system.
3. Preserve evidence by exporting relevant Sentinel incident details, activity logs, and resource diagnostics.
4. Contain the issue by disabling exposed credentials, restricting network access, or isolating affected resources.
5. Eradicate the root cause by patching configuration, rotating secrets, or applying policy controls.
6. Recover the service and monitor for recurrence.
7. Document timeline, impact, root cause, corrective actions, and preventive controls.

## Useful Commands

```powershell
az monitor activity-log list --status Failed --max-events 50
az security assessment list
az sentinel incident list --resource-group <rg> --workspace-name <workspace>
```
