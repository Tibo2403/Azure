[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $ResourceGroupName,

  [string] $Location = "westeurope",

  [string] $AlertEmailAddress = ""
)

$ErrorActionPreference = "Stop"

az group create --name $ResourceGroupName --location $Location --tags environment=prod certification=AZ-305 theme=observability managedBy=bicep | Out-Null
az deployment group create `
  --resource-group $ResourceGroupName `
  --parameters .\params\observability.prod.bicepparam `
  --parameters alertEmailAddress=$AlertEmailAddress
