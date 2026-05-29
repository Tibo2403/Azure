@description('Deployment location.')
param location string = resourceGroup().location

@description('Name prefix used for resources.')
param prefix string = 'az305-id'

@description('Short unique suffix.')
param suffix string = toLower(take(uniqueString(resourceGroup().id, prefix), 6))

@description('Optional admin principal object ID to receive scoped Reader and Key Vault Secrets User assignments.')
param adminPrincipalObjectId string = ''

@description('Resource tags.')
param tags object = {}

var keyVaultName = 'kv-${take(replace(prefix, '-', ''), 12)}-${suffix}'
var readerRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
var monitoringReaderRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '43d0d8ad-25c7-4714-9337-8ba259a9fe05')
var keyVaultSecretsUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource appIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${prefix}-app'
  location: location
  tags: tags
}

resource opsIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${prefix}-ops'
  location: location
  tags: tags
}

resource automationIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${prefix}-automation'
  location: location
  tags: tags
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
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
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource platformKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: keyVault
  name: 'cmk-platform'
  properties: {
    kty: 'RSA'
    keySize: 2048
    keyOps: [
      'encrypt'
      'decrypt'
      'sign'
      'verify'
      'wrapKey'
      'unwrapKey'
    ]
    attributes: {
      enabled: true
    }
  }
}

resource appIdentityReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, appIdentity.name, 'reader')
  scope: resourceGroup()
  properties: {
    principalId: appIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: readerRoleDefinitionId
  }
}

resource opsIdentityMonitoringReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, opsIdentity.name, 'monitoring-reader')
  scope: resourceGroup()
  properties: {
    principalId: opsIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: monitoringReaderRoleDefinitionId
  }
}

resource appIdentityKeyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, appIdentity.name, 'kv-secrets-user')
  scope: keyVault
  properties: {
    principalId: appIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
  }
}

resource adminReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(adminPrincipalObjectId)) {
  name: guid(resourceGroup().id, adminPrincipalObjectId, 'admin-reader')
  scope: resourceGroup()
  properties: {
    principalId: adminPrincipalObjectId
    principalType: 'User'
    roleDefinitionId: readerRoleDefinitionId
  }
}

resource adminKeyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(adminPrincipalObjectId)) {
  name: guid(keyVault.id, adminPrincipalObjectId, 'admin-kv-secrets-user')
  scope: keyVault
  properties: {
    principalId: adminPrincipalObjectId
    principalType: 'User'
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
  }
}

output appIdentityId string = appIdentity.id
output opsIdentityId string = opsIdentity.id
output automationIdentityId string = automationIdentity.id
output keyVaultName string = keyVault.name
output platformKeyId string = platformKey.id
