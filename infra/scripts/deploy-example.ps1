# deploy-example.ps1 - Example deployment commands for md-decision-maker infrastructure

$ErrorActionPreference = 'Stop'

Write-Host "=== MD Decision Maker Infrastructure Deployment Guide ===" -ForegroundColor Blue
Write-Host ""

# Function to show deployment command
function Show-Deployment {
    param(
        [string]$Environment,
        [string]$Subscription
    )
    
    Write-Host "Deployment for $Environment environment:" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "1. Login to Azure (if not already logged in):"
    Write-Host "   az login" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "2. Set the subscription:"
    Write-Host "   az account set --subscription `"$Subscription`"" -ForegroundColor Cyan
    Write-Host ""
    
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    
    Write-Host "3. Run what-if deployment to preview changes:"
    Write-Host "   az deployment sub what-if ``" -ForegroundColor Cyan
    Write-Host "     --name mdm-$Environment-$timestamp ``" -ForegroundColor Cyan
    Write-Host "     --location eastus ``" -ForegroundColor Cyan
    Write-Host "     --template-file main.bicep ``" -ForegroundColor Cyan
    Write-Host "     --parameters environments/main.$Environment.bicepparam" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "4. Deploy the infrastructure:"
    Write-Host "   az deployment sub create ``" -ForegroundColor Cyan
    Write-Host "     --name mdm-$Environment-$timestamp ``" -ForegroundColor Cyan
    Write-Host "     --location eastus ``" -ForegroundColor Cyan
    Write-Host "     --template-file main.bicep ``" -ForegroundColor Cyan
    Write-Host "     --parameters environments/main.$Environment.bicepparam" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "5. View deployment outputs:"
    Write-Host "   az deployment sub show ``" -ForegroundColor Cyan
    Write-Host "     --name mdm-$Environment-$timestamp ``" -ForegroundColor Cyan
    Write-Host "     --query properties.outputs" -ForegroundColor Cyan
    Write-Host ""
}

# Show current directory
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Green
Write-Host "Ensure you are in the /infra directory before running deployment commands."
Write-Host ""

# Development environment
Write-Host "=== DEVELOPMENT ENVIRONMENT ===" -ForegroundColor Blue
Show-Deployment -Environment "dev" -Subscription "Your-Dev-Subscription-Name"

# Production environment
Write-Host "=== PRODUCTION ENVIRONMENT ===" -ForegroundColor Blue
Show-Deployment -Environment "prod" -Subscription "Your-Prod-Subscription-Name"

# Additional notes
Write-Host "=== IMPORTANT NOTES ===" -ForegroundColor Blue
Write-Host ""
Write-Host "1. Environment-specific configurations:"
Write-Host "   - Dev: 1 App Service instance, 30-day retention, no geo-replication"
Write-Host "   - Prod: 2 App Service instances, 90-day retention, geo-replication to westus2"
Write-Host ""
Write-Host "2. After deployment, you'll need to:"
Write-Host "   - Configure the Azure AI Foundry endpoint in Key Vault"
Write-Host "   - Deploy container images to the Container Registry"
Write-Host "   - Set up any additional network security rules"
Write-Host ""
Write-Host "3. Resource naming convention:"
Write-Host "   - All resources follow the pattern: {resourceType}-{projectName}-{component}-{environment}"
Write-Host "   - Example: app-mdm-fe-dev (Frontend App Service for dev environment)"
Write-Host ""
Write-Host "4. Tags applied to all resources:"
Write-Host "   - Environment, Project, ManagedBy, DeploymentDate"
Write-Host "   - Plus environment-specific tags (CostCenter, Owner, DataClassification, etc.)"
Write-Host ""

Write-Host "For more information, see the README.md file in the /infra directory." -ForegroundColor Green
