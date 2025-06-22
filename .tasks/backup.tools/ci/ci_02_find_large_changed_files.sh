# Filename: .tasks/.tools/ci_find_large_changed_files.sh
#!/usr/bin/env bash
# =============================================================================
# ci_find_large_changed_files.sh – List changed files whose total line-count
#                                   exceeds a configurable threshold. (v2)
#
# * "Changed" = (staged OR unstaged OR new-untracked) relative to <commit>.
# * Files within the `.tasks/` directory are now ignored.
# * If any file exceeds the threshold, the script exits with status 1.
# * Outputs **only** the full, absolute file paths that exceed the threshold
#   as its final, agent-parsable data.
#
# Compatible with Bash 4+ on Linux, macOS, WSL, Git-for-Windows.
# =============================================================================

set -Eeuo pipefail

###############################################################################
# 1. Usage & argument parsing
###############################################################################
usage() {
  cat >&2 <<EOF
Usage: $0 [--since <commit-ish>] [--max-lines <N>] [--count-blank]

Detect changed files (excluding those in .tasks/) whose total line-count
is greater than <N> lines. Exits 1 if any large files are found.

Options
  --since <commit-ish>   Compare working tree against this revision (default: HEAD)
  --max-lines <N>        Threshold line count (default: 300)
  --count-blank          Include blank lines in the count (default: ignore them)
EOF
  exit 2
}

# Defaults
SINCE_REF="HEAD"
MAX_LINES=300
COUNT_BLANK=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --since)
      [[ $# -lt 2 ]] && usage
      SINCE_REF=$2; shift 2 ;;
    --max-lines)
      [[ $# -lt 2 || ! $2 =~ ^[0-9]+$ ]] && usage
      MAX_LINES=$2; shift 2 ;;
    --count-blank)
      COUNT_BLANK=true; shift ;;
    -h|--help) usage ;;
    *) printf '❌ Unknown option: %s\n' "$1" >&2; usage ;;
  esac
done

###############################################################################
# 2. Sanity checks
###############################################################################
command -v git >/dev/null 2>&1 || { printf '❌ git not found in PATH.\n' >&2; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { printf '❌ Not inside a Git repository.\n' >&2; exit 1; }
if ! git rev-parse --quiet --verify "${SINCE_REF}^{commit}" >/dev/null; then
  printf '❌ The reference "%s" is not a valid commit.\n' "$SINCE_REF" >&2
  exit 1
fi

###############################################################################
# 3. Gather candidate files
###############################################################################
# Staged + unstaged (modified / added / renamed / copied) but NOT deleted
mapfile -t diff_files < <(git diff --name-only --diff-filter=ACMR "$SINCE_REF")
# Untracked new files
mapfile -t untracked_files < <(git ls-files --others --exclude-standard)

# Combined unique list
declare -A seen
changed_files=()
for f in "${diff_files[@]}" "${untracked_files[@]}"; do
  [[ -n ${seen["$f"]+1} ]] && continue
  seen["$f"]=1
  [[ -f $f ]] && changed_files+=("$f")
done

if [[ ${#changed_files[@]} -eq 0 ]]; then
  printf '✅ No changed files detected.\n'
  exit 0
fi

###############################################################################
# 4. Analyse line counts
###############################################################################
printf '🔎 Checking line counts (limit: %d lines, ignoring .tasks/ directory)...\n' "$MAX_LINES"

over_limit=()
for file in "${changed_files[@]}"; do
  # FIX: Ignore any file inside the .tasks/ directory
  if [[ "$file" == ".tasks/"* ]]; then
    continue
  fi

  if $COUNT_BLANK; then
    lines=$(wc -l < "$file")
  else
    # Count only non-blank lines
    lines=$(grep -cve '^[[:space:]]*$' -- "$file" || true)
  fi

  if [[ $lines -gt $MAX_LINES ]]; then
    over_limit+=("$file")
    printf '  ⚠️  %s (%d lines)\n' "$file" "$lines" >&2
  fi
done

###############################################################################
# 5. Final output and exit code
###############################################################################
if [[ ${#over_limit[@]} -eq 0 ]]; then
  printf '✅ No large files found.\n'
  printf '\n' # Predictable empty line for agent
  exit 0
else
  printf '❌ Found %d file(s) exceeding the %d line limit.\n' "${#over_limit[@]}" "$MAX_LINES" >&2
  # Convert to absolute paths (one per line) – **final script output**
  repo_root=$(git rev-parse --show-toplevel)
  printf '\n'
  for p in "${over_limit[@]}"; do
    printf '%s/%s\n' "$repo_root" "$p"
  done
  exit 1 # FIX: Exit with failure code
fi