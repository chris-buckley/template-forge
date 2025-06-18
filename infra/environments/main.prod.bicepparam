using '../main.bicep'

param environment = 'prod'
param location = 'eastus'
param projectName = 'mdm'

param tags = {
  stack: 'md-decision-maker'
  env: 'prod'
  owner: 'Platform Team'
  costCenter: 'Production'
  DataClassification: 'Production'
  Compliance: 'HIPAA-Eligible'
  BackupPolicy: 'Tier1'
  DisasterRecovery: 'Enabled'
  SLA: '99.9%'
}
