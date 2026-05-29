# Backup Restore Runbook

## Trigger

Use this runbook for accidental deletion, data corruption, ransomware recovery,
or restore validation exercises.

## Steps

1. Identify the workload, backup vault, protected item, and target restore point.
2. Confirm restore objective: original location, alternate location, or file-level recovery.
3. Validate restore permissions and target resource group capacity.
4. Start restore from Recovery Services Vault or Data Protection Backup Vault.
5. Validate restored data integrity and application connectivity.
6. Record restore duration and compare it with the target RTO.
7. Keep restored resources isolated until the owner approves cutover or deletion.

## Useful Commands

```powershell
az backup vault list
az backup item list --resource-group <rg> --vault-name <vault>
az backup recoverypoint list --resource-group <rg> --vault-name <vault> --container-name <container> --item-name <item>
```
