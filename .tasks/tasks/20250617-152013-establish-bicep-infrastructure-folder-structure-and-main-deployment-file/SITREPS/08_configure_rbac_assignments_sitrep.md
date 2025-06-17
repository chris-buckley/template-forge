# SITREP: Configure RBAC Assignments for All Managed Identities

**Task ID:** T-08  
**Status:** Complete  
**Date:** 2025-06-17  

## Summary

Successfully configured comprehensive RBAC assignments for all managed identities in the infrastructure. Created a centralized RBAC module to manage role definition IDs and implemented role assignments for all services requiring access to other resources.

## Actions Taken

### 1. Created RBAC Role Definitions Module
- Created `/infra/modules/rbac.bicep` to centralize Azure built-in role definition IDs
- Included role definitions for:
  - Key Vault roles (Secrets User, Secrets Officer, Crypto User)
  - Storage roles (Blob Data Contributor, Blob Data Reader, Account Contributor)
  - Container Registry roles (ACR Pull, ACR Push, ACR Delete)
  - Application Insights roles (Monitoring Metrics Publisher, Monitoring Reader)
  - Azure Machine Learning roles (Data Scientist, Workspace Contributor)
  - Cognitive Services roles (User, OpenAI User)
  - General roles (Contributor, Reader)

### 2. Implemented RBAC Assignments in resources.bicep

#### Backend App Service RBAC Assignments:
- **Key Vault Secrets User**: Read secrets for API keys and configuration
- **Storage Blob Data Contributor**: Read/write documents and temporary uploads
- **ACR Pull**: Pull backend container images during deployment
- **Monitoring Metrics Publisher**: Publish telemetry to Application Insights
- **Azure ML Data Scientist**: Access AI models from AI Foundry Hub
- **Cognitive Services OpenAI User**: Use OpenAI models from AI Project

#### Frontend App Service RBAC Assignments:
- **ACR Pull**: Pull frontend container images during deployment
- **Monitoring Metrics Publisher**: Publish telemetry to Application Insights

#### AI Foundry Hub RBAC Assignments:
- **Key Vault Secrets Officer**: Manage secrets for model deployments
- **Storage Blob Data Contributor**: Store model artifacts and datasets
- **ACR Push**: Push/pull custom ML environment images

#### AI Foundry Project RBAC Assignments:
- **Key Vault Secrets User**: Read secrets for model connections

### 3. Technical Implementation Details

- Used AVM authorization module `br/public:avm/ptn/authorization/resource-role-assignment:0.1.1`
- Implemented null coalescing operators (`??`) for AI resource principal IDs to handle potential null values
- All role assignments include descriptive comments explaining their purpose
- Role definition IDs are properly scoped using `subscriptionResourceId()`
- Principal type is set to 'ServicePrincipal' for all managed identities

### 4. Security Considerations

- Followed principle of least privilege - only granted necessary permissions
- Used RBAC instead of access policies for Key Vault (best practice)
- Backend app has comprehensive permissions for its operational needs
- Frontend app has minimal permissions (only ACR pull and monitoring)
- AI resources have appropriate permissions for model management

## File Modifications

1. **Created**: `/infra/modules/rbac.bicep`
   - Centralized role definition management
   - Exportable role IDs for consistent usage

2. **Modified**: `/infra/resources.bicep`
   - Added RBAC role definitions module reference
   - Added 13 RBAC assignment modules
   - Handled nullable principal IDs for AI resources

## Validation Results

- ✅ Bicep build successful with only minor linter warnings
- ✅ Bicep lint passed with safe access operator suggestions
- ✅ Bicep format applied successfully
- ✅ All RBAC assignments properly configured

## Expected Outcomes

1. **Immediate Benefits**:
   - App Services can authenticate with managed identities instead of connection strings
   - Secure access to Key Vault secrets without hardcoded credentials
   - Container images can be pulled without registry credentials
   - AI resources properly integrated with storage and registry

2. **Security Improvements**:
   - Zero hardcoded credentials in application configurations
   - Auditable access patterns through Azure AD
   - Automatic credential rotation handled by Azure
   - Compliance with zero-trust security model

## Next Steps

1. **T-09**: Create environment parameter files (main.dev.bicepparam, main.prod.bicepparam)
2. **T-10**: Add bicepconfig.json with module aliases and PSRule configuration
3. **T-11**: Create comprehensive README.md with deployment guide
4. **T-12**: Validate with bicep build, linting, and what-if deployment

## Notes

- The safe access operator warnings are non-critical and relate to the AI resource outputs potentially being null
- All RBAC assignments will take effect upon actual deployment to Azure
- Additional RBAC assignments may be needed after network security (VNet/Private Endpoints) implementation
