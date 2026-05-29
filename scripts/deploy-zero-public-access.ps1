[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $SubscriptionId,

  [Parameter(Mandatory = $true)]
  [string] $ResourceGroupName,

  [ValidateSet("Default", "DoNotEnforce")]
  [string] $EnforcementMode = "DoNotEnforce",

  [string] $Location = "westeurope"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId
az deployment sub create `
  --location $Location `
  --template-file .\modules\az305-zero-public-access-policy.bicep `
  --parameters resourceGroupName=$ResourceGroupName enforcementMode=$EnforcementMode
