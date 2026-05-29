@description('Deployment location.')
param location string

@description('Name prefix used for resources.')
param prefix string

@description('Short unique suffix.')
param suffix string

@description('Deploy messaging and eventing reference resources.')
param deployIntegration bool

@description('Deploy Data Factory reference resource.')
param deployDataIntegration bool

@description('Log Analytics workspace ID for diagnostic settings.')
param logAnalyticsWorkspaceId string

@description('Resource tags.')
param tags object

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = if (deployIntegration) {
  name: 'sb-${prefix}-${suffix}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    disableLocalAuth: false
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-10-01-preview' = if (deployIntegration) {
  parent: serviceBus
  name: 'work-items'
  properties: {
    maxSizeInMegabytes: 1024
    defaultMessageTimeToLive: 'P14D'
  }
}

resource serviceBusDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployIntegration) {
  name: 'diag-servicebus'
  scope: serviceBus
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
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

resource eventGridTopic 'Microsoft.EventGrid/topics@2022-06-15' = if (deployIntegration) {
  name: 'egt-${prefix}-${suffix}'
  location: location
  tags: tags
  properties: {
    publicNetworkAccess: 'Enabled'
    inputSchema: 'EventGridSchema'
  }
}

resource eventGridDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployIntegration) {
  name: 'diag-eventgrid'
  scope: eventGridTopic
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'DeliveryFailures'
        enabled: true
      }
      {
        category: 'PublishFailures'
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

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = if (deployDataIntegration) {
  name: 'adf-${prefix}-${suffix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
}

resource dataFactoryDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployDataIntegration) {
  name: 'diag-datafactory'
  scope: dataFactory
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
        enabled: true
      }
      {
        category: 'ActivityRuns'
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

output serviceBusNamespaceName string = deployIntegration ? serviceBus.name : ''
output eventGridTopicName string = deployIntegration ? eventGridTopic.name : ''
output dataFactoryName string = deployDataIntegration ? dataFactory.name : ''
