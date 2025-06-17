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
var containerRegistryName = toLower(replace('${abbrs.containerRegistry}${projectName}${environment}${substring(location, 0, 3)}', '-', ''))

// Define SKU based on environment
var appServicePlanSkuName = 'P1v3'
var appServicePlanSkuCapacity = environment == 'prod' ? 2 : 1

// Container Registry configuration
var containerRegistrySkuName = 'Premium' // Premium SKU for vulnerability scanning

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
    replications: environment == 'prod' ? [
      {
        name: 'westus2'
        location: 'westus2'
        regionEndpointEnabled: true
        zoneRedundancy: 'Enabled'
        tags: tags
      }
    ] : []
    managedIdentities: {
      systemAssigned: true
    }
    // TODO: Add diagnosticSettings when Log Analytics workspace is available (T-06)
    // diagnosticSettings: [
    //   {
    //     workspaceResourceId: logAnalytics.outputs.resourceId
    //     categories: ['ContainerRegistryRepositoryEvents', 'ContainerRegistryLoginEvents']
    //   }
    // ]
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
