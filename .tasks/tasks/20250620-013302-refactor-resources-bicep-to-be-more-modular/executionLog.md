<!---
⚠️ **DO NOT DELETE**
🔧 **EXECUTION LOG USAGE GUIDE**
================================

PURPOSE
-------
This file is the single source‑of‑truth for tracking the change request for
**`Refactor resources.bicep to be more modular`**.
It provides a high-level dashboard and context. Detailed execution steps and
situation reports for each task are kept in separate markdown files, linked
from the Task Board below.

_If it didn’t happen in the logs, it didn’t happen._

HOW TO USE THIS LOG
-------------------
1. **Overall Status** – keep the top‑level status current:
   📋 *Not Started* → ▶️ *In Progress* → ✅ *Complete* → 🚧 *Blocked*.
2. **Task Board** - When updating a specific task's log file, update its
   status and timestamp here in the main task board as well.

EMOJI LEGEND (copy exactly whenever using emojis for updates)
---------------------------
| Emoji | Meaning              |
| :---: | :------------------- |
|   📋  | To-Do                |
|   ▶️  | In Progress          |
|   ⏳   | Awaiting Sign-off    |
|   🚧  | Blocked              |
|   ✅   | Complete / No Issues |

⚠️ **DO NOT DELETE THESE COMMENTS.**
They are the **only** place where instructions may appear in this file.
\--->

# Situation & Context – Refactor resources.bicep to be more modular

## Original Request

The resources.bicep file in the infrastructure directory has grown to a large file, the file itself needs to be refactored to be much more modular.

## Overall Objective & Purpose

The resources.bicep file has grown to approximately 900 lines and contains all Azure resource definitions in a single monolithic file. This makes the infrastructure code difficult to maintain, test, and understand. The objective is to refactor this file into smaller, more modular components that follow Azure Verified Modules (AVM) best practices and improve maintainability.

**Background Context:**
- The project is an LLM Document Generation PoC using FastAPI backend and React frontend
- Infrastructure follows AVM best practices and uses Azure Verified Modules from the public registry
- Current structure has main.bicep (subscription-scoped) calling resources.bicep (resource group-scoped)
- A modules directory already exists with rbac.bicep showing initial modularization efforts
- The infrastructure includes comprehensive Azure services: App Services, Container Registry, Key Vault, Storage, AI Foundry, monitoring, and extensive RBAC configurations

## Scope & Boundaries


| ✅ **In Scope & Affected Areas** | 🚫 **Out of Scope & Unaffected Areas** |
| :----------------------------- | :------------------------------------- |
| • Refactoring resources.bicep into logical modules | • Changes to Azure resource configurations or SKUs |
| • Creating new module files in the /modules directory | • Modifications to deployment parameters |
| • Maintaining all existing resource definitions | • Changes to main.bicep entry point |
| • Preserving all RBAC assignments and dependencies | • Updates to AVM module versions |
| • Updating resource references to use new modules | • Changes to environment-specific configurations |
| • Ensuring deployment outputs remain unchanged | • Modifications to deployment scripts |
| • Following AVM module structure best practices | • Changes to PSRule or bicepconfig.json |
| • Adding appropriate module documentation | • Altering resource naming conventions |



## 📊 At-a-Glance Dashboard

| Metric             | Value             |
| :----------------- | :---------------- |
| **Overall Status** | ▶️ **In Progress** |
| ✅ Completed       | 2                 |
| ▶️ In Progress     | 0                 |
| 📋 To-Do           | 8                 |
| **Critical Issues**| ✅ None           |
| **Last Update**    | 2025-06-20 02:30        |

---

## 🗺️ Task Board

| #    | Task (brief)                                    | Status   | Depends on | Updated (YYYY-MM-DD HH:MM) | Link |
| :--- | :---------------------------------------------- | :------- | :--------- | :------------------------- | :--- |
| T-01 | Gather context, refine, align & scope objective | ✅ Complete | –          | 2025-06-20 01:52            | [📝 log](./T-01_task_execution_report.md) |
| T-02 | Update board with specific tasks                | ✅ Complete | T-01       | 2025-06-20 02:25            | [📝 log](./T-02_task_execution_report.md) |
| T-03 | Create monitoring.bicep module                  | 📋 To-Do | T-02       | –                          | [📝 log](./T-03_task_execution_report.md) |
| T-04 | Create storage.bicep module                     | 📋 To-Do | T-03       | –                          | [📝 log](./T-04_task_execution_report.md) |
| T-05 | Create container-registry.bicep module          | 📋 To-Do | T-03       | –                          | [📝 log](./T-05_task_execution_report.md) |
| T-06 | Create key-vault.bicep module                   | 📋 To-Do | T-03       | –                          | [📝 log](./T-06_task_execution_report.md) |
| T-07 | Create app-services.bicep module                | 📋 To-Do | T-04,T-05,T-06 | –                          | [📝 log](./T-07_task_execution_report.md) |
| T-08 | Create ai-foundry.bicep module                  | 📋 To-Do | T-04,T-05,T-06 | –                          | [📝 log](./T-08_task_execution_report.md) |
| T-09 | Create rbac-assignments.bicep module            | 📋 To-Do | T-07,T-08  | –                          | [📝 log](./T-09_task_execution_report.md) |
| T-10 | Integration and validation                      | 📋 To-Do | T-09       | –                          | [📝 log](./T-10_task_execution_report.md) |


---


## Global Context & Links

### Current Infrastructure Components
- **Monitoring**: Log Analytics Workspace, Application Insights
- **Storage**: Storage Account with blob containers, lifecycle policies
- **Container Services**: Azure Container Registry (Premium SKU)
- **Security**: Key Vault with RBAC authorization
- **Compute**: App Service Plan, Frontend & Backend App Services
- **AI/ML**: AI Foundry Hub and Project for LLM integration
- **RBAC**: Comprehensive role assignments for all managed identities

### Key Files
- **Current Monolith**: `/infra/resources.bicep` (~900 lines)
- **Entry Point**: `/infra/main.bicep` (subscription-scoped deployment)
- **Existing Module**: `/infra/modules/rbac.bicep` (role definitions)
- **Naming Standards**: `/infra/modules/abbreviations.json`
- **Documentation**: `/infra/README.md` (comprehensive deployment guide)

### Technical Standards
- Following Azure Verified Modules (AVM) specification
- Using public AVM registry modules (br/public:avm/...)
- Implementing Azure Well-Architected Framework principles
- PSRule for Azure compliance validation enabled


---
