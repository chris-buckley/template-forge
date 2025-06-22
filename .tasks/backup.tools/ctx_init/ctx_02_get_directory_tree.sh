#!/usr/bin/env bash
# ========================================================================
# ctx_get_directory_tree.sh – Generates a filtered directory tree list.
#
# MODIFIED: This script now accepts the project root path as its first
# command-line argument. This is the required and only way to specify
# the root, making the script independent of its own location.
#
# It scans the specified project root and produces a list of all
# non-ignored files and directories, wrapped in a Markdown code block.
#
# Compatible with Bash 4+ on Linux, macOS, WSL and Git‑for‑Windows.
# ========================================================================

set -Eeuo pipefail

# ---------------------------------------------------
# Step 1 – Define Default Ignore Lists
# ---------------------------------------------------
# Default comprehensive ignore patterns for directories
DEFAULT_IGNORE_DIRS=(
    # .tasks
    '.tasks' '.tools' '.scripts' '.config' '.settings'
    # Python
    '__pycache__' '.pytest_cache' '.mypy_cache' '.ruff_cache'
    '.tox' '.nox' 'htmlcov' '.coverage' '.hypothesis'
    'venv' 'env' '.env' '.venv' 'ENV' 'env.bak' 'venv.bak'
    '*.egg-info' '.eggs' 'build' 'develop-eggs' 'dist' 'downloads'
    'eggs' '.Python' 'pip-wheel-metadata' 'share/python-wheels'
    # Node/React
    'node_modules' '.npm' '.yarn' '.pnp' '.pnp.js'
    # Electron
    'out' '.electron-builder'
    # Vite
    '.vite'
    # Version Control
    '.git' '.svn' '.hg' '.bzr'
    # IDEs
    '.idea' '.vscode' '.vs' '*.swp' '*.swo' '*.swn'
    '.project' '.classpath' '.settings'
    # OS
    '.DS_Store' 'Thumbs.db' 'desktop.ini'
    # Testing/Coverage
    'coverage' '.nyc_output' 'test-results' '.jest'
    # Build/Temp
    'tmp' 'temp' '.tmp' '.temp' '.cache' '.parcel-cache'
)

# Default comprehensive ignore patterns for files
IGNORE_FILES=(
    # Python
    '*.pyc' '*.pyo' '*.pyd' '.Python' '*.so' '*.dylib'
    'pip-log.txt' 'pip-delete-this-directory.txt' '.coverage.*'
    'coverage.xml' '*.cover' '*.log' '.installed.cfg' '*.pot'
    # Node/React
    'npm-debug.log*' 'yarn-debug.log*' 'yarn-error.log*'
    'lerna-debug.log*' '.pnpm-debug.log*' 'package-lock.json'
    'yarn.lock' 'pnpm-lock.yaml'
    # Environment
    '.env' '.env.*' '*.local'
    # OS
    '.DS_Store' 'Thumbs.db' 'ehthumbs.db' 'desktop.ini'
    # Editor
    '*.swp' '*.swo' '*.swn' '*.bak' '~*' '*~'
    '.project' '.classpath' '*.sublime-*'
    # Compiled
    '*.dll' '*.exe' '*.o' '*.obj' '*.class'
    # Archives
    '*.zip' '*.tar' '*.gz' '*.rar' '*.7z'
    # Misc
    '*.pid' '*.seed' '*.pid.lock' '.lock-wscript'
)

# ---------------------------------------------------
# Step 2 – Resolve Root Path from Command-Line Argument
# ---------------------------------------------------
# MODIFIED: Replaced complex root-finding logic with a simple, robust
# argument check. This script now requires the caller to provide the root path.
if [[ $# -eq 0 || -z "$1" ]]; then
  printf '❌ Error: Project root path was not provided as an argument.\n' >&2
  printf 'Usage: %s /path/to/project/root\n' "$(basename "$0")" >&2
  exit 1
fi

PROJECT_ROOT="$1"

if [[ ! -d "$PROJECT_ROOT" ]]; then
  printf '❌ Error: Provided root path "%s" is not a directory or does not exist!\n' "$PROJECT_ROOT" >&2
  exit 1
fi

# ---------------------------------------------------
# Step 3 – Dynamically Build `find` Arguments
# ---------------------------------------------------
# An environment variable can override the default directory ignore list.
if [[ -n "${IGNORE_DIRS_LIST:-}" ]]; then
  IFS=',' read -r -a IGNORE_DIRS <<< "$IGNORE_DIRS_LIST"
else
  IGNORE_DIRS=("${DEFAULT_IGNORE_DIRS[@]}")
fi

# Build `-prune` conditions for ignored directories (basename only)
prune_args=()
for pattern in "${IGNORE_DIRS[@]}"; do
    [[ "$pattern" == *"/"* ]] && continue # silently ignore bad pattern
    prune_args+=(-o -name "$pattern")
done
# The `unset` is a clever way to remove the leading '-o' which would be a syntax error
[[ ${#prune_args[@]} -gt 0 ]] && unset 'prune_args[0]'

# Same idea for the file‑ignore list
ignore_file_args=()
for pattern in "${IGNORE_FILES[@]}"; do
    [[ "$pattern" == *"/"* ]] && continue
    ignore_file_args+=(-o -name "$pattern")
done
[[ ${#ignore_file_args[@]} -gt 0 ]] && unset 'ignore_file_args[0]'


# ---------------------------------------------------
# Step 4 – Execute Main Logic and Format Output
# ---------------------------------------------------
# Use a subshell to avoid changing the script's main working directory
(
  cd "$PROJECT_ROOT"

  # Construct the find command dynamically for robustness
  final_cmd=("find" "." "-path" "./*")

  # Add directory pruning logic. If a directory name matches, prune it (don't enter it).
  if [[ ${#prune_args[@]} -gt 0 ]]; then
      final_cmd+=(-type d \( "${prune_args[@]}" \) -prune)
  fi

  # Add the 'or' operator. For everything not pruned, apply the next set of tests.
  final_cmd+=(-o)

  # Add file ignore logic. Exclude any files matching the ignore patterns.
  if [[ ${#ignore_file_args[@]} -gt 0 ]]; then
      final_cmd+=(! \( "${ignore_file_args[@]}" \))
  fi

  # Always print the items that pass all the filters
  final_cmd+=(-print)

  # MODIFIED: Wrap output in a markdown code block for clean presentation
  printf '```\n'
  # Execute the command, remove the leading './' from paths, and sort the final result.
  "${final_cmd[@]}" | sed 's/^\.\///' | sort
  printf '```\n'
)