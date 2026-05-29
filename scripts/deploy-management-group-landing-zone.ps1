[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $ManagementGroupId,

  [string] $Location = "westeurope"
)

$ErrorActionPreference = "Stop"

az deployment mg create `
  --management-group-id $ManagementGroupId `
  --location $Location `
  --parameters .\params\management-group-landing-zone.bicepparam
