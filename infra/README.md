# MD Decision Maker - Infrastructure as Code

This directory contains the Bicep Infrastructure as Code (IaC) for deploying the MD Decision Maker application to Azure.

## Overview

The infrastructure is built using Azure Bicep and follows Azure Verified Modules (AVM) best practices. It deploys all required Azure resources for the LLM Document Generation PoC.

## Directory Structure

```
/infra
├── main.bicep                    # Entry point (subscription scope)
├── bicepconfig.json              # Bicep configuration
├── .gitignore                    # Ignore build outputs
├── README.md                     # This file
├── /environments
│   ├── main.dev.bicepparam       # Dev environment parameters
│   └── main.prod.bicepparam      # Prod environment parameters (TBD)
├── /modules
│   └── abbreviations.json        # Resource naming abbreviations
└── /scripts
    ├── deploy.ps1                # PowerShell deployment script (TBD)
    └── validate.sh               # Bash validation script (TBD)
```

## Prerequisites

- Azure CLI (>= 2.50.0)
- Bicep CLI (>= 0.20.0)
- Azure subscription with appropriate permissions
- PowerShell 7+ or Bash

## Resource Naming Convention

Resources follow the Cloud Adoption Framework (CAF) naming convention:
- `{resource-type-abbreviation}-{project}-{environment}-{location}`
- Example: `rg-mdm-dev-eastus`

## Deployment

### Validate the Bicep files

```bash
# Build and validate the bicep files
az bicep build --file main.bicep

# Run linter
az bicep lint --file main.bicep
```

### Deploy to Azure

```bash
# Login to Azure
az login

# Set the subscription
az account set --subscription "<subscription-id>"

# Deploy to dev environment
az deployment sub create \
  --name "mdm-dev-$(date +%Y%m%d%H%M%S)" \
  --location eastus \
  --template-file main.bicep \
  --parameters environments/main.dev.bicepparam

# Preview changes with what-if
az deployment sub what-if \
  --name "mdm-dev-$(date +%Y%m%d%H%M%S)" \
  --location eastus \
  --template-file main.bicep \
  --parameters environments/main.dev.bicepparam
```

## Resources Deployed

Currently, this infrastructure deploys:
- Resource Group with standard tags

Future deployments will include:
- 2x App Services (Frontend and Backend)
- Container Registry (Premium SKU)
- Key Vault (with RBAC)
- Application Insights (workspace-based)
- Storage Account (Blob Storage)
- AI Foundry Hub and Project

## Tags

All resources are tagged with:
- `Environment`: dev/prod
- `Project`: md-decision-maker
- `ManagedBy`: Bicep
- Additional custom tags from parameter files

## Security Considerations

- All resources use managed identities (no passwords/keys)
- Key Vault uses RBAC authorization
- App Services are HTTPS-only
- Container Registry has admin user disabled
- Network security groups restrict access appropriately

## Next Steps

- Complete remaining infrastructure modules (T-03 to T-12)
- Add resources.bicep for all Azure resources
- Create production parameter file
- Add deployment scripts
- Configure CI/CD pipeline
