**TOOL INDEX**

*All scripts are in `./.tasks/.tools/`.*

| Tool | Command & Example | Description |
| :--- | :--- | :--- |
| **Create Execution Log** | `create_execution_log.sh "<title>" "<input>"`<br>_e.g._, `...sh "Fix bug" "Login fails"` | Creates a new execution log.<br>- `<title>`: Log title.<br>- `<input>`: Original user input. |
| **Get Directory Tree** | `get_directory_tree.sh` | Generates a filtered directory tree of the project. |
| **Git Commit All** | `git_commit_all.sh "<message>"`<br>_e.g._, `...sh "chore: snapshot"` | Stages all repository changes and commits with a single message. |
| **Create Task Report** | `create_task.sh "<dir>" "<num>" "<title>"`<br>_e.g._, `...sh ".tasks/..." "03" "Implement CSV"` | Creates a task report (`T-XX_...md`) in the specified `<dir>`.<br>- `<num>`: Numeric task ID.<br>- `<title>`: Task title. |
| **Find Large Files** | `ci_find_large_changed_files.sh [options]`<br>_e.g._, `...sh --since main --max-lines 400` | Lists files changed since `<ref>` whose line count exceeds `<N>`.<br>- `--since <ref>`: (default: `HEAD`)<br>- `--max-lines <N>`: (default: `300`)<br>- `--count-blank`: Includes blank lines. |
| **Run Python Lint** | `ci_python_lint.sh [options]`<br>_e.g._, `...sh -t src -f` | Runs Ruff lint checks and saves a JSON report.<br>- `-t, --target`: Path to scan (default: root)<br>- `-f, --fix`: Apply auto-fixes<br>- `-o, --output`: Explicit report path |
| **Git View Commit Changes** | `ci_view_commit_changes.sh` | Shows recent commits and the files they touched |
| **Check Situation Reports** | `ci_check_situation_reports.sh [--dir <path>]` | Verifies that every Situation Report’s **Status** is ✅ (complete). Exits 1 and lists offending files if any are incomplete. |
| **Infra Lint & Build** | `ci_infra_lint_build.sh [options]`<br>_e.g._, `...sh --fix` | Formats, lints and compiles all *Bicep* files in the infra directory to ensure they meet CI quality gates.<br>- `-f, --fix`: Auto‑format files.<br>- `--dir <path>`: Override infra directory. |
| **CI-Gated Task Sign-off** | `run_ci_then_sign_off.sh "<folder>" "<T-XX>" "<Result>" "<commit>" "<comments>"`<br>_e.g._, `...sh "20250620-..." "T-05" "Approved" "feat: done" "LGTM"`<br><br> **⚠️ Important: The agent MUST get explicit confirmation from the user before running this command.** | Runs all CI checks. If they pass, it performs final task sign-off, updating the task report and main dashboard. Aborts if any CI check fails.<br>- `<Result>`: `Approved \| Approved with comments \| Rejected` |
