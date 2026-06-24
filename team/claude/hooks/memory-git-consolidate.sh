#!/usr/bin/env bash
# PostToolUse hook — detects git push/merge and triggers memory consolidation

INPUT=$(cat)
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")
CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

if [[ "$TOOL" != "Bash" ]]; then
    exit 0
fi

if ! echo "$CMD" | python3 -c "
import sys, re
cmd = sys.stdin.read()
segments = re.split(r'[;&|]+', cmd)
for seg in segments:
    if re.match(r'\s*(git push|git merge|gh pr merge)\b', seg):
        sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
    exit 0
fi

CONTEXT=$(cat "$HOME/.claude/.session-context" 2>/dev/null || echo "none")
if [[ "$CONTEXT" == "none" ]]; then
    exit 0
fi

JOURNAL="$HOME/.claude/projects/$CONTEXT/memory/journal.md"

MSG="MEMORY_CONSOLIDATE: git push/merge detected. Consolidate $JOURNAL into memory/*.md structured files now, then clear journal entries."
echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":$(echo "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')}}"
