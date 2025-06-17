// ========== Parameters ==========
@description('The environment name (dev, prod)')
@allowed(['dev', 'prod'])
param environment string

@description('The Azure region for resource deployment')
param location string

@description('The project identifier')
param projectName string

@description('Tags to apply to all resources')
param tags object

// ========== Variables ==========
var abbrs = loadJsonContent('./modules/abbreviations.json')
var appServicePlanName = '${abbrs.appServicePlan}-${projectName}-${environment}'
var frontendAppName = '${abbrs.appService}-${projectName}-fe-${environment}'
var backendAppName = '${abbrs.appService}-${projectName}-be-${environment}'
// Container Registry names must be globally unique and alphanumeric only
// Using location suffix to ensure uniqueness while maintaining readability
var containerRegistryName = toLower(replace(
  '${abbrs.containerRegistry}${projectName}${environment}${substring(location, 0, 3)}',
  '-',
  ''
))
// Key Vault names must be globally unique and have character limits
var keyVaultName = '${abbrs.keyVault}-${projectName}-${environment}'
// Log Analytics workspace name
var logAnalyticsWorkspaceName = '${abbrs.logAnalyticsWorkspace}-${projectName}-${environment}'
// Application Insights name
var applicationInsightsName = '${abbrs.applicationInsights}-${projectName}-${environment}'
// Storage Account name must be globally unique, lowercase alphanumeric only, max 24 chars
var storageAccountName = toLower(replace(
  substring('${abbrs.storageAccount}${projectName}${environment}${substring(location, 0, 3)}', 0, 24),
  '-',
  ''
))
// AI Foundry Hub name - following naming convention
var aiFoundryHubName = '${abbrs.machineLearningWorkspace}-hub-${projectName}-${environment}'
// AI Foundry Project name - following naming convention
var aiFoundryProjectName = '${abbrs.machineLearningWorkspace}-proj-${projectName}-${environment}'

// Define SKU based on environment
var appServicePlanSkuName = 'P1v3'
var appServicePlanSkuCapacity = environment == 'prod' ? 2 : 1

// Container Registry configuration
var containerRegistrySkuName = 'Premium' // Premium SKU for vulnerability scanning

// ========== Log Analytics Workspace ==========
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: 'log-analytics-deployment'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags
    // Set retention based on environment
    dataRetention: environment == 'prod' ? 90 : 30
    // Enable ingestion for Application Insights
    useResourcePermissions: true
    // Configure daily cap to control costs
    dailyQuotaGb: environment == 'prod' ? 50 : 10
    // Enable public network access (will be restricted later with Private Endpoints)
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    // Managed identity for future integrations
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// ========== Application Insights ==========
module applicationInsights 'br/public:avm/res/insights/component:0.4.1' = {
  name: 'app-insights-deployment'
  params: {
    name: applicationInsightsName
    location: location
    tags: tags
    // Workspace-based mode for unified observability
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    // Application type for proper categorization
    applicationType: 'web'
    // Request type for monitoring
    kind: 'web'
    // Enable public network access (will be restricted later with Private Endpoints)
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    // Retention period inherits from Log Analytics workspace
    retentionInDays: environment == 'prod' ? 90 : 30
    // Disable legacy Application Insights features
    disableIpMasking: false
    // Sampling settings for cost control
    samplingPercentage: environment == 'prod' ? 100 : 100 // 100% for now, can be adjusted
  }
}

