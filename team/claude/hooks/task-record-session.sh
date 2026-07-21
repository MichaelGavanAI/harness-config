#!/usr/bin/env bash
# SessionStart hook — injects the shared active-task read model (docs/agent-workflow/active-task.md).
# Fail-open: any error here produces empty output, never blocks session start.

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id','unknown'))" 2>/dev/null || echo "unknown")
touch "$HOME/.claude/.task-record-turn-start-$SESSION_ID" 2>/dev/null || true

OUTPUT=$(python3 "$HOOK_DIR/task_record.py" read-active 2>/dev/null) || true

if [[ -z "$OUTPUT" || "$OUTPUT" == "no active task" ]]; then
    exit 0
fi

MSG="TASK RECORD (shared, cross-agent — see docs/agent-workflow/CONTRACT.md):"$'\n\n'"$OUTPUT"

if echo "$OUTPUT" | grep -q "^STALE:"; then
    MSG+=$'\n\n'"This active task is stale. Report it and update its next_action or blocker before proceeding."
fi

jq -n --arg ctx "$MSG" '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}' 2>/dev/null || true
