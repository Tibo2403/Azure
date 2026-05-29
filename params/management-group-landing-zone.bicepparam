using '../modules/az305-management-group-landing-zone.bicep'

param allowedLocations = [
  'westeurope'
  'northeurope'
]
param environmentTagName = 'environment'
