#!/usr/bin/env bash
# =========================================================================
# ctx_view_commit_changes.sh – Show recent commit subjects plus each file
#                             changed (with status codes), without paging.
#
# MODIFIED: This script now requires the project root path as its first
# argument and the number of commits as the second. This removes its
# dependency on its own location or any configuration files.
#
# Usage:
#   ctx_view_commit_changes.sh /path/to/project/root <number-of-commits>
#
# =========================================================================

set -Eeuo pipefail

# ---------------------------------------------------
# 1 – Parse required arguments
# ---------------------------------------------------
if [[ $# -lt 2 ]]; then
  printf '❌ Error: Missing required arguments.\n' >&2
  printf 'Usage: %s /path/to/project/root <NUM_COMMITS>\n' "$(basename "$0")" >&2
  exit 1
fi

PROJECT_ROOT="$1"
NUM_COMMITS="$2"

# ---------------------------------------------------
# 2 – Validate Arguments
# ---------------------------------------------------
if ! [[ "$NUM_COMMITS" =~ ^[0-9]+$ ]] || [[ "$NUM_COMMITS" -le 0 ]]; then
  printf '❌ Error: <number-of-commits> must be a positive integer.\n' >&2
  exit 1
fi

if [[ ! -d "$PROJECT_ROOT" ]]; then
  printf '❌ Error: Provided project root path is not a valid directory: %s\n' "$PROJECT_ROOT" >&2
  exit 1
fi

# Ensure the target directory is a Git repository before proceeding.
if ! git -C "$PROJECT_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf '❌ Error: The directory "%s" is not inside a Git repository.\n' "$PROJECT_ROOT" >&2
  exit 1
fi


# ---------------------------------------------------
# 3 – Output commit hash + subject + status/file list
#     `--no-pager` prevents Git from spawning `less`.
#     `git -C` runs the command from the specified project root
#     without changing the script's working directory.
# ---------------------------------------------------
git -C "$PROJECT_ROOT" --no-pager log -n "$NUM_COMMITS" \
  --no-merges \
  --pretty=format:'%h  %ad  | %s%d [%an]' \
  --date=short \
  --name-status