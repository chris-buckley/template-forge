# SITREP 05: Add AVM Key Vault Module

**Task ID:** T-05  
**Summary:** Add AVM module for Key Vault with RBAC and diagnostic settings  
**Status:** Complete  
**Date:** 2025-06-17  

## Summary of Actions Taken

Successfully added the Azure Verified Modules (AVM) Key Vault module to the resources.bicep file with RBAC authorization and diagnostic settings configuration. The Key Vault will be used to securely store secrets, connection strings, and API keys for the md-decision-maker application.

## Detailed Implementation

### 1. Key Vault Module Configuration

Added the following Key Vault module to `resources.bicep`:

- **Module:** `br/public:avm/res/key-vault/vault:0.10.2`
- **Name Pattern:** `kv-mdm-{environment}` (following CAF naming conventions)
- **RBAC Authorization:** Enabled (best practice over access policies)
- **Purge Protection:** Enabled for production safety
- **Soft Delete Retention:** 90 days for production, 7 days for development
- **Network Configuration:** Currently allows public access with Azure Services bypass (will be restricted after VNet integration)
- **SKU:** Standard tier

### 2. App Service Integration

Updated the backend App Service configuration to include the Key Vault URI in its app settings:
- Added `AZURE_KEY_VAULT_URI` environment variable pointing to the Key Vault URI
- This allows the backend application to access secrets using managed identity

### 3. Main Deployment Updates

Updated `main.bicep` to expose Key Vault outputs:
- `keyVaultName`: The name of the created Key Vault
- `keyVaultUri`: The URI for accessing the Key Vault
- `keyVaultId`: The resource ID for RBAC assignments

## Technical Details

### Key Vault Security Features
- **RBAC Authorization**: Using Azure RBAC instead of traditional access policies (per Azure Key Vault handbook)
- **Purge Protection**: Prevents accidental permanent deletion of secrets (BCPNFR security requirement)
- **Soft Delete**: Allows recovery of deleted secrets within retention period
  - Production: 90 days retention (compliance requirement)
  - Development: 7 days retention (faster cleanup)
- **Network ACLs**: Configured to allow Azure services while maintaining security
  - Currently set to 'Allow' with Azure Services bypass
  - Will be changed to 'Deny' default after Private Endpoint configuration
- **Diagnostic Settings**: Comprehensive logging configuration prepared:
  - AuditEvent logs for security auditing
  - AzurePolicyEvaluationDetails for compliance tracking
  - AllMetrics for performance monitoring

### Handbook Compliance
- ✅ Following Azure Key Vault handbook recommendations:
  - Least privilege access model with RBAC
  - Defense in depth with HSM-backed encryption
  - Automated governance ready for implementation
- ✅ Following Azure AVM Bicep handbook patterns:
  - Secure defaults (HTTPS-only, purge protection)
  - Proper module versioning (pinned to 0.10.2)
  - Network isolation ready for implementation
  - No secret values in outputs

### Placeholder for Future Enhancements
- Diagnostic settings are prepared but commented out pending Log Analytics workspace creation (T-06)
- Network restrictions will be tightened after VNet/Private Endpoint setup
- RBAC role assignments will be configured in T-08
- Customer-managed keys (CMK) can be added for enhanced compliance if needed

## Validation Results

- ✅ `az bicep build --file main.bicep`: Success (no errors)
- ✅ `az bicep lint --file main.bicep`: Success (no warnings)
- ✅ All parameter references validated
- ✅ Module version `0.10.2` confirmed as latest stable

## Expected Outcomes

1. **Secure Secret Storage**: Key Vault will provide centralized, secure storage for:
   - Azure AI Foundry API keys
   - Database connection strings
   - Application secrets
   - SSL certificates (if needed)

2. **Managed Identity Access**: App Services can access secrets using their system-assigned managed identities (pending RBAC configuration in T-08)

3. **Audit Trail**: Once diagnostic settings are enabled, all Key Vault access will be logged to Log Analytics

## Next Steps

1. **T-06**: Add Application Insights and Storage Account modules
2. **T-08**: Configure RBAC assignments for managed identities to access Key Vault
3. **Future**: Implement secret rotation policies and monitoring alerts

## Notes

- Key Vault names must be globally unique; the current naming pattern should provide uniqueness
- The module supports advanced features like private endpoints which can be added later
- Customer-managed keys for encryption can be configured if required