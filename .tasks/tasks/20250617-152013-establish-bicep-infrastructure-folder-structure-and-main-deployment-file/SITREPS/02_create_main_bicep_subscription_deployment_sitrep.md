# SITREP: Create main.bicep with Subscription-Scoped Deployment and Resource Group

**Date:** 2025-06-17  
**Task ID:** T-02  
**Status:** Complete  

## Summary of Actions Taken

Successfully created and validated the main.bicep file with subscription-scoped deployment that serves as the entry point for the Azure infrastructure deployment. The file follows Azure Verified Modules (AVM) best practices and Cloud Adoption Framework (CAF) naming conventions.

## Technical Implementation Details

### 1. Main.bicep Structure
- **Target Scope:** Set to 'subscription' level deployment
- **Parameters:**
  - `environment`: Allowed values 'dev' or 'prod'
  - `location`: Azure region with default 'eastus'
  - `projectName`: Project identifier with default 'mdm'
  - `tags`: Optional custom tags object
  - `deploymentDate`: Auto-generated deployment date using utcNow()

### 2. Resource Group Configuration
- **Naming Convention:** `rg-{projectName}-{environment}-{location}`
- **AVM Module:** Using `br/public:avm/res/resources/resource-group:0.4.1`
- **Module Name:** `rg-deployment` (simplified from uniqueString pattern)
- **Tags:** Merged default tags with custom tags including:
  - Environment
  - Project: 'md-decision-maker'
  - ManagedBy: 'Bicep'
  - DeploymentDate: Auto-generated

### 3. File Modifications Made

#### Fixed Issues:
1. **utcNow() Function Error:** Moved utcNow() to parameter default value as required by Bicep
2. **Unused Variable Warning:** Removed unused `abbrs` variable
3. **Parameter File Path:** Updated main.dev.bicepparam to use correct relative path `../main.bicep`

#### Outputs Configured:
- `resourceGroupName`: Name of the created resource group
- `resourceGroupId`: Resource ID of the created resource group
- `location`: Deployment location
- `environment`: Environment name
- `tags`: Complete set of applied tags

### 4. Validation Results
- **Bicep Build:** ✅ Successful (no errors)
- **Bicep Lint:** ✅ Successful (no warnings)
- **Syntax Validation:** ✅ All AVM module references valid

## Code Changes

### Main.bicep Final Version:
```bicep
targetScope = 'subscription'

// Parameters section with proper descriptions and constraints
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

// Variables for resource naming and tagging
var resourceGroupName = 'rg-${projectName}-${environment}-${location}'
var defaultTags = {
  Environment: environment
  Project: 'md-decision-maker'
  ManagedBy: 'Bicep'
  DeploymentDate: deploymentDate
}
var allTags = union(defaultTags, tags)

// Resource Group module deployment
module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.1' = {
  name: 'rg-deployment'
  params: {
    name: resourceGroupName
    location: location
    tags: allTags
  }
}

// Outputs for downstream consumption
output resourceGroupName string = resourceGroup.outputs.name
output resourceGroupId string = resourceGroup.outputs.resourceId
output location string = location
output environment string = environment
output tags object = allTags
```

## Expected Outcomes

1. **Deployment Ready:** main.bicep can now be deployed to create the resource group
2. **Foundation Set:** Subscription-scoped deployment pattern established for all resources
3. **Standards Compliance:** Following AVM best practices and CAF naming conventions
4. **Extensible Design:** Structure ready for resources.bicep module in future tasks

## Next Steps

1. **Task T-03:** Add AVM modules for App Services (frontend and backend)
2. **Create resources.bicep:** New file to contain all resource deployments within the resource group
3. **Module Integration:** Uncomment and configure the resources module reference in main.bicep
4. **Testing:** Validate deployment with `az deployment sub what-if` command

## Files Modified
- `/infra/main.bicep` - Created and configured subscription-scoped deployment
- `/infra/environments/main.dev.bicepparam` - Updated relative path reference

## Dependencies
- Azure Bicep CLI installed and up-to-date
- Access to Azure Verified Modules public registry
- Azure subscription with appropriate permissions

## Notes
- The resources.bicep module reference is commented out until created in subsequent tasks
- All future resource deployments will be scoped to the resource group created by this file
- The deployment uses the latest stable version of AVM resource group module (0.4.1)
