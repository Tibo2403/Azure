targetScope = 'subscription'

@description('Azure region for the resource group.')
param location string = 'westeurope'

@description('Resource group name used for the AZ-305 reference architecture.')
param resourceGroupName string = 'rg-az305-reference-dev'

@description('Monthly budget amount in billing currency.')
@minValue(1)
param monthlyBudgetAmount int = 25

@description('Email address that receives budget notifications.')
param budgetContactEmail string

@description('Budget start date in ISO 8601 format. Defaults to deployment time.')
param budgetStartDate string = utcNow('yyyy-MM-ddTHH:mm:ssZ')

@description('Required tag name enforced by a custom Azure Policy assignment.')
param requiredTagName string = 'environment'

@description('Required tag value enforced by a custom Azure Policy assignment.')
param requiredTagValue string = 'dev'

@description('Optional resource group tags.')
param tags object = {}

var mergedTags = union(tags, {
  environment: requiredTagValue
  certification: 'AZ-305'
  managedBy: 'bicep'
})

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: mergedTags
}

resource requireTagPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-require-tag-${requiredTagName}'
  properties: {
    displayName: 'AZ-305 require tag ${requiredTagName}'
    description: 'Deny resource creation when the required governance tag is missing or has an unexpected value.'
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

module rgGovernance './modules/rg-governance.bicep' = {
  name: 'az305-rg-governance'
  scope: rg
  params: {
    policyDefinitionId: requireTagPolicy.id
    requiredTagName: requiredTagName
    monthlyBudgetAmount: monthlyBudgetAmount
    budgetContactEmail: budgetContactEmail
    budgetStartDate: budgetStartDate
  }
}

output resourceGroupId string = rg.id
output policyAssignmentId string = rgGovernance.outputs.policyAssignmentId
output budgetId string = rgGovernance.outputs.budgetId
