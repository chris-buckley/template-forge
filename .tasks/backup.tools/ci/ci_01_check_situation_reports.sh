#!/usr/bin/env bash
# =============================================================================
# ci_check_situation_reports.sh – Verify that every **Situation Report**
# in every task‑markdown file has its **Status** set to ✅ Complete.
#
# * Scans markdown files (default: all under the task directory configured in
#   `_tool_config.yaml`).  A custom root may be supplied with `--dir`.
# * Ignores any Status lines that appear **inside fenced code‑blocks** – so the
#   template snippet doesn’t trigger false alarms.
# * If it finds at least one report whose status is not ✅, it prints the list
#   of offending files (optionally with the line number), then **exits 1**.
#   Otherwise it exits 0.
#
# The last thing printed (if any failures) is therefore a clean,
# newline‑delimited list of absolute file paths – ideal for the agent.
#
# Compatible with Bash 4+ on Linux, macOS, WSL and Git‑for‑Windows.
# =============================================================================

set -Eeuo pipefail

###############################################################################
# 1. Usage & argument parsing
###############################################################################
usage() {
  cat >&2 <<EOF
Usage: $0 [--dir <directory>]

Checks that all *real* Situation Reports (those outside fenced code blocks)
have "**Status:** ✅".

Options
  --dir <directory>   Directory to scan instead of the default tasks folder
  -h, --help          Show this help and exit

Exit codes
  0  All reports complete (✅)
  1  At least one report is not ✅
  2  Script error (bad args, config missing, etc.)
EOF
  exit 2
}

SCAN_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      [[ $# -lt 2 ]] && usage
      SCAN_DIR=$2; shift 2 ;;
    -h|--help)
      usage ;;
    *)
      printf '❌ Unknown option: %s\n' "$1" >&2
      usage ;;
  esac
done

###############################################################################
# 2. Locate config & resolve default task directory (if needed)
###############################################################################
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_FILE="${SCRIPT_DIR}/_tool_config.yaml"

if [[ -z "$SCAN_DIR" ]]; then
  [[ -f "$CONFIG_FILE" ]] || { printf '❌ Config not found: %s\n' "$CONFIG_FILE" >&2; exit 2; }
  get_yaml_value() {
    grep -E "^\s*$1\s*:" "$CONFIG_FILE" \
      | sed -E 's/^[^:]+:\s*//; s/\s*#.*$//; s/^\s*|\s*$//g'
  }
  ROOT_RELATIVE=$(get_yaml_value "root_directory_relative_from_this_directory")
  TASK_DIR_RELATIVE=$(get_yaml_value "task_directory_relative_from_root")

  if [[ -z "$ROOT_RELATIVE" || -z "$TASK_DIR_RELATIVE" ]]; then
    printf '❌ Config file missing required keys.\n' >&2; exit 2
  fi
  PROJECT_ROOT="$(cd "${SCRIPT_DIR}/${ROOT_RELATIVE}" && pwd -P)"
  SCAN_DIR="${PROJECT_ROOT}/${TASK_DIR_RELATIVE}"
fi

[[ -d "$SCAN_DIR" ]] || { printf '❌ Directory not found: %s\n' "$SCAN_DIR" >&2; exit 2; }

###############################################################################
# 3. Discover markdown files
###############################################################################
mapfile -t MD_FILES < <(find "$SCAN_DIR" -type f -name '*.md' | sort)

[[ ${#MD_FILES[@]} -eq 0 ]] && { printf '✅ No markdown files to scan.\n'; exit 0; }

###############################################################################
# 4. Analyse each file with awk
###############################################################################
offender_count=0
offending_files_list=""

for file in "${MD_FILES[@]}"; do
  # The AWK script returns 1 if it finds an incomplete report, 0 otherwise.
  # Its stderr is preserved to show which line failed.
  if ! awk '
    BEGIN { inside_code=0; awaiting_status=0; bad=0 }
    function ltrim(s) { sub(/^[[:space:]]*/, "", s); return s }
    /^```/      { inside_code = !inside_code; next }
    {
      if (!inside_code) {
        if ($0 ~ /^\*\*Situation Report:/) { awaiting_status=1 }
        else if (awaiting_status && $0 ~ /^\*+[[:space:]]+\*\*Status:\*\*/) {
          awaiting_status=0
          line = ltrim($0)
          if (line !~ /✅/) { bad=1; print FNR ":" line > "/dev/stderr" }
        }
      }
    }
    END { exit bad }
  ' "$file" >/dev/null; then
    # On the first failure, print the header for the user.
    if [[ $offender_count -eq 0 ]]; then
      printf '❌ Incomplete Situation Reports found:\n' >&2
    fi

    absolute_path="$(cd -- "$(dirname -- "$file")" && pwd -P)/$(basename -- "$file")"
    printf '  • %s\n' "$absolute_path" >&2
    offending_files_list+="${absolute_path}"$'\n'
    ((offender_count++))
  fi
done

###############################################################################
# 5. Final output
###############################################################################
if [[ $offender_count -eq 0 ]]; then
  printf '✅ All Situation Reports are marked ✅.\n'
  printf '\n'      # predictable empty line for the agent
  exit 0
else
  printf '\n'       # FINAL agent‑consumable data (absolute paths)
  printf '%s' "${offending_files_list}"
  exit 1
fi