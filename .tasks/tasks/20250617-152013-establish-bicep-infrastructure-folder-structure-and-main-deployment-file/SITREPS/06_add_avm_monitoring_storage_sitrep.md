# SITREP: Add AVM Modules for Application Insights and Storage Account

**Task ID:** T-06  
**Date:** 2025-06-17  
**Status:** Complete  

## Summary

Successfully added Azure Verified Modules (AVM) for observability and storage infrastructure:
- Log Analytics Workspace for centralized logging and monitoring
- Application Insights for application performance monitoring with OpenTelemetry support
- Storage Account with blob containers for document and temporary file storage

## Actions Taken

### 1. Added Log Analytics Workspace Module
- Used AVM module `br/public:avm/res/operational-insights/workspace:0.9.1`
- Configured retention periods based on environment (90 days for prod, 30 days for dev)
- Set daily quota caps to control costs (50 GB for prod, 10 GB for dev)
- Enabled system-assigned managed identity for future integrations
- Enabled public network access (to be restricted later with Private Endpoints)

### 2. Added Application Insights Module
- Used AVM module `br/public:avm/res/insights/component:0.4.1`
- Configured in workspace-based mode for unified observability
- Linked to Log Analytics workspace for centralized data storage
- Set as 'web' application type for proper categorization
- Configured 100% sampling rate (can be adjusted for cost optimization)
- Disabled IP masking per Azure Application Insights handbook

### 3. Added Storage Account Module
- Used AVM module `br/public:avm/res/storage/storage-account:0.14.3`
- Configured with Standard_LRS SKU for cost optimization
- Created two blob containers:
  - `documents` - For LLM document storage
  - `temp-uploads` - For temporary upload storage
- Implemented lifecycle management policies:
  - Delete temp uploads after 7 days
  - Move documents to cool tier after 30 days
- Enabled soft delete for blob recovery (7 days retention)
- Configured comprehensive diagnostic settings to Log Analytics
- Enabled system-assigned managed identity for future RBAC assignments

### 4. Updated Container Registry and Key Vault
- Added diagnostic settings to Container Registry for repository and login events
- Added diagnostic settings to Key Vault for audit events and policy evaluation
- Both now send logs and metrics to the Log Analytics workspace

### 5. Updated App Services Configuration
- Backend App Service:
  - Added Application Insights connection string
  - Added OpenTelemetry resource attributes for proper service identification
  - Added Azure Storage connection string for blob access
- Frontend App Service:
  - Added Application Insights connection string for client-side monitoring

### 6. Updated Module Outputs
- Added outputs for all new resources in resources.bicep
- Updated main.bicep to expose the new outputs at subscription level
- Outputs include resource IDs, names, and connection strings

## Technical Details

### Implementation Approach
- Followed Azure Verified Modules best practices
- Used workspace-based Application Insights as recommended in the handbook
- Configured diagnostic settings for all resources per monitoring best practices
- Implemented cost control measures (quotas, sampling, lifecycle policies)
- Prepared for future security enhancements (Private Endpoints, RBAC)

### Code Changes
1. **resources.bicep**:
   - Added variable definitions for new resource names
   - Added Log Analytics Workspace module deployment
   - Added Application Insights module deployment  
   - Added Storage Account module with blob containers and lifecycle rules
   - Updated Container Registry and Key Vault with diagnostic settings
   - Updated App Services with monitoring configuration
   - Added comprehensive outputs for all new resources

2. **main.bicep**:
   - Added outputs for monitoring and storage resources
   - Maintained proper output organization by category

### Validation Results
- ✅ `az bicep build --file main.bicep` - Success, no errors
- ✅ `az bicep lint --file main.bicep` - Success, no warnings
- ✅ `az bicep format --file main.bicep` - Applied formatting standards
- ✅ `az bicep format --file resources.bicep` - Applied formatting standards

## Expected Outcomes

1. **Monitoring Infrastructure**: Complete observability stack ready for deployment with Log Analytics and Application Insights
2. **Storage Infrastructure**: Blob storage configured with proper lifecycle management and security settings
3. **Cost Control**: Daily quotas, sampling rates, and lifecycle policies in place
4. **Security Preparation**: Diagnostic logging enabled for all resources, ready for RBAC configuration
5. **Integration Ready**: App Services configured with connection strings for monitoring and storage

## Next Steps

- **T-07**: Add AVM modules for AI Foundry Hub and Project
- **T-08**: Configure RBAC assignments for all managed identities
- **T-09**: Create environment parameter files
- **T-10**: Add bicepconfig.json with module aliases and PSRule configuration (already completed)
- **T-11**: Create comprehensive README.md with deployment guide
- **T-12**: Validate with bicep build, linting, and what-if deployment

## Notes

- All resources follow Cloud Adoption Framework (CAF) naming conventions
- Diagnostic settings are comprehensive and follow Azure monitoring best practices
- The infrastructure is designed for future enhancements (VNet integration, Private Endpoints)
- Cost optimization measures are built-in but can be adjusted based on actual usage patterns
