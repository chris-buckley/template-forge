#!/bin/bash
# deploy-example.sh - Example deployment commands for md-decision-maker infrastructure

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== MD Decision Maker Infrastructure Deployment Guide ===${NC}"
echo ""

# Function to show deployment command
show_deployment() {
    local env=$1
    local subscription=$2
    
    echo -e "${YELLOW}Deployment for ${env} environment:${NC}"
    echo ""
    
    echo "1. Login to Azure (if not already logged in):"
    echo "   az login"
    echo ""
    
    echo "2. Set the subscription:"
    echo "   az account set --subscription \"${subscription}\""
    echo ""
    
    echo "3. Run what-if deployment to preview changes:"
    echo "   az deployment sub what-if \\"
    echo "     --name mdm-${env}-\$(date +%Y%m%d%H%M%S) \\"
    echo "     --location eastus \\"
    echo "     --template-file main.bicep \\"
    echo "     --parameters environments/main.${env}.bicepparam"
    echo ""
    
    echo "4. Deploy the infrastructure:"
    echo "   az deployment sub create \\"
    echo "     --name mdm-${env}-\$(date +%Y%m%d%H%M%S) \\"
    echo "     --location eastus \\"
    echo "     --template-file main.bicep \\"
    echo "     --parameters environments/main.${env}.bicepparam"
    echo ""
    
    echo "5. View deployment outputs:"
    echo "   az deployment sub show \\"
    echo "     --name mdm-${env}-\$(date +%Y%m%d%H%M%S) \\"
    echo "     --query properties.outputs"
    echo ""
}

# Show current directory
echo -e "${GREEN}Current directory: $(pwd)${NC}"
echo "Ensure you are in the /infra directory before running deployment commands."
echo ""

# Development environment
echo -e "${BLUE}=== DEVELOPMENT ENVIRONMENT ===${NC}"
show_deployment "dev" "Your-Dev-Subscription-Name"

# Production environment
echo -e "${BLUE}=== PRODUCTION ENVIRONMENT ===${NC}"
show_deployment "prod" "Your-Prod-Subscription-Name"

# Additional notes
echo -e "${BLUE}=== IMPORTANT NOTES ===${NC}"
echo ""
echo "1. Environment-specific configurations:"
echo "   - Dev: 1 App Service instance, 30-day retention, no geo-replication"
echo "   - Prod: 2 App Service instances, 90-day retention, geo-replication to westus2"
echo ""
echo "2. After deployment, you'll need to:"
echo "   - Configure the Azure AI Foundry endpoint in Key Vault"
echo "   - Deploy container images to the Container Registry"
echo "   - Set up any additional network security rules"
echo ""
echo "3. Resource naming convention:"
echo "   - All resources follow the pattern: {resourceType}-{projectName}-{component}-{environment}"
echo "   - Example: app-mdm-fe-dev (Frontend App Service for dev environment)"
echo ""
echo "4. Tags applied to all resources:"
echo "   - Environment, Project, ManagedBy, DeploymentDate"
echo "   - Plus environment-specific tags (CostCenter, Owner, DataClassification, etc.)"
echo ""

echo -e "${GREEN}For more information, see the README.md file in the /infra directory.${NC}"
