@description('Deployment location. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Short workload name used in Azure resource names.')
@minLength(3)
@maxLength(12)
param workloadName string = 'az305'

@description('Environment tag and naming suffix.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('CIDR range allowed to reach public administration endpoints. Keep the default closed value until you know your public IP.')
param adminSourceAddressPrefix string = '0.0.0.0/32'

@description('Optional resource tags.')
param tags object = {}

@description('Deploy a Linux VM reference workload.')
param deployVm bool = false

@description('Administrator username for the optional Linux VM.')
param vmAdminUsername string = 'azureadmin'

@description('SSH public key for the optional Linux VM. Required when deployVm is true.')
param sshPublicKey string = ''

@description('Attach a public IP to the VM. Prefer Bastion or private access for real environments.')
param deployPublicIpForVm bool = false

@description('Deploy Azure Bastion for private VM administration.')
param deployBastion bool = false

@description('Deploy an App Service reference workload with managed identity and Application Insights.')
param deployAppService bool = true

@description('Deploy an Azure Container Registry reference resource.')
param deployContainerRegistry bool = true

@description('Deploy storage account controls for semi-structured and unstructured data.')
param deployStorage bool = true

@description('Deploy Key Vault for secrets, certificates, and keys.')
param deployKeyVault bool = true

@description('Deploy messaging and eventing reference resources.')
param deployIntegration bool = true

@description('Deploy Data Factory as an integration and analytics reference resource.')
param deployDataIntegration bool = true

@description('Deploy a Recovery Services vault for backup and disaster recovery design.')
param deployBusinessContinuity bool = true

@description('Deploy a resource group delete lock. Enable only when you are not using an ephemeral lab.')
param deployDeleteLock bool = false

var safeWorkload = toLower(replace(workloadName, '_', '-'))
var nameToken = toLower(uniqueString(resourceGroup().id, workloadName, environment))
var prefix = '${safeWorkload}-${environment}'
var storageName = 'st${take(nameToken, 18)}'
var keyVaultName = 'kv-${take(prefix, 12)}-${take(nameToken, 6)}'
var logAnalyticsName = 'law-${prefix}-${take(nameToken, 6)}'
var appInsightsName = 'appi-${prefix}'
var vnetName = 'vnet-${prefix}'
var vmName = 'vm-${prefix}'
var appServicePlanName = 'asp-${prefix}'
var webAppName = 'app-${prefix}-${take(nameToken, 6)}'
var acrName = 'acr${take(nameToken, 16)}'
var serviceBusName = 'sb-${prefix}-${take(nameToken, 6)}'
var eventGridTopicName = 'egt-${prefix}-${take(nameToken, 6)}'
var dataFactoryName = 'adf-${prefix}-${take(nameToken, 6)}'
var recoveryVaultName = 'rsv-${prefix}-${take(nameToken, 6)}'
var mergedTags = union(tags, {
  workload: workloadName
  environment: environment
  certification: 'AZ-305'
  architecture: 'reference'
  managedBy: 'bicep'
})
var appSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-app')
var bastionSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'AzureBastionSubnet')
var vmIpConfigurationProperties = deployPublicIpForVm ? {
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

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: mergedTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: mergedTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource appNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-${prefix}-app'
  location: location
  tags: mergedTags
  properties: {
    securityRules: deployPublicIpForVm ? [
      {
        name: 'Allow-SSH-From-Admin-CIDR'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: adminSourceAddressPrefix
          destinationAddressPrefix: '*'
        }
      }
    ] : []
  }
}

resource dataNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-${prefix}-data'
  location: location
  tags: mergedTags
  properties: {
    securityRules: [
      {
        name: 'Deny-Internet-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  tags: mergedTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.40.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.40.1.0/24'
          networkSecurityGroup: {
            id: appNsg.id
          }
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: '10.40.2.0/24'
          networkSecurityGroup: {
            id: dataNsg.id
          }
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.40.3.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.40.10.0/26'
        }
      }
    ]
  }
}

resource vmPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (deployVm && deployPublicIpForVm) {
  name: 'pip-${vmName}'
  location: location
  tags: mergedTags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (deployBastion) {
  name: 'pip-bastion-${prefix}'
  location: location
  tags: mergedTags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = if (deployBastion) {
  name: 'bas-${prefix}'
  location: location
  tags: mergedTags
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'bastion-ipconfig'
        properties: {
          subnet: {
            id: bastionSubnetId
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2023-09-01' = if (deployVm) {
  name: 'nic-${vmName}'
  location: location
  tags: mergedTags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: vmIpConfigurationProperties
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = if (deployVm) {
  name: vmName
  location: location
  tags: mergedTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
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

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = if (deployStorage) {
  name: storageName
  location: location
  tags: mergedTags
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
      }
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = if (deployStorage) {
  parent: storage
  name: 'default'
  properties: {
    isVersioningEnabled: true
    changeFeed: {
      enabled: true
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 30
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 30
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = if (deployKeyVault) {
  name: keyVaultName
  location: location
  tags: mergedTags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource appPlan 'Microsoft.Web/serverfarms@2022-09-01' = if (deployAppService) {
  name: appServicePlanName
  location: location
  tags: mergedTags
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
  tags: mergedTags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      alwaysOn: false
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
      ]
    }
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = if (deployContainerRegistry) {
  name: acrName
  location: location
  tags: mergedTags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'enabled'
      }
    }
  }
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2022-10-01-preview' = if (deployIntegration) {
  name: serviceBusName
  location: location
  tags: mergedTags
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

resource eventGridTopic 'Microsoft.EventGrid/topics@2022-06-15' = if (deployIntegration) {
  name: eventGridTopicName
  location: location
  tags: mergedTags
  properties: {
    publicNetworkAccess: 'Enabled'
    inputSchema: 'EventGridSchema'
  }
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = if (deployDataIntegration) {
  name: dataFactoryName
  location: location
  tags: mergedTags
  identity: {
    type: 'SystemAssigned'
  }
}

resource recoveryVault 'Microsoft.RecoveryServices/vaults@2023-04-01' = if (deployBusinessContinuity) {
  name: recoveryVaultName
  location: location
  tags: mergedTags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (deployDeleteLock) {
  name: 'lock-${prefix}-cannot-delete'
  properties: {
    level: 'CanNotDelete'
    notes: 'AZ-305 reference architecture delete protection. Disable deployDeleteLock before lab cleanup.'
  }
}

output logAnalyticsWorkspaceId string = logAnalytics.id
output applicationInsightsName string = appInsights.name
output virtualNetworkName string = vnet.name
output vmName string = deployVm ? vm.name : ''
output webAppUrl string = deployAppService ? 'https://${webApp!.properties.defaultHostName}' : ''
output storageAccountName string = deployStorage ? storage.name : ''
output keyVaultName string = deployKeyVault ? keyVault.name : ''
output serviceBusNamespaceName string = deployIntegration ? serviceBus.name : ''
output dataFactoryName string = deployDataIntegration ? dataFactory.name : ''
output recoveryVaultName string = deployBusinessContinuity ? recoveryVault.name : ''
