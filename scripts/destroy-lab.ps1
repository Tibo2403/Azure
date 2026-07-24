[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param(
  [Parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $ResourceGroupName,

  [string] $SubscriptionId,

  [switch] $Force,

  [switch] $NoWait
)

$ErrorActionPreference = "Stop"

if ($SubscriptionId) {
  az account set --subscription $SubscriptionId | Out-Null
}

$resourceGroupJson = az group show --name $ResourceGroupName --output json 2>$null
if (-not $resourceGroupJson) {
  throw "Resource group '$ResourceGroupName' was not found in the active subscription context."
}

$resourceGroup = $resourceGroupJson | ConvertFrom-Json
$certificationTag = $null

if ($resourceGroup.tags) {
  $certificationTag = $resourceGroup.tags.certification
}

if (-not $Force.IsPresent -and $certificationTag -ne "AZ-305") {
  throw "Refusing to delete resource group '$ResourceGroupName' because it is not tagged with certification=AZ-305. Re-run with -Force only if this is intentional."
}

$targetDescription = if ($resourceGroup.location) {
  "$ResourceGroupName in $($resourceGroup.location)"
} else {
  $ResourceGroupName
}

if ($PSCmdlet.ShouldProcess($targetDescription, "Delete Azure resource group")) {
  az group delete `
    --name $ResourceGroupName `
    --yes `
    --no-wait:$NoWait.IsPresent
}
