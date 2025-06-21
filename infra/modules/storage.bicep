/*
SYNOPSIS: Storage Module - Azure Storage Account with blob containers
DESCRIPTION: This module deploys a storage account with document containers,
             lifecycle policies, and diagnostic settings following AVM patterns.
VERSION: 1.0.0
*/

// ========== Parameters ==========
@description('Required. The prefix for naming the storage account.')
param namePrefix string

@description('Required. The location for the storage account.')
param location string

@description('Required. Tags to apply to all storage resources.')
param tags object

@description('Required. The environment name for conditional configuration.')
param environment string

@description('Required. The resource ID of the Log Analytics workspace for diagnostics.')
param logAnalyticsWorkspaceResourceId string

@description('Optional. The storage account SKU name.')
param skuName string = 'Standard_LRS'

@description('Optional. Enable public network access for the storage account.')
param enablePublicNetworkAccess bool = true

@description('Optional. Number of days to retain deleted blobs.')
@minValue(1)
@maxValue(365)
param blobDeleteRetentionDays int = 7

@description('Optional. Number of days to retain deleted containers.')
@minValue(1)
@maxValue(365)
param containerDeleteRetentionDays int = 7

// ========== Variables ==========
var abbrs = loadJsonContent('./abbreviations.json')

// Storage Account name must be globally unique, lowercase alphanumeric only, max 24 chars
var storageAccountName = toLower(replace(
  substring('${abbrs.storageAccount}${namePrefix}${substring(location, 0, 3)}', 0, 24),
  '-',
  ''
))

// ========== Resources ==========

// Storage Account
module storageAccount 'br/public:avm/res/storage/storage-account:0.14.3' = {
  name: 'storage-${uniqueString(deployment().name, location)}'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    // Storage account configuration
    skuName: skuName
    kind: 'StorageV2'
    // Access tier for blob storage
    accessTier: 'Hot'
    // Enable HTTPS-only traffic
    supportsHttpsTrafficOnly: true
    // Minimum TLS version
    minimumTlsVersion: 'TLS1_2'
    // Allow public blob access (will be restricted via container settings)
    allowBlobPublicAccess: false
    // Allow shared key access (will migrate to Azure AD later)
    allowSharedKeyAccess: true
    // Network access configuration
    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    networkAcls: {
      defaultAction: 'Allow' // TODO: Change to 'Deny' after VNet/Private Endpoint setup
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
    // Enable soft delete for blob recovery
    blobServices: {
      deleteRetentionPolicyEnabled: true
      deleteRetentionPolicyDays: blobDeleteRetentionDays
      containerDeleteRetentionPolicyEnabled: true
      containerDeleteRetentionPolicyDays: containerDeleteRetentionDays
      // Create containers for document storage
      containers: [
        {
          name: 'documents'
          publicAccess: 'None'
          metadata: {
            purpose: 'LLM document storage'
            environment: environment
          }
        }
        {
          name: 'temp-uploads'
          publicAccess: 'None'
          metadata: {
            purpose: 'Temporary upload storage'
            environment: environment
          }
        }
      ]
    }
    // Lifecycle management for cost optimization
    managementPolicyRules: [
      {
        enabled: true
        name: 'delete-old-temp-uploads'
        type: 'Lifecycle'
        definition: {
          actions: {
            baseBlob: {
              delete: {
                daysAfterModificationGreaterThan: 7
              }
            }
          }
          filters: {
            blobTypes: [
              'blockBlob'
            ]
            prefixMatch: [
              'temp-uploads/'
            ]
          }
        }
      }
      {
        enabled: true
        name: 'move-to-cool-tier'
        type: 'Lifecycle'
        definition: {
          actions: {
            baseBlob: {
              tierToCool: {
                daysAfterModificationGreaterThan: 30
              }
            }
          }
          filters: {
            blobTypes: [
              'blockBlob'
            ]
            prefixMatch: [
              'documents/'
            ]
          }
        }
      }
    ]
    // Diagnostic settings
    diagnosticSettings: [
      {
        name: 'storage-diagnostics'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        storageAccountResourceId: '' // Self-logging not recommended
        logCategoriesAndGroups: [
          {
            category: 'StorageRead'
            enabled: true
          }
          {
            category: 'StorageWrite'
            enabled: true
          }
          {
            category: 'StorageDelete'
            enabled: true
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
      }
    ]
    // Managed identity for future integrations
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// ========== Outputs ==========

@description('The resource ID of the storage account.')
output storageAccountId string = storageAccount.outputs.resourceId

@description('The name of the storage account.')
output storageAccountName string = storageAccount.outputs.name

@description('The resource ID of the storage account.')
output resourceId string = storageAccount.outputs.resourceId

@description('The primary blob endpoint of the storage account.')
output primaryBlobEndpoint string = storageAccount.outputs.primaryBlobEndpoint

@description('The principal ID of the system-assigned managed identity.')
output systemAssignedMIPrincipalId string = storageAccount.outputs.systemAssignedMIPrincipalId
