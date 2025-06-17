# SITREP 04: Add AVM Module for Container Registry with Premium SKU

## Summary of Actions

Successfully added the Azure Verified Modules (AVM) Container Registry module to the bicep infrastructure with Premium SKU configuration. The module is integrated with the existing App Services to support container-based deployments.

## Technical Implementation Details

### 1. Container Registry Configuration
- **Module Used**: `br/public:avm/res/container-registry/registry:0.5.1`
- **SKU**: Premium (for vulnerability scanning capabilities)
- **Security Settings**:
  - Admin user disabled (security best practice)
  - System-assigned managed identity enabled
  - Public network access enabled with Azure Services bypass

### 2. Container Registry Policies
- **Quarantine Policy**: Enabled - ensures images are scanned before use
- **Retention Policy**: Enabled with 30-day retention
- **Trust Policy**: Disabled (to be configured later if needed)
- **Soft Delete Policy**: Enabled with 7-day retention for recovery
- **Export Policy**: Disabled to prevent unauthorized image exports
- **Tag Mutability**: Controlled to ensure immutable artifacts

### 3. Variable Configuration
```bicep
var containerRegistryName = toLower(replace('${abbrs.containerRegistry}${projectName}${environment}${substring(location, 0, 3)}', '-', ''))
var containerRegistrySkuName = 'Premium' // Premium SKU for vulnerability scanning
```
- Container Registry names cannot contain hyphens, so they are removed
- Naming follows CAF standards with location suffix for uniqueness: `cr{projectName}{environment}{loc}` (e.g., `crmdmdeveas`)
- Names are forced to lowercase for consistency

### 4. App Service Integration
Updated both frontend and backend App Services to:
- Use Container Registry images: `{loginServer}/{app}:latest`
- Added `DOCKER_REGISTRY_SERVER_URL` environment variable
- Configured to pull images from the private registry

### 5. Outputs Added
```bicep
output containerRegistryId string = containerRegistry.outputs.resourceId
output containerRegistryName string = containerRegistry.outputs.name
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer
output containerRegistryManagedIdentityPrincipalId string = containerRegistry.outputs.systemAssignedMIPrincipalId
```

## Code Changes

### Modified Files:
1. **infra/resources.bicep**:
   - Added Container Registry module declaration
   - Updated App Service configurations to use ACR
   - Added necessary outputs for downstream consumption

## Validation Results

✅ **Bicep Build**: Successful - no errors or warnings
✅ **Bicep Lint**: Successful - no issues detected

## Expected Outcomes

1. **Container Registry Deployment**: When deployed, will create a Premium tier Azure Container Registry with:
   - Vulnerability scanning enabled through quarantine policy
   - Geo-replication to West US 2 for production environments
   - Zone redundancy enabled for high availability in production
   - Content trust support (configurable)
   - Managed identity for secure access
   - Soft delete protection for accidental deletion recovery
   - Immutable artifacts through export policy control

2. **App Service Integration**: App Services will be configured to:
   - Pull Docker images from the private registry
   - Use managed identities for authentication (RBAC to be configured in T-08)

3. **Security Posture**: 
   - No admin user access (using RBAC only)
   - Quarantine policy ensures only scanned images are used
   - Network isolation capabilities available

## Next Steps

1. **T-05**: Add Key Vault module with RBAC and diagnostic settings
2. **T-08**: Configure RBAC assignments for App Services to pull from Container Registry
3. **Future**: Set up CI/CD pipelines to push images to the registry

## Notes

- The Container Registry name must be globally unique across Azure
- Premium SKU chosen for enterprise features like vulnerability scanning, geo-replication, and zone redundancy
- The registry URL will be in format: `{registryName}.azurecr.io`
- Images will need to be pushed to the registry before App Services can successfully start
- Diagnostic settings will be configured in T-06 when Log Analytics workspace is available
- Following Azure Container Registry handbook best practices for security and reliability

## Dependencies

- App Services depend on Container Registry for Docker images
- RBAC assignments (T-08) required for App Services to authenticate to ACR
- Container images must be built and pushed separately (not part of infrastructure)
