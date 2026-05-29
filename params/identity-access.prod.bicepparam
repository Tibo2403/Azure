using '../modules/az305-identity-access.bicep'

param prefix = 'az305-id-prod'
param adminPrincipalObjectId = ''
param tags = {
  environment: 'prod'
  certification: 'AZ-305'
  theme: 'identity-access'
  managedBy: 'bicep'
}
