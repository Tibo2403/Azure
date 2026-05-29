@description('Deployment location.')
param location string = resourceGroup().location

@description('Name prefix used for resources.')
param prefix string = 'az305-migrate'

@description('Short unique suffix.')
param suffix string = toLower(take(uniqueString(resourceGroup().id, prefix), 6))

@description('Resource tags.')
param tags object = {}

var storageName = 'stmig${take(uniqueString(resourceGroup().id, prefix), 18)}'

resource migrationWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${prefix}-${suffix}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource migrationArtifactsStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Cool'
  }
}

resource migrationProject 'Microsoft.Migrate/migrateProjects@2018-09-01-preview' = {
  name: 'migrate-${prefix}-${suffix}'
  location: location
  tags: tags
  properties: {}
}

resource databaseMigrationService 'Microsoft.DataMigration/services@2022-03-30-preview' = {
  name: 'dms-${prefix}-${suffix}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_1vCore'
    tier: 'Standard'
  }
  properties: {}
}

resource moveCollection 'Microsoft.Migrate/moveCollections@2023-08-01' = {
  name: 'move-${prefix}-${suffix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sourceRegion: location
    targetRegion: 'northeurope'
  }
}

output migrationWorkspaceName string = migrationWorkspace.name
output migrationArtifactsStorageName string = migrationArtifactsStorage.name
output migrationProjectName string = migrationProject.name
output databaseMigrationServiceName string = databaseMigrationService.name
output moveCollectionName string = moveCollection.name
