[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $ResourceGroupName,

  [string] $Location = "westeurope",

  [string] $TemplateFile = ".\az305-reference-architecture.bicep",

  [string] $WorkloadName = "az305",

  [ValidateSet("dev", "test", "prod")]
  [string] $Environment = "dev",

  [string] $AdminSourceAddressPrefix = "0.0.0.0/32",

  [switch] $DeployVm,

  [switch] $DeployPublicIpForVm,

  [switch] $DeployBastion
)

$ErrorActionPreference = "Stop"

az group create `
  --name $ResourceGroupName `
  --location $Location `
  --tags environment=$Environment certification=AZ-305 managedBy=bicep | Out-Null

az deployment group what-if `
  --resource-group $ResourceGroupName `
  --template-file $TemplateFile `
  --parameters workloadName=$WorkloadName `
               environment=$Environment `
               adminSourceAddressPrefix=$AdminSourceAddressPrefix `
               deployVm=$DeployVm.IsPresent `
               deployPublicIpForVm=$DeployPublicIpForVm.IsPresent `
               deployBastion=$DeployBastion.IsPresent
