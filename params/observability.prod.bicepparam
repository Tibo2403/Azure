using '../modules/az305-observability-advanced.bicep'

param prefix = 'az305-obs-prod'
param alertEmailAddress = ''
param tags = {
  environment: 'prod'
  certification: 'AZ-305'
  theme: 'observability'
  managedBy: 'bicep'
}
