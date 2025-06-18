# PSRule Configuration for Azure Infrastructure

This directory contains PSRule configuration and custom rules for validating the md-decision-maker Azure infrastructure.

## Files

- `ps-rule.yaml` - Main PSRule configuration file
- `.ps-rule/Rule.Rule.ps1` - Custom validation rules specific to this project

## Installation

To use PSRule for Azure, install the required PowerShell modules:

```powershell
# Install PSRule and PSRule for Azure
Install-Module -Name PSRule -Scope CurrentUser -Force
Install-Module -Name PSRule.Rules.Azure -Scope CurrentUser -Force
```

## Usage

### Validate Bicep Files

From the `/infra` directory, run:

```powershell
# Validate all Bicep files
Invoke-PSRule -InputPath . -Module PSRule.Rules.Azure

# Validate specific file
Invoke-PSRule -InputPath main.bicep -Module PSRule.Rules.Azure

# Validate with detailed output
Invoke-PSRule -InputPath . -Module PSRule.Rules.Azure -OutputFormat Wide
```

### Validate Compiled ARM Templates

```powershell
# First compile Bicep to ARM
az bicep build --file main.bicep

# Then validate the JSON
Invoke-PSRule -InputPath main.json -Module PSRule.Rules.Azure
```

## Built-in Azure Rules

The configuration enables the following Azure Well-Architected Framework rules:

- **Security Rules**
  - `Azure.Deployment.SecureParameter` - Use secure parameters for sensitive values
  - `Azure.Deployment.OutputSecretValue` - Don't output secrets
  - `Azure.KeyVault.PurgeProtect` - Enable purge protection on Key Vault
  - `Azure.AppService.UseHTTPS` - Enforce HTTPS only
  - `Azure.ACR.AdminUser` - Disable admin user on Container Registry

- **Operational Excellence**
  - `Azure.Resource.UseTags` - Require tags on resources
  - `Azure.AppInsights.Workspace` - Use workspace-based Application Insights
  - `Azure.Template.UseLocationParameter` - Use location parameter

- **Cost Optimization**
  - `Azure.Storage.BlobPublicAccess` - Disable public blob access

## Custom Project Rules

The `.ps-rule/Rule.Rule.ps1` file contains custom rules:

- `MDM.Resource.NamingConvention` - Enforce project naming standards
- `MDM.AppService.UseManagedIdentity` - Require managed identity on App Services
- `MDM.Storage.UseLifecyclePolicy` - Require lifecycle policies on storage
- `MDM.Resource.RequiredTags` - Enforce required tags (Environment, Project, etc.)
- `MDM.ACR.UsePremiumSku` - Require Premium SKU for Container Registry
- `MDM.AI.Security` - Enforce security settings for AI services

## Integration with CI/CD

To integrate PSRule validation in your pipeline:

### Azure DevOps

```yaml
- task: ps-rule-assert@2
  displayName: 'Validate Azure Infrastructure'
  inputs:
    inputType: 'repository'
    inputPath: 'infra/'
    modules: 'PSRule.Rules.Azure'
    outputFormat: 'Nunit3'
    outputPath: 'reports/ps-rule-results.xml'
```

### GitHub Actions

```yaml
- name: Run PSRule analysis
  uses: microsoft/ps-rule@v2.9.0
  with:
    modules: 'PSRule.Rules.Azure'
    inputPath: 'infra/'
    outputFormat: 'Sarif'
    outputPath: 'reports/ps-rule-results.sarif'
```

## Suppressing Rules

If you need to suppress a rule for specific resources, add it to the `suppression` section in `ps-rule.yaml`:

```yaml
suppression:
  Rule.Name:
    - 'Resource.Type/Resource.Name'
```

## Troubleshooting

- If PSRule doesn't find the rules, ensure you're running from the `/infra` directory
- For "module not found" errors, verify PSRule.Rules.Azure is installed
- Use `-Verbose` flag for detailed execution information
