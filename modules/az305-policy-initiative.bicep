targetScope = 'subscription'

@description('Policy assignment target resource group name.')
param resourceGroupName string

@description('Allowed Azure locations.')
param allowedLocations array = [
  'westeurope'
  'northeurope'
]

@description('Required tag name.')
param requiredTagName string = 'environment'

@description('Required tag value.')
param requiredTagValue string = 'dev'

resource targetRg 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  name: resourceGroupName
}

resource allowedLocationsPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-allowed-locations'
  properties: {
    displayName: 'AZ-305 allowed locations'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        not: {
          field: 'location'
          in: allowedLocations
        }
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource requireTagPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-require-standard-tag'
  properties: {
    displayName: 'AZ-305 require standard tag'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        anyOf: [
          {
            field: 'tags[${requiredTagName}]'
            exists: false
          }
          {
            field: 'tags[${requiredTagName}]'
            notEquals: requiredTagValue
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource denyPublicIpPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-deny-public-ip'
  properties: {
    displayName: 'AZ-305 deny public IP addresses'
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

resource denyStoragePublicAccessPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-deny-storage-public-access'
  properties: {
    displayName: 'AZ-305 deny storage public blob access'
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
            field: 'Microsoft.Storage/storageAccounts/allowBlobPublicAccess'
            equals: true
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource initiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'az305-secure-landing-zone'
  properties: {
    displayName: 'AZ-305 secure landing zone initiative'
    policyType: 'Custom'
    policyDefinitions: [
      {
        policyDefinitionId: allowedLocationsPolicy.id
      }
      {
        policyDefinitionId: requireTagPolicy.id
      }
      {
        policyDefinitionId: denyPublicIpPolicy.id
      }
      {
        policyDefinitionId: denyStoragePublicAccessPolicy.id
      }
    ]
  }
}

module assignment './policy-assignment-rg.bicep' = {
  name: 'az305-policy-initiative-assignment'
  scope: targetRg
  params: {
    policySetDefinitionId: initiative.id
  }
}

output initiativeId string = initiative.id
output assignmentId string = assignment.outputs.assignmentId
