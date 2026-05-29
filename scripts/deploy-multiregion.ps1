[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $ResourceGroupName,

  [string] $Location = "westeurope",

  [securestring] $SqlAdministratorPassword
)

$ErrorActionPreference = "Stop"

if (-not $SqlAdministratorPassword) {
  $SqlAdministratorPassword = Read-Host "SQL administrator password" -AsSecureString
}

$sqlPassword = [System.Net.NetworkCredential]::new("", $SqlAdministratorPassword).Password

az group create --name $ResourceGroupName --location $Location --tags environment=prod certification=AZ-305 managedBy=bicep | Out-Null
az deployment group create `
  --resource-group $ResourceGroupName `
  --template-file .\modules\az305-multiregion-frontdoor.bicep `
  --parameters .\params\multiregion.prod.bicepparam `
  --parameters sqlAdministratorPassword="$sqlPassword"
