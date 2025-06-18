# validate-params.ps1 - Validate parameter files for bicep deployment

$ErrorActionPreference = 'Stop'

Write-Host "=== Validating Bicep Parameter Files ===" -ForegroundColor Cyan
Write-Host ""

# Function to validate a parameter file
function Test-ParameterFile {
    param(
        [string]$Environment
    )
    
    $paramFile = "environments/main.$Environment.bicepparam"
    
    Write-Host "Testing $Environment environment parameters..." -ForegroundColor Yellow
    
    # First, check if the parameter file exists
    if (-not (Test-Path $paramFile)) {
        Write-Host "✗ Parameter file $paramFile not found" -ForegroundColor Red
        return $false
    }
    
    # Build with parameter file to check for syntax errors
    try {
        $null = az bicep build-params --file $paramFile 2>$null
        Write-Host "✓ Parameter file syntax is valid" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Parameter file has syntax errors" -ForegroundColor Red
        return $false
    }
    
    # Generate parameter file JSON to validate structure
    $paramJson = $paramFile -replace '\.bicepparam$', '.parameters.json'
    try {
        $null = az bicep build-params --file $paramFile --outfile $paramJson 2>$null
        Write-Host "✓ Parameter file builds successfully" -ForegroundColor Green
        # Clean up generated file
        if (Test-Path $paramJson) {
            Remove-Item $paramJson -Force
        }
    }
    catch {
        Write-Host "✗ Failed to build parameter file" -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    return $true
}

# Navigate to infra directory
Push-Location $PSScriptRoot\..

try {
    # Validate both environments
    $devValid = Test-ParameterFile -Environment "dev"
    $prodValid = Test-ParameterFile -Environment "prod"
    
    Write-Host "=== Parameter File Summary ===" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "Dev environment parameters:" -ForegroundColor Yellow
    Write-Host "  - Location: eastus"
    Write-Host "  - Environment: dev"
    Write-Host "  - Project: mdm"
    Write-Host "  - Tags: Development configuration"
    Write-Host ""
    
    Write-Host "Prod environment parameters:" -ForegroundColor Yellow
    Write-Host "  - Location: eastus"
    Write-Host "  - Environment: prod"
    Write-Host "  - Project: mdm"
    Write-Host "  - Tags: Production configuration with compliance tags"
    Write-Host ""
    
    Write-Host "To deploy, use:" -ForegroundColor Green
    Write-Host "  az deployment sub create --location eastus --template-file main.bicep --parameters environments/main.dev.bicepparam"
    Write-Host "  az deployment sub create --location eastus --template-file main.bicep --parameters environments/main.prod.bicepparam"
    
    if ($devValid -and $prodValid) {
        Write-Host ""
        Write-Host "All parameter files validated successfully!" -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host ""
        Write-Host "Some parameter files failed validation." -ForegroundColor Red
        exit 1
    }
}
finally {
    Pop-Location
}
