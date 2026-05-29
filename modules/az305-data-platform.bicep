@description('Deployment location.')
param location string

@description('Name prefix used for resources.')
param prefix string

@description('Short unique suffix.')
param suffix string

@description('Private endpoint subnet ID.')
param privateEndpointSubnetId string

@description('Virtual network ID used for private DNS links.')
param virtualNetworkId string

@description('Deploy Storage Account reference resource.')
param deployStorage bool

@description('Deploy Azure SQL reference resource.')
param deploySql bool

@secure()
@description('SQL administrator password. Required when deploySql is true.')
param sqlAdministratorPassword string

@description('Deploy private endpoints and private DNS zones.')
param deployPrivateEndpoints bool

@description('Log Analytics workspace ID for diagnostic settings.')
param logAnalyticsWorkspaceId string

@description('Resource tags.')
param tags object

var storageName = 'st${take(uniqueString(resourceGroup().id, prefix), 18)}'
var sqlServerName = 'sql-${prefix}-${suffix}'
var sqlDbName = 'sqldb-${prefix}'
var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var sqlPrivateDnsZoneName = 'privatelink.${environment().suffixes.sqlServerHostname}'

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = if (deployStorage) {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: deployPrivateEndpoints ? 'Disabled' : 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: deployPrivateEndpoints ? 'Deny' : 'Allow'
    }
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = if (deployStorage) {
  parent: storage
  name: 'default'
  properties: {
    isVersioningEnabled: true
    changeFeed: {
      enabled: true
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}

resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployStorage) {
  name: 'diag-storage'
  scope: storage
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

resource blobPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = if (deployStorage && deployPrivateEndpoints) {
  name: blobPrivateDnsZoneName
  location: 'global'
  tags: tags
}

resource blobPrivateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (deployStorage && deployPrivateEndpoints) {
  parent: blobPrivateDns
  name: 'link-${prefix}-blob'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource storagePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (deployStorage && deployPrivateEndpoints) {
  name: 'pe-${storage.name}-blob'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storagePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (deployStorage && deployPrivateEndpoints) {
  parent: storagePrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: {
          privateDnsZoneId: blobPrivateDns.id
        }
      }
    ]
  }
}

resource sqlServer 'Microsoft.Sql/servers@2023-08-01' = if (deploySql) {
  name: sqlServerName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: 'sqladminuser'
    administratorLoginPassword: sqlAdministratorPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: deployPrivateEndpoints ? 'Disabled' : 'Enabled'
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2023-08-01' = if (deploySql) {
  parent: sqlServer
  name: sqlDbName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
    capacity: 5
  }
  properties: {
    zoneRedundant: false
    readScale: 'Disabled'
  }
}

resource sqlAuditing 'Microsoft.Sql/servers/auditingSettings@2023-08-01' = if (deploySql) {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
  }
}

resource sqlDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deploySql) {
  name: 'diag-sqldb'
  scope: sqlDb
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLInsights'
        enabled: true
      }
      {
        category: 'AutomaticTuning'
        enabled: true
      }
      {
        category: 'QueryStoreRuntimeStatistics'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Basic'
        enabled: true
      }
    ]
  }
}

resource sqlPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = if (deploySql && deployPrivateEndpoints) {
  name: sqlPrivateDnsZoneName
  location: 'global'
  tags: tags
}

resource sqlPrivateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (deploySql && deployPrivateEndpoints) {
  parent: sqlPrivateDns
  name: 'link-${prefix}-sql'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (deploySql && deployPrivateEndpoints) {
  name: 'pe-${sqlServer.name}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'sql'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

resource sqlPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (deploySql && deployPrivateEndpoints) {
  parent: sqlPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sql'
        properties: {
          privateDnsZoneId: sqlPrivateDns.id
        }
      }
    ]
  }
}

output storageAccountName string = deployStorage ? storage.name : ''
output storageAccountId string = deployStorage ? storage.id : ''
output sqlServerName string = deploySql ? sqlServer.name : ''
output sqlDatabaseName string = deploySql ? sqlDb.name : ''
