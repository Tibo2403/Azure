@description('Deployment location.')
param location string = resourceGroup().location

@description('Name prefix used for resources.')
param prefix string = 'az305-compute'

@description('Short unique suffix.')
param suffix string = toLower(take(uniqueString(resourceGroup().id, prefix), 6))

@description('Deploy AKS reference cluster.')
param deployAks bool = true

@description('Deploy Azure Container Apps reference workload.')
param deployContainerApps bool = true

@description('Deploy Azure Functions reference workload.')
param deployFunctions bool = true

@description('Resource tags.')
param tags object = {}

var storageName = 'stfunc${take(uniqueString(resourceGroup().id, prefix), 17)}'
var functionAppName = 'func-${prefix}-${suffix}'

resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = if (deployAks) {
  name: 'aks-${prefix}-${suffix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'aks-${prefix}-${suffix}'
    kubernetesVersion: ''
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'system'
        count: 1
        vmSize: 'Standard_B2s'
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
      outboundType: 'loadBalancer'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = if (deployContainerApps) {
  name: 'cae-${prefix}-${suffix}'
  location: location
  tags: tags
  properties: {}
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = if (deployContainerApps) {
  name: 'ca-${prefix}-${suffix}'
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: [
        {
          name: 'hello'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

resource functionStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = if (deployFunctions) {
  name: storageName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource functionPlan 'Microsoft.Web/serverfarms@2022-09-01' = if (deployFunctions) {
  name: 'plan-${functionAppName}'
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = if (deployFunctions) {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: functionPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'Python|3.11'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionStorage!.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
      ]
    }
  }
}

output aksName string = deployAks ? aks.name : ''
output containerAppsEnvironmentName string = deployContainerApps ? containerAppsEnvironment.name : ''
output containerAppName string = deployContainerApps ? containerApp.name : ''
output functionAppName string = deployFunctions ? functionApp.name : ''
