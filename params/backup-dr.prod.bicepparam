using '../modules/az305-backup-dr-advanced.bicep'

param prefix = 'az305-dr-prod'
param tags = {
  environment: 'prod'
  certification: 'AZ-305'
  theme: 'backup-dr'
  managedBy: 'bicep'
}
