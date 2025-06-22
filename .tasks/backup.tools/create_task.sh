#!/usr/bin/env bash
# =========================================================================
# create_task.sh – Create a **single** task execution‑report markdown file
#                  inside an **existing** task folder.
#
# Compatible with Bash 4+ on Linux, macOS, WSL and Git‑for‑Windows.
#
# Usage:
#   ./create_task.sh "<task_directory>" "<task_number>" "<task_title>"
#
# Example:
#   ./create_task.sh ".tasks/tasks/20250620-demo-task" "03" \
#     "Implement CSV export feature"
# =========================================================================

set -Eeuo pipefail

# ---------------------------------------------------
# Step 1 – Validate command‑line arguments
# ---------------------------------------------------
if [[ $# -lt 3 ]]; then
  printf '❌ Error: Missing arguments.\n' >&2
  printf 'Usage: %s \"<task_directory>\" \"<task_number>\" \"<task_title>\"\n' "$0" >&2
  exit 1
fi

TASK_DIR=$1
TASK_NUM_RAW=$2
TASK_TITLE=$3

# ---------------------------------------------------
# Step 2 – Sanity checks & normalisation
# ---------------------------------------------------
# Resolve directory to an absolute path
TASK_DIR_ABS="$(cd -- "$TASK_DIR" && pwd -P 2>/dev/null || true)"

if [[ -z "$TASK_DIR_ABS" || ! -d "$TASK_DIR_ABS" ]]; then
  printf '❌ Error: Task directory does not exist or is not accessible: %s\n' "$TASK_DIR" >&2
  exit 1
fi

# Normalise the numeric part (always two digits)
if [[ ! "$TASK_NUM_RAW" =~ ^[0-9]+$ ]]; then
  printf '❌ Error: Task number must be numeric (got: %s)\n' "$TASK_NUM_RAW" >&2
  exit 1
fi
TASK_NUM=$(printf '%02d' "$TASK_NUM_RAW")
TASK_ID="T-${TASK_NUM}"

REPORT_FILENAME="${TASK_ID}_task_execution_report.md"
REPORT_PATH="${TASK_DIR_ABS}/${REPORT_FILENAME}"

if [[ -e "$REPORT_PATH" ]]; then
  printf '⚠️  File already exists – nothing created: %s\n' "$REPORT_PATH" >&2
  exit 1
fi

# ---------------------------------------------------
# Step 3 – Helper to generate the markdown template
# ---------------------------------------------------
generate_task_report_md() {
  local TASK_ID="$1"
  local TASK_TITLE="$2"
  local MD_TIMESTAMP
  MD_TIMESTAMP=$(date -u +'%Y-%m-%d %H:%M')
cat <<EOF
<!---
⚠️ **DO NOT DELETE**
🔧 **TASK REPORT USAGE GUIDE**
================================

PURPOSE
-------
This file is the detailed execution log for a single task:
**${TASK_ID}: ${TASK_TITLE}**.
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
    \`executionLog.md\` Task Board.

SITUATION REPORT TEMPLATE (Copy/paste to log an update)
-------------------------------------------------------
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

*Created UTC:* \`${MD_TIMESTAMP}\`

## Situation & Context

...

### HIGH‑LEVEL CONTEXT (WEBSITES, FILE PATHS, CLASSES, METHODS, etc.)

...

## Objective & Purpose

...

## Scope & Boundaries

| ✅ **In Scope & Affected Areas** | 🚫 **Out of Scope & Unaffected Areas** |
| :----------------------------- | :------------------------------------- |
| [Describe in‑scope items here] | [Describe out‑of‑scope items here]     |

## Execution & Implementation Plan

### Implementation Plan

* ...

### Detailed Execution Phases, Steps, Implementations

* [ ] ...

### ✍️ Situation & Decision Reports

*No reports yet.*

### Sign‑off
*   **Result:** \`[Approved / Approved with comments / Rejected]\`
*   **Commit:** \`<type>[optional scope]: <description>\`
*   **Comments:**
    > ...

---
EOF
}

# ---------------------------------------------------
# Step 4 – Write the file
# ---------------------------------------------------
generate_task_report_md "$TASK_ID" "$TASK_TITLE" > "$REPORT_PATH"
printf '✅ Created: %s\n' "$REPORT_PATH"
