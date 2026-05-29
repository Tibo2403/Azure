@description('Deployment location.')
param location string = resourceGroup().location

@description('Name prefix used for resources.')
param prefix string = 'az305-obs'

@description('Short unique suffix.')
param suffix string = toLower(take(uniqueString(resourceGroup().id, prefix), 6))

@description('Optional email receiver for critical alerts.')
param alertEmailAddress string = ''

@description('Resource tags.')
param tags object = {}

var storageName = 'stobs${take(uniqueString(resourceGroup().id, prefix), 18)}'
var eventHubNamespaceName = 'evhns-${prefix}-${suffix}'
var actionGroupShortName = take(replace(prefix, '-', ''), 12)

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'law-${prefix}-${suffix}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource archiveStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2022-10-01-preview' = {
  name: eventHubNamespaceName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
  }
}

resource platformLogsHub 'Microsoft.EventHub/namespaces/eventhubs@2022-10-01-preview' = {
  parent: eventHubNamespace
  name: 'platform-logs'
  properties: {
    messageRetentionInDays: 7
    partitionCount: 2
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${prefix}-critical'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: empty(alertEmailAddress) ? [] : [
      {
        name: 'primary-email'
        emailAddress: alertEmailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

resource activityLogAlert 'Microsoft.Insights/activityLogAlerts@2020-10-01' = {
  name: 'ala-${prefix}-service-health'
  location: 'global'
  tags: tags
  properties: {
    enabled: true
    scopes: [
      subscription().id
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ServiceHealth'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: actionGroup.id
        }
      ]
    }
  }
}

resource dailyIngestionAlert 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'sqr-${prefix}-high-ingestion'
  location: location
  tags: tags
  properties: {
    displayName: 'High Log Analytics ingestion'
    description: 'Reference cost-control alert for daily workspace ingestion.'
    enabled: false
    severity: 3
    scopes: [
      workspace.id
    ]
    evaluationFrequency: 'PT1H'
    windowSize: 'P1D'
    criteria: {
      allOf: [
        {
          query: 'Usage | where IsBillable == true | summarize GB=sum(Quantity) / 1024 by bin(TimeGenerated, 1d)'
          timeAggregation: 'Maximum'
          operator: 'GreaterThan'
          threshold: 5
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        actionGroup.id
      ]
    }
  }
}

resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-storage-account'
  scope: archiveStorage
  properties: {
    workspaceId: workspace.id
    eventHubAuthorizationRuleId: '${eventHubNamespace.id}/authorizationRules/RootManageSharedAccessKey'
    eventHubName: platformLogsHub.name
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

resource eventHubDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-eventhub-namespace'
  scope: eventHubNamespace
  properties: {
    workspaceId: workspace.id
    storageAccountId: archiveStorage.id
    logs: [
      {
        category: 'ArchiveLogs'
        enabled: true
      }
      {
        category: 'OperationalLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output workspaceId string = workspace.id
output workspaceName string = workspace.name
output archiveStorageName string = archiveStorage.name
output eventHubNamespaceName string = eventHubNamespace.name
output platformLogsEventHubName string = platformLogsHub.name
output actionGroupId string = actionGroup.id
