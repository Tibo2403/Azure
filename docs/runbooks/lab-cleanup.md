# Lab Cleanup Runbook

## Trigger

Use this runbook after AZ-305 practice, failed deployments, or cost-control
reviews.

## Steps

1. Confirm the resource group is not production and has no active owner dependency.
2. Remove delete locks if they were enabled.
3. Export useful deployment outputs, logs, or screenshots.
4. Delete resource groups with `scripts/destroy-lab.ps1` or Azure CLI.
5. Confirm expensive global resources such as Front Door, API Management, AKS, and Sentinel workspaces are removed.
6. Check cost analysis the next day for remaining charges.

## Useful Commands

```powershell
.\scripts\destroy-lab.ps1 -ResourceGroupName <rg>
az group list --tag certification=AZ-305 --query "[].{name:name,location:location}"
az consumption usage list
```
