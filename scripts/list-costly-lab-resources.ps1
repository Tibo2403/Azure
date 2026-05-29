[CmdletBinding()]
param(
  [string] $SubscriptionId = "",

  [string] $TagName = "certification",

  [string] $TagValue = "AZ-305"
)

$ErrorActionPreference = "Stop"

if (-not [string]::IsNullOrWhiteSpace($SubscriptionId)) {
  az account set --subscription $SubscriptionId
}

$query = "[?tags.${TagName}=='${TagValue}'].{name:name,type:type,resourceGroup:resourceGroup,location:location,sku:sku.name,tags:tags}"
$resources = az resource list --query $query --output json | ConvertFrom-Json

$costlyTypePatterns = @(
  "Microsoft.ApiManagement/service",
  "Microsoft.Cdn/profiles",
  "Microsoft.ContainerService/managedClusters",
  "Microsoft.Network/applicationGateways",
  "Microsoft.Network/azureFirewalls",
  "Microsoft.Network/bastionHosts",
  "Microsoft.OperationalInsights/workspaces",
  "Microsoft.RecoveryServices/vaults",
  "Microsoft.Sql/servers/databases",
  "Microsoft.Web/serverfarms"
)

$resources |
  Where-Object { $costlyTypePatterns -contains $_.type } |
  Sort-Object resourceGroup, type, name |
  Select-Object name, type, resourceGroup, location, sku
