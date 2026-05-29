[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $ResourceGroupName,

  [string] $Location = "westeurope",

  [string] $AdminPrincipalObjectId = ""
)

$ErrorActionPreference = "Stop"

az group create --name $ResourceGroupName --location $Location --tags environment=prod certification=AZ-305 theme=identity-access managedBy=bicep | Out-Null
az deployment group create `
  --resource-group $ResourceGroupName `
  --parameters .\params\identity-access.prod.bicepparam `
  --parameters adminPrincipalObjectId=$AdminPrincipalObjectId
