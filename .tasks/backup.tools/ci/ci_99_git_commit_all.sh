#!/usr/bin/env bash
# =========================================================================
# git_commit_all.sh – Stage **all** changes in the repo and create
#                     a single commit with the provided message.
#
# Compatible with Bash 4+ on Linux, macOS, WSL and Git‑for‑Windows.
#
# Usage:
#   ./git_commit_all.sh "<commit‑message>"
#
# Example:
#   ./git_commit_all.sh "feat: initial implementation of git commit tool"
# =========================================================================

set -Eeuo pipefail

# ---------------------------------------------------
# Step 1 – Validate command‑line arguments
# ---------------------------------------------------
if [[ $# -lt 1 ]]; then
  printf '❌ Error: Missing commit message.\nUsage: %s "<commit‑message>"\n' "$0" >&2
  exit 1
fi

# Capture *all* supplied words as the commit message
COMMIT_MSG="$*"

# ---------------------------------------------------
# Step 2 – Ensure we’re inside a Git repository
# ---------------------------------------------------
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '❌ Error: This directory is not inside a Git repository.\n' >&2
  exit 1
fi

# ---------------------------------------------------
# Step 3 – Stage changes and create the commit
# ---------------------------------------------------
printf 'Staging all changes …\n'
git add -A

# Nothing staged → bail out gracefully
if git diff --cached --quiet; then
  printf '⚠️  Nothing to commit. Working tree clean.\n'
  exit 0
fi

printf 'Creating commit …\n'
git commit -m "$COMMIT_MSG"
printf '✅ Commit created successfully.\n'
