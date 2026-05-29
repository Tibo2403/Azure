using '../az305-reference-architecture.bicep'

param workloadName = 'az305'
param environment = 'dev'
param adminSourceAddressPrefix = '0.0.0.0/32'
param deployVm = false
param deployBastion = false
param deployPrivateEndpoints = true
param deployNatGateway = true
param deployApplicationGatewayWaf = false
param deploySql = true
param sqlAdministratorPassword = ''
param deployAppService = true
param deployContainerRegistry = true
param deployStorage = true
param deployKeyVault = true
param deployIntegration = true
param deployDataIntegration = true
param deployBusinessContinuity = true
