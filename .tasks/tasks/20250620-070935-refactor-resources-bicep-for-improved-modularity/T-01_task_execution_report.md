<!---
⚠️ **DO NOT DELETE**
🔧 **TASK REPORT USAGE GUIDE**
================================

PURPOSE
-------
This file is the detailed execution log for a single task:
**T-01: Gather context, refine, align & scope objective**.
It captures the specific context, plan, and ongoing status reports for this task only.

HOW TO USE THIS LOG
-------------------
1.  **Fill out context & plan:** Before starting, detail the 'why' and 'how' in the relevant sections below.
2.  **Log all progress:** Use the "Situation Report" template to add updates under the "✍️ Situation & Decision Reports" section. Always add the newest report at the top.
3.  **Update the main log:** After updating this file, remember to also update the status and timestamp for this task in the main `executionLog.md` Task Board.

SITUATION REPORT TEMPLATE (Copy/paste this to log an update)
-------------------------------------------------------------
```markdown
**Situation Report: YYYY‑MM‑DD HH:MM UTC**
*   **Status:** 📋 / ▶️ / ✅ / 🚧
*   **Activity:** <concise summary of work performed>
*   **Observations:** <key findings, decisions, surprises>
*   **Next Steps:** <immediate follow‑ups or hand‑offs>
---
```
--->

# T-01 Details – Gather context, refine, align & scope objective

## Situation & Context

The MD Decision Maker infrastructure is currently deployed using a single monolithic `resources.bicep` file that contains all Azure resource definitions. This file has grown to approximately 800 lines and includes:
- Resource deployments using Azure Verified Modules (AVM)
- Variable definitions and naming conventions
- Multiple RBAC role assignments
- Complex interdependencies between resources

### HIGH LEVEL CONTEXT (WEBSITE LINKS, RESEARCH, HANDBOOKS, FILE PATHS, CLASSES, METHODS etc.)

**File Paths:**
- Main entry: `/infra/main.bicep` (subscription-scoped deployment)
- Target file: `/infra/resources.bicep` (resource group-scoped, ~800 lines)
- Existing modules: `/infra/modules/` (rbac.bicep, abbreviations.json, monitoring.json)
- Config: `/infra/bicepconfig.json` (Bicep linting and AVM configuration)

**Current Resource Structure:**
1. **Monitoring Stack**
   - Log Analytics Workspace (AVM module: `br/public:avm/res/operational-insights/workspace:0.9.1`)
   - Application Insights (AVM module: `br/public:avm/res/insights/component:0.4.1`)

2. **Storage Stack**
   - Storage Account (AVM module: `br/public:avm/res/storage/storage-account:0.14.3`)
   - Container Registry (AVM module: `br/public:avm/res/container-registry/registry:0.5.1`)

3. **Security Stack**
   - Key Vault (AVM module: `br/public:avm/res/key-vault/vault:0.10.2`)

4. **Compute Stack**
   - App Service Plan (AVM module: `br/public:avm/res/web/serverfarm:0.3.0`)
   - Backend App Service (AVM module: `br/public:avm/res/web/site:0.10.0`)
   - Frontend App Service (AVM module: `br/public:avm/res/web/site:0.10.0`)

5. **AI Stack**
   - AI Foundry Hub (AVM module: `br/public:avm/res/machine-learning-services/workspace:0.10.0`)
   - AI Foundry Project (AVM module: `br/public:avm/res/machine-learning-services/workspace:0.10.0`)

6. **RBAC Assignments**
   - Multiple role assignments using `br/public:avm/ptn/authorization/resource-role-assignment:0.1.1`

**Key Dependencies:**
- Backend App depends on: Key Vault, Storage, Container Registry, App Insights, AI resources
- Frontend App depends on: Container Registry, Backend App URL
- AI Project depends on: AI Hub
- All resources depend on: Log Analytics Workspace for diagnostics

## Objective & Purpose

**Primary Objective:** Refactor the monolithic `resources.bicep` file into a modular architecture that improves maintainability, reusability, and follows Bicep best practices.

**Specific Goals:**
1. Create focused, single-purpose modules for each logical resource group
2. Maintain all existing functionality without breaking changes
3. Improve code organization and reduce complexity
4. Enable easier testing and validation of individual components
5. Follow consistent patterns aligned with existing AVM usage

**Success Criteria:**
- All resources deploy successfully with same configuration
- Module boundaries are logical and cohesive
- Parameters and outputs are properly managed
- Dependencies are explicit and well-defined
- Code is more readable and maintainable

## Scope & Boundaries

