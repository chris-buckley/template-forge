# SITREP: Add AVM Modules for App Services (Frontend and Backend)

**Task ID:** T-03
**Completed Date:** 2025-06-17
**Status:** Complete

## Summary of Actions Taken

Successfully added Azure Verified Modules (AVM) for App Services to support both frontend and backend deployments. Created a new `resources.bicep` file to organize resource deployments at the resource group scope, and updated `main.bicep` to reference this module.

## Technical Implementation Details

### 1. Created resources.bicep
- Added resource group scoped bicep file to contain all resource deployments
- Implemented App Service Plan using AVM module `br/public:avm/res/web/serverfarm:0.3.0`
- Configured Linux App Service Plan with P1v3 SKU
- Set capacity to 1 instance for dev and 2 instances for prod

### 2. App Services Configuration
- Added two App Service instances using AVM module `br/public:avm/res/web/site:0.10.0`
  - **Backend App Service (`app-mdm-be-{env}`)**:
    - Configured for Linux container deployment
    - Set WEBSITES_PORT to 8000
    - Enabled health check on `/health` endpoint
    - Configured CORS to allow frontend origin
    - Enabled system-assigned managed identity
  - **Frontend App Service (`app-mdm-fe-{env}`)**:
    - Configured for Linux container deployment
    - Set WEBSITES_PORT to 3000
    - Set REACT_APP_API_URL to backend URL
    - Enabled health check on `/` endpoint
    - Enabled system-assigned managed identity

### 3. Security Configuration
- Both App Services configured with:
  - HTTPS-only enforcement
  - Minimum TLS version 1.2
  - FTP disabled
  - Always On enabled
  - HTTP/2 enabled
  - System-assigned managed identities for future RBAC assignments

### 4. Updated main.bicep
- Uncommented resources module reference
- Fixed scope configuration to use `az.resourceGroup()` for subscription-scoped deployment
- Added outputs for App Service URLs and names
- Added dependency on resource group module

## Code Changes and File Modifications

### Files Modified:
1. **infra/main.bicep**
   - Enabled resources module deployment
   - Added App Service outputs
   - Fixed resource group scope reference

2. **infra/resources.bicep** (new file)
   - Complete implementation of App Service Plan and App Services
   - Proper parameter handling and variable definitions
   - Comprehensive outputs for downstream consumption

### Validation Results:
- `az bicep build --file main.bicep`: ✓ Success
- `az bicep lint --file main.bicep`: ✓ No warnings or errors
- `az bicep lint --file resources.bicep`: ✓ No warnings or errors

## Expected Outcomes

1. **Infrastructure Ready**: App Service infrastructure can now be deployed with proper configuration
2. **Security Baseline**: HTTPS-only, TLS 1.2+, and managed identities configured
3. **Environment Separation**: Different SKU capacities for dev vs prod environments
4. **CORS Configuration**: Backend properly configured to accept requests from frontend
5. **Container Ready**: Both services configured for Docker container deployment

## Next Steps

Based on the plan, the following tasks should be completed next:
- **T-04**: Add AVM module for Container Registry with Premium SKU
- **T-05**: Add AVM module for Key Vault with RBAC and diagnostic settings
- **T-06**: Add AVM modules for Application Insights and Storage Account
- **T-07**: Add AVM modules for AI Foundry Hub and Project

The App Services will need the Container Registry (T-04) for pulling Docker images and Key Vault (T-05) for secure configuration management. These should be prioritized next.

## Notes

- Currently using placeholder Docker images (`mcr.microsoft.com/appsvc/node:18-lts`) which will be replaced with actual application images from Container Registry in future deployments
- CORS is configured to allow localhost:3000 in dev environment for local development testing
- Managed identity principal IDs are exposed as outputs for future RBAC assignments in T-08
