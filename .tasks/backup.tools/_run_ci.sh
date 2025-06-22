# Filename: .tasks/.tools/_run_ci.sh
#!/usr/bin/env bash
# =============================================================================
# _run_ci.sh – Fail-fast CI script orchestrator.
#
# Runs a sequence of CI check scripts. By default, it operates in "fail-fast"
# mode, halting the entire run as soon as any single check fails.
#
# Each `ci_*` script is responsible for providing its own detailed feedback
# on success or failure. This script's job is to orchestrate them.
#
# Options:
#   --continue  - If present, runs ALL checks and reports all failures at the end.
#   --list      - Lists the scripts that would be run, then exits.
# =============================================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# --- CI Script Configuration ---
# The order of scripts in this array defines the execution order.
declare -a CI_SCRIPTS=(
  "ci_check_situation_reports.sh"
  "ci_find_large_changed_files.sh"
  "ci_infra_lint_build.sh"
  "ci_python_lint.sh"
  "ci_view_commit_changes.sh"
)
# -----------------------------

# Argument Parsing
CONTINUE_ON_FAILURE=false
if [[ "${1:-}" == "--continue" || "${1:-}" == "-c" ]]; then
  CONTINUE_ON_FAILURE=true
elif [[ "${1:-}" == "--list" || "${1:-}" == "-l" ]]; then
  printf 'CI scripts that will be run (in order):\n'
  for script_name in "${CI_SCRIPTS[@]}"; do
    printf -- "- %s\n" "$script_name"
  done
  printf '\nOK\n'
  exit 0
fi

# --- Main Execution Loop ---
TOTAL_FAILURES=0
for script_name in "${CI_SCRIPTS[@]}"; do
  script_path="${SCRIPT_DIR}/${script_name}"

  if [[ ! -x "$script_path" ]]; then
    printf '⚠️  Skipping missing or non-executable script: %s\n' "$script_name" >&2
    continue
  fi

  printf '────────────────────────────────────────────────────────\n'
  printf '▶️  Running: %s\n\n' "$script_name"

  # Execute the script. Let it print its own output directly.
  set +e
  "$script_path"
  exit_code=$?
  set -e

  if [[ $exit_code -ne 0 ]]; then
    printf '\n   ❌ %s FAILED (exit code %d).\n' "$script_name" "$exit_code" >&2
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
    if ! $CONTINUE_ON_FAILURE; then
      # FAIL-FAST MODE (DEFAULT): Abort the entire run now.
      printf '────────────────────────────────────────────────────────\n' >&2
      printf '⛔ Aborting CI run due to first failure.\n' >&2
      exit 1
    fi
  else
    printf '\n   ✅ %s PASSED.\n' "$script_name"
  fi
done

# --- Final Summary (only reached if --continue was used or all passed) ---
printf '────────────────────────────────────────────────────────\n'
if [[ $TOTAL_FAILURES -gt 0 ]]; then
  printf '❌ CI run finished with %d failure(s).\n' "$TOTAL_FAILURES"
  exit 1
else
  printf '✅ All CI checks passed successfully.\n'
  printf 'OK\n'
fi