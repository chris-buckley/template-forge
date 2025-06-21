/*
SYNOPSIS: Monitoring Module - Log Analytics Workspace and Application Insights
DESCRIPTION: This module deploys monitoring resources including Log Analytics Workspace and Application Insights 
             following Azure Verified Modules (AVM) patterns and best practices.
VERSION: 1.0.0
*/

// ========== Parameters ==========
@description('Required. The prefix for naming monitoring resources.')
param namePrefix string

@description('Required. The location for all monitoring resources.')
param location string

@description('Required. Tags to apply to all monitoring resources.')
param tags object

@description('Optional. The retention period in days for Log Analytics Workspace.')
@minValue(30)
@maxValue(730)
param logAnalyticsRetentionInDays int = 30

@description('Optional. The daily quota in GB for Log Analytics Workspace.')
@minValue(1)
@maxValue(1000)
param logAnalyticsDailyQuotaGb int = 10

@description('Optional. The sampling percentage for Application Insights.')
@minValue(0)
@maxValue(100)
param applicationInsightsSamplingPercentage int = 100

@description('Optional. Enable public network access for monitoring resources.')
param enablePublicNetworkAccess bool = true

// ========== Variables ==========
var abbrs = loadJsonContent('./abbreviations.json')

// Resource names
var logAnalyticsWorkspaceName = '${abbrs.logAnalyticsWorkspace}-${namePrefix}'
var applicationInsightsName = '${abbrs.applicationInsights}-${namePrefix}'

// Network access configuration
var publicNetworkAccess = enablePublicNetworkAccess ? 'Enabled' : 'Disabled'

// ========== Resources ==========

// Log Analytics Workspace
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: 'log-analytics-${uniqueString(deployment().name, location)}'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags
    // Set retention based on parameter (can be overridden by environment)
    dataRetention: logAnalyticsRetentionInDays
    // Enable ingestion for Application Insights
    useResourcePermissions: true
    // Configure daily cap to control costs
    dailyQuotaGb: logAnalyticsDailyQuotaGb
    // Public network access configuration
    publicNetworkAccessForIngestion: publicNetworkAccess
    publicNetworkAccessForQuery: publicNetworkAccess
    // Managed identity for future integrations
    managedIdentities: {
      systemAssigned: true
    }
  }
}

// Application Insights
module applicationInsights 'br/public:avm/res/insights/component:0.4.1' = {
  name: 'app-insights-${uniqueString(deployment().name, location)}'
  params: {
    name: applicationInsightsName
    location: location
    tags: tags
    // Workspace-based mode for unified observability
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    // Application type for proper categorization
    applicationType: 'web'
    // Request type for monitoring
    kind: 'web'
    // Public network access configuration
    publicNetworkAccessForIngestion: publicNetworkAccess
    publicNetworkAccessForQuery: publicNetworkAccess
    // Retention period inherits from Log Analytics workspace
    retentionInDays: logAnalyticsRetentionInDays
    // Disable legacy Application Insights features
    disableIpMasking: false
    // Sampling settings for cost control
    samplingPercentage: applicationInsightsSamplingPercentage
  }
}

// ========== Outputs ==========

// Log Analytics Workspace outputs
@description('The resource ID of the Log Analytics Workspace.')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.outputs.resourceId

@description('The name of the Log Analytics Workspace.')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.name

@description('The resource ID of the Log Analytics Workspace (duplicate for compatibility).')
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId

// Application Insights outputs
@description('The resource ID of the Application Insights component.')
output applicationInsightsId string = applicationInsights.outputs.resourceId

@description('The name of the Application Insights component.')
output applicationInsightsName string = applicationInsights.outputs.name

@description('The connection string for the Application Insights component.')
output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString

@description('The instrumentation key for the Application Insights component.')
output applicationInsightsInstrumentationKey string = applicationInsights.outputs.instrumentationKey

@description('The resource ID of the Application Insights component (duplicate for compatibility).')
output applicationInsightsResourceId string = applicationInsights.outputs.resourceId