// ========== Storage Account ==========
module storageAccount 'br/public:avm/res/storage/storage-account:0.14.3' = {
  name: 'storage-deployment'
  params: {
    name: storageAccountName
    location: location
    tags: tags
    // Storage account configuration
    skuName: 'Standard_LRS' // Locally redundant storage for cost optimization
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
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow' // TODO: Change to 'Deny' after VNet/Private Endpoint setup
      bypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
    // Enable soft delete for blob recovery
    blobServices: {
      deleteRetentionPolicyEnabled: true
      deleteRetentionPolicyDays: 7
      containerDeleteRetentionPolicyEnabled: true
      containerDeleteRetentionPolicyDays: 7
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
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
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

// ========== Container Registry ==========
module containerRegistry 'br/public:avm/res/container-registry/registry:0.5.1' = {
  name: 'acr-deployment'
  params: {
    name: containerRegistryName
    location: location
    acrSku: containerRegistrySkuName
    tags: tags
    acrAdminUserEnabled: false // Security best practice: disable admin user
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    // Enable vulnerability scanning with Premium SKU
    quarantinePolicyStatus: 'enabled'
    retentionPolicyStatus: 'enabled'
    retentionPolicyDays: 30
    trustPolicyStatus: 'disabled' // Will be configured later if needed
    // Enable soft delete for recovery (Premium feature)
    softDeletePolicyStatus: 'enabled'
    softDeletePolicyDays: 7
    // Disable tag mutability for immutable artifacts
    exportPolicyStatus: 'disabled' // Prevents exporting images out of registry
    // Enable zone redundancy for high availability (Premium feature)
    zoneRedundancy: environment == 'prod' ? 'Enabled' : 'Disabled'
    // Geo-replication for regional affinity (Premium feature)
    replications: environment == 'prod'
      ? [
          {
            name: 'westus2'
            location: 'westus2'
            regionEndpointEnabled: true
            zoneRedundancy: 'Enabled'
            tags: tags
          }
        ]
      : []
    managedIdentities: {
      systemAssigned: true
    }
    // Diagnostic settings for monitoring and auditing
    diagnosticSettings: [
      {
        name: 'acr-diagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
        logCategoriesAndGroups: [
          {
            category: 'ContainerRegistryRepositoryEvents'
            enabled: true
          }
          {
            category: 'ContainerRegistryLoginEvents'
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
  }
}

// ========== Key Vault ==========
module keyVault 'br/public:avm/res/key-vault/vault:0.10.2' = {
  name: 'keyvault-deployment'
  params: {
    name: keyVaultName
    location: location
    tags: tags
    // Enable RBAC authorization instead of access policies (Azure Key Vault handbook best practice)
    enableRbacAuthorization: true
    // Enable purge protection for production safety (BCPNFR security requirement)
    enablePurgeProtection: true
    // Set retention days for soft delete per handbook recommendation
    softDeleteRetentionInDays: environment == 'prod' ? 90 : 7
    // Enable soft delete for recovery capabilities
    enableSoftDelete: true
    // Enable public network access (will be restricted later with Private Endpoints)
    publicNetworkAccess: 'Enabled'
    // Network ACLs - secure by default, allow Azure services for managed identities
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow' // TODO: Change to 'Deny' after VNet/Private Endpoint setup
      ipRules: []
      virtualNetworkRules: []
    }
    // SKU configuration - Standard is sufficient for our needs
    sku: 'standard'
    // Disable key vault for deployment scenarios (not needed for our use case)
    enableVaultForDeployment: false
    enableVaultForDiskEncryption: false
    enableVaultForTemplateDeployment: false
    // No access policies needed with RBAC authorization
    accessPolicies: []
    // Diagnostic settings for security auditing and monitoring
    diagnosticSettings: [
      {
        name: 'kv-diagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
        logCategoriesAndGroups: [
          {
            category: 'AuditEvent' // Critical for security auditing
            enabled: true
          }
          {
            category: 'AzurePolicyEvaluationDetails' // Policy compliance tracking
            enabled: true
          }
        ]
      }
    ]
    // Role assignments will be configured in T-08
    // Private endpoints will be added in future infrastructure updates
  }
}

// ========== App Service Plan ==========
module appServicePlan 'br/public:avm/res/web/serverfarm:0.3.0' = {
  name: 'asp-deployment'
  params: {
    name: appServicePlanName
    location: location
    skuName: appServicePlanSkuName
    skuCapacity: appServicePlanSkuCapacity
    kind: 'Linux'
    tags: tags
  }
}

// ========== Backend App Service ==========
module backendApp 'br/public:avm/res/web/site:0.10.0' = {
  name: 'backend-app-deployment'
  params: {
    name: backendAppName
    location: location
    serverFarmResourceId: appServicePlan.outputs.resourceId
    kind: 'app,linux,container'
    tags: tags
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistry.outputs.loginServer}/backend:latest'
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.outputs.loginServer}'
        }
        {
          name: 'REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.outputs.connectionString
        }
        {
          name: 'AZURE_KEY_VAULT_URI'
          value: keyVault.outputs.uri
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.outputs.connectionString
        }
        {
          name: 'OTEL_RESOURCE_ATTRIBUTES'
          value: 'service.name=${backendAppName},service.version=1.0.0,deployment.environment=${environment}'
        }
        {
          name: 'OTEL_TRACES_SAMPLER'
          value: 'parentbased_always_on'
        }
        {
          name: 'AZURE_STORAGE_CONNECTION_STRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.outputs.name};EndpointSuffix=core.windows.net'
        }
        {
          name: 'AZURE_FOUNDRY_ENDPOINT'
          value: 'https://<TO_BE_CONFIGURED>.openai.azure.com/' // Placeholder - actual endpoint to be configured after AI Service deployment
        }
        {
          name: 'AZURE_FOUNDRY_OPENAI_DEPLOYMENT'
          value: 'gpt-4o-${environment}' // Deployment name to be created in AI Foundry
        }
        {
          name: 'AZURE_AI_HUB_NAME'
          value: aiFoundryHub.outputs.name
        }
        {
          name: 'AZURE_AI_PROJECT_NAME'
          value: aiFoundryProject.outputs.name
        }
      ]
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      healthCheckPath: '/health'
      cors: {
        allowedOrigins: [
          'https://${frontendAppName}.azurewebsites.net'
          environment == 'dev' ? 'http://localhost:3000' : ''
        ]
        supportCredentials: true
      }
    }
    httpsOnly: true
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// ========== Frontend App Service ==========
module frontendApp 'br/public:avm/res/web/site:0.10.0' = {
  name: 'frontend-app-deployment'
  params: {
    name: frontendAppName
    location: location
    serverFarmResourceId: appServicePlan.outputs.resourceId
    kind: 'app,linux,container'
    tags: tags
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistry.outputs.loginServer}/frontend:latest'
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '3000'
        }
        {
          name: 'REACT_APP_API_URL'
          value: 'https://${backendAppName}.azurewebsites.net'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.outputs.loginServer}'
        }
      ]
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      healthCheckPath: '/'
    }
    httpsOnly: true
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// ========== AI Foundry Hub ==========
module aiFoundryHub 'br/public:avm/res/machine-learning-services/workspace:0.10.0' = {
  name: 'ai-foundry-hub-deployment'
  params: {
    name: aiFoundryHubName
    location: location
    tags: tags
    // Hub configuration
    kind: 'Hub'
    sku: 'Basic'
    // Enable system-assigned managed identity
    managedIdentities: {
      systemAssigned: true
    }
    // Associated resources for the hub
    associatedStorageAccountResourceId: storageAccount.outputs.resourceId
    associatedKeyVaultResourceId: keyVault.outputs.resourceId
    associatedApplicationInsightsResourceId: applicationInsights.outputs.resourceId
    // Public network access settings
    publicNetworkAccess: 'Enabled' // TODO: Restrict after VNet/Private Endpoint setup
    // Workspace settings
    description: 'AI Foundry Hub for md-decision-maker LLM Document Generation'
    // Container registry association for custom environments
    associatedContainerRegistryResourceId: containerRegistry.outputs.resourceId
    // High business impact workspace for compliance
    hbiWorkspace: environment == 'prod' ? true : false
    // Diagnostic settings
    diagnosticSettings: [
      {
        name: 'ai-hub-diagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
        logCategoriesAndGroups: [
          {
            category: 'AmlComputeClusterEvent'
            enabled: true
          }
          {
            category: 'AmlComputeClusterNodeEvent'
            enabled: true
          }
          {
            category: 'AmlComputeJobEvent'
            enabled: true
          }
          {
            category: 'AmlComputeCpuGpuUtilization'
            enabled: true
          }
          {
            category: 'AmlRunStatusChangedEvent'
            enabled: true
          }
          {
            category: 'ModelsChangeEvent'
            enabled: true
          }
          {
            category: 'ModelsReadEvent'
            enabled: true
          }
          {
            category: 'ModelsActionEvent'
            enabled: true
          }
          {
            category: 'DeploymentReadEvent'
            enabled: true
          }
          {
            category: 'DeploymentEventACI'
            enabled: true
          }
          {
            category: 'DeploymentEventAKS'
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
  }
}

// ========== AI Foundry Project ==========
module aiFoundryProject 'br/public:avm/res/machine-learning-services/workspace:0.10.0' = {
  name: 'ai-foundry-project-deployment'
  params: {
    name: aiFoundryProjectName
    location: location
    tags: tags
    // Project configuration
    kind: 'Project'
    sku: 'Basic'
    // Enable system-assigned managed identity
    managedIdentities: {
      systemAssigned: true
    }
    // Link to the hub workspace
    hubResourceId: aiFoundryHub.outputs.resourceId
    // Public network access settings - inherits from hub
    publicNetworkAccess: 'Enabled' // TODO: Restrict after VNet/Private Endpoint setup
    // Project settings
    description: 'AI Foundry Project for md-decision-maker document generation'
    // High business impact workspace for compliance (inherit from hub)
    hbiWorkspace: environment == 'prod' ? true : false
    // Diagnostic settings
    diagnosticSettings: [
      {
        name: 'ai-project-diagnostics'
        workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
        logCategoriesAndGroups: [
          {
            category: 'AmlComputeClusterEvent'
            enabled: true
          }
          {
            category: 'AmlComputeClusterNodeEvent'
            enabled: true
          }
          {
            category: 'AmlComputeJobEvent'
            enabled: true
          }
          {
            category: 'AmlComputeCpuGpuUtilization'
            enabled: true
          }
          {
            category: 'AmlRunStatusChangedEvent'
            enabled: true
          }
          {
            category: 'ModelsChangeEvent'
            enabled: true
          }
          {
            category: 'ModelsReadEvent'
            enabled: true
          }
          {
            category: 'ModelsActionEvent'
            enabled: true
          }
          {
            category: 'DeploymentReadEvent'
            enabled: true
          }
          {
            category: 'DeploymentEventACI'
            enabled: true
          }
          {
            category: 'DeploymentEventAKS'
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
  }
}

// ========== RBAC Role Definitions ==========
module rbacRoles './modules/rbac.bicep' = {
  name: 'rbac-roles'
}

// ========== RBAC Assignments ==========
// Backend App Service RBAC assignments
// Grant access to Key Vault secrets
module backendKeyVaultAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'backend-keyvault-rbac'
  params: {
    resourceId: keyVault.outputs.resourceId
    principalId: backendApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      rbacRoles.outputs.keyVaultSecretsUser
    )
    principalType: 'ServicePrincipal'
    description: 'Allow backend app to read secrets from Key Vault'
  }
}

// Grant access to Storage Account blobs
module backendStorageAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'backend-storage-rbac'
  params: {
    resourceId: storageAccount.outputs.resourceId
    principalId: backendApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      rbacRoles.outputs.storageBlobDataContributor
    )
    principalType: 'ServicePrincipal'
    description: 'Allow backend app to read/write blobs in Storage Account'
  }
}

// Grant access to pull images from Container Registry
module backendAcrAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'backend-acr-rbac'
  params: {
    resourceId: containerRegistry.outputs.resourceId
    principalId: backendApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbacRoles.outputs.acrPull)
    principalType: 'ServicePrincipal'
    description: 'Allow backend app to pull images from Container Registry'
  }
}

// Grant access to Application Insights for metrics publishing
module backendAppInsightsAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'backend-appinsights-rbac'
  params: {
    resourceId: applicationInsights.outputs.resourceId
    principalId: backendApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      rbacRoles.outputs.monitoringMetricsPublisher
    )
    principalType: 'ServicePrincipal'
    description: 'Allow backend app to publish metrics to Application Insights'
  }
}

