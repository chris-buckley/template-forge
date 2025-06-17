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
// Resources will be deployed in future tasks (T-03 to T-08)
// This module reference is commented out until resources.bicep is created
/*
module resources './resources.bicep' = {
  name: 'resources-deployment'
  scope: az.resourceGroup(resourceGroup.outputs.name)
  params: {
    environment: environment
    location: location
    projectName: projectName
    tags: allTags
  }
}
*/

// ========== Outputs ==========
output resourceGroupName string = resourceGroup.outputs.name
output resourceGroupId string = resourceGroup.outputs.resourceId
output location string = location
output environment string = environment
output tags object = allTags

// Future outputs will be added as resources are deployed
// output keyVaultName string = resources.outputs.keyVaultName
// output appServiceFrontendUrl string = resources.outputs.frontendUrl
// output appServiceBackendUrl string = resources.outputs.backendUrl
