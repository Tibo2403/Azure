# Secret Rotation Runbook

## Trigger

Use this runbook for scheduled rotation, suspected credential exposure, or owner
changes.

## Steps

1. Identify the Key Vault, secret, certificate, key, or application setting to rotate.
2. Confirm consuming applications and managed identities.
3. Create a new secret version or key version.
4. Update application configuration or references if the consumer does not use latest-version references.
5. Restart or refresh consuming services if required.
6. Validate successful authentication with the new value.
7. Disable the old secret version after the validation window.
8. Delete or purge only when retention and audit requirements allow it.

## Useful Commands

```powershell
az keyvault secret list --vault-name <vault>
az keyvault secret set --vault-name <vault> --name <name> --value <value>
az keyvault key rotate --vault-name <vault> --name <key>
```
