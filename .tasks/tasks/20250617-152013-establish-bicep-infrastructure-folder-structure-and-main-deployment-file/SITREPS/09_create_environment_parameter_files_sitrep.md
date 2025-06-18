# SITREP: Create Environment Parameter Files

## Task ID: T-09
**Summary**: Create environment parameter files (main.dev.bicepparam, main.prod.bicepparam)

## Actions Taken

### 1. Created Production Parameter File
- Created `main.prod.bicepparam` with production-specific configurations
- Added comprehensive tags for production environment:
  - stack: 'md-decision-maker' (Required by handbook)
  - env: 'prod' (Required by handbook)
  - owner: 'Platform Team' (Required by handbook)
  - costCenter: 'Production' (Required by handbook)
  - DataClassification: Production
  - Compliance: HIPAA-Eligible
  - BackupPolicy: Tier1
  - DisasterRecovery: Enabled
  - SLA: 99.9%

### 2. Enhanced Development Parameter File
- Updated `main.dev.bicepparam` with required tags per Azure AVM Bicep handbook:
  - stack: 'md-decision-maker' (Required by handbook)
  - env: 'dev' (Required by handbook)
  - owner: 'DevTeam' (Required by handbook)
  - costCenter: 'Development' (Required by handbook)
  - BackupPolicy: None
  - DisasterRecovery: Disabled
  - SLA: BestEffort

### 3. Created Validation Scripts
- Created `validate-params.sh` for bash environments
- Created `validate-params.ps1` for PowerShell environments
- Scripts validate parameter file syntax and structure

### 4. Created Deployment Example Scripts
- Created `deploy-example.sh` with example Azure CLI commands
- Created `deploy-example.ps1` with PowerShell deployment examples
- Scripts show step-by-step deployment process for both environments

### 5. Handbook Compliance Check
- Reviewed Azure AVM Bicep handbook requirements
- Updated parameter files to include all REQUIRED tags per PSRule Azure.Tag compliance:
  - `stack`, `env`, `owner`, `costCenter` are now present in both files
- Verified compliance with other handbook requirements:
  - ✅ Using .bicepparam format (BCPNFR8)
  - ✅ Module versions are pinned (never using :latest)
  - ✅ Location parameter uses resourceGroup().location default
  - ✅ httpsOnly = true on App Services
  - ✅ Key Vault with purge protection enabled
  - ✅ RBAC-based access (no access policies)
  - ✅ Secure defaults implemented

## Technical Details

### Parameter Files Structure
Both parameter files use the new bicepparam format:
```bicep
using '../main.bicep'

param environment = 'dev|prod'
param location = 'eastus'
param projectName = 'mdm'
param tags = { 
  // All required tags per handbook
  stack: 'md-decision-maker'
  env: 'dev|prod'
  owner: 'Team Name'
  costCenter: 'Cost Center'
  // Additional tags...
}
```

### Environment-Specific Differences
The infrastructure automatically configures different settings based on environment:
- **App Service**: Dev gets 1 instance, Prod gets 2 instances
- **Log Analytics**: Dev retains for 30 days, Prod for 90 days
- **Container Registry**: Prod gets geo-replication and zone redundancy
- **Key Vault**: Dev has 7-day soft delete, Prod has 90-day
- **AI Foundry**: Prod is marked as high business impact workspace

### Validation Results
- Both parameter files build successfully with `az bicep build-params`
- Only warnings present are from resources.bicep about safe access operators (existing)
- Parameter files are ready for deployment
- Full compliance with Azure AVM Bicep handbook requirements

## Expected Outcomes

1. **Deployment Ready**: Both dev and prod environments can now be deployed using:
   ```bash
   az deployment sub create \
     --location eastus \
     --template-file main.bicep \
     --parameters environments/main.{env}.bicepparam
   ```

2. **Environment Isolation**: Clear separation between development and production configurations

3. **Compliance Tags**: Both environments include all required tags per PSRule Azure.Tag compliance

4. **Validation Tools**: Scripts provided for parameter file validation before deployment

5. **Handbook Compliance**: Full alignment with Azure AVM Bicep best practices

## Next Steps

1. Task T-10: Add bicepconfig.json with module aliases and PSRule configuration
2. Task T-11: Create comprehensive README.md with deployment guide
3. Task T-12: Validate with bicep build, linting, and what-if deployment

## Files Created/Modified
- Modified: `infra/environments/main.dev.bicepparam` (added required tags)
- Modified: `infra/environments/main.prod.bicepparam` (added required tags)
- Created: `infra/scripts/validate-params.sh`
- Created: `infra/scripts/validate-params.ps1`
- Created: `infra/scripts/deploy-example.sh`
- Created: `infra/scripts/deploy-example.ps1`

## Status
✅ Task completed successfully - Environment parameter files are ready for use and fully compliant with Azure AVM Bicep handbook