// Frontend App Service RBAC assignments
// Grant access to pull images from Container Registry
module frontendAcrAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'frontend-acr-rbac'
  params: {
    resourceId: containerRegistry.outputs.resourceId
    principalId: frontendApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbacRoles.outputs.acrPull)
    principalType: 'ServicePrincipal'
    description: 'Allow frontend app to pull images from Container Registry'
  }
}

// Grant access to Application Insights for metrics publishing
module frontendAppInsightsAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'frontend-appinsights-rbac'
  params: {
    resourceId: applicationInsights.outputs.resourceId
    principalId: frontendApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      rbacRoles.outputs.monitoringMetricsPublisher
    )
    principalType: 'ServicePrincipal'
    description: 'Allow frontend app to publish metrics to Application Insights'
  }
}

// AI Foundry Hub RBAC assignments
// Grant access to Key Vault for storing model keys
module aiHubKeyVaultAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'aihub-keyvault-rbac'
  params: {
    resourceId: keyVault.outputs.resourceId
    principalId: aiFoundryHub.outputs.systemAssignedMIPrincipalId ?? ''
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      rbacRoles.outputs.keyVaultSecretsOfficer
    )
    principalType: 'ServicePrincipal'
    description: 'Allow AI Hub to manage secrets in Key Vault'
  }
}

