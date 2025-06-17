// ========== RBAC Module ==========
// This module defines common role definition IDs used across the infrastructure

// Azure built-in role definition IDs
// Reference: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles

// Key Vault roles
var keyVaultSecretsUser = '4633458b-17de-408a-b874-0445c86b69e6'
var keyVaultSecretsOfficer = 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
var keyVaultCryptoUser = '12338af0-0e69-4776-bea7-57ae8d297424'

// Storage roles
var storageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var storageBlobDataReader = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
var storageAccountContributor = '17d1049b-9a84-46fb-8f53-869881c3d3ab'

// Container Registry roles
var acrPull = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
var acrPush = '8311e382-0749-4cb8-b61a-304f252e45ec'
var acrDelete = 'c2f4ef07-c644-48eb-af81-4b1b4947fb11'

// Application Insights roles
var monitoringMetricsPublisher = '3913510d-42f4-4e42-8a64-420c390055eb'
var monitoringReader = '43d0d8ad-25c7-4714-9337-8ba259a9fe05'

// Azure Machine Learning roles
var azureMLDataScientist = 'f6c7c914-8db3-469d-8ca1-694a8f32e121'
var azureMLWorkspaceContributor = 'ea01e6af-a1c1-4350-9563-ad00f8c72ec5'
var cognitiveServicesUser = 'a97b65f3-24c7-4388-baec-2e87135dc908'
var cognitiveServicesOpenAIUser = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

// General roles
var contributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var reader = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

// ========== Output role definition IDs ==========
output keyVaultSecretsUser string = keyVaultSecretsUser
output keyVaultSecretsOfficer string = keyVaultSecretsOfficer
output keyVaultCryptoUser string = keyVaultCryptoUser
output storageBlobDataContributor string = storageBlobDataContributor
output storageBlobDataReader string = storageBlobDataReader
output storageAccountContributor string = storageAccountContributor
output acrPull string = acrPull
output acrPush string = acrPush
output acrDelete string = acrDelete
output monitoringMetricsPublisher string = monitoringMetricsPublisher
output monitoringReader string = monitoringReader
output azureMLDataScientist string = azureMLDataScientist
output azureMLWorkspaceContributor string = azureMLWorkspaceContributor
output cognitiveServicesUser string = cognitiveServicesUser
output cognitiveServicesOpenAIUser string = cognitiveServicesOpenAIUser
output contributor string = contributor
output reader string = reader
