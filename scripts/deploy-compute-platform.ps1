[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $ResourceGroupName,

  [string] $Location = "westeurope",

  [switch] $SkipAks,

  [switch] $SkipContainerApps,

  [switch] $SkipFunctions
)

$ErrorActionPreference = "Stop"

az group create --name $ResourceGroupName --location $Location --tags environment=dev certification=AZ-305 theme=compute-platform managedBy=bicep | Out-Null
az deployment group create `
  --resource-group $ResourceGroupName `
  --parameters .\params\compute-platform.dev.bicepparam `
  --parameters deployAks=$(-not $SkipAks) deployContainerApps=$(-not $SkipContainerApps) deployFunctions=$(-not $SkipFunctions)
