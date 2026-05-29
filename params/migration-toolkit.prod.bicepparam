using '../modules/az305-migration-toolkit.bicep'

param prefix = 'az305-migrate-prod'
param tags = {
  environment: 'prod'
  certification: 'AZ-305'
  theme: 'migration'
  managedBy: 'bicep'
}
