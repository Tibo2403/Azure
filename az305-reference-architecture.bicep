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

@description('Email address used by Azure Monitor action group. Leave empty to create an action group without receivers.')
param alertEmailAddress string = ''

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

@description('Deploy NAT Gateway for controlled outbound internet access.')
param deployNatGateway bool = false

@description('Deploy Application Gateway WAF v2. This can be more expensive than the default lab resources.')
param deployApplicationGatewayWaf bool = false

@description('Deploy private endpoints and private DNS zones for supported services.')
param deployPrivateEndpoints bool = false

@description('Deploy an App Service reference workload with managed identity and Application Insights.')
param deployAppService bool = true

@description('Deploy an Azure Container Registry reference resource.')
param deployContainerRegistry bool = true

@description('Deploy storage account controls for semi-structured and unstructured data.')
param deployStorage bool = true

@description('Deploy Azure SQL Database reference resources.')
param deploySql bool = false

@secure()
@description('SQL administrator password. Required only when deploySql is true.')
param sqlAdministratorPassword string = ''

@description('Deploy Key Vault for secrets, certificates, and keys.')
param deployKeyVault bool = true

@description('Deploy messaging and eventing reference resources.')
param deployIntegration bool = true

@description('Deploy Data Factory as an integration and analytics reference resource.')
param deployDataIntegration bool = true

@description('Deploy a Recovery Services vault and backup policy for business continuity design.')
param deployBusinessContinuity bool = true

@description('Deploy a resource group delete lock. Enable only when you are not using an ephemeral lab.')
param deployDeleteLock bool = false

var safeWorkload = toLower(replace(workloadName, '_', '-'))
var suffix = toLower(take(uniqueString(resourceGroup().id, workloadName, environment), 6))
var prefix = '${safeWorkload}-${environment}'
var mergedTags = union(tags, {
  workload: workloadName
  environment: environment
  certification: 'AZ-305'
  architecture: 'reference'
  managedBy: 'bicep'
})

module monitoring './modules/az305-monitoring-governance.bicep' = {
  name: 'az305-monitoring-governance'
  params: {
    location: location
    prefix: prefix
    suffix: suffix
    alertEmailAddress: alertEmailAddress
    tags: mergedTags
  }
}

module networking './modules/az305-networking.bicep' = {
  name: 'az305-networking'
  params: {
    location: location
    prefix: prefix
    adminSourceAddressPrefix: adminSourceAddressPrefix
    deployBastion: deployBastion
    deployNatGateway: deployNatGateway
    deployApplicationGatewayWaf: deployApplicationGatewayWaf
    tags: mergedTags
  }
}

module identitySecurity './modules/az305-identity-security.bicep' = {
  name: 'az305-identity-security'
  params: {
    location: location
    prefix: prefix
    suffix: suffix
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    virtualNetworkId: networking.outputs.virtualNetworkId
    deployKeyVault: deployKeyVault
    deployPrivateEndpoints: deployPrivateEndpoints
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: mergedTags
  }
}

module compute './modules/az305-compute-app.bicep' = {
  name: 'az305-compute-app'
  params: {
    location: location
    prefix: prefix
    suffix: suffix
    appSubnetId: networking.outputs.appSubnetId
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    virtualNetworkId: networking.outputs.virtualNetworkId
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: monitoring.outputs.appInsightsInstrumentationKey
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    userAssignedIdentityId: identitySecurity.outputs.userAssignedIdentityId
    deployVm: deployVm
    vmAdminUsername: vmAdminUsername
    sshPublicKey: sshPublicKey
    deployPublicIpForVm: deployPublicIpForVm
    deployAppService: deployAppService
    deployContainerRegistry: deployContainerRegistry
    deployPrivateEndpoints: deployPrivateEndpoints
    tags: mergedTags
  }
}

module dataPlatform './modules/az305-data-platform.bicep' = {
  name: 'az305-data-platform'
  params: {
    location: location
    prefix: prefix
    suffix: suffix
    privateEndpointSubnetId: networking.outputs.privateEndpointSubnetId
    virtualNetworkId: networking.outputs.virtualNetworkId
    deployStorage: deployStorage
    deploySql: deploySql
    sqlAdministratorPassword: sqlAdministratorPassword
    deployPrivateEndpoints: deployPrivateEndpoints
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: mergedTags
  }
}

module integration './modules/az305-integration.bicep' = {
  name: 'az305-integration'
  params: {
    location: location
    prefix: prefix
    suffix: suffix
    deployIntegration: deployIntegration
    deployDataIntegration: deployDataIntegration
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: mergedTags
  }
}

module businessContinuity './modules/az305-business-continuity.bicep' = {
  name: 'az305-business-continuity'
  params: {
    location: location
    prefix: prefix
    suffix: suffix
    deployBusinessContinuity: deployBusinessContinuity
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    tags: mergedTags
  }
}

resource deleteLock 'Microsoft.Authorization/locks@2020-05-01' = if (deployDeleteLock) {
  name: 'lock-${prefix}-cannot-delete'
  properties: {
    level: 'CanNotDelete'
    notes: 'AZ-305 reference architecture delete protection. Disable deployDeleteLock before lab cleanup.'
  }
}

output logAnalyticsWorkspaceId string = monitoring.outputs.logAnalyticsWorkspaceId
output virtualNetworkName string = networking.outputs.virtualNetworkName
output keyVaultName string = identitySecurity.outputs.keyVaultName
output vmName string = compute.outputs.vmName
output webAppUrl string = compute.outputs.webAppUrl
output storageAccountName string = dataPlatform.outputs.storageAccountName
output sqlServerName string = dataPlatform.outputs.sqlServerName
output serviceBusNamespaceName string = integration.outputs.serviceBusNamespaceName
output dataFactoryName string = integration.outputs.dataFactoryName
output recoveryVaultName string = businessContinuity.outputs.recoveryVaultName
output applicationGatewayName string = networking.outputs.applicationGatewayName