// Grant access to Storage Account for model artifacts
module aiHubStorageAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'aihub-storage-rbac'
  params: {
    resourceId: storageAccount.outputs.resourceId
    principalId: aiFoundryHub.outputs.systemAssignedMIPrincipalId ?? ''
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      rbacRoles.outputs.storageBlobDataContributor
    )
    principalType: 'ServicePrincipal'
    description: 'Allow AI Hub to read/write model artifacts in Storage Account'
  }
}

// Grant access to Container Registry for custom environments
module aiHubAcrAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'aihub-acr-rbac'
  params: {
    resourceId: containerRegistry.outputs.resourceId
    principalId: aiFoundryHub.outputs.systemAssignedMIPrincipalId ?? ''
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbacRoles.outputs.acrPush)
    principalType: 'ServicePrincipal'
    description: 'Allow AI Hub to push/pull custom environment images'
  }
}

// AI Foundry Project RBAC assignments
// Grant access to Key Vault for model keys
module aiProjectKeyVaultAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'aiproject-keyvault-rbac'
  params: {
    resourceId: keyVault.outputs.resourceId
    principalId: aiFoundryProject.outputs.systemAssignedMIPrincipalId ?? ''
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      rbacRoles.outputs.keyVaultSecretsUser
    )
    principalType: 'ServicePrincipal'
    description: 'Allow AI Project to read secrets from Key Vault'
  }
}

