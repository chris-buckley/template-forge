<!---
⚠️ **DO NOT DELETE**
🔧 **TASK REPORT USAGE GUIDE**
================================

PURPOSE
-------
This file is the detailed execution log for a single task:
**T-03: Create monitoring module (Log Analytics + App Insights)**.
It captures the specific context, plan, and ongoing status reports for
*this* task only.

HOW TO USE THIS LOG
-------------------
1.  **Fill out context & plan:** Before starting, detail the 'why' and 'how'
    in the relevant sections below.
2.  **Log all progress:** Use the "Situation Report" template to add updates
    under the "✍️ Situation & Decision Reports" section. Always add the newest
    report at the top.
3.  **Update the main log:** After updating this file, remember to also
    update the status and timestamp for this task in the main
    `executionLog.md` Task Board.

SITUATION REPORT TEMPLATE (Copy/paste to log an update)
-------------------------------------------------------
```markdown
**Situation Report: YYYY‑MM‑DD HH:MM UTC**
*   **Status:** 📋 / ▶️ / ✅ / 🚧
*   **Activity:** <concise summary of work performed>
*   **Observations:** <key findings, decisions, surprises>
*   **Next Steps:** <immediate follow‑ups or hand‑offs>
---
```
--->

# T-03 Details – Create monitoring module (Log Analytics + App Insights)

*Created UTC:* `2025-06-20 07:32`

## Situation & Context

The current `resources.bicep` file contains monitoring resources (Log Analytics Workspace and Application Insights) that need to be extracted into a dedicated module as part of the infrastructure refactoring initiative. These monitoring resources are currently defined inline within the main resources file, making it difficult to reuse and maintain them separately.

### HIGH‑LEVEL CONTEXT (WEBSITES, FILE PATHS, CLASSES, METHODS, etc.)

**Current State:**
- **File Location**: `D:\repos\work-microsoft\template-forge\infra\resources.bicep`
- **Log Analytics Workspace**: Lines ~69-91 using AVM module `br/public:avm/res/operational-insights/workspace:0.9.1`
- **Application Insights**: Lines ~94-117 using AVM module `br/public:avm/res/insights/component:0.4.1`
- **RBAC Assignments**: Multiple monitoring-related RBAC assignments for App Services (lines ~620-680)
- **Dependencies**: These resources are referenced by Storage Account, Container Registry, AI Foundry resources, and App Services for diagnostic settings

**Technical Stack:**
- Azure Bicep with Azure Verified Modules (AVM)
- Azure Monitor services (Log Analytics + Application Insights)
- OpenTelemetry integration for observability
- Workspace-based Application Insights mode

**Key Configurations:**
- Environment-based retention periods (30 days for dev, 90 days for prod)
- Daily quota caps for cost control (10GB for dev, 50GB for prod)
- System-assigned managed identities enabled
- Diagnostic settings configured for all resources
- Public network access enabled (to be restricted later with Private Endpoints)

## Objective & Purpose

Create a dedicated, reusable monitoring module that encapsulates the Log Analytics Workspace and Application Insights resources, following Azure Verified Modules (AVM) patterns and Bicep best practices. This module will:

1. **Improve Modularity**: Extract monitoring resources into a self-contained module that can be versioned and tested independently
2. **Enable Reusability**: Allow the monitoring stack to be deployed across different projects and environments
3. **Simplify Configuration**: Provide a clean interface with sensible defaults while allowing customization
4. **Maintain Functionality**: Preserve all existing monitoring capabilities and integrations
5. **Follow Best Practices**: Align with AVM patterns, Bicep conventions, and Azure Monitor handbook recommendations

## Scope & Boundaries

| ✅ **In Scope & Affected Areas** | 🚫 **Out of Scope & Unaffected Areas** |
| :----------------------------- | :------------------------------------- |
| • Extract Log Analytics Workspace configuration<br>• Extract Application Insights configuration<br>• Create module interface (parameters/outputs)<br>• Maintain environment-based settings<br>• Preserve diagnostic settings structure<br>• Document module usage and parameters<br>• Create module file in `/infra/modules/monitoring.bicep`<br>• Update resources.bicep to use the new module | • RBAC assignments (handled in T-09)<br>• Diagnostic settings on other resources<br>• Private endpoint configuration<br>• Alert rules and action groups<br>• Dashboard and workbook configurations<br>• Existing monitoring data or settings<br>• Network security configurations<br>• Cost management settings     |

## Execution & Implementation Plan

### Implementation Plan

* Create a new monitoring module file that encapsulates both Log Analytics Workspace and Application Insights
* Design a clean parameter interface that supports environment-specific configurations
* Ensure all existing functionality is preserved including diagnostic settings capabilities
* Provide comprehensive outputs for downstream resource integration
* Follow AVM patterns and Bicep best practices throughout

### Detailed Execution Phases, Steps, Implementations

