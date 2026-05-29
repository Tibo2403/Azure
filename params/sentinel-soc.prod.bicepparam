using '../modules/az305-sentinel-soc.bicep'

param prefix = 'az305-soc-prod'
param tags = {
  environment: 'prod'
  certification: 'AZ-305'
  theme: 'sentinel-soc'
  managedBy: 'bicep'
}
