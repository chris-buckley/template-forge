# SITREP: Add AVM Modules for AI Foundry Hub and Project

**Task ID:** T-07  
**Status:** Complete  
**Date:** 2025-06-17  

## Summary

Successfully added Azure Verified Modules (AVM) for AI Foundry Hub and AI Foundry Project to the Bicep infrastructure. These modules enable the deployment of Azure AI Foundry resources required for the LLM Document Generation PoC.

## Actions Taken

### 1. Added AI Foundry Resource Naming Variables
- Added `aiFoundryHubName` variable following CAF naming convention: `${abbrs.machineLearningWorkspace}-hub-${projectName}-${environment}`
- Added `aiFoundryProjectName` variable following CAF naming convention: `${abbrs.machineLearningWorkspace}-proj-${projectName}-${environment}`

### 2. Implemented AI Foundry Hub Module
- Used AVM module: `br/public:avm/res/machine-learning-services/workspace:0.10.0`
- Configured as Hub with `kind: 'Hub'`
- Enabled system-assigned managed identity
- Associated with existing resources:
  - Storage Account for artifact storage
  - Key Vault for secrets management
  - Application Insights for monitoring
  - Container Registry for custom environments
- Set up comprehensive diagnostic settings for all AI-related events
- Configured High Business Impact (HBI) workspace for production environment

### 3. Implemented AI Foundry Project Module
- Used same AVM module with `kind: 'Project'`
- Linked to the Hub via `hubResourceId` parameter
- Enabled system-assigned managed identity
- Configured identical diagnostic settings as the Hub
- Inherits HBI setting from Hub for compliance

### 4. Updated Backend App Service Configuration
- Added environment variables for AI Foundry integration:
  - `AZURE_FOUNDRY_ENDPOINT`: Placeholder for Azure OpenAI endpoint (to be configured post-deployment)
  - `AZURE_FOUNDRY_OPENAI_DEPLOYMENT`: Model deployment name (`gpt-4o-${environment}`)
  - `AZURE_AI_HUB_NAME`: Reference to deployed Hub name
  - `AZURE_AI_PROJECT_NAME`: Reference to deployed Project name

### 5. Added Resource Outputs
- Updated resources.bicep outputs:
  - `aiFoundryHubId`
  - `aiFoundryHubName`
  - `aiFoundryProjectId`
  - `aiFoundryProjectName`
- Updated main.bicep to expose AI Foundry outputs at subscription level

### 6. Resolved Bicep Validation Issues
- Removed unsupported `v1LegacyMode` property
- Removed unsupported `friendlyName`/`workspaceFriendlyName` properties
- Removed unnecessary `dependsOn` that was causing linter warning

## Technical Details

### Module Configuration
```bicep
// AI Foundry Hub
module aiFoundryHub 'br/public:avm/res/machine-learning-services/workspace:0.10.0' = {
  name: 'ai-foundry-hub-deployment'
  params: {
    name: aiFoundryHubName
    location: location
    tags: tags
    kind: 'Hub'
    sku: 'Basic'
    managedIdentities: {
      systemAssigned: true
    }
    // Associated resources
    associatedStorageAccountResourceId: storageAccount.outputs.resourceId
    associatedKeyVaultResourceId: keyVault.outputs.resourceId
    associatedApplicationInsightsResourceId: applicationInsights.outputs.resourceId
    associatedContainerRegistryResourceId: containerRegistry.outputs.resourceId
    // ... diagnostic settings
  }
}
```

### Diagnostic Categories Configured
- AmlComputeClusterEvent
- AmlComputeClusterNodeEvent
- AmlComputeJobEvent
- AmlComputeCpuGpuUtilization
- AmlRunStatusChangedEvent
- ModelsChangeEvent
- ModelsReadEvent
- ModelsActionEvent
- DeploymentReadEvent
- DeploymentEventACI
- DeploymentEventAKS

## Validation Results

- ✅ `az bicep build --file main.bicep`: Success (no errors)
- ✅ `az bicep lint --file main.bicep`: Success (no warnings)
- ✅ `az bicep format --file main.bicep`: Completed
- ✅ `az bicep format --file resources.bicep`: Completed

## Expected Outcomes

1. **Hub Deployment**: Creates an AI Foundry Hub that serves as the central governance point for AI resources
2. **Project Deployment**: Creates an AI Foundry Project linked to the Hub for actual model deployments
3. **Integration Ready**: Backend application has necessary configuration to connect to AI services
4. **Monitoring Enabled**: Comprehensive diagnostic logging for all AI operations

## Next Steps

1. After deployment, the actual Azure OpenAI endpoint needs to be configured
2. Model deployments (e.g., GPT-4o) need to be created within the AI Foundry Project
3. API keys or managed identity access needs to be configured for the backend application
4. The `AZURE_FOUNDRY_ENDPOINT` placeholder in the backend configuration needs to be updated with the actual endpoint

## Notes

- The AI Foundry resources use Basic SKU which is appropriate for the PoC
- Public network access is enabled but marked with TODO for future VNet/Private Endpoint configuration
- The modules are configured to support both development and production environments with appropriate settings
- High Business Impact (HBI) workspace is enabled for production to ensure compliance requirements are met