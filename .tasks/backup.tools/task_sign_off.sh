#!/usr/bin/env bash
# =========================================================================
# task_sign_off.sh – Final‑approval helper with dashboard auto‑sync (v4)
# =========================================================================

set -Eeuo pipefail

# ────────────────────────────────────────────────────────────────────────────
# 1. CLI validation
# ────────────────────────────────────────────────────────────────────────────
if [[ $# -lt 5 ]]; then
  cat >&2 <<'USAGE'
❌  Error – missing arguments.

Usage:
  task_sign_off.sh "<folder_name>" "T-XX" "<Approved|Approved with comments|Rejected>" "<commit_message>" "<comments>"
USAGE
  exit 1
fi

FOLDER_NAME=$1
TASK_ID_RAW=$2
RESULT_RAW=$3
COMMIT_MSG=$4
COMMENTS=$5

[[ "$TASK_ID_RAW" =~ ^T-[0-9]{2}$ ]] \
  || { printf '❌ Task‑ID must be T-01..T-99 (got: %s)\n' "$TASK_ID_RAW" >&2; exit 1; }
TASK_ID="$TASK_ID_RAW"

case "$RESULT_RAW" in
  "Approved"|"Approved with comments"|"Rejected") RESULT="$RESULT_RAW" ;;
  *) printf '❌ Result must be: Approved | Approved with comments | Rejected (got: %s)\n' "$RESULT_RAW" >&2; exit 1 ;;
esac
[[ -n "$COMMIT_MSG" ]] || { printf '❌ Commit message is empty.\n' >&2; exit 1; }

# ────────────────────────────────────────────────────────────────────────────
# 2. Locate project structure via YAML
# ────────────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_FILE="${SCRIPT_DIR}/_tool_config.yaml"
[[ -f "$CONFIG_FILE" ]] || { printf '❌ Config file not found: %s\n' "$CONFIG_FILE" >&2; exit 1; }

yaml() { grep -E "^\s*$1\s*:" "$CONFIG_FILE" | sed -E 's/^[^:]+:\s*//; s/#.*$//; s/^[[:space:]]+|[[:space:]]+$//g'; }
ROOT_REL=$(yaml root_directory_relative_from_this_directory)
TASK_REL=$(yaml task_directory_relative_from_root)
[[ -n "$ROOT_REL" && -n "$TASK_REL" ]] || { printf '❌ Config keys missing.\n' >&2; exit 1; }

PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/${ROOT_REL}" && pwd -P)"
TASK_DIR="${PROJECT_ROOT}/${TASK_REL}/${FOLDER_NAME}"
[[ -d "$TASK_DIR" ]] || { printf '❌ Task folder not found: %s\n' "$TASK_DIR" >&2; exit 1; }

EXEC_LOG="${TASK_DIR}/executionLog.md"
REPORT_FILE="${TASK_DIR}/${TASK_ID}_task_execution_report.md"
[[ -f "$EXEC_LOG" ]] || { printf '❌ executionLog.md missing.\n' >&2; exit 1; }
[[ -f "$REPORT_FILE" ]] || { printf '❌ %s missing.\n' "$(basename "$REPORT_FILE")" >&2; exit 1; }

