@description('Deployment location.')
param location string = resourceGroup().location

@description('Name prefix used for resources.')
param prefix string = 'az305-dr'

@description('Short unique suffix.')
param suffix string = toLower(take(uniqueString(resourceGroup().id, prefix), 6))

@description('Resource tags.')
param tags object = {}

resource recoveryVault 'Microsoft.RecoveryServices/vaults@2023-04-01' = {
  name: 'rsv-${prefix}-${suffix}'
  location: location
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
  }
}

resource recoveryVaultConfig 'Microsoft.RecoveryServices/vaults/backupconfig@2023-04-01' = {
  parent: recoveryVault
  name: 'vaultconfig'
  properties: {
    storageModelType: 'GeoRedundant'
    storageType: 'GeoRedundant'
    storageTypeState: 'Unlocked'
  }
}

resource dailyVmBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = {
  parent: recoveryVault
  name: 'daily-vm-30d'
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V1'
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicy'
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2026-01-01T23:00:00Z'
      ]
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2026-01-01T23:00:00Z'
        ]
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
        ]
        retentionTimes: [
          '2026-01-01T23:00:00Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
          ]
        }
        retentionTimes: [
          '2026-01-01T23:00:00Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Months'
        }
      }
    }
    timeZone: 'UTC'
  }
}

resource dataProtectionVault 'Microsoft.DataProtection/backupVaults@2023-01-01' = {
  name: 'bv-${prefix}-${suffix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: 'GeoRedundant'
      }
    ]
  }
}

resource asrReplicationPolicy 'Microsoft.RecoveryServices/vaults/replicationPolicies@2023-04-01' = {
  parent: recoveryVault
  name: 'asr-a2a-24h'
  properties: {
    providerSpecificInput: {
      instanceType: 'A2A'
      multiVmSyncStatus: 'Disable'
      recoveryPointHistory: 24
      appConsistentFrequencyInMinutes: 240
      crashConsistentFrequencyInMinutes: 5
    }
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: 'aa-${prefix}-${suffix}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'
    }
    publicNetworkAccess: true
  }
}

output recoveryVaultName string = recoveryVault.name
output dataProtectionVaultName string = dataProtectionVault.name
output vmBackupPolicyName string = dailyVmBackupPolicy.name
output asrReplicationPolicyName string = asrReplicationPolicy.name
output automationAccountName string = automationAccount.name
