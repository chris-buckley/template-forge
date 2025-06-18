using '../main.bicep'

param environment = 'dev'
param location = 'eastus'
param projectName = 'mdm'

param tags = {
  stack: 'md-decision-maker'
  env: 'dev'
  owner: 'DevTeam'
  costCenter: 'Development'
  DataClassification: 'Non-Production'
  BackupPolicy: 'None'
  DisasterRecovery: 'Disabled'
  SLA: 'BestEffort'
}
