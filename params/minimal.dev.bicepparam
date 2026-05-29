using '../az305-reference-architecture.bicep'

param workloadName = 'az305'
param environment = 'dev'
param deployVm = false
param deployBastion = false
param deployPrivateEndpoints = false
param deployNatGateway = false
param deployApplicationGatewayWaf = false
param deploySql = false
param deployAppService = true
param deployContainerRegistry = true
param deployStorage = true
param deployKeyVault = true
param deployIntegration = true
param deployDataIntegration = true
param deployBusinessContinuity = true
