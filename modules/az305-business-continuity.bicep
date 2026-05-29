@description('Deployment location.')
param location string

@description('Name prefix used for resources.')
param prefix string

@description('Short unique suffix.')
param suffix string

@description('Deploy Recovery Services vault and backup policy.')
param deployBusinessContinuity bool

@description('Log Analytics workspace ID for diagnostic settings.')
param logAnalyticsWorkspaceId string

@description('Resource tags.')
param tags object

resource recoveryVault 'Microsoft.RecoveryServices/vaults@2023-04-01' = if (deployBusinessContinuity) {
  name: 'rsv-${prefix}-${suffix}'
  location: location
  tags: tags
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource recoveryVaultConfig 'Microsoft.RecoveryServices/vaults/backupconfig@2023-04-01' = if (deployBusinessContinuity) {
  parent: recoveryVault
  name: 'vaultconfig'
  properties: {
    storageModelType: 'GeoRedundant'
    storageType: 'GeoRedundant'
    storageTypeState: 'Unlocked'
  }
}

resource vmBackupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2023-04-01' = if (deployBusinessContinuity) {
  parent: recoveryVault
  name: 'daily-vm-backup'
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V1'
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
    }
    timeZone: 'UTC'
  }
}

resource recoveryVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (deployBusinessContinuity) {
  name: 'diag-recovery-vault'
  scope: recoveryVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AzureBackupReport'
        enabled: true
      }
      {
        category: 'CoreAzureBackup'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output recoveryVaultName string = deployBusinessContinuity ? recoveryVault.name : ''
output backupPolicyName string = deployBusinessContinuity ? vmBackupPolicy.name : ''
