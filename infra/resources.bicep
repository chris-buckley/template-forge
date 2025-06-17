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

// Define SKU based on environment
var appServicePlanSkuName = 'P1v3'
var appServicePlanSkuCapacity = environment == 'prod' ? 2 : 1

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
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/node:18-lts' // Placeholder image
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '8000'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
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
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/node:18-lts' // Placeholder image
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
