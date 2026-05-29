targetScope = 'resourceGroup'

@description('Policy set definition ID to assign.')
param policySetDefinitionId string

@description('Assignment enforcement mode.')
@allowed([
  'Default'
  'DoNotEnforce'
])
param enforcementMode string = 'DoNotEnforce'

resource assignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'az305-zero-public-access'
  properties: {
    displayName: 'AZ-305 zero public access baseline'
    description: 'Assign zero public access policy baseline to the target resource group.'
    policyDefinitionId: policySetDefinitionId
    enforcementMode: enforcementMode
  }
}

output assignmentId string = assignment.id
