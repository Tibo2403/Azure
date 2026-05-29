targetScope = 'subscription'

@description('Monthly budget amount in billing currency.')
@minValue(1)
param monthlyBudgetAmount int = 100

@description('Email address that receives budget notifications.')
param budgetContactEmail string

@description('Budget start date in ISO 8601 format. Defaults to deployment time.')
param budgetStartDate string = utcNow('yyyy-MM-ddTHH:mm:ssZ')

@description('Required cost center tag name.')
param costCenterTagName string = 'costCenter'

@description('Required owner tag name.')
param ownerTagName string = 'owner'

resource requireCostCenterPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-require-cost-center'
  properties: {
    displayName: 'AZ-305 require cost center tag'
    description: 'Deny resource creation when the cost center tag is missing.'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        field: 'tags[${costCenterTagName}]'
        exists: false
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource requireOwnerPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'az305-require-owner'
  properties: {
    displayName: 'AZ-305 require owner tag'
    description: 'Deny resource creation when the owner tag is missing.'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        field: 'tags[${ownerTagName}]'
        exists: false
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

resource finopsInitiative 'Microsoft.Authorization/policySetDefinitions@2021-06-01' = {
  name: 'az305-finops-baseline'
  properties: {
    displayName: 'AZ-305 FinOps baseline'
    description: 'Reference initiative for cost allocation and ownership tagging.'
    policyType: 'Custom'
    policyDefinitions: [
      {
        policyDefinitionId: requireCostCenterPolicy.id
        policyDefinitionReferenceId: 'require-cost-center'
      }
      {
        policyDefinitionId: requireOwnerPolicy.id
        policyDefinitionReferenceId: 'require-owner'
      }
    ]
  }
}

resource finopsAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' = {
  name: 'az305-finops-baseline'
  properties: {
    displayName: 'AZ-305 FinOps baseline'
    description: 'Assign cost allocation and ownership tagging policies at subscription scope.'
    policyDefinitionId: finopsInitiative.id
    enforcementMode: 'DoNotEnforce'
  }
}

resource subscriptionBudget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: 'az305-monthly-budget'
  properties: {
    category: 'Cost'
    amount: monthlyBudgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
    }
    notifications: {
      actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: [
          budgetContactEmail
        ]
      }
      forecast100: {
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

output finopsInitiativeId string = finopsInitiative.id
output finopsAssignmentId string = finopsAssignment.id
output budgetId string = subscriptionBudget.id
