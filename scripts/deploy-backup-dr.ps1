[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $ResourceGroupName,

  [string] $Location = "westeurope"
)

$ErrorActionPreference = "Stop"

az group create --name $ResourceGroupName --location $Location --tags environment=prod certification=AZ-305 theme=backup-dr managedBy=bicep | Out-Null
az deployment group create `
  --resource-group $ResourceGroupName `
  --parameters .\params\backup-dr.prod.bicepparam