// Grant backend app access to AI Foundry resources
module backendAIHubAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'backend-aihub-rbac'
  params: {
    resourceId: aiFoundryHub.outputs.resourceId
    principalId: backendApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      rbacRoles.outputs.azureMLDataScientist
    )
    principalType: 'ServicePrincipal'
    description: 'Allow backend app to use AI models from AI Hub'
  }
}

module backendAIProjectAccess 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: 'backend-aiproject-rbac'
  params: {
    resourceId: aiFoundryProject.outputs.resourceId
    principalId: backendApp.outputs.systemAssignedMIPrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      rbacRoles.outputs.cognitiveServicesOpenAIUser
    )
    principalType: 'ServicePrincipal'
    description: 'Allow backend app to use OpenAI models from AI Project'
  }
}

// ========== Outputs ==========
output appServicePlanId string = appServicePlan.outputs.resourceId
output appServicePlanName string = appServicePlan.outputs.name

output frontendAppId string = frontendApp.outputs.resourceId
output frontendAppName string = frontendApp.outputs.name
output frontendUrl string = 'https://${frontendApp.outputs.defaultHostname}'
output frontendManagedIdentityPrincipalId string = frontendApp.outputs.systemAssignedMIPrincipalId

output backendAppId string = backendApp.outputs.resourceId
output backendAppName string = backendApp.outputs.name
output backendUrl string = 'https://${backendApp.outputs.defaultHostname}'
output backendManagedIdentityPrincipalId string = backendApp.outputs.systemAssignedMIPrincipalId

output containerRegistryId string = containerRegistry.outputs.resourceId
output containerRegistryName string = containerRegistry.outputs.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerRegistryManagedIdentityPrincipalId string = containerRegistry.outputs.systemAssignedMIPrincipalId

output keyVaultId string = keyVault.outputs.resourceId
output keyVaultName string = keyVault.outputs.name
output keyVaultUri string = keyVault.outputs.uri

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.outputs.resourceId
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.name

output applicationInsightsId string = applicationInsights.outputs.resourceId
output applicationInsightsName string = applicationInsights.outputs.name
output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString
output applicationInsightsInstrumentationKey string = applicationInsights.outputs.instrumentationKey

output storageAccountId string = storageAccount.outputs.resourceId
output storageAccountName string = storageAccount.outputs.name
output storageAccountPrimaryBlobEndpoint string = storageAccount.outputs.primaryBlobEndpoint

output aiFoundryHubId string = aiFoundryHub.outputs.resourceId
output aiFoundryHubName string = aiFoundryHub.outputs.name
output aiFoundryProjectId string = aiFoundryProject.outputs.resourceId
output aiFoundryProjectName string = aiFoundryProject.outputs.name
