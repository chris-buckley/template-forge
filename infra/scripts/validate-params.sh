#!/bin/bash
# validate-params.sh - Validate parameter files for bicep deployment

set -e

echo "=== Validating Bicep Parameter Files ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to validate a parameter file
validate_param_file() {
    local env=$1
    local param_file="environments/main.${env}.bicepparam"
    
    echo "Testing ${env} environment parameters..."
    
    # First, check if the parameter file exists
    if [ ! -f "$param_file" ]; then
        echo -e "${RED}✗ Parameter file $param_file not found${NC}"
        return 1
    fi
    
    # Build with parameter file to check for syntax errors
    if az bicep build-params --file "$param_file" 2>/dev/null; then
        echo -e "${GREEN}✓ Parameter file syntax is valid${NC}"
    else
        echo -e "${RED}✗ Parameter file has syntax errors${NC}"
        return 1
    fi
    
    # Generate parameter file JSON to validate structure
    local param_json="${param_file%.bicepparam}.parameters.json"
    if az bicep build-params --file "$param_file" --outfile "$param_json" 2>/dev/null; then
        echo -e "${GREEN}✓ Parameter file builds successfully${NC}"
        # Clean up generated file
        rm -f "$param_json"
    else
        echo -e "${RED}✗ Failed to build parameter file${NC}"
        return 1
    fi
    
    echo ""
}

# Navigate to infra directory
cd "$(dirname "$0")/.."

# Validate both environments
validate_param_file "dev"
validate_param_file "prod"

echo "=== Parameter File Summary ==="
echo ""
echo "Dev environment parameters:"
echo "  - Location: eastus"
echo "  - Environment: dev"
echo "  - Project: mdm"
echo "  - Tags: Development configuration"
echo ""
echo "Prod environment parameters:"
echo "  - Location: eastus"
echo "  - Environment: prod"
echo "  - Project: mdm"
echo "  - Tags: Production configuration with compliance tags"
echo ""

echo "To deploy, use:"
echo "  az deployment sub create --location eastus --template-file main.bicep --parameters environments/main.dev.bicepparam"
echo "  az deployment sub create --location eastus --template-file main.bicep --parameters environments/main.prod.bicepparam"
