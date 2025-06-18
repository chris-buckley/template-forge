# Custom PSRule rules for md-decision-maker infrastructure
# These rules supplement the Azure Well-Architected Framework rules

# Rule: Resources must follow the project naming convention
Rule 'MDM.Resource.NamingConvention' -Type 'Microsoft.Web/sites', 'Microsoft.ContainerRegistry/registries', 'Microsoft.KeyVault/vaults', 'Microsoft.Storage/storageAccounts', 'Microsoft.Insights/components' {
    $Assert.Match($TargetObject, 'name', '^(app|cr|kv|st|appi|aih|aip|asp|log)-(mdm|mddecisionmaker)-(dev|prod|test|staging)(-[a-z0-9]+)?(-[a-z]{2,})?$')
}

# Rule: App Services must have managed identity enabled
Rule 'MDM.AppService.UseManagedIdentity' -Type 'Microsoft.Web/sites' -If { $TargetObject.kind -like 'app*' } {
    $Assert.HasFieldValue($TargetObject, 'identity.type', 'SystemAssigned')
}

# Rule: Storage accounts must have lifecycle policies for cost optimization
Rule 'MDM.Storage.UseLifecyclePolicy' -Type 'Microsoft.Storage/storageAccounts' {
    $Assert.HasFieldValue($TargetObject, 'properties.lifecycleManagement.policy', $true)
}

# Rule: All resources must have required tags (per AVM handbook)
Rule 'MDM.Resource.RequiredTags' -Type 'Microsoft.Resources/subscriptions/resourceGroups', 'Microsoft.Web/sites', 'Microsoft.ContainerRegistry/registries', 'Microsoft.KeyVault/vaults', 'Microsoft.Storage/storageAccounts' {
    # Core tags required by AVM handbook
    $requiredTags = @('stack', 'env', 'owner', 'costCenter')
    # Additional project-specific tags
    $additionalTags = @('Project', 'DeploymentDate')
    $allTags = $requiredTags + $additionalTags
    
    foreach ($tag in $allTags) {
        $Assert.HasFieldValue($TargetObject, "tags.$tag")
    }
}

# Rule: Diagnostic settings must be configured for all applicable resources
Rule 'MDM.Resource.DiagnosticSettings' -Type 'Microsoft.KeyVault/vaults', 'Microsoft.ContainerRegistry/registries', 'Microsoft.Storage/storageAccounts', 'Microsoft.Web/sites' {
    $Assert.HasFieldValue($TargetObject, 'properties.diagnosticSettings')
}

# Rule: Container Registry must use Premium SKU for security features
Rule 'MDM.ACR.UsePremiumSku' -Type 'Microsoft.ContainerRegistry/registries' {
    $Assert.HasFieldValue($TargetObject, 'sku.name', 'Premium')
}

# Rule: App Service Plan must use appropriate SKU for environment
Rule 'MDM.AppServicePlan.EnvironmentSku' -Type 'Microsoft.Web/serverfarms' {
    if ($TargetObject.tags.Environment -eq 'prod') {
        $Assert.In($TargetObject, 'sku.name', @('P1v3', 'P2v3', 'P3v3'))
    }
    else {
        $Assert.In($TargetObject, 'sku.name', @('B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1v3'))
    }
}

# Rule: RBAC assignments must use least privilege principle
Rule 'MDM.RBAC.LeastPrivilege' -Type 'Microsoft.Authorization/roleAssignments' {
    # Ensure no Owner or Contributor roles are assigned at subscription level
    if ($TargetObject.properties.scope -eq '/subscriptions/*') {
        $Assert.NotIn($TargetObject, 'properties.roleDefinitionId', @(
            '/providers/Microsoft.Authorization/roleDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635',  # Owner
            '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c'   # Contributor
        ))
    }
}

# Rule: AI Services must have appropriate security configurations
Rule 'MDM.AI.Security' -Type 'Microsoft.MachineLearningServices/workspaces' {
    $Assert.HasFieldValue($TargetObject, 'properties.publicNetworkAccess', 'Disabled')
    $Assert.HasFieldValue($TargetObject, 'identity.type', 'SystemAssigned')
}

# Rule: Ensure proper dependency chain for resources
Rule 'MDM.Deployment.DependencyChain' -Type 'Microsoft.Resources/deployments' {
    # Key Vault should be deployed before App Services
    # Log Analytics should be deployed before Application Insights
    $Assert.HasFieldValue($TargetObject, 'dependsOn')
}
