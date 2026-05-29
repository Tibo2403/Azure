@description('Primary Azure region.')
param primaryLocation string = resourceGroup().location

@description('Secondary Azure region.')
param secondaryLocation string = 'northeurope'

@description('Name prefix used for resources.')
param prefix string = 'az305-prod'

@description('Short unique suffix.')
param suffix string = toLower(take(uniqueString(resourceGroup().id, prefix), 6))

@secure()
@description('SQL administrator password for the sample primary and secondary SQL servers.')
param sqlAdministratorPassword string

@description('Resource tags.')
param tags object = {}

var primaryAppName = 'app-${prefix}-pri-${suffix}'
var secondaryAppName = 'app-${prefix}-sec-${suffix}'
var frontDoorName = 'afd-${prefix}-${suffix}'
var sqlPrimaryName = 'sql-${prefix}-pri-${suffix}'
var sqlSecondaryName = 'sql-${prefix}-sec-${suffix}'
var failoverGroupName = 'fog-${prefix}-${suffix}'

resource primaryPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-${prefix}-pri'
  location: primaryLocation
  tags: tags
  sku: {
    name: 'P0v3'
    tier: 'PremiumV3'
    capacity: 1
  }
  properties: {
    reserved: true
    zoneRedundant: false
  }
}

resource secondaryPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'asp-${prefix}-sec'
  location: secondaryLocation
  tags: tags
  sku: {
    name: 'P0v3'
    tier: 'PremiumV3'
    capacity: 1
  }
  properties: {
    reserved: true
    zoneRedundant: false
  }
}

resource primaryApp 'Microsoft.Web/sites@2022-09-01' = {
  name: primaryAppName
  location: primaryLocation
  tags: union(tags, {
    regionRole: 'primary'
  })
  kind: 'app,linux'
  properties: {
    serverFarmId: primaryPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }
}

resource secondaryApp 'Microsoft.Web/sites@2022-09-01' = {
  name: secondaryAppName
  location: secondaryLocation
  tags: union(tags, {
    regionRole: 'secondary'
  })
  kind: 'app,linux'
  properties: {
    serverFarmId: secondaryPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }
}

resource frontDoorProfile 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: frontDoorName
  location: 'global'
  tags: tags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoorProfile
  name: 'default'
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoorProfile
  name: 'apps'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
  }
}

resource primaryOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'primary-app'
  properties: {
    hostName: primaryApp.properties.defaultHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: primaryApp.properties.defaultHostName
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource secondaryOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: originGroup
  name: 'secondary-app'
  properties: {
    hostName: secondaryApp.properties.defaultHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: secondaryApp.properties.defaultHostName
    priority: 2
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: endpoint
  name: 'default-route'
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: [
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
    linkToDefaultDomain: 'Enabled'
  }
  dependsOn: [
    primaryOrigin
    secondaryOrigin
  ]
}

resource wafPolicy 'Microsoft.Network/frontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: 'waf${replace(prefix, '-', '')}${suffix}'
  location: 'global'
  tags: tags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '2.1'
        }
      ]
    }
  }
}

resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  parent: frontDoorProfile
  name: 'waf-policy'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: endpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
}

resource sqlPrimary 'Microsoft.Sql/servers@2023-08-01' = {
  name: sqlPrimaryName
  location: primaryLocation
  tags: union(tags, {
    regionRole: 'primary'
  })
  properties: {
    administratorLogin: 'sqladminuser'
    administratorLoginPassword: sqlAdministratorPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource sqlSecondary 'Microsoft.Sql/servers@2023-08-01' = {
  name: sqlSecondaryName
  location: secondaryLocation
  tags: union(tags, {
    regionRole: 'secondary'
  })
  properties: {
    administratorLogin: 'sqladminuser'
    administratorLoginPassword: sqlAdministratorPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2023-08-01' = {
  parent: sqlPrimary
  name: 'appdb'
  location: primaryLocation
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    zoneRedundant: false
  }
}

resource failoverGroup 'Microsoft.Sql/servers/failoverGroups@2023-08-01' = {
  parent: sqlPrimary
  name: failoverGroupName
  properties: {
    partnerServers: [
      {
        id: sqlSecondary.id
      }
    ]
    readWriteEndpoint: {
      failoverPolicy: 'Automatic'
      failoverWithDataLossGracePeriodMinutes: 60
    }
    readOnlyEndpoint: {
      failoverPolicy: 'Disabled'
    }
    databases: [
      sqlDb.id
    ]
  }
}

output frontDoorEndpointHostName string = endpoint.properties.hostName
output primaryAppHostName string = primaryApp.properties.defaultHostName
output secondaryAppHostName string = secondaryApp.properties.defaultHostName
output sqlFailoverGroupName string = failoverGroup.name
