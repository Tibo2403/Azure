[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $SubscriptionId,

  [Parameter(Mandatory = $true)]
  [string] $BudgetContactEmail,

  [string] $ResourceGroupName = "rg-az305-reference-dev",

  [string] $Location = "westeurope",

  [int] $MonthlyBudgetAmount = 25,

  [string] $RequiredTagName = "environment",

  [string] $RequiredTagValue = "dev"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId

az deployment sub create `
  --location $Location `
  --template-file ".\az305-subscription-governance.bicep" `
  --parameters location=$Location `
               resourceGroupName=$ResourceGroupName `
               monthlyBudgetAmount=$MonthlyBudgetAmount `
               budgetContactEmail=$BudgetContactEmail `
               requiredTagName=$RequiredTagName `
               requiredTagValue=$RequiredTagValue
