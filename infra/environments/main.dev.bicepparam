using '../main.bicep'

param environment = 'dev'
param location = 'eastus'
param projectName = 'mdm'

param tags = {
  CostCenter: 'Development'
  Owner: 'DevTeam'
  DataClassification: 'Non-Production'
}
