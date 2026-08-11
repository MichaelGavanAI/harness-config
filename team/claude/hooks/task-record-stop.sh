#!/usr/bin/env bash
# Stop hook — if the shared task's state changed since this session/turn started, remind
# Claude to confirm active-task.md and events.jsonl are current. Silent otherwise.
# Fail-open: any error exits silently, never blocks turn completion.

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id','unknown'))" 2>/dev/null || echo "unknown")
MARKER="$HOME/.claude/.task-record-turn-start-$SESSION_ID"

[[ -f "$MARKER" ]] || exit 0

RESOLVED=$(python3 "$HOOK_DIR/task_record.py" resolve 2>/dev/null) || exit 0
TASK_ID=$(echo "$RESOLVED" | python3 -c "import sys,json; print(json.load(sys.stdin).get('active_task_id') or '')" 2>/dev/null || echo "")
GIT_ROOT=$(echo "$RESOLVED" | python3 -c "import sys,json; print(json.load(sys.stdin).get('git_root') or '')" 2>/dev/null || echo "")
TASK_DIR=$(echo "$RESOLVED" | python3 -c "import sys,json; print(json.load(sys.stdin).get('task_dir') or '')" 2>/dev/null || echo "")

[[ -n "$TASK_ID" && -n "$GIT_ROOT" ]] || exit 0

# TASK_DIR is absolute (see task_record.py cmd_resolve) since the ledger now lives under
# --git-common-dir, outside the working tree GIT_ROOT points at — do not join it onto GIT_ROOT.
TASK_JSON="$TASK_DIR/tasks/$TASK_ID/task.json"
[[ -f "$TASK_JSON" ]] || exit 0

if [[ "$TASK_JSON" -nt "$MARKER" ]]; then
    MSG="TASK RECORD: task state changed this turn — confirm active-task.md and events.jsonl are current before ending."
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"Stop\",\"additionalContext\":$(printf '%s' "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}}" 2>/dev/null || true
fi

# Reset the baseline to now so this only re-fires on genuinely NEW changes since this
# Stop, not forever after the first change of the session (the marker is otherwise only
# touched once, at SessionStart).
touch "$MARKER" 2>/dev/null || true

exit 0
