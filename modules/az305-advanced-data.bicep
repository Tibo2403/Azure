@description('Deployment location.')
param location string = resourceGroup().location

@description('Secondary Azure region for Cosmos DB replication.')
param secondaryLocation string = 'northeurope'

@description('Name prefix used for resources.')
param prefix string = 'az305-data'

@description('Short unique suffix.')
param suffix string = toLower(take(uniqueString(resourceGroup().id, prefix), 6))

@description('Deploy Cosmos DB account with multi-region configuration.')
param deployCosmosDb bool = true

@description('Deploy Redis cache reference resource.')
param deployRedis bool = true

@description('Deploy immutable blob storage reference resource.')
param deployImmutableStorage bool = true

@description('Resource tags.')
param tags object = {}

var cosmosName = 'cosmos-${prefix}-${suffix}'
var redisName = 'redis-${prefix}-${suffix}'
var storageName = 'st${take(uniqueString(resourceGroup().id, prefix, 'immutable'), 18)}'

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = if (deployCosmosDb) {
  name: cosmosName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    publicNetworkAccess: 'Disabled'
    enableAutomaticFailover: true
    enableMultipleWriteLocations: false
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    backupPolicy: {
      type: 'Periodic'
      periodicModeProperties: {
        backupIntervalInMinutes: 240
        backupRetentionIntervalInHours: 720
        backupStorageRedundancy: 'Geo'
      }
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
      {
        locationName: secondaryLocation
        failoverPriority: 1
        isZoneRedundant: false
      }
    ]
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' = if (deployCosmosDb) {
  parent: cosmos
  name: 'app'
  properties: {
    resource: {
      id: 'app'
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = if (deployCosmosDb) {
  parent: cosmosDatabase
  name: 'items'
  properties: {
    resource: {
      id: 'items'
      partitionKey: {
        paths: [
          '/tenantId'
        ]
        kind: 'Hash'
      }
    }
  }
}

resource redis 'Microsoft.Cache/redis@2023-08-01' = if (deployRedis) {
  name: redisName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'Basic'
      family: 'C'
      capacity: 0
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource immutableStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = if (deployImmutableStorage) {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Disabled'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = if (deployImmutableStorage) {
  parent: immutableStorage
  name: 'default'
  properties: {
    isVersioningEnabled: true
    deleteRetentionPolicy: {
      enabled: true
      days: 90
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 90
    }
  }
}

resource archiveContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = if (deployImmutableStorage) {
  parent: blobService
  name: 'archive'
  properties: {
    publicAccess: 'None'
    immutableStorageWithVersioning: {
      enabled: true
    }
  }
}

resource immutablePolicy 'Microsoft.Storage/storageAccounts/blobServices/containers/immutabilityPolicies@2023-01-01' = if (deployImmutableStorage) {
  parent: archiveContainer
  name: 'default'
  properties: {
    immutabilityPeriodSinceCreationInDays: 30
    allowProtectedAppendWrites: true
  }
}

resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = if (deployImmutableStorage) {
  parent: immutableStorage
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'cool-then-archive'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: [
                'blockBlob'
              ]
            }
            actions: {
              baseBlob: {
                tierToCool: {
                  daysAfterModificationGreaterThan: 30
                }
                tierToArchive: {
                  daysAfterModificationGreaterThan: 180
                }
              }
            }
          }
        }
      ]
    }
  }
}

output cosmosDbAccountName string = deployCosmosDb ? cosmos.name : ''
output redisName string = deployRedis ? redis.name : ''
output immutableStorageAccountName string = deployImmutableStorage ? immutableStorage.name : ''