* [x] **Phase 1: Module Creation**
  * [x] Create `/infra/modules/monitoring.bicep` file
  * [x] Define module metadata and description
  * [x] Import required types and configure targetScope

* [x] **Phase 2: Parameter Definition**
  * [x] Define required parameters (name prefix, location, tags)
  * [x] Define optional parameters with defaults:
    * [x] `logAnalyticsRetentionInDays` (default: 30)
    * [x] `logAnalyticsDailyQuotaGb` (default: 10)
    * [x] `applicationInsightsSamplingPercentage` (default: 100)
    * [x] `enablePublicNetworkAccess` (default: true)
  * [x] Add parameter decorators and descriptions per BCPNFR guidelines

* [x] **Phase 3: Log Analytics Workspace Implementation**
  * [x] Copy existing Log Analytics module configuration
  * [x] Parameterize all environment-specific values
  * [x] Maintain AVM module version `0.9.1`
  * [x] Ensure managed identity configuration is preserved

* [x] **Phase 4: Application Insights Implementation**
  * [x] Copy existing Application Insights module configuration
  * [x] Reference Log Analytics Workspace output for workspace-based mode
  * [x] Parameterize retention and sampling settings
  * [x] Maintain AVM module version `0.4.1`

* [x] **Phase 5: Module Outputs**
  * [x] Export Log Analytics Workspace outputs:
    * [x] `logAnalyticsWorkspaceId`
    * [x] `logAnalyticsWorkspaceName`
    * [x] `logAnalyticsWorkspaceResourceId`
  * [x] Export Application Insights outputs:
    * [x] `applicationInsightsId`
    * [x] `applicationInsightsName`
    * [x] `applicationInsightsConnectionString`
    * [x] `applicationInsightsInstrumentationKey`
    * [x] `applicationInsightsResourceId`

* [x] **Phase 6: Update resources.bicep**
  * [x] Remove inline Log Analytics Workspace module
  * [x] Remove inline Application Insights module
  * [x] Add monitoring module import
  * [x] Configure module with appropriate parameters
  * [x] Update all references to use module outputs

* [x] **Phase 7: Validation**
  * [x] Run `bicep build` to validate syntax
  * [x] Check all resource references are updated
  * [x] Verify outputs match expected format
  * [x] Ensure no breaking changes to downstream dependencies

### ✍️ Situation & Decision Reports

**Situation Report: 2025‑06‑20 09:45 UTC**
*   **Status:** ✅ Complete
*   **Activity:** Fixed lint warnings and validated all Bicep files
*   **Observations:** 
    - Removed unused 'environment' parameter from monitoring module
    - Updated resources.bicep to remove the parameter reference
    - All Bicep files now pass lint tests with zero warnings
    - Only experimental feature notices remain (expected for Assert features)
*   **Next Steps:** Ready for sign-off with clean lint results
---

**Situation Report: 2025‑06‑20 09:35 UTC**
*   **Status:** ✅ Complete
*   **Activity:** Successfully completed monitoring module creation and integration
*   **Observations:** 
    - Created new monitoring.bicep module with all required parameters and outputs
    - Successfully extracted Log Analytics and Application Insights configurations
    - Updated resources.bicep to use the new module
    - Updated all 11 references throughout resources.bicep to use module outputs
    - Bicep build validation passed with only one warning about unused environment parameter
    - All functionality preserved with no breaking changes
*   **Next Steps:** Ready for sign-off to proceed with T-04 (Storage module creation)
---

**Situation Report: 2025‑06‑20 09:15 UTC**
*   **Status:** ✅ Complete
*   **Activity:** Beginning execution of monitoring module creation
*   **Observations:** 
    - Successfully read resources.bicep file
    - Confirmed Log Analytics Workspace at lines 69-91 using AVM 0.9.1
    - Confirmed Application Insights at lines 94-117 using AVM 0.4.1
    - Both resources have environment-specific configurations
    - Identified all required outputs for downstream dependencies
*   **Next Steps:** Create monitoring.bicep module file and implement Phase 1 of execution plan
---

**Situation Report: 2025‑06‑20 08:35 UTC**
*   **Status:** ✅ Complete
*   **Activity:** Gathered comprehensive context about monitoring resources in the current infrastructure
*   **Observations:** 
    - Log Analytics Workspace and Application Insights are currently embedded in resources.bicep (lines 69-117)
    - Both use Azure Verified Modules (AVM) from the public registry
    - Environment-specific configurations are hardcoded with conditional logic
    - Multiple resources depend on monitoring outputs for diagnostic settings
    - RBAC assignments for monitoring metrics publisher role exist for App Services
*   **Next Steps:** Ready to execute the module creation or gather additional context if needed
---

### Sign‑off
*   **Result:** `Approved`
*   **Commit:** `feat(infra): create monitoring module for Log Analytics and App Insights`
*   **Comments:**
    > Successfully extracted monitoring resources into a dedicated module with clean lint results and all functionality preserved.

---
