#!/usr/bin/env bash
# ============================================================================
# _initialize_ctx.sh – Initialise “what’s going on here?” context for an agent
#
# Changes  ───────────────────────────────────────────────────────────────────
#   • Auto‑discovers every executable ctx_*.sh in ctx_init/ and runs them in
#     alphabetical order (typically by numeric prefix).
#   • Eliminates all hard‑coded paths for individual context scripts.
#   • Adds small helpers (title derivation, safe execution wrapper) so the
#     file is easier to extend and maintain.
#   • Retains IDENTICAL final output ‑ the same Markdown sections produced by
#     the individual ctx_*.sh scripts followed by the absolute project root
#     path on the very last line.
# ============================================================================

set -Eeuo pipefail

##############################################################################
# 0. Locate ourselves & key paths
##############################################################################
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_FILE="${SCRIPT_DIR}/_tool_config.yaml"

##############################################################################
# 1. CLI parsing
##############################################################################
NUM_COMMITS=10

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--commits <N>] [--help]

Options
  --commits <N>   Show the last <N> commits in ctx_01_view_commit_changes.sh
                  (default: 10)
  -h, --help      Show this help

All other args are ignored.  The script exits non‑zero on failure.
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --commits)
      [[ $# -lt 2 || ! $2 =~ ^[0-9]+$ || $2 -le 0 ]] && usage
      NUM_COMMITS=$2; shift 2 ;;
    -h|--help) usage ;;
    *) printf '⚠️  Ignoring unknown argument: %s\n' "$1" >&2; shift ;;
  esac
done

##############################################################################
# 2. Safety checks common to all runs
##############################################################################
[[ -f "$CONFIG_FILE" ]] || { printf '❌ Config not found: %s\n' "$CONFIG_FILE" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { printf '❌ git not in PATH.\n' >&2; exit 1; }

##############################################################################
# 3. Tiny YAML helper
##############################################################################
get_yaml_value() {
  grep -E "^\s*$1\s*:" "$CONFIG_FILE" \
    | sed -E 's/^[^:]+:\s*//; s/\s*#.*$//; s/^\s+|\s+$//g'
}

##############################################################################
# 4. Resolve project‑root & ctx_init directory
##############################################################################
ROOT_RELATIVE=$(get_yaml_value "root_directory_relative_from_this_directory")
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/${ROOT_RELATIVE:-.}" && pwd -P)"

CTX_DIR_RELATIVE=$(get_yaml_value "ctx_directory_relative_from_root")
CTX_DIR="${PROJECT_ROOT}/${CTX_DIR_RELATIVE}"

[[ -d "$CTX_DIR" ]] || { printf '❌ ctx_init directory not found: %s\n' "$CTX_DIR" >&2; exit 1; }

##############################################################################
# 5. Discover ctx_init scripts (executable, single level, sorted)
##############################################################################
mapfile -t CTX_SCRIPTS < <(
  find "$CTX_DIR" -maxdepth 1 -type f -name 'ctx_*.sh' -perm -u+x | sort
)

[[ ${#CTX_SCRIPTS[@]} -gt 0 ]] || {
  printf '❌ No ctx_*.sh scripts found in %s\n' "$CTX_DIR" >&2
  exit 1
}

##############################################################################
# 6. Helper: produce a human‑readable section title from the filename
##############################################################################
derive_title() {
  local fname="$1"                           # e.g. ctx_02_get_directory_tree.sh
  fname="${fname##*/}"                       # → ctx_02_get_directory_tree.sh
  fname="${fname%.sh}"                       # → ctx_02_get_directory_tree
  fname="${fname#ctx_}"                      # → 02_get_directory_tree
  fname="${fname#[0-9][0-9]_}"               # → get_directory_tree
  fname="${fname//_/ }"                      # → get directory tree
  # Capitalise first letter
  printf '%s%s' "$(tr '[:lower:]' '[:upper:]' <<< "${fname:0:1}")" "${fname:1}"
}

##############################################################################
# 7. Run each ctx script in turn
##############################################################################
section_no=1
for script in "${CTX_SCRIPTS[@]}"; do
  title="$(derive_title "$script")"

  printf '\n## %d. %s\n\n' "$section_no" "$title"

  # Optional extra narrative for well‑known scripts
  case "$(basename "$script")" in
    *get_directory_tree*) printf 'Below is the directory tree of the project, showing the structure and contents:\n\n' ;;
  esac

  # Some scripts (e.g. the commit viewer) expect their output in a code‑block.
  # We detect these by filename pattern; new scripts can self‑format if needed.
  case "$(basename "$script")" in
    *view_commit_changes*) printf '```\n'; "$script" "$PROJECT_ROOT" "$NUM_COMMITS"; printf '```\n' ;;
    *)                     "$script" "$PROJECT_ROOT" "$NUM_COMMITS" ;;
  esac

  ((section_no++))
done

##############################################################################
# 8. Final agent‑parsable datum – **absolute** project root path
##############################################################################
printf '%s\n' "$PROJECT_ROOT"
