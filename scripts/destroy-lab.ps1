[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $ResourceGroupName,

  [switch] $NoWait
)

$ErrorActionPreference = "Stop"

az group delete `
  --name $ResourceGroupName `
  --yes `
  --no-wait:$NoWait.IsPresent
