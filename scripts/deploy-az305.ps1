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

  [string] $VmAdminUsername = "azureadmin",

  [string] $SshPublicKeyPath = "$HOME\.ssh\id_rsa.pub",

  [switch] $DeployPublicIpForVm,

  [switch] $DeployBastion,

  [switch] $DeployDeleteLock
)

$ErrorActionPreference = "Stop"

$sshPublicKey = ""
if ($DeployVm) {
  if (-not (Test-Path -LiteralPath $SshPublicKeyPath)) {
    throw "SSH public key not found at $SshPublicKeyPath. Create one with ssh-keygen or pass -SshPublicKeyPath."
  }
  $sshPublicKey = Get-Content -LiteralPath $SshPublicKeyPath -Raw
}

az group create `
  --name $ResourceGroupName `
  --location $Location `
  --tags environment=$Environment certification=AZ-305 managedBy=bicep | Out-Null

az deployment group create `
  --resource-group $ResourceGroupName `
  --template-file $TemplateFile `
  --parameters workloadName=$WorkloadName `
               environment=$Environment `
               adminSourceAddressPrefix=$AdminSourceAddressPrefix `
               deployVm=$DeployVm.IsPresent `
               vmAdminUsername=$VmAdminUsername `
               sshPublicKey="$sshPublicKey" `
               deployPublicIpForVm=$DeployPublicIpForVm.IsPresent `
               deployBastion=$DeployBastion.IsPresent `
               deployDeleteLock=$DeployDeleteLock.IsPresent
