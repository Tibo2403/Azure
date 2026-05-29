# GitHub OIDC Setup

Use OpenID Connect instead of long-lived Azure client secrets for GitHub Actions.

## Required Repository Secrets

The workflows expect these repository secrets:

| Secret | Value |
| --- | --- |
| `AZURE_CLIENT_ID` | App registration client ID. |
| `AZURE_TENANT_ID` | Microsoft Entra tenant ID. |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID. |

## Automated Setup

```powershell
.\scripts\setup-github-oidc.ps1 `
  -GitHubOrg "Tibo2403" `
  -GitHubRepo "Azure" `
  -SubscriptionId "<subscription-id>" `
  -Role "Contributor"
```

Copy the returned values into GitHub repository secrets. The script creates:

- an Entra app registration
- a service principal
- a federated credential for `main`
- an optional subscription role assignment

## Security Notes

- Prefer least privilege over subscription-wide Contributor for production.
- Create separate federated credentials for protected environments.
- Use GitHub environments with required reviewers before destructive workflows.
- Rotate by deleting and recreating federated credentials, not by storing secrets.
