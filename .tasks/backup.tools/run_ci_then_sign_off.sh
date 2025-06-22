# Filename: .tasks/.tools/run_ci_then_sign_off.sh
#!/usr/bin/env bash
# =============================================================================
# run_ci_then_sign_off.sh – Run the full CI suite, and upon success,
# perform a task sign-off. (v3 - Fail-Fast)
#
# This script uses the fail-fast CI orchestrator. It will halt on the
# first CI error, providing immediate, specific feedback.
# =============================================================================

set -Eeuo pipefail

# --- (Argument validation and script location logic remains unchanged) ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CI_SCRIPT="${SCRIPT_DIR}/_run_ci.sh"
SIGN_SCRIPT="${SCRIPT_DIR}/task_sign_off.sh"

[[ -x "$CI_SCRIPT"   ]] || { printf '❌ Missing or non-exec: %s\n' "$CI_SCRIPT" >&2; exit 2; }
[[ -x "$SIGN_SCRIPT" ]] || { printf '❌ Missing or non-exec: %s\n' "$SIGN_SCRIPT" >&2; exit 2; }

if [[ $# -lt 5 ]]; then
  cat >&2 <<'EOF'
❌ Error: Missing arguments. See usage in script source.
EOF
  exit 2
fi
declare -a SIGN_ARGS=("$@")
# --- (End of unchanged section) ---

################################################################################
# 2. Phase 1: Run CI Suite (in Fail-Fast Mode)
################################################################################
printf '▶️  Phase 1 – Running all CI checks (fail-fast mode)...\n'

# CRITICAL CHANGE: We no longer pass --continue.
# This makes the CI run stop at the very first error.
set +e
"$CI_SCRIPT"
CI_EXIT=$?
set -e

if [[ $CI_EXIT -ne 0 ]]; then
  # The _run_ci.sh script has already printed the specific error.
  # We just provide the final, parsable "FAIL" token.
  printf 'FAIL:CI\n'
  exit 1
fi

# If we get here, _run_ci.sh printed "✅ All CI checks passed successfully."
# and "OK". We proceed to the next phase.

################################################################################
# 3. Phase 2: Run Task Sign-off
################################################################################
printf '────────────────────────────────────────────────────────\n'
printf '▶️  Phase 2 – Performing task sign-off…\n'

# This part remains the same.
SIGN_STDOUT=$(mktemp)
SIGN_STDERR=$(mktemp)
trap 'rm -f "${SIGN_STDOUT:-}" "${SIGN_STDERR:-}"' EXIT

set +e
"$SIGN_SCRIPT" "${SIGN_ARGS[@]}" >"$SIGN_STDOUT" 2>"$SIGN_STDERR"
SIGN_EXIT=$?
set -e

if [[ $SIGN_EXIT -ne 0 ]]; then
  [[ -s "$SIGN_STDERR" ]] && cat "$SIGN_STDERR" >&2
  printf 'FAIL:SIGNOFF\n'
  exit 1
fi

cat "$SIGN_STDOUT"
printf 'OK\n'