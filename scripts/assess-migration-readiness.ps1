[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $SubscriptionId,

  [string] $OutputPath = ".\migration-readiness.csv"
)

$ErrorActionPreference = "Stop"

az account set --subscription $SubscriptionId

$resources = az resource list --query "[].{name:name,type:type,resourceGroup:resourceGroup,location:location,sku:sku.name}" --output json | ConvertFrom-Json

$assessment = foreach ($resource in $resources) {
  $recommendation = switch -Wildcard ($resource.type) {
    "Microsoft.Compute/virtualMachines" { "Assess with Azure Migrate; target VM SKU, zone support, backup, ASR, and dependency map."; break }
    "Microsoft.Sql/servers/databases" { "Assess with Azure Database Migration Service; validate compatibility, tier, HA, backup, and failover."; break }
    "Microsoft.Storage/storageAccounts" { "Assess AzCopy/Data Box; validate redundancy, lifecycle, private endpoints, and immutability."; break }
    "Microsoft.Web/sites" { "Assess PaaS migration; validate runtime, App Service plan, slots, identity, config, and networking."; break }
    default { "Classify workload, dependencies, data gravity, RTO/RPO, security, and target landing zone." }
  }

  [pscustomobject]@{
    Name = $resource.name
    Type = $resource.type
    ResourceGroup = $resource.resourceGroup
    Location = $resource.location
    Sku = $resource.sku
    MigrationRecommendation = $recommendation
  }
}

$assessment | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Migration readiness exported to $OutputPath"