| ✅ **In Scope & Affected Areas** | 🚫 **Out of Scope & Unaffected Areas** |
| :----------------------------- | :------------------------------------- |
| • resources.bicep file refactoring<br>• Creating new module files in /modules<br>• Module organization and structure<br>• Parameter and output management<br>• RBAC assignment modularization<br>• Module dependencies and references<br>• Maintaining all existing functionality<br>• Following AVM patterns | • main.bicep (subscription-level deployment)<br>• Environment parameter files<br>• Deployment scripts<br>• Resource naming conventions<br>• Existing rbac.bicep module<br>• bicepconfig.json settings<br>• PS Rule configurations<br>• README documentation (will update after) |

## Execution & Implementation Plan

### Implementation Plan

1. **Module Structure Design**
   - Create `monitoring.bicep` for Log Analytics + Application Insights
   - Create `storage.bicep` for Storage Account
   - Create `containerRegistry.bicep` for Container Registry
   - Create `keyVault.bicep` for Key Vault
   - Create `appServices.bicep` for App Service Plan + Apps
   - Create `aiFoundry.bicep` for AI Hub + Project
   - Create `rbacAssignments.bicep` for all RBAC assignments

2. **Refactoring Approach**
   - Extract each logical group into its module
   - Define clear input parameters for each module
   - Define comprehensive outputs for inter-module dependencies
   - Update resources.bicep to orchestrate module calls
   - Maintain existing naming conventions using shared variables

3. **Testing Strategy**
   - Validate each module individually with `az bicep build`
   - Run what-if deployment to ensure no changes
   - Deploy to dev environment for validation
   - Verify all outputs and dependencies work correctly

### Detailed Execution Phases, Steps, Implementations

**Phase 1: Preparation and Analysis**
* [ ] Analyze current resource dependencies and relationships
* [ ] Document module boundaries and interfaces
* [ ] Create module templates with parameters and outputs

**Phase 2: Module Creation**
* [ ] Create `/modules/monitoring.bicep` for observability resources
* [ ] Create `/modules/storage.bicep` for Storage Account with lifecycle policies
* [ ] Create `/modules/containerRegistry.bicep` for ACR with security settings
* [ ] Create `/modules/keyVault.bicep` for Key Vault with RBAC settings
* [ ] Create `/modules/appServices.bicep` for App Service Plan and Apps
* [ ] Create `/modules/aiFoundry.bicep` for AI Hub and Project
* [ ] Create `/modules/rbacAssignments.bicep` consolidating all RBAC

**Phase 3: Integration and Orchestration**
* [ ] Update resources.bicep to use new modules
* [ ] Ensure all parameters flow correctly
* [ ] Verify all outputs are properly exposed
* [ ] Handle module dependencies explicitly

**Phase 4: Validation and Testing**
* [ ] Run `az bicep build` on all files
* [ ] Execute bicep linting and PSRule validation
* [ ] Perform what-if deployment comparison
* [ ] Document any changes or improvements

**Phase 5: Deployment and Verification**
* [ ] Deploy to development environment
* [ ] Verify all resources are created correctly
* [ ] Test application functionality
* [ ] Validate RBAC assignments work properly


### ✍️ Situation & Decision Reports

**Situation Report: 2025-06-20 07:28 UTC**
*   **Status:** ✅ Complete
*   **Activity:** T-01 signed off - context gathering and planning phase completed
*   **Observations:** 
    - Comprehensive modularization plan created with 7 focused modules
    - All dependencies and relationships documented
    - Clear implementation phases defined
    - Ready for task breakdown and implementation
*   **Next Steps:** Proceed to T-02 to create specific implementation tasks
---

**Situation Report: 2025-06-20 07:25 UTC**
*   **Status:** ▶️ In Progress
*   **Activity:** Completed comprehensive context gathering and analysis of the infrastructure codebase
*   **Observations:** 
    - The resources.bicep file is indeed monolithic at ~800 lines
    - Clear logical groupings exist for modularization
    - All resources use AVM modules consistently
    - Complex RBAC assignments could benefit from consolidation
    - Dependencies are well-defined but scattered throughout the file
*   **Next Steps:** Present refactoring plan to user for approval before proceeding with implementation
---


### Sign-off
*   **Result:** `Approved`
*   **Commit:** `plan[infra]: gather context and create plan for resources.bicep modularization`
*   **Comments:**
    > Context gathering completed successfully. Comprehensive analysis of the monolithic resources.bicep file has been performed, dependencies mapped, and a clear modularization strategy has been defined. Ready to proceed with implementation tasks.

---
