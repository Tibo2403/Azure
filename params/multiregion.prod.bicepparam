using '../modules/az305-multiregion-frontdoor.bicep'

param primaryLocation = 'westeurope'
param secondaryLocation = 'northeurope'
param prefix = 'az305-prod'
param sqlAdministratorPassword = ''
param tags = {
  environment: 'prod'
  certification: 'AZ-305'
  architecture: 'multi-region'
}
