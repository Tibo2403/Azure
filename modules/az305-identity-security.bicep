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

@description('Deploy Key Vault.')
param deployKeyVault bool

@description('Deploy private endpoints and private DNS zones.')
param deployPrivateEndpoints bool

@description('Log Analytics workspace ID for diagnostic settings.')
param logAnalyticsWorkspaceId string

@description('Resource tags.')
param tags object

var keyVaultName = 'kv-${take(prefix, 12)}-${suffix}'

resource workloadIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${prefix}-workload'
  location: location
  tags: tags
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = if (deployKeyVault) {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: deployPrivateEndpoints ? 'Disabled' : 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: deployPrivateEndpoints ? 'Deny' : 'Allow'
    }
  }
}

resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployKeyVault) {
  name: 'diag-keyvault'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource kvPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = if (deployKeyVault && deployPrivateEndpoints) {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags
}

resource kvPrivateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (deployKeyVault && deployPrivateEndpoints) {
  parent: kvPrivateDns
  name: 'link-${prefix}-kv'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource kvPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (deployKeyVault && deployPrivateEndpoints) {
  name: 'pe-${keyVault.name}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'kv'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource kvPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (deployKeyVault && deployPrivateEndpoints) {
  parent: kvPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vault'
        properties: {
          privateDnsZoneId: kvPrivateDns.id
        }
      }
    ]
  }
}

output keyVaultId string = deployKeyVault ? keyVault.id : ''
output keyVaultName string = deployKeyVault ? keyVault.name : ''
output userAssignedIdentityId string = workloadIdentity.id
output userAssignedIdentityPrincipalId string = workloadIdentity.properties.principalId
