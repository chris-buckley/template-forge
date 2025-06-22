# .tasks/.tools/ci_infra_lint_build.sh
#!/usr/bin/env bash
# =============================================================================
# ci_infra_lint_build.sh – Format, lint and *compile* every Bicep file in the
# project’s infra directory to guarantee syntax and style correctness.
#
# * No ARM deployments are executed – this is an offline CI safety check.
# * Default infra folder is resolved via `_tool_config.yaml`; override with
#   `--dir`.
# * Exit codes
#       0  All good
#       1  Formatting or compile errors detected
#       2  Script misuse / configuration error
#
# Compatible with Bash 4+ on Linux, macOS, WSL and Git‑for‑Windows.
# =============================================================================

set -Eeuo pipefail

###############################################################################
# 0. Locate ourselves & configuration
###############################################################################
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_FILE="${SCRIPT_DIR}/_tool_config.yaml"

###############################################################################
# 1. CLI parsing
###############################################################################
FIX=false        # default: do NOT rewrite files
INFRA_DIR=""

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [options]

Options
  -f, --fix           Apply \`bicep format\` in-place (defaults to check‑only)
  --dir <path>        Override infra directory
  -h, --help          Show this help

Exit codes
  0  All checks passed
  1  Formatting or build failures
  2  Script/configuration error
EOF
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--fix) FIX=true; shift ;;
    --dir)
      [[ $# -lt 2 ]] && usage
      INFRA_DIR=$2; shift 2 ;;
    -h|--help) usage ;;
    *) printf '❌ Unknown argument: %s\n' "$1" >&2; usage ;;
  esac
done

###############################################################################
# 2. Resolve infra directory (if not supplied)
###############################################################################
if [[ -z "$INFRA_DIR" ]]; then
  [[ -f "$CONFIG_FILE" ]] \
    || { printf '❌ Config not found: %s\n' "$CONFIG_FILE" >&2; exit 2; }

  get_yaml() {
    grep -E "^\s*$1\s*:" "$CONFIG_FILE" \
      | sed -E 's/^[^:]+:\s*//; s/\s*#.*$//; s/^\s*|\s*$//g'
  }

  ROOT_REL=$(get_yaml root_directory_relative_from_this_directory)
  INFRA_REL=$(get_yaml infra_directory_relative_from_root)

  [[ -n "$ROOT_REL" && -n "$INFRA_REL" ]] \
    || { printf '❌ Config missing required keys.\n' >&2; exit 2; }

  PROJECT_ROOT="$(cd "${SCRIPT_DIR}/${ROOT_REL}" && pwd -P)"
  INFRA_DIR="${PROJECT_ROOT}/${INFRA_REL}"
fi

[[ -d "$INFRA_DIR" ]] \
  || { printf '❌ Infra directory not found: %s\n' "$INFRA_DIR" >&2; exit 2; }

###############################################################################
# 3. Dependency checks
###############################################################################
command -v az     >/dev/null 2>&1 \
  || { printf '❌ Azure CLI (az) not found in PATH.\n' >&2; exit 2; }
command -v bicep  >/dev/null 2>&1 \
  || { printf '❌ Bicep CLI not found. Install via "az bicep install".\n' >&2; exit 2; }

###############################################################################
# 4. Discover Bicep files
###############################################################################
printf '🔍 Scanning infra directory: %s\n' "$INFRA_DIR"
mapfile -t BICEP_FILES < <(find "$INFRA_DIR" -type f -name '*.bicep' | sort)

if [[ ${#BICEP_FILES[@]} -eq 0 ]]; then
  printf '✅ No *.bicep files detected – nothing to lint/build.\n'
  printf '\n'
  exit 0
fi

###############################################################################
# 5. Formatting phase
###############################################################################
format_offenders=()
if $FIX; then
  printf '🛠️  Formatting Bicep files in place …\n'
  bicep format "$INFRA_DIR"
else
  printf '🔎 Checking formatting (no changes made) …\n'
  set +e
  fmt_output=$(bicep format --check "$INFRA_DIR" 2>&1)
  fmt_status=$?
  set -e

  if [[ $fmt_status -eq 2 ]]; then
    printf '❌ Formatting issues detected:\n'
    # Extract file paths mentioned by the formatter
    while IFS= read -r line; do
      [[ $line =~ ([^[:space:]]+\.bicep) ]] || continue
      file="${BASH_REMATCH[1]}"
      # Normalise to absolute path
      [[ "$file" != /* ]] && file="${INFRA_DIR}/${file}"
      format_offenders+=("$(cd -- "$(dirname -- "$file")" && pwd -P)/$(basename -- "$file")")
      printf '  • %s\n' "$file"
    done <<< "$fmt_output"
  elif [[ $fmt_status -eq 0 ]]; then
    printf '✅ Formatting clean.\n'
  else
    printf '❌ bicep format failed with exit code %d\n' "$fmt_status" >&2
    printf '\n'; exit 1
  fi
fi

###############################################################################
# 6. Build/compile phase
###############################################################################
compile_offenders=()
printf '🔨 Compiling each Bicep file …\n'
for file in "${BICEP_FILES[@]}"; do
  set +e
  az bicep build --file "$file" --stdout >/dev/null 2>&1
  status=$?
  set -e
  if [[ $status -ne 0 ]]; then
    compile_offenders+=("$(cd -- "$(dirname -- "$file")" && pwd -P)/$(basename -- "$file")")
    printf '  ⚠️  Build failed: %s\n' "$file"
  fi
done

###############################################################################
# 7. Final evaluation & output
###############################################################################
declare -A uniq
for p in "${format_offenders[@]}" "${compile_offenders[@]}"; do
  [[ -n "$p" ]] && uniq["$p"]=1
done
mapfile -t FAILURES < <(printf '%s\n' "${!uniq[@]}" | sort)

if [[ ${#FAILURES[@]} -eq 0 ]]; then
  printf '✅ Infra lint & build checks passed.\n'
  printf '\n'
  exit 0
else
  printf '❌ Infra checks failed (%d file(s)).\n' "${#FAILURES[@]}" >&2
  printf '\n'
  printf '%s\n' "${FAILURES[@]}"
  exit 1
fi
