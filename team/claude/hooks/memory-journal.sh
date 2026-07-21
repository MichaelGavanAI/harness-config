#!/usr/bin/env bash
# UserPromptSubmit hook — memory journal system
# 1. Detects /compact → inject consolidation-first instruction
# 2. Otherwise → inject backward-glance reminder

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null || echo "")

CONTEXT=$(cat "$HOME/.claude/.session-context" 2>/dev/null || echo "none")

# Per-project journal — derived from CWD the same way Claude Code slugs the dir
# (every "/" and "." replaced with "-"). Available in EVERY context, incl. "none".
PROJECT_SLUG=$(printf '%s' "$PWD" | sed 's/[/.]/-/g')
PROJECT_JOURNAL="$HOME/.claude/projects/$PROJECT_SLUG/memory/journal.md"

# Build the list of journals in play for this session.
JOURNALS="$PROJECT_JOURNAL"
if [[ "$CONTEXT" != "none" ]]; then
    JOURNALS="$HOME/.claude/projects/$CONTEXT/memory/journal.md and $PROJECT_JOURNAL"
fi

# /compact detected — must consolidate before compress runs
if echo "$PROMPT" | grep -qiE '^\s*/compact'; then
    MSG="MEMORY_SYNC_REQUIRED: /compact detected. Before compacting, you MUST consolidate memory journals ($JOURNALS). Steps: 1) Read each journal.md 2) Merge each entry into the relevant memory/*.md structured file in the SAME bucket 3) Clear that journal.md (leave blank). Do this NOW as your first action."
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":$(echo "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')}}"
    exit 0
fi

# Backward-glance reminder — every turn
MSG="MEMORY: If last response completed a meaningful task, append 1 line to the appropriate journal ($JOURNALS) before responding. Format: [$(date '+%Y-%m-%d %H:%M')] <what done> — <decision/why>. Skip for Q&A, lookups, caveman toggles."
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":$(echo "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')}}"
