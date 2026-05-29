@description('Deployment location.')
param location string = resourceGroup().location

@description('Name prefix used for resources.')
param prefix string = 'az305-soc'

@description('Short unique suffix.')
param suffix string = toLower(take(uniqueString(resourceGroup().id, prefix), 6))

@description('Resource tags.')
param tags object = {}

var workspaceName = 'law-${prefix}-${suffix}'
var playbookName = 'logic-${prefix}-incident-triage'

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
}

resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${workspace.name})'
  location: location
  tags: tags
  plan: {
    name: 'SecurityInsights(${workspace.name})'
    product: 'OMSGallery/SecurityInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: workspace.id
  }
}

resource failedSigninRule 'Microsoft.SecurityInsights/alertRules@2023-02-01' = {
  name: guid(workspace.id, 'failed-signin-volume')
  scope: workspace
  kind: 'Scheduled'
  properties: {
    displayName: 'AZ-305 failed sign-in volume'
    description: 'Reference Sentinel analytics rule for identity monitoring design.'
    enabled: false
    severity: 'Medium'
    query: 'SigninLogs | where ResultType != 0 | summarize Failed=count() by bin(TimeGenerated, 15m), UserPrincipalName | where Failed > 10'
    queryFrequency: 'PT15M'
    queryPeriod: 'PT1H'
    triggerOperator: 'GreaterThan'
    triggerThreshold: 0
    suppressionEnabled: false
    suppressionDuration: 'PT1H'
    tactics: [
      'CredentialAccess'
      'InitialAccess'
    ]
    incidentConfiguration: {
      createIncident: true
      groupingConfiguration: {
        enabled: true
        reopenClosedIncident: false
        lookbackDuration: 'PT1H'
        matchingMethod: 'Selected'
        groupByEntities: [
          'Account'
        ]
        groupByAlertDetails: []
        groupByCustomDetails: []
      }
    }
    eventGroupingSettings: {
      aggregationKind: 'SingleAlert'
    }
  }
  dependsOn: [
    sentinelSolution
  ]
}

resource playbook 'Microsoft.Logic/workflows@2019-05-01' = {
  name: playbookName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Disabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {}
          }
        }
      }
      actions: {
        compose_incident_context: {
          type: 'Compose'
          inputs: 'Review Sentinel incident, assign owner, capture impact, and document containment.'
          runAfter: {}
        }
      }
      outputs: {}
    }
    parameters: {}
  }
}

resource automationRule 'Microsoft.SecurityInsights/automationRules@2023-02-01' = {
  name: guid(workspace.id, 'tag-medium-incidents')
  scope: workspace
  properties: {
    displayName: 'AZ-305 tag medium incidents'
    order: 1
    triggeringLogic: {
      isEnabled: false
      triggersOn: 'Incidents'
      triggersWhen: 'Created'
      conditions: [
        {
          conditionType: 'Property'
          conditionProperties: {
            propertyName: 'IncidentSeverity'
            operator: 'Equals'
            propertyValues: [
              'Medium'
            ]
          }
        }
      ]
    }
    actions: [
      {
        order: 1
        actionType: 'ModifyProperties'
        actionConfiguration: {
          labels: [
            {
              labelName: 'az305-reference'
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    sentinelSolution
    failedSigninRule
  ]
}

output workspaceName string = workspace.name
output sentinelSolutionName string = sentinelSolution.name
output failedSigninRuleId string = failedSigninRule.id
output playbookName string = playbook.name
output automationRuleId string = automationRule.id
