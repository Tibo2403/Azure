using '../modules/az305-app-integration-advanced.bicep'

param prefix = 'az305-appint-prod'
param tags = {
  environment: 'prod'
  certification: 'AZ-305'
  theme: 'app-integration'
  managedBy: 'bicep'
}
