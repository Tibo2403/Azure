@description('Deployment location.')
param location string = resourceGroup().location

@description('Name prefix used for resources.')
param prefix string = 'az305-dev'

@description('Deploy Azure Firewall and route spoke outbound traffic through the hub.')
param deployAzureFirewall bool = true

@description('Deploy DDoS Network Protection plan.')
param deployDdosProtection bool = false

@description('Resource tags.')
param tags object = {}

var hubVnetName = 'vnet-${prefix}-hub'
var appSpokeName = 'vnet-${prefix}-spoke-app'
var dataSpokeName = 'vnet-${prefix}-spoke-data'
var firewallName = 'afw-${prefix}'
var firewallPolicyName = 'afwp-${prefix}'
var firewallPrivateIp = '10.50.0.4'
var blobPrivateDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var sqlPrivateDnsZoneName = 'privatelink.${environment().suffixes.sqlServerHostname}'
var privateDnsZoneNames = [
  'privatelink.vaultcore.azure.net'
  blobPrivateDnsZoneName
  sqlPrivateDnsZoneName
  'privatelink.azurecr.io'
]

resource ddosPlan 'Microsoft.Network/ddosProtectionPlans@2023-09-01' = if (deployDdosProtection) {
  name: 'ddos-${prefix}'
  location: location
  tags: tags
}

resource firewallPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (deployAzureFirewall) {
  name: 'pip-${firewallName}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = if (deployAzureFirewall) {
  name: firewallPolicyName
  location: location
  tags: tags
  properties: {
    threatIntelMode: 'Alert'
    dnsSettings: {
      enableProxy: true
    }
  }
}

resource firewallPolicyRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = if (deployAzureFirewall) {
  parent: firewallPolicy
  name: 'default-application-rules'
  properties: {
    priority: 100
    ruleCollections: [
      {
        name: 'allow-azure-management'
        priority: 100
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow-azure-management-fqdns'
            ruleType: 'ApplicationRule'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: [
              '10.51.0.0/16'
              '10.52.0.0/16'
            ]
            targetFqdns: [
              '*.azure.com'
              '*.microsoft.com'
            ]
          }
        ]
      }
    ]
  }
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: hubVnetName
  location: location
  tags: tags
  properties: {
    enableDdosProtection: deployDdosProtection
    ddosProtectionPlan: deployDdosProtection ? {
      id: ddosPlan.id
    } : null
    addressSpace: {
      addressPrefixes: [
        '10.50.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.50.0.0/26'
        }
      }
      {
        name: 'snet-shared-services'
        properties: {
          addressPrefix: '10.50.1.0/24'
        }
      }
      {
        name: 'snet-private-dns'
        properties: {
          addressPrefix: '10.50.2.0/24'
        }
      }
    ]
  }
}

resource appSpokeVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: appSpokeName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.51.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.51.1.0/24'
        }
      }
      {
        name: 'snet-container'
        properties: {
          addressPrefix: '10.51.2.0/24'
        }
      }
    ]
  }
}

resource dataSpokeVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: dataSpokeName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.52.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-data'
        properties: {
          addressPrefix: '10.52.1.0/24'
        }
      }
      {
        name: 'snet-private-endpoints'
        properties: {
          addressPrefix: '10.52.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = if (deployAzureFirewall) {
  name: firewallName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'firewall-ipconfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnet.name, 'AzureFirewallSubnet')
          }
          publicIPAddress: {
            id: firewallPublicIp.id
          }
        }
      }
    ]
  }
}

resource appRouteTable 'Microsoft.Network/routeTables@2023-09-01' = if (deployAzureFirewall) {
  name: 'rt-${prefix}-app-to-firewall'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource dataRouteTable 'Microsoft.Network/routeTables@2023-09-01' = if (deployAzureFirewall) {
  name: 'rt-${prefix}-data-to-firewall'
  location: location
  tags: tags
  properties: {
    routes: [
      {
        name: 'default-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

resource appToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: appSpokeVnet
  name: 'peer-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

resource hubToAppPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: hubVnet
  name: 'peer-to-app-spoke'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: appSpokeVnet.id
    }
  }
}

resource dataToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: dataSpokeVnet
  name: 'peer-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

resource hubToDataPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: hubVnet
  name: 'peer-to-data-spoke'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: dataSpokeVnet.id
    }
  }
}

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [for zoneName in privateDnsZoneNames: {
  name: zoneName
  location: 'global'
  tags: tags
}]

resource privateDnsHubLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [for (zoneName, index) in privateDnsZoneNames: {
  parent: privateDnsZones[index]
  name: 'link-hub'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnet.id
    }
  }
}]

output hubVnetId string = hubVnet.id
output appSpokeVnetId string = appSpokeVnet.id
output dataSpokeVnetId string = dataSpokeVnet.id
output firewallName string = deployAzureFirewall ? firewall.name : ''
output firewallPolicyId string = deployAzureFirewall ? firewallPolicy.id : ''
