targetScope = 'subscription'

@description('Policy assignment target resource group name.')
param resourceGroupName string

@description('Assignment enforcement mode. Use DoNotEnforce for dry-run audits.')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'DoNotEnforce'

resource targetRg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: resourceGroupName
}

resource denyPublicIpPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-zero-deny-public-ip'
  properties: {
    displayName: 'AZ-305 zero public access deny public IP'
    description: 'Deny public IP resources unless an exception process is used.'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Network/publicIPAddresses'
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource denyStoragePublicNetworkPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-zero-deny-storage-public-network'
  properties: {
    displayName: 'AZ-305 zero public access deny storage public network'
    description: 'Deny storage accounts that allow public network access.'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Storage/storageAccounts'
          }
          {
            field: 'Microsoft.Storage/storageAccounts/publicNetworkAccess'
            equals: 'Enabled'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource denyKeyVaultPublicNetworkPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-zero-deny-keyvault-public-network'
  properties: {
    displayName: 'AZ-305 zero public access deny Key Vault public network'
    description: 'Deny Key Vaults that allow public network access.'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.KeyVault/vaults'
          }
          {
            field: 'Microsoft.KeyVault/vaults/publicNetworkAccess'
            equals: 'Enabled'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource denySqlPublicNetworkPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-zero-deny-sql-public-network'
  properties: {
    displayName: 'AZ-305 zero public access deny SQL public network'
    description: 'Deny Azure SQL logical servers that allow public network access.'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Sql/servers'
          }
          {
            field: 'Microsoft.Sql/servers/publicNetworkAccess'
            equals: 'Enabled'
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource auditAppServicePublicIngressPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-zero-audit-appservice-public-ingress'
  properties: {
    displayName: 'AZ-305 zero public access audit App Service public ingress'
    description: 'Audit App Service apps that do not use public network restrictions.'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Web/sites'
      }
      then: {
        effect: 'audit'
      }
    }
  }
}

resource initiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'az305-zero-public-access'
  properties: {
    displayName: 'AZ-305 zero public access baseline'
    description: 'Strict production baseline for workloads that should use private access by default.'
    policyType: 'Custom'
    policyDefinitions: [
      {
        policyDefinitionId: denyPublicIpPolicy.id
        policyDefinitionReferenceId: 'deny-public-ip'
      }
      {
        policyDefinitionId: denyStoragePublicNetworkPolicy.id
        policyDefinitionReferenceId: 'deny-storage-public-network'
      }
      {
        policyDefinitionId: denyKeyVaultPublicNetworkPolicy.id
        policyDefinitionReferenceId: 'deny-keyvault-public-network'
      }
      {
        policyDefinitionId: denySqlPublicNetworkPolicy.id
        policyDefinitionReferenceId: 'deny-sql-public-network'
      }
      {
        policyDefinitionId: auditAppServicePublicIngressPolicy.id
        policyDefinitionReferenceId: 'audit-appservice-public-ingress'
      }
    ]
  }
}

module assignment './zero-public-access-assignment-rg.bicep' = {
  name: 'az305-zero-public-access-assignment'
  scope: targetRg
  params: {
    policySetDefinitionId: initiative.id
    enforcementMode: enforcementMode
  }
}

output initiativeId string = initiative.id
output assignmentId string = assignment.outputs.assignmentId
