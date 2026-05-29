using '../modules/az305-hub-spoke-network.bicep'

param prefix = 'az305-prod'
param deployAzureFirewall = true
param deployDdosProtection = false
param tags = {
  environment: 'prod'
  certification: 'AZ-305'
  architecture: 'hub-spoke'
}
