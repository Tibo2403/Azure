# Azure Pentest VM

This repository contains Bicep templates for deploying a small Linux virtual machine dedicated to authorized security testing labs on Azure.

> Legal notice: use these templates only on environments where you have explicit permission to perform security testing.

## What It Deploys

- Ubuntu Linux VM sized for a lightweight lab.
- Virtual network and subnet.
- Network security group allowing SSH.
- Public IP and network interface.
- Optional custom script extension that installs basic tools such as `nmap` and `curl`.

## Repository Contents

| Path | Purpose |
| --- | --- |
| `pentest.bicep` | Main Bicep template for the lab VM. |
| `pentest2.bicep` | Alternate copy of the VM template kept for experimentation. |
| `Resume/` | Static resume site assets. |
| `.github/workflows/bicep-validate.yml` | CI check that builds the Bicep templates. |

## Prerequisites

- Azure CLI installed and authenticated.
- Existing Azure resource group.
- SSH public key for VM authentication.
- Permission to create compute, networking, and public IP resources.

## Deploy

```bash
az login
az account set --subscription <subscription-id-or-name>

az deployment group create \
  --resource-group <resource-group-name> \
  --template-file pentest.bicep \
  --parameters adminUsername=<admin-user> \
               sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

Get the public IP:

```bash
az network public-ip show \
  --resource-group <resource-group-name> \
  --name pentest-ip \
  --query "ipAddress" \
  --output tsv
```

Connect:

```bash
ssh <admin-user>@<public-ip>
```

## Validate Locally

```bash
az bicep build --file pentest.bicep
az bicep build --file pentest2.bicep
```

## Security Notes

- Restrict `sourceAddressPrefix` to your own IP range before using this outside a temporary lab.
- Rotate SSH keys and delete unused public IPs.
- Patch the VM after deployment.
- Remove the resource group when the lab is no longer needed.

## Cleanup

```bash
az group delete --name <resource-group-name> --yes --no-wait
```

## License

Use at your own risk and only for authorized testing.
