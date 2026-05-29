# SQL Failover Runbook

## Trigger

Use this runbook for Azure SQL regional failover testing or an actual regional
outage affecting the primary database.

## Steps

1. Confirm the current primary SQL server and failover group state.
2. Notify application owners before planned failover.
3. Check replication health and lag.
4. Initiate planned failover for tests, or forced failover for disaster recovery.
5. Validate application connection strings use the failover group listener.
6. Run smoke tests against the new primary region.
7. Document RTO, data loss if any, and follow-up actions.

## Useful Commands

```powershell
az sql failover-group list --resource-group <rg> --server <server>
az sql failover-group set-primary --resource-group <rg> --server <secondary-server> --name <fog-name>
```