# ────────────────────────────────────────────────────────────────────────────
# 3. Build sign‑off block
# ────────────────────────────────────────────────────────────────────────────
UTC_NOW="$(date -u '+%Y-%m-%d %H:%M')"
SIGN_OFF_BLOCK=$(cat <<EOF
### Sign‑off
*   **Result:** \`$RESULT\`
*   **Commit:** \`$COMMIT_MSG\`
*   **Comments:**
    > $(printf '%s\n' "$COMMENTS")
EOF
)

# ────────────────────────────────────────────────────────────────────────────
# 4. Update individual task report
# ────────────────────────────────────────────────────────────────────────────
TMP_REPORT="$(mktemp)"
awk -v block="$SIGN_OFF_BLOCK" '
{ sub(/\r$/, "") }
BEGIN          { done=0 }
/^### Sign‑off/ { print block; skip=1; next }
/^---[[:space:]]*$/ && skip { print; skip=0; done=1; next }
skip           { next }
{ print }
END            { if(done==0){ print ""; print block; print "" } }
' "$REPORT_FILE" >"$TMP_REPORT"
mv "$TMP_REPORT" "$REPORT_FILE"

# ────────────────────────────────────────────────────────────────────────────
# 5. Patch Task Board row (✅ + timestamp)
# ────────────────────────────────────────────────────────────────────────────
TMP_EXEC="$(mktemp)"
awk -v id="$TASK_ID" -v ts="$UTC_NOW" '
{ sub(/\r$/, "") }
BEGIN { FS=OFS="|"; changed=0 }
/^\|/ && $2 ~ "^[[:space:]]*"id"[[:space:]]*$" {
     $4=" ✅ Complete ";
     $6=" "ts" ";
     changed=1;
}
{ print }
END { if (changed==0) exit 42 }
' "$EXEC_LOG" >"$TMP_EXEC" || { rm -f "$TMP_EXEC"; printf '❌ No Task Board row for %s.\n' "$TASK_ID" >&2; exit 42; }
mv "$TMP_EXEC" "$EXEC_LOG"

# ────────────────────────────────────────────────────────────────────────────
# 6. Re‑calculate and replace At‑a‑Glance Dashboard
#    (status detection based on English words, not emoji)
# ────────────────────────────────────────────────────────────────────────────
read COMPLETED INPROG AWAIT TODO BLOCKED TOTAL <<<"$(awk '
{ sub(/\r$/, "") }
BEGIN { FS="|"; c=p=a=t=b=tot=0 }
/^\|/ && $2 ~ /^[[:space:]]*T-[0-9]{2}[[:space:]]*$/ {
  tot++
  s=tolower($4)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
  if(s ~ /complete/)            c++
  else if(s ~ /in[[:space:]]*progress/) p++
  else if(s ~ /await/)           a++
  else if(s ~ /to-?[[:space:]]*do/)  t++
  else if(s ~ /blocked/)         b++
}
END { print c,p,a,t,b,tot }
' "$EXEC_LOG")"

if (( BLOCKED > 0 ));        then OVERALL="🚧 **Blocked**"
elif (( INPROG > 0 ));       then OVERALL="▶️ **In Progress**"
elif (( TODO + AWAIT > 0 )); then OVERALL="📋 **To-Do**"
else                              OVERALL="✅ **Complete**"
fi
CRITICAL=$([[ $BLOCKED -gt 0 ]] && echo "🚧 Issues" || echo "✅ None")

DASH_BLOCK=$(cat <<EOF
| Metric             | Value             |
| :----------------- | :---------------- |
| **Overall Status** | $OVERALL |
| ✅ Completed       | $COMPLETED |
| ▶️ In Progress     | $INPROG |
| ⏳ Awaiting Sign-off | $AWAIT |
| 📋 To-Do           | $TODO |
| **Critical Issues**| $CRITICAL |
| **Last Update**    | $UTC_NOW |
EOF
)

TMP_EXEC2="$(mktemp)"
awk -v dash="$DASH_BLOCK" '
{ sub(/\r$/, "") }
BEGIN { inDash=0; done=0 }
/^##/ && index($0,"📊") && $0 ~ /[Aa]t/ {
    print; inDash=1; next
}
inDash {
    if ($0 ~ /^[[:space:]]*---[[:space:]]*$/) {
        print dash
        print "---"
        inDash=0; done=1; next
    }
    next
}
{ print }
END { if(done==0) exit 43 }
' "$EXEC_LOG" >"$TMP_EXEC2" || {
    rm -f "$TMP_EXEC2"
    printf '❌ At‑a‑Glance Dashboard header or end‑marker not found – no update.\n' >&2
    exit 43
}
mv "$TMP_EXEC2" "$EXEC_LOG"

# ────────────────────────────────────────────────────────────────────────────
# 7. Summary
# ────────────────────────────────────────────────────────────────────────────
cat <<SUMMARY
✓ Sign‑off written        : $(basename "$REPORT_FILE")
✓ Task Board row updated  : $(basename "$EXEC_LOG")
✓ Dashboard synchronised  : Completed=$COMPLETED  In‑Progress=$INPROG  Awaiting=$AWAIT  To‑Do=$TODO  Blocked=$BLOCKED
✓ Overall Status          : ${OVERALL//\`/}
✓ Time (UTC)              : $UTC_NOW
SUMMARY
