targetScope = 'subscription'

@description('Email address for Defender for Cloud security contact.')
param securityContactEmail string

@description('Phone number for Defender for Cloud security contact.')
param securityContactPhone string = ''

@description('Enable Defender for Servers.')
param enableDefenderForServers bool = true

@description('Enable Defender for Storage.')
param enableDefenderForStorage bool = true

@description('Enable Defender for SQL.')
param enableDefenderForSql bool = true

resource pricingServers 'Microsoft.Security/pricings@2024-01-01' = if (enableDefenderForServers) {
  name: 'VirtualMachines'
  properties: {
    pricingTier: 'Standard'
  }
}

resource pricingStorage 'Microsoft.Security/pricings@2024-01-01' = if (enableDefenderForStorage) {
  name: 'StorageAccounts'
  properties: {
    pricingTier: 'Standard'
  }
}

resource pricingSql 'Microsoft.Security/pricings@2024-01-01' = if (enableDefenderForSql) {
  name: 'SqlServers'
  properties: {
    pricingTier: 'Standard'
  }
}

resource securityContact 'Microsoft.Security/securityContacts@2023-12-01-preview' = {
  name: 'default'
  properties: {
    emails: securityContactEmail
    phone: securityContactPhone
    notificationsByRole: {
      state: 'On'
      roles: [
        'Owner'
      ]
    }
    isEnabled: true
    notificationsSources: [
      {
        sourceType: 'Alert'
        minimalSeverity: 'Medium'
      }
    ]
  }
}

output securityContactId string = securityContact.id
