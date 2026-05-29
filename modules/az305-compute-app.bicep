@description('Deployment location.')
param location string

@description('Name prefix used for resources.')
param prefix string

@description('Short unique suffix.')
param suffix string

@description('App subnet ID.')
param appSubnetId string

@description('Private endpoint subnet ID.')
param privateEndpointSubnetId string

@description('Virtual network ID used for private DNS links.')
param virtualNetworkId string

@description('Application Insights connection string.')
param appInsightsConnectionString string

@description('Application Insights instrumentation key.')
param appInsightsInstrumentationKey string

@description('Log Analytics workspace ID for diagnostic settings.')
param logAnalyticsWorkspaceId string

@description('User-assigned identity ID to attach to compute resources.')
param userAssignedIdentityId string

@description('Deploy Linux VM reference workload.')
param deployVm bool

@description('Administrator username for the optional Linux VM.')
param vmAdminUsername string

@description('SSH public key for the optional Linux VM.')
param sshPublicKey string

@description('Deploy public IP for the optional VM.')
param deployPublicIpForVm bool

@description('Deploy App Service.')
param deployAppService bool

@description('Deploy Container Registry.')
param deployContainerRegistry bool

@description('Deploy private endpoints and private DNS zones.')
param deployPrivateEndpoints bool

@description('Resource tags.')
param tags object

var webAppName = 'app-${prefix}-${suffix}'
var acrName = 'acr${take(uniqueString(resourceGroup().id, prefix), 16)}'

resource vmPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (deployVm && deployPublicIpForVm) {
  name: 'pip-vm-${prefix}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2023-09-01' = if (deployVm) {
  name: 'nic-vm-${prefix}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: deployPublicIpForVm ? {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: appSubnetId
          }
          publicIPAddress: {
            id: vmPublicIp.id
          }
        } : {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: appSubnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = if (deployVm) {
  name: 'vm-${prefix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'vm-${prefix}'
      adminUsername: vmAdminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${vmAdminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource vmDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployVm) {
  name: 'diag-vm'
  scope: vm
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource appPlan 'Microsoft.Web/serverfarms@2022-09-01' = if (deployAppService) {
  name: 'asp-${prefix}'
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = if (deployAppService) {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: appPlan.id
    httpsOnly: true
    virtualNetworkSubnetId: appSubnetId
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      alwaysOn: false
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
      ]
    }
  }
}

resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployAppService) {
  name: 'diag-webapp'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
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

resource webAutoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (deployAppService) {
  name: 'autoscale-${webAppName}'
  location: location
  tags: tags
  properties: {
    enabled: true
    targetResourceUri: appPlan.id
    profiles: [
      {
        name: 'default'
        capacity: {
          minimum: '1'
          maximum: '2'
          default: '1'
        }
        rules: []
      }
    ]
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = if (deployContainerRegistry) {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: deployPrivateEndpoints ? 'Disabled' : 'Enabled'
    policies: {
      retentionPolicy: {
        days: 7
        status: 'enabled'
      }
    }
  }
}

resource acrDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployContainerRegistry) {
  name: 'diag-acr'
  scope: acr
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
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

resource acrPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = if (deployContainerRegistry && deployPrivateEndpoints) {
  name: 'privatelink.azurecr.io'
  location: 'global'
  tags: tags
}

resource acrPrivateDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (deployContainerRegistry && deployPrivateEndpoints) {
  parent: acrPrivateDns
  name: 'link-${prefix}-acr'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (deployContainerRegistry && deployPrivateEndpoints) {
  name: 'pe-${acr.name}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'acr'
        properties: {
          privateLinkServiceId: acr.id
          groupIds: [
            'registry'
          ]
        }
      }
    ]
  }
}

resource acrPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-09-01' = if (deployContainerRegistry && deployPrivateEndpoints) {
  parent: acrPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'acr'
        properties: {
          privateDnsZoneId: acrPrivateDns.id
        }
      }
    ]
  }
}

output vmName string = deployVm ? vm.name : ''
output webAppName string = deployAppService ? webApp.name : ''
output webAppUrl string = deployAppService ? 'https://${webApp!.properties.defaultHostName}' : ''
output appServicePlanId string = deployAppService ? appPlan.id : ''
output containerRegistryName string = deployContainerRegistry ? acr.name : ''
output vmId string = deployVm ? vm.id : ''
