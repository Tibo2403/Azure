[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $GitHubOrg,

  [Parameter(Mandatory = $true)]
  [string] $GitHubRepo,

  [string] $AppName = "github-az305-oidc",

  [string] $SubscriptionId = "",

  [string] $Role = "Contributor",

  [string] $Branch = "main"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is required for OIDC setup."
}

$app = az ad app create --display-name $AppName --query "{appId:appId,id:id}" --output json | ConvertFrom-Json
$sp = az ad sp create --id $app.appId --query "{id:id,appId:appId}" --output json | ConvertFrom-Json

$credentialName = "github-${GitHubOrg}-${GitHubRepo}-${Branch}"
$subject = "repo:${GitHubOrg}/${GitHubRepo}:ref:refs/heads/${Branch}"

$params = @{
  name = $credentialName
  issuer = "https://token.actions.githubusercontent.com"
  subject = $subject
  description = "GitHub Actions OIDC for ${GitHubOrg}/${GitHubRepo} ${Branch}"
  audiences = @("api://AzureADTokenExchange")
} | ConvertTo-Json -Depth 4

$tempFile = New-TemporaryFile
try {
  Set-Content -Path $tempFile.FullName -Value $params -Encoding UTF8
  az ad app federated-credential create --id $app.id --parameters "@$($tempFile.FullName)" | Out-Null
} finally {
  Remove-Item -LiteralPath $tempFile.FullName -Force
}

if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
  az account set --subscription $SubscriptionId
  az role assignment create `
    --assignee $sp.appId `
    --role $Role `
    --scope "/subscriptions/$SubscriptionId" | Out-Null
}

[pscustomobject]@{
  AZURE_CLIENT_ID = $app.appId
  AZURE_TENANT_ID = (az account show --query tenantId --output tsv)
  AZURE_SUBSCRIPTION_ID = $SubscriptionId
  FederatedCredentialSubject = $subject
  ServicePrincipalObjectId = $sp.id
}
