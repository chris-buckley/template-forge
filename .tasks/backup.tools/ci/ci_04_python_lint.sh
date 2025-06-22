# .tasks/.tools/run_python_lint.sh
# =============================================================================
# run_python_lint.sh – Perform Ruff‑based lint checks (and optional auto‑fixes)
#                      on a Python codebase, outputting a JSON report path as
#                      its **final, parse‑friendly line**.
#
# Compatible with Bash 4+ on Linux, macOS, WSL and Git‑for‑Windows.
# =============================================================================

set -Eeuo pipefail

#--------------------------------------
# 0 – Locate this script & config file
#--------------------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_FILE="${SCRIPT_DIR}/_tool_config.yaml"

#--------------------------------------
# 1 – Helper: print usage & exit
#--------------------------------------
usage() {
  cat >&2 <<EOF
Usage: $0 [options]

Options:
  -t|--target <dir|file>   Path to scan (defaults to project root)
  -f|--fix                 Apply Ruff's --fix option
  -o|--output <file>       Write JSON report to <file>
  -h|--help                Show this help and exit

The final line printed to STDOUT will be the absolute path to the JSON report.
The script exits with Ruff's exit code (0 = clean, 1 = violations, 2 = error).
EOF
  exit 1
}

#--------------------------------------
# 2 – Parse CLI arguments
#--------------------------------------
TARGET_PATH=""
OUTPUT_FILE=""
FIX=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--target)
      [[ $# -lt 2 ]] && usage
      TARGET_PATH="$2"; shift 2 ;;
    -f|--fix)
      FIX=true; shift ;;
    -o|--output)
      [[ $# -lt 2 ]] && usage
      OUTPUT_FILE="$2"; shift 2 ;;
    -h|--help)
      usage ;;
    *) usage ;;
  esac
done

#--------------------------------------
# 3 – Determine project root (if needed)
#--------------------------------------
if [[ -z "$TARGET_PATH" ]]; then
  if [[ ! -f "$CONFIG_FILE" ]]; then
    printf '❌ Config file not found: %s\n' "$CONFIG_FILE" >&2; exit 1
  fi
  get_yaml_value() {
    grep -E "^\s*$1\s*:" "$CONFIG_FILE" | \
      sed -E 's/^[^:]+:\s*//; s/\s*#.*$//; s/^\s*|\s*$//g'
  }
  ROOT_RELATIVE=$(get_yaml_value "root_directory_relative_from_this_directory")
  [[ -z "$ROOT_RELATIVE" ]] && \
    { printf '❌ Malformed config file.\n' >&2; exit 1; }
  TARGET_PATH="$(cd "${SCRIPT_DIR}/${ROOT_RELATIVE}" && pwd -P)"
fi

if [[ ! -e "$TARGET_PATH" ]]; then
  printf '❌ Target path does not exist: %s\n' "$TARGET_PATH" >&2
  exit 1
fi

#--------------------------------------
# 4 – Dependency check
#--------------------------------------
if ! command -v ruff >/dev/null 2>&1; then
  printf '❌ Ruff is not installed. Install with: python -m pip install ruff\n' >&2
  exit 1
fi

#--------------------------------------
# 5 – Determine output file
#--------------------------------------
if [[ -z "$OUTPUT_FILE" ]]; then
  timestamp="$(date -u +'%Y%m%d-%H%M%S')"
  OUTPUT_FILE="$(pwd)/ruff_report_${timestamp}.json"
fi
OUTPUT_FILE="$(cd -- "$(dirname -- "$OUTPUT_FILE")" && pwd -P)/$(basename -- "$OUTPUT_FILE")"

# Ensure directory exists & is writable
mkdir -p -- "$(dirname -- "$OUTPUT_FILE")"

printf '▶️  Running Ruff on: %s\n' "$TARGET_PATH"
printf '▶️  Report will be written to: %s\n' "$OUTPUT_FILE"
$FIX && printf '▶️  Auto‑fix mode enabled.\n'

#--------------------------------------
# 6 – Execute Ruff (capture exit without aborting)
#--------------------------------------
set +e
CMD=(ruff check "$TARGET_PATH" --output-format json)
$FIX && CMD+=(--fix)

"${CMD[@]}" > "$OUTPUT_FILE"
RUFF_EXIT=$?
set -e

case $RUFF_EXIT in
  0) printf '✅ No violations found.\n' ;;
  1) printf '⚠️  Violations detected – see report.\n' ;;
  2) printf '❌ Ruff encountered an internal error (see report).\n' ;;
esac

#--------------------------------------
# 7 – FINAL OUTPUT (for agent consumption)
#--------------------------------------
printf '%s\n' "$OUTPUT_FILE"

exit "$RUFF_EXIT"
