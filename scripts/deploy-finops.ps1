[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $SubscriptionId,

  [Parameter(Mandatory = $true)]
  [string] $BudgetContactEmail,

  [int] $MonthlyBudgetAmount = 100,

  [string] $Location = "westeurope"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId
az deployment sub create `
  --location $Location `
  --template-file .\modules\az305-finops-governance.bicep `
  --parameters monthlyBudgetAmount=$MonthlyBudgetAmount budgetContactEmail=$BudgetContactEmail
