@description('Préfixe commun pour nommer les ressources')
param namePrefix string

@description('Région Azure (ex: westeurope, northeurope)')
param location string = resourceGroup().location

@allowed([
  'B1'
  'P1v3'
  'P2v3'
])
@description('SKU de l’App Service Plan')
param appServiceSku string = 'B1'

@description('Stack runtime de la Web App (ex: DOTNET|8.0, PYTHON|3.12, NODE|20-lts)')
param linuxFxVersion string = 'PYTHON|3.12'

@description('Tags communs')
param tags object = {
  env: 'dev'
  owner: 'infra'
  app: namePrefix
}

@description('Autoriser l’accès public au Key Vault (à adapter selon votre réseau)')
param kvPublicNetworkAccess string = 'Enabled'

var storageName = toLower(replace('${namePrefix}sa${uniqueString(resourceGroup().id)}','-',''))
var planName    = '${namePrefix}-plan'
var webName     = '${namePrefix}-web'
var aiName      = '${namePrefix}-ai'
var kvName      = '${namePrefix}-kv'

/* -------- Storage Account -------- */
resource stg 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: tags
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

/* -------- Application Insights -------- */
resource ai 'Microsoft.Insights/components@2020-02-02' = {
  name: aiName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    IngestionMode: 'ApplicationInsights'
  }
}

/* -------- App Service Plan (Linux) -------- */
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  kind: 'linux'
  tags: tags
  sku: {
    name: appServiceSku
  }
  properties: {
    reserved: true
  }
}

/* -------- Web App (Linux) -------- */
resource web 'Microsoft.Web/sites@2023-12-01' = {
  name: webName
  location: location
  kind: 'app,linux'
  tags: tags
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '0'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: ai.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=' + ai.properties.InstrumentationKey
        }
      ]
    }
  }
  dependsOn: [
    plan
    ai
  ]
}

/* -------- Key Vault + exemple de secret -------- */
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    publicNetworkAccess: kvPublicNetworkAccess
    enableRbacAuthorization: false
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    // Par défaut, aucun access policy n'est ajouté : à gérer après déploiement (RBAC conseillé)
    accessPolicies: []
  }
}

/* Secret d’exemple (remplacez la valeur après déploiement si besoin) */
@secure()
param exampleSecretValue string = 'ChangeMe_StrongP@ssw0rd!'

resource kvSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: '${kv.name}/ExampleSecret'
  properties: {
    value: exampleSecretValue
  }
  dependsOn: [
    kv
  ]
}

/* -------- Sorties -------- */
output storageAccountName string = stg.name
output webAppName string = web.name
output webAppUrl string = 'https://' + web.name + '.azurewebsites.net'
output appInsightsName string = ai.name
output keyVaultName string = kv.name
