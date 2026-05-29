targetScope = 'resourceGroup'

@description('Policy set definition ID to assign.')
param policySetDefinitionId string

resource assignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'az305-secure-landing-zone'
  properties: {
    displayName: 'AZ-305 secure landing zone initiative'
    policyDefinitionId: policySetDefinitionId
  }
}

output assignmentId string = assignment.id
