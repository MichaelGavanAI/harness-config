#!/bin/bash
# task-record-freshness-gate.sh — PreToolUse hook (Write, Edit)
# Blocks non-trivial code changes when the shared task record is stale or
# self-contradictory (e.g. status=complete but next_action describes unstarted
# work). Small/contained edits pass through untouched — same size/sensitivity
# signals as superpowers-gate.sh, kept independent per-script on purpose.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

if ! echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|vue|svelte)$'; then
    exit 0
fi

if echo "$FILE_PATH" | grep -qE 'docs/(superpowers|agent-workflow)'; then
    exit 0
fi

DIR=$(dirname "$FILE_PATH")
[ -d "$DIR" ] || DIR=$(dirname "$DIR")
GIT_ROOT=$(cd "$DIR" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)
[ -z "$GIT_ROOT" ] && exit 0

cd "$GIT_ROOT" || exit 0

# Same "big enough" signal as superpowers-gate.sh — trivial/contained edits
# never need a fresh task record, only real feature/fix work does.
BASE=""
for REF in origin/main origin/staging main staging; do
    B=$(git merge-base HEAD "$REF" 2>/dev/null)
    if [ -n "$B" ]; then BASE="$B"; break; fi
done
[ -z "$BASE" ] && exit 0

CHANGED_FILES=$(git diff "$BASE" --name-only 2>/dev/null)
SENSITIVE=$(echo "$CHANGED_FILES" | grep -qE 'migrations/|supabase/|/auth|quota|patient|/v1/' && echo yes || true)
NEW_FILES=$(git diff "$BASE" --diff-filter=A --name-only 2>/dev/null | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|vue|svelte)$' && echo yes || true)
LINES=$(git diff "$BASE" --shortstat 2>/dev/null | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)

if [ -z "$SENSITIVE" ] && [ -z "$NEW_FILES" ] && [ "${LINES:-0}" -le 150 ]; then
    exit 0
fi

# Task record itself may not exist for this repo/worktree — fail open.
DOCTOR=$(python3 "${HOME}/.claude/hooks/task_record.py" doctor 2>/dev/null)
[ -z "$DOCTOR" ] && exit 0

STALE=$(echo "$DOCTOR" | python3 -c "import sys,json; print(json.load(sys.stdin).get('active_task_stale', False))" 2>/dev/null)
ACTIVE_ID=$(echo "$DOCTOR" | python3 -c "import sys,json; print(json.load(sys.stdin).get('active_task_id') or '')" 2>/dev/null)

# No active task tracked at all — nothing to be stale, fail open.
[ -z "$ACTIVE_ID" ] && exit 0

RECORD=$(python3 "${HOME}/.claude/hooks/task_record.py" read-active 2>/dev/null)

# Contradiction heuristic: record claims closure but next_action still reads
# like open implementation work.
STATUS=$(echo "$RECORD" | grep -oE '\*\*Status:\*\* *[a-z_]+' | grep -oE '[a-z_]+$' || true)
NEXT_ACTION=$(echo "$RECORD" | grep -oE '\*\*Next action:\*\*.*' || true)
CONTRADICTION=""
if echo "$STATUS" | grep -qE '^(complete|cancelled)$'; then
    if echo "$NEXT_ACTION" | grep -qiE 'implement|build|add|fix|create|wire|write'; then
        CONTRADICTION="yes"
    fi
fi

if [ "$STALE" != "True" ] && [ -z "$CONTRADICTION" ]; then
    exit 0
fi

echo ""
echo "TASK RECORD FRESHNESS GATE — SOURCE CODE BLOCKED"
echo "Active task: $ACTIVE_ID"
[ "$STALE" = "True" ] && echo "Reason: not updated in >24h (stale)."
[ -n "$CONTRADICTION" ] && echo "Reason: status='$STATUS' but next_action describes unstarted work: $NEXT_ACTION"
echo ""
echo "This change is non-trivial (sensitive=${SENSITIVE:-no} new_files=${NEW_FILES:-no} lines=${LINES:-0})."
echo "Fix the task record before continuing:"
echo "  python3 ~/.claude/hooks/task_record.py set-task --task-id $ACTIVE_ID ..."
echo "or finalize it if the work is genuinely done:"
echo "  python3 ~/.claude/hooks/task_record.py finalize --task-id $ACTIVE_ID ..."
echo ""
echo "File blocked: $FILE_PATH"
echo ""
exit 2
