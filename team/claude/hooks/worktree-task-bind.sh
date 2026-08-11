#!/usr/bin/env bash
# worktree-task-bind.sh — PreToolUse hook (Write, Edit)
# Checkpoint 1 of the worktree lifecycle system: reminds Claude to ask the
# user whether this task gets a dedicated worktree, before any file gets
# written for it. Never blocks — additionalContext only. Fails open.

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null)
[ -z "$file_path" ] && { echo '{}'; exit 0; }

dir=$(dirname "$file_path")
[ -d "$dir" ] || dir=$(dirname "$dir")
[ -d "$dir" ] || { echo '{}'; exit 0; }

git_root=$(cd "$dir" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
[ -z "$git_root" ] && { echo '{}'; exit 0; }

resolved=$(cd "$git_root" && python3 "${HOME}/.claude/hooks/task_record.py" resolve 2>/dev/null)
[ -z "$resolved" ] && { echo '{}'; exit 0; }
active_id=$(echo "$resolved" | jq -r '.active_task_id // empty' 2>/dev/null)
task_dir_rel=$(echo "$resolved" | jq -r '.task_dir // empty' 2>/dev/null)

if [ -z "$active_id" ]; then
  jq -n '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: "WORKTREE CHECK: no active task is tracked for this repo. If this is new feature or fix work, ask the user whether to open a dedicated worktree before continuing, then record the answer with task_record.py (field: worktree)."}}'
  exit 0
fi

# task_dir_rel is absolute (task_record.py's ledger now lives under --git-common-dir, outside
# the working tree) — do not join it onto git_root.
task_json="$task_dir_rel/tasks/$active_id/task.json"
[ -f "$task_json" ] || { echo '{}'; exit 0; }

has_worktree=$(jq 'has("worktree")' "$task_json" 2>/dev/null)
if [ "$has_worktree" != "true" ]; then
  title=$(jq -r '.title // ""' "$task_json" 2>/dev/null)
  jq -n --arg id "$active_id" --arg title "$title" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: ("WORKTREE CHECK: active task " + $id + " (\"" + $title + "\") has no worktree decision recorded yet. Ask the user whether to open a dedicated worktree for this task or work in place, then record their answer in the task record'"'"'s worktree field.")}}'
  exit 0
fi

echo '{}'
