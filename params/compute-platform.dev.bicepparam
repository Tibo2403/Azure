using '../modules/az305-compute-platform.bicep'

param prefix = 'az305-compute-dev'
param deployAks = true
param deployContainerApps = true
param deployFunctions = true
param tags = {
  environment: 'dev'
  certification: 'AZ-305'
  theme: 'compute-platform'
  managedBy: 'bicep'
}
