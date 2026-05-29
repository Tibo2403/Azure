using '../modules/az305-advanced-data.bicep'

param location = 'westeurope'
param secondaryLocation = 'northeurope'
param prefix = 'az305-data'
param deployCosmosDb = true
param deployRedis = true
param deployImmutableStorage = true
param tags = {
  environment: 'prod'
  certification: 'AZ-305'
  architecture: 'advanced-data'
}
