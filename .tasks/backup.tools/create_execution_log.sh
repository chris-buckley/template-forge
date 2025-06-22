#!/usr/bin/env bash
# ========================================================================
# create_task.sh – Create a new task folder and a self-contained
#                  execution log from a template.
# Compatible with Bash 4+ on Linux, macOS, WSL and Git‑for‑Windows.
# ========================================================================

set -Eeuo pipefail

# ---------------------------------------------------
# Step 0 – Resolve the script’s own absolute location
# ---------------------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_FILE="${SCRIPT_DIR}/_tool_config.yaml"

# ---------------------------------------------------
# Step 1 – Validate command‑line arguments
# ---------------------------------------------------
if [[ $# -lt 2 ]]; then
  printf '❌ Error: Missing arguments.\nUsage: %s "<task_title>" "<original_input>"\n' "$0" >&2
  exit 1
fi
TASK_TITLE=$1
ORIGINAL_INPUT=$2

# ---------------------------------------------------
# Step 2 – Load configuration from YAML
# ---------------------------------------------------
if [[ ! -f "$CONFIG_FILE" ]]; then
  printf '❌ Error: Configuration file not found at: %s\n' "$CONFIG_FILE" >&2
  exit 1
fi

# Simple YAML parser using grep and sed. Not a general-purpose parser.
# Reads a value for a given key, trims whitespace, and removes comments.
get_yaml_value() {
  grep -E "^\s*${1}\s*:" "$CONFIG_FILE" | sed -E 's/^[^:]+:\s*//; s/\s*#.*$//; s/^\s*|\s*$//g'
}

ROOT_DIRECTORY_RELATIVE_FROM_THIS_DIRECTORY=$(get_yaml_value "root_directory_relative_from_this_directory")
TASK_DIRECTORY_RELATIVE_FROM_ROOT=$(get_yaml_value "task_directory_relative_from_root")

if [[ -z "${ROOT_DIRECTORY_RELATIVE_FROM_THIS_DIRECTORY:-}" \
   || -z "${TASK_DIRECTORY_RELATIVE_FROM_ROOT:-}" ]]; then
  printf '❌ Error: Config file is missing required variables or is malformed.\n' >&2
  printf '    In "%s", expected "root_directory_relative_from_this_directory" and "task_directory_relative_from_root".\n' "$CONFIG_FILE" >&2
  exit 1
fi

# ---------------------------------------------------
# Step 3 – Build paths and metadata
# ---------------------------------------------------
DIR_TIMESTAMP=$(date -u +'%Y%m%d-%H%M%S')
MD_TIMESTAMP=$(date -u +'%Y-%m-%d %H:%M')
TASK_SLUG=$(echo "$TASK_TITLE" | tr '[:upper:]' '[:lower:]' \
           | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//')
TASK_DIR_NAME="${DIR_TIMESTAMP}-${TASK_SLUG}"

PROJECT_ROOT="$(cd "${SCRIPT_DIR}/${ROOT_DIRECTORY_RELATIVE_FROM_THIS_DIRECTORY}" && pwd -P)"
BASE_DIR="${PROJECT_ROOT}/${TASK_DIRECTORY_RELATIVE_FROM_ROOT}"
TASK_PATH="${BASE_DIR}/${TASK_DIR_NAME}"

# ---------------------------------------------------
# Step 4 – Create directory structure
# ---------------------------------------------------
printf 'Creating task directory: %s\n' "$TASK_PATH"
mkdir -p "$TASK_PATH" || { printf '❌ Error: Unable to create directory.\n' >&2; exit 1; }

# ---------------------------------------------------
# Step 5 – Main log template generator
# ---------------------------------------------------
generate_main_md() {
cat <<EOF
<!---
⚠️ **DO NOT DELETE**
🔧 **EXECUTION LOG USAGE GUIDE**
================================

PURPOSE
-------
This file is the single source‑of‑truth for tracking the change request for
**\`${TASK_TITLE}\`**.
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

# Situation & Context – ${TASK_TITLE}

## Original Request

${ORIGINAL_INPUT}

## Overall Objective & Purpose

[Describe the overall objective and purpose of this change request here, including any relevant background information or context that led to this request.]

## Scope & Boundaries


| ✅ **In Scope & Affected Areas** | 🚫 **Out of Scope & Unaffected Areas** |
| :----------------------------- | :------------------------------------- |
| [Describe in-scope items here] | [Describe out-of-scope items here]     |



## 📊 At-a-Glance Dashboard

| Metric             | Value             |
| :----------------- | :---------------- |
| **Overall Status** | 📋 **Not Started** |
| ✅ Completed       | 0                 |
| ▶️ In Progress     | 0                 |
| 📋 To-Do           | 2                 |
| **Critical Issues**| ✅ None           |
| **Last Update**    | ${MD_TIMESTAMP}        |

---

## 🗺️ Task Board

| #    | Task (brief)                                    | Status   | Depends on | Updated (YYYY-MM-DD HH:MM) | Link |
| :--- | :---------------------------------------------- | :------- | :--------- | :------------------------- | :--- |
| T-01 | Gather context, refine, align & scope objective | 📋 To-Do | –          | ${MD_TIMESTAMP}            | [📝 log](./T-01_task_execution_report.md) |
| T-02 | Read T-01s log and update board with specific tasks                | 📋 To-Do | T-01       | ${MD_TIMESTAMP}            | [📝 log](./T-02_task_execution_report.md) |


---


## Global Context & Links

...


---
EOF
}

# ---------------------------------------------------
# Step 6 – Individual task report template generator
# ---------------------------------------------------
generate_task_report_md() {
  local TASK_ID="$1"
  local TASK_TITLE="$2"
cat <<EOF
<!---
⚠️ **DO NOT DELETE**
🔧 **TASK REPORT USAGE GUIDE**
================================

PURPOSE
-------
This file is the detailed execution log for a single task:
**${TASK_ID}: ${TASK_TITLE}**.
It captures the specific context, plan, and ongoing status reports for this task only.

HOW TO USE THIS LOG
-------------------
1.  **Fill out context & plan:** Before starting, detail the 'why' and 'how' in the relevant sections below.
2.  **Log all progress:** Use the "Situation Report" template to add updates under the "✍️ Situation & Decision Reports" section. Always add the newest report at the top.
3.  **Update the main log:** After updating this file, remember to also update the status and timestamp for this task in the main \`executionLog.md\` Task Board.

SITUATION REPORT TEMPLATE (Copy/paste this to log an update)
-------------------------------------------------------------
\`\`\`markdown
**Situation Report: YYYY‑MM‑DD HH:MM UTC**
*   **Status:** 📋 / ▶️ / ✅ / 🚧
*   **Activity:** <concise summary of work performed>
*   **Observations:** <key findings, decisions, surprises>
*   **Next Steps:** <immediate follow‑ups or hand‑offs>
---
\`\`\`
--->

# ${TASK_ID} Details – ${TASK_TITLE}

## Situation & Context

...

### HIGH LEVEL CONTEXT (WEBSITE LINKS, RESEARCH, HANDBOOKS, FILE PATHS, CLASSES, METHODS etc.)

...

## Objective & Purpose

...

## Scope & Boundaries

| ✅ **In Scope & Affected Areas** | 🚫 **Out of Scope & Unaffected Areas** |
| :----------------------------- | :------------------------------------- |
| [Describe in-scope items here] | [Describe out-of-scope items here]     |

## Execution & Implementation Plan

### Implementation Plan

* ...

### Detailed Execution Phases, Steps, Implementations

* [ ] ...


### ✍️ Situation & Decision Reports

*No reports yet.*


### Sign-off
*   **Result:** \`[Approved / Approved with comments / Rejected]\`
*   **Commit:** \`<type>[optional scope]: <description>\`
*   **Comments:**
    > ...

---
EOF
}

# ---------------------------------------------------
# Step 7 – Write the main execution log file
# ---------------------------------------------------
generate_main_md > "${TASK_PATH}/executionLog.md"
printf '  ✓ executionLog.md\n'

# ---------------------------------------------------
# Step 8 – Create individual task report files
# ---------------------------------------------------
INITIAL_TASK_IDS=("T-01" "T-02")
INITIAL_TASK_TITLES=(
    "Gather context, refine, align & scope objective"
    "Update board with specific tasks"
)

for i in "${!INITIAL_TASK_IDS[@]}"; do
    TASK_ID="${INITIAL_TASK_IDS[i]}"
    TASK_TITLE="${INITIAL_TASK_TITLES[i]}"
    REPORT_FILENAME="${TASK_ID}_task_execution_report.md"
    generate_task_report_md "$TASK_ID" "$TASK_TITLE" > "${TASK_PATH}/${REPORT_FILENAME}"
    printf '  ✓ %s\n' "$REPORT_FILENAME"
done

# ---------------------------------------------------
# Step 9 – Final output
# ---------------------------------------------------
printf '\n✅ Task creation complete.\n'
printf -- '----------------------------------------------------\n'
printf 'Task files created in:\n'
printf '  %s/\n' "$TASK_PATH"
printf -- '----------------------------------------------------\n'