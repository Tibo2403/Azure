targetScope = 'resourceGroup'

@description('Policy definition ID to assign to the current resource group.')
param policyDefinitionId string

@description('Required tag name.')
param requiredTagName string

@description('Monthly budget amount in billing currency.')
@minValue(1)
param monthlyBudgetAmount int

@description('Email address that receives budget notifications.')
param budgetContactEmail string

@description('Budget start date in ISO 8601 format.')
param budgetStartDate string

resource requireTagAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'az305-require-tag-assignment'
  properties: {
    displayName: 'AZ-305 require ${requiredTagName} tag'
    policyDefinitionId: policyDefinitionId
  }
}

resource monthlyBudget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'az305-${resourceGroup().name}-monthly-budget'
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
      endDate: '2035-12-31T00:00:00Z'
    }
    notifications: {
      actual80Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [
          budgetContactEmail
        ]
      }
      forecast100Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [
          budgetContactEmail
        ]
      }
    }
  }
}

output policyAssignmentId string = requireTagAssignment.id
output budgetId string = monthlyBudget.id
