#!/usr/bin/env bash
# worktree-mismatch-check.sh — PreToolUse hook (Write, Edit, Bash)
# Checkpoint 2 of the worktree lifecycle system: warns when the current
# directory doesn't match the active task's bound worktree. Never blocks —
# additionalContext only. Fails open.

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""' 2>/dev/null)

target_dir=""
if [ "$tool_name" = "Bash" ]; then
  cmd=$(echo "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
  echo "$cmd" | grep -q "git commit" || { echo '{}'; exit 0; }
  target_dir="$PWD"
else
  file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
  [ -z "$file_path" ] && { echo '{}'; exit 0; }
  target_dir=$(dirname "$file_path")
  [ -d "$target_dir" ] || target_dir=$(dirname "$target_dir")
fi
[ -d "$target_dir" ] || { echo '{}'; exit 0; }

target_real=$(cd "$target_dir" 2>/dev/null && pwd -P)
[ -z "$target_real" ] && { echo '{}'; exit 0; }

git_root=$(cd "$target_dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
[ -z "$git_root" ] && { echo '{}'; exit 0; }
actual_root=$(cd "$git_root" && pwd -P)

resolved=$(cd "$actual_root" && python3 "${HOME}/.claude/hooks/task_record.py" resolve 2>/dev/null)
[ -z "$resolved" ] && { echo '{}'; exit 0; }
active_id=$(echo "$resolved" | jq -r '.active_task_id // empty' 2>/dev/null)
task_dir_rel=$(echo "$resolved" | jq -r '.task_dir // empty' 2>/dev/null)
[ -z "$active_id" ] && { echo '{}'; exit 0; }

# task_dir_rel is absolute (task_record.py's ledger now lives under --git-common-dir, outside
# the working tree) — do not join it onto actual_root.
task_json="$task_dir_rel/tasks/$active_id/task.json"
[ -f "$task_json" ] || { echo '{}'; exit 0; }

recorded=$(jq -r '.worktree // empty' "$task_json" 2>/dev/null)
[ -z "$recorded" ] && { echo '{}'; exit 0; }
[ "$recorded" = "none" ] && { echo '{}'; exit 0; }

recorded_real=$(cd "$recorded" 2>/dev/null && pwd -P)
[ -z "$recorded_real" ] && { echo '{}'; exit 0; }

case "$target_real" in
  "$recorded_real"|"$recorded_real"/*) echo '{}'; exit 0 ;;
esac

jq -n --arg id "$active_id" --arg bound "$recorded_real" --arg actual "$target_real" \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: ("WORKTREE MISMATCH: active task " + $id + " is bound to " + $bound + ", but this change is happening in " + $actual + ". Ask the user whether this is intentional (rebind the task) or a mistake (switch directories) before proceeding.")}}'
