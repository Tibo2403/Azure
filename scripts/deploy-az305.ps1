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

  [string] $AlertEmailAddress = "",

  [switch] $DeployVm,

  [string] $VmAdminUsername = "azureadmin",

  [string] $SshPublicKeyPath = "$HOME\.ssh\id_rsa.pub",

  [switch] $DeployPublicIpForVm,

  [switch] $DeployBastion,

  [switch] $DeployNatGateway,

  [switch] $DeployApplicationGatewayWaf,

  [switch] $DeployPrivateEndpoints,

  [switch] $DeploySql,

  [securestring] $SqlAdministratorPassword,

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

$sqlPassword = ""
if ($DeploySql) {
  if (-not $SqlAdministratorPassword) {
    $SqlAdministratorPassword = Read-Host "SQL administrator password" -AsSecureString
  }
  $sqlPassword = [System.Net.NetworkCredential]::new("", $SqlAdministratorPassword).Password
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
    alertEmailAddress=$AlertEmailAddress `
    deployVm=$DeployVm.IsPresent `
    vmAdminUsername=$VmAdminUsername `
    sshPublicKey="$sshPublicKey" `
    deployPublicIpForVm=$DeployPublicIpForVm.IsPresent `
    deployBastion=$DeployBastion.IsPresent `
    deployNatGateway=$DeployNatGateway.IsPresent `
    deployApplicationGatewayWaf=$DeployApplicationGatewayWaf.IsPresent `
    deployPrivateEndpoints=$DeployPrivateEndpoints.IsPresent `
    deploySql=$DeploySql.IsPresent `
    sqlAdministratorPassword="$sqlPassword" `
    deployDeleteLock=$DeployDeleteLock.IsPresent
