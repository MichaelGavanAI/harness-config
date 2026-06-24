#!/usr/bin/env bash
# UserPromptSubmit hook — memory journal system
# 1. Detects /compact → inject consolidation-first instruction
# 2. Otherwise → inject backward-glance reminder

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || echo "")

CONTEXT=$(cat "$HOME/.claude/.session-context" 2>/dev/null || echo "none")

# No journaling outside known contexts
if [[ "$CONTEXT" == "none" ]]; then
    exit 0
fi

JOURNAL="$HOME/.claude/projects/$CONTEXT/memory/journal.md"

# /compact detected — must consolidate before compress runs
if echo "$PROMPT" | grep -qiE '^\s*/compact'; then
    MSG="MEMORY_SYNC_REQUIRED: /compact detected. Before compacting, you MUST consolidate memory journal. Steps: 1) Read $JOURNAL 2) Merge each entry into the relevant memory/*.md structured file 3) Clear journal.md entries (leave blank). Do this NOW as your first action."
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":$(echo "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')}}"
    exit 0
fi

# Backward-glance reminder — every turn
MSG="MEMORY: If last response completed a meaningful task, append 1 line to $JOURNAL before responding. Format: [$(date '+%Y-%m-%d %H:%M')] <what done> — <decision/why>. Skip for Q&A, lookups, caveman toggles."
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":$(echo "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')}}"
