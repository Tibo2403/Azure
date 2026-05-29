targetScope = 'managementGroup'

@description('Allowed Azure regions for landing-zone resources.')
param allowedLocations array = [
  'westeurope'
  'northeurope'
]

@description('Required environment tag name.')
param environmentTagName string = 'environment'

var allowedLocationsPolicyId = tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')

resource requireEnvironmentTagPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-mg-require-environment-tag'
  properties: {
    displayName: 'AZ-305 management group require environment tag'
    description: 'Deny resource creation when the environment tag is missing.'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        field: 'tags[${environmentTagName}]'
        exists: false
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource landingZoneInitiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'az305-management-group-landing-zone'
  properties: {
    displayName: 'AZ-305 management group landing zone'
    description: 'Reference management-group initiative for landing-zone governance.'
    policyType: 'Custom'
    policyDefinitions: [
      {
        policyDefinitionId: allowedLocationsPolicyId
        policyDefinitionReferenceId: 'allowed-locations'
        parameters: {
          listOfAllowedLocations: {
            value: allowedLocations
          }
        }
      }
      {
        policyDefinitionId: requireEnvironmentTagPolicy.id
        policyDefinitionReferenceId: 'require-environment-tag'
      }
    ]
  }
}

resource landingZoneAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'az305-mg-landing-zone'
  properties: {
    displayName: 'AZ-305 management group landing zone'
    description: 'Assign the AZ-305 landing-zone baseline at the current management group scope.'
    policyDefinitionId: landingZoneInitiative.id
    enforcementMode: 'DoNotEnforce'
  }
}

output landingZoneInitiativeId string = landingZoneInitiative.id
output landingZoneAssignmentId string = landingZoneAssignment.id
