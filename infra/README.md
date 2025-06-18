# MD Decision Maker - Infrastructure as Code

This directory contains the Bicep Infrastructure as Code (IaC) for deploying the MD Decision Maker application to Azure. The infrastructure follows Azure Verified Modules (AVM) best practices and implements a comprehensive, production-ready deployment.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Resource Naming Convention](#resource-naming-convention)
- [Deployment Guide](#deployment-guide)
- [Resources Deployed](#resources-deployed)
- [Parameters Reference](#parameters-reference)
- [Security Configuration](#security-configuration)
- [Monitoring and Observability](#monitoring-and-observability)
- [Cost Optimization](#cost-optimization)
- [Troubleshooting](#troubleshooting)
- [Maintenance](#maintenance)
- [Contributing](#contributing)

## 🎯 Overview

The MD Decision Maker infrastructure deploys a complete Azure environment for an LLM-powered document generation application. It includes:

- **Containerized applications** running on Azure App Service
- **AI/ML capabilities** via Azure AI Foundry
- **Secure secret management** with Azure Key Vault
- **Document storage** using Azure Blob Storage
- **Container registry** for Docker images
- **Comprehensive monitoring** with Application Insights
- **RBAC-based security** with managed identities

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             Azure Subscription                              │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │                  Resource Group (rg-mdm-{env}-{location})                 │ │
│ │                                                                         │ │
│ │ ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐        │ │
│ │ │  App Service     │   │  App Service     │   │   Container      │        │ │
│ │ │  (Frontend)      │   │  (Backend)       │   │   Registry       │        │ │
│ │ │ app-mdm-fe-{env} │   │ app-mdm-be-{env} │   │ cr-mdm-{env}     │        │ │
│ │ │   Port: 3000     │   │   Port: 8000     │   │  Premium SKU     │        │ │
│ │ └────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘        │ │
│ │          │ MSI                  │ MSI                  │ MSI             │ │
│ │          └──────────────────────┴──────────────────────┘                  │ │
│ │                                 │                                         │ │
│ │                 ┌───────────────┴─────────────────┐                       │ │
│ │                 │    Key Vault (kv-mdm-{env})     │                       │ │
│ │                 │ • Secrets, RBAC, Soft Delete  │                       │ │
│ │                 └───────────────────────────────┘                       │ │
│ │                                                                         │ │
│ │ ┌──────────────────────┐   ┌──────────────────────────────────┐         │ │
│ │ │ Application Insights │   │          Blob Storage            │         │ │
│ │ │   (appi-mdm-{env})   │   │        (st-mdm-{env})            │         │ │
│ │ │   • OpenTelemetry    │   │      • Document Storage          │         │ │
│ │ │   • Metrics & Logs   │   │      • Lifecycle Policies        │         │ │
│ │ └───────────┬──────────┘   └──────────────────────────────────┘         │ │
│ │             │                                                           │ │
│ │             └───────────> Log Analytics Workspace (log-mdm-{env})       │ │
│ │                           • Centralized Logging                       │ │
│ │                           • 30-90 Day Retention                       │ │
│ │                                                                         │ │
│ │ ┌─────────────────────────────────────────────────────────────────────┐ │ │
│ │ │                 AI Foundry Hub (aih-hub-mdm-{env})                  │ │ │
│ │ │ ┌───────────────────────────────────────────────────────────────┐ │ │ │
│ │ │ │              AI Project (aih-proj-mdm-{env})                  │ │ │ │
│ │ │ │ • GPT-4o Model Deployment                                     │ │ │ │
│ │ │ │ • AI Services Connection                                      │ │ │ │
│ │ │ └───────────────────────────────────────────────────────────────┘ │ │ │
│ │ └─────────────────────────────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘

Legend:
- MSI = Managed Service Identity
- {env} = Environment (dev/prod)
- {location} = Azure region (e.g., eastus)
```

## 📝 Prerequisites

### Required Tools

| Tool | Minimum Version | Installation |
|------|----------------|--------------|
| Azure CLI | 2.50.0 | [Install Guide](https://docs.microsoft.com/cli/azure/install-azure-cli) |
| Bicep CLI | 0.29.47 | `az bicep install` |
| PowerShell Core | 7.0+ | [Install Guide](https://docs.microsoft.com/powershell/scripting/install/installing-powershell) |
| Git | 2.0+ | [Install Guide](https://git-scm.com/downloads) |

### Azure Permissions

You need the following Azure RBAC roles at the subscription level:
- **Contributor** - To create and manage resources
- **User Access Administrator** - To create role assignments
- **Key Vault Administrator** - To manage Key Vault policies

### Pre-deployment Checklist

- [ ] Azure subscription is active
- [ ] Required permissions are granted
- [ ] Azure CLI is authenticated: `az login`
- [ ] Correct subscription is selected: `az account show`
- [ ] Bicep CLI is up to date: `az bicep upgrade`
- [ ] PSRule for Azure is installed (optional): `Install-Module -Name PSRule.Rules.Azure`

## 📁 Directory Structure

```
/infra
├── main.bicep                    # Subscription-scoped entry point
├── resources.bicep               # Resource group-scoped resources
├── bicepconfig.json              # Bicep configuration and security rules
├── ps-rule.yaml                  # PSRule configuration for validation
├── README.md                     # This file
├── .gitignore                    # Ignore build outputs
│
├── /environments                 # Environment-specific parameters
│   ├── main.dev.bicepparam       # Development environment config
│   ├── main.prod.bicepparam      # Production environment config
│   ├── main.dev.json             # Legacy parameter format (auto-generated)
│   └── main.prod.json            # Legacy parameter format (auto-generated)
│
├── /modules                      # Shared modules and configurations
│   ├── abbreviations.json        # Azure resource naming standards
│   └── rbac.bicep                # RBAC role definitions
│
├── /scripts                      # Deployment automation scripts
│   ├── deploy-example.ps1        # PowerShell deployment example
│   ├── deploy-example.sh         # Bash deployment example
│   ├── validate-params.ps1       # Parameter validation script
│   └── validate-params.sh        # Parameter validation script
│
└── /.ps-rule                     # PSRule custom rules
    ├── Rule.Rule.ps1             # Custom validation rules
    └── README.md                 # PSRule documentation
```

## 🏷️ Resource Naming Convention

All resources follow the Cloud Adoption Framework (CAF) naming convention:

```
{resource-type-abbreviation}-{project}-{component}-{environment}-{location}
```

Examples:
- Resource Group: `rg-mdm-dev-eastus`
- App Service: `app-mdm-fe-dev` (frontend), `app-mdm-be-dev` (backend)
- Key Vault: `kv-mdm-dev`
- Storage Account: `stmdmdeveas` (24 char limit, no hyphens)

## 🚀 Deployment Guide

### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/your-org/md-decision-maker.git
cd md-decision-maker/infra

# 2. Login to Azure
az login
az account set --subscription "Your Subscription Name"

# 3. Deploy to development environment
az deployment sub create \
  --name "mdm-dev-$(date +%Y%m%d%H%M%S)" \
  --location eastus \
  --template-file main.bicep \
  --parameters environments/main.dev.bicepparam

# 4. Deploy to production environment
az deployment sub create \
  --name "mdm-prod-$(date +%Y%m%d%H%M%S)" \
  --location eastus \
  --template-file main.bicep \
  --parameters environments/main.prod.bicepparam
```

### Step-by-Step Deployment

#### 1. Validate Templates

```bash
# Build and validate Bicep files
az bicep build --file main.bicep

# Run linter checks
az bicep lint --file main.bicep

# Validate parameters
pwsh scripts/validate-params.ps1 -Environment dev
```

#### 2. Preview Changes (What-If)

```bash
# Preview deployment changes
az deployment sub what-if \
  --name "mdm-dev-whatif" \
  --location eastus \
  --template-file main.bicep \
  --parameters environments/main.dev.bicepparam
```

#### 3. Deploy Infrastructure

```bash
# Deploy with confirmation
az deployment sub create \
  --name "mdm-dev-$(date +%Y%m%d%H%M%S)" \
  --location eastus \
  --template-file main.bicep \
  --parameters environments/main.dev.bicepparam \
  --confirm-with-what-if
```

#### 4. Verify Deployment

```bash
# Get deployment outputs
az deployment sub show \
  --name "mdm-dev-<timestamp>" \
  --query properties.outputs
```

### PowerShell Deployment

Use the provided PowerShell script for enhanced deployment features:

```powershell
# Deploy to development
./scripts/deploy-example.ps1 -Environment dev -Location eastus

# Deploy to production with what-if
./scripts/deploy-example.ps1 -Environment prod -Location eastus -WhatIf
```

## 📦 Resources Deployed

### Core Infrastructure

| Resource | Type | SKU/Tier | Purpose |
|----------|------|----------|---------|
| Resource Group | Microsoft.Resources/resourceGroups | N/A | Container for all resources |
| App Service Plan | Microsoft.Web/serverfarms | P1v3 | Hosting for web applications |
| Frontend App Service | Microsoft.Web/sites | Linux Container | React application hosting |
| Backend App Service | Microsoft.Web/sites | Linux Container | FastAPI application hosting |

### Data & Storage

| Resource | Type | SKU/Tier | Purpose |
|----------|------|----------|---------|
| Storage Account | Microsoft.Storage/storageAccounts | Standard_LRS | Document storage |
| Container Registry | Microsoft.ContainerRegistry/registries | Premium | Docker image storage |
| Key Vault | Microsoft.KeyVault/vaults | Standard | Secret management |

### Monitoring & Analytics

| Resource | Type | SKU/Tier | Purpose |
|----------|------|----------|---------|
| Log Analytics Workspace | Microsoft.OperationalInsights/workspaces | PerGB2018 | Centralized logging |
| Application Insights | Microsoft.Insights/components | Workspace-based | Application monitoring |

### AI & Machine Learning

| Resource | Type | SKU/Tier | Purpose |
|----------|------|----------|---------|
| AI Foundry Hub | Microsoft.MachineLearningServices/workspaces | Basic | AI model management |
| AI Foundry Project | Microsoft.MachineLearningServices/workspaces | Basic | Project workspace |

## 🔧 Parameters Reference

### main.bicep Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environment` | string | - | Environment name (dev/prod) |
| `location` | string | eastus | Azure region for deployment |
| `projectName` | string | mdm | Project identifier |
| `tags` | object | {} | Additional resource tags |
| `deploymentDate` | string | utcNow() | Deployment timestamp |

### Environment-Specific Parameters

Development (`main.dev.bicepparam`):
```bicep
using './main.bicep'

param environment = 'dev'
param location = 'eastus'
param projectName = 'mdm'
param tags = {
  CostCenter: 'Development'
  Owner: 'DevTeam'
  DataClassification: 'Non-Production'
}
```

Production (`main.prod.bicepparam`):
```bicep
using './main.bicep'

param environment = 'prod'
param location = 'eastus'
param projectName = 'mdm'
param tags = {
  CostCenter: 'Production'
  Owner: 'ProdOps'
  DataClassification: 'Production'
  SLA: '99.9'
}
```

## 🔒 Security Configuration

### Managed Identities

All services use system-assigned managed identities with the following RBAC assignments:

| Service | Target Resource | Role | Purpose |
|---------|----------------|------|---------|
| Backend App | Key Vault | Key Vault Secrets User | Read secrets |
| Backend App | Storage Account | Storage Blob Data Contributor | Read/write documents |
| Backend App | Container Registry | AcrPull | Pull Docker images |
| Backend App | Application Insights | Monitoring Metrics Publisher | Send telemetry |
| Backend App | AI Foundry | Azure ML Data Scientist | Use AI models |
| Frontend App | Container Registry | AcrPull | Pull Docker images |
| AI Hub | Key Vault | Key Vault Secrets Officer | Manage AI secrets |
| AI Hub | Storage Account | Storage Blob Data Contributor | Store model artifacts |

### Network Security

- **HTTPS-only** enforced on all App Services
- **TLS 1.2** minimum version requirement
- **CORS** configured for frontend-backend communication
- **Container Registry** admin user disabled
- **Key Vault** uses RBAC authorization (not access policies)

### Security Best Practices

1. **No hardcoded secrets** - All sensitive values in Key Vault
2. **Least privilege access** - Minimal RBAC permissions
3. **Audit logging** - All resources send logs to Log Analytics
4. **Soft delete** enabled on Key Vault and Container Registry
5. **Purge protection** enabled on Key Vault for production

## 📊 Monitoring and Observability

### Application Insights Configuration

- **Connection Mode**: Workspace-based (via Log Analytics)
- **Instrumentation**: OpenTelemetry for distributed tracing
- **Retention**: 30 days (dev) / 90 days (prod)
- **Sampling**: 100% (adjustable for cost optimization)

### Log Analytics Workspace

- **Retention**: 30 days (dev) / 90 days (prod)
- **Daily Cap**: 10GB (dev) / 50GB (prod)
- **Data Sources**:
  - Application logs from App Services
  - Diagnostic logs from all Azure resources
  - Security audit logs from Key Vault
  - Container registry events

### Alerts and Dashboards

Configure these alerts post-deployment:
- App Service availability < 99%
- Response time > 1000ms
- Error rate > 5%
- Storage capacity > 80%
- Key Vault access failures

## 💰 Cost Optimization

### Estimated Monthly Costs

| Environment | Estimated Cost | Main Drivers |
|-------------|---------------|--------------|
| Development | $200-300 | App Service P1v3, Storage, AI |
| Production | $500-800 | 2x App Service instances, Premium ACR, increased retention |

### Cost Optimization Strategies

1. **App Service Plan**
   - Use B-series for non-production workloads
   - Enable auto-scaling for production
   - Consider spot instances for batch workloads

2. **Storage**
   - Lifecycle policies move old data to cool tier
   - Auto-delete temporary uploads after 7 days
   - Use locally redundant storage (LRS) where appropriate

3. **Container Registry**
   - Enable retention policies to auto-delete old images
   - Use Basic tier for development environments

4. **Monitoring**
   - Adjust Application Insights sampling
   - Reduce log retention periods
   - Set daily caps on data ingestion

## 🔍 Troubleshooting

### Common Deployment Issues

#### 1. Subscription Not Found
```
Error: The subscription 'xxx' could not be found
```
**Solution**: Run `az account set --subscription "Your Subscription"`

#### 2. Insufficient Permissions
```
Error: Authorization failed for scope
```
**Solution**: Ensure you have Contributor and User Access Administrator roles

#### 3. Name Already Exists
```
Error: Storage account name 'xxx' is already taken
```
**Solution**: Modify the `projectName` parameter to ensure uniqueness

#### 4. Region Capacity
```
Error: The subscription policy prevents creating resources in region
```
**Solution**: Try a different region or contact Azure support

### Validation Commands

```bash
# Check deployment status
az deployment sub list --query "[?name.contains(@, 'mdm')]"

# Get resource group resources
az resource list --resource-group rg-mdm-dev-eastus --output table

# Test Key Vault access
az keyvault secret list --vault-name kv-mdm-dev

# Check App Service health
az webapp show --name app-mdm-be-dev --query "state"
```

### Debug Mode Deployment

```bash
# Enable debug output
export AZURE_LOG_LEVEL=debug
az deployment sub create \
  --name "mdm-debug" \
  --location eastus \
  --template-file main.bicep \
  --parameters environments/main.dev.bicepparam \
  --verbose
```

## 🛠️ Maintenance

### Regular Maintenance Tasks

1. **Weekly**
   - Review Application Insights for errors
   - Check storage account usage
   - Verify backup policies

2. **Monthly**
   - Update AVM module versions
   - Review and rotate access keys
   - Audit RBAC assignments
   - Check for security recommendations

3. **Quarterly**
   - Review cost optimization opportunities
   - Update documentation
   - Disaster recovery testing

### Updating Infrastructure

```bash
# 1. Update module versions in Bicep files
# 2. Validate changes
az bicep build --file main.bicep

# 3. Preview changes
az deployment sub what-if \
  --template-file main.bicep \
  --parameters environments/main.dev.bicepparam

# 4. Apply updates
az deployment sub create \
  --template-file main.bicep \
  --parameters environments/main.dev.bicepparam
```

## 🤝 Contributing

### Development Workflow

1. Create a feature branch
2. Make infrastructure changes
3. Run validation and linting
4. Test deployment to dev environment
5. Create pull request with deployment outputs

### Code Standards

- Follow AVM best practices
- Use consistent naming conventions
- Add comments for complex logic
- Update documentation for any changes
- Include security considerations

### Testing Checklist

- [ ] Bicep build succeeds
- [ ] Linting passes with no errors
- [ ] What-if deployment shows expected changes
- [ ] Deployment succeeds in dev environment
- [ ] All outputs are populated correctly
- [ ] RBAC assignments work as expected
- [ ] Applications can access required resources

## 📚 Additional Resources

- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Cloud Adoption Framework](https://learn.microsoft.com/azure/cloud-adoption-framework/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/architecture/framework/)

## 📞 Support

For issues or questions:
1. Check the [troubleshooting](#troubleshooting) section
2. Review Azure resource logs in the portal
3. Contact the infrastructure team
4. Create an issue in the repository

---

**Last Updated**: 2025-06-18
**Version**: 1.0.0
**Maintained By**: Infrastructure Team
