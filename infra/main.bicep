targetScope = 'subscription'

// ========== Parameters ==========
@description('The environment name (dev, prod)')
@allowed(['dev', 'prod'])
param environment string

@description('The Azure region for resource deployment')
param location string = 'eastus'

@description('The project identifier')
param projectName string = 'mdm'

@description('Optional tags to apply to all resources')
param tags object = {}

@description('Deployment date for tagging')
param deploymentDate string = utcNow('yyyy-MM-dd')

// ========== Variables ==========
var resourceGroupName = 'rg-${projectName}-${environment}-${location}'
var defaultTags = {
  Environment: environment
  Project: 'md-decision-maker'
  ManagedBy: 'Bicep'
  DeploymentDate: deploymentDate
}
var allTags = union(defaultTags, tags)

// ========== Resource Group ==========
module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'rg-deployment'
  params: {
    name: resourceGroupName
    location: location
    tags: allTags
  }
}

// ========== Resources Deployment ==========
module resources './resources.bicep' = {
  name: 'resources-deployment'
  scope: az.resourceGroup(resourceGroupName)
  params: {
    environment: environment
    location: location
    projectName: projectName
    tags: allTags
  }
  dependsOn: [
    resourceGroup
  ]
}

// ========== Outputs ==========
output resourceGroupName string = resourceGroup.outputs.name
output resourceGroupId string = resourceGroup.outputs.resourceId
output location string = location
output environment string = environment
output tags object = allTags

// App Service outputs
output appServiceFrontendUrl string = resources.outputs.frontendUrl
output appServiceBackendUrl string = resources.outputs.backendUrl
output frontendAppName string = resources.outputs.frontendAppName
output backendAppName string = resources.outputs.backendAppName

// Key Vault outputs
output keyVaultName string = resources.outputs.keyVaultName
output keyVaultUri string = resources.outputs.keyVaultUri
output keyVaultId string = resources.outputs.keyVaultId

// Container Registry outputs
output containerRegistryName string = resources.outputs.containerRegistryName
output containerRegistryLoginServer string = resources.outputs.containerRegistryLoginServer

// Monitoring outputs
output logAnalyticsWorkspaceName string = resources.outputs.logAnalyticsWorkspaceName
output applicationInsightsName string = resources.outputs.applicationInsightsName
output applicationInsightsConnectionString string = resources.outputs.applicationInsightsConnectionString

// Storage outputs
output storageAccountName string = resources.outputs.storageAccountName
output storageAccountPrimaryBlobEndpoint string = resources.outputs.storageAccountPrimaryBlobEndpoint

// AI Foundry outputs
output aiFoundryHubName string = resources.outputs.aiFoundryHubName
output aiFoundryHubId string = resources.outputs.aiFoundryHubId
output aiFoundryProjectName string = resources.outputs.aiFoundryProjectName
output aiFoundryProjectId string = resources.outputs.aiFoundryProjectId
