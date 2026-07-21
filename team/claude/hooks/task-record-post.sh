#!/usr/bin/env bash
# PostToolUse hook — reminds Claude to record a semantic milestone/evidence, never every tool call.
# Fail-open: any parse error exits silently.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null || echo "")

if [[ "$TOOL" == "Bash" ]]; then
    CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
    IS_GIT_EVENT=$(echo "$CMD" | python3 -c "
import sys, re
cmd = sys.stdin.read()
segments = re.split(r'[;&|]+', cmd)
for seg in segments:
    if re.match(r'\s*(git push|git merge|gh pr merge|gh pr create)\b', seg):
        print('yes'); sys.exit(0)
print('no')
" 2>/dev/null || echo "no")
    if [[ "$IS_GIT_EVENT" == "yes" ]]; then
        MSG="TASK RECORD: git push/merge/PR detected. If this closes a milestone, attach a sanitized evidence reference (commit hash / PR URL) via 'python3 ~/.claude/hooks/task_record.py append-event' and consider closure review."
        echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":$(printf '%s' "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}}" 2>/dev/null || true
    fi
    exit 0
fi

if [[ "$TOOL" == "Write" || "$TOOL" == "Edit" ]]; then
    FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
    if echo "$FILE_PATH" | grep -qE 'docs/superpowers/|^\.'; then
        exit 0
    fi
    MSG="TASK RECORD: if this edit was a semantic implementation milestone, verification, or blocker (not routine editing), record it now via 'python3 ~/.claude/hooks/task_record.py append-event'."
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PostToolUse\",\"additionalContext\":$(printf '%s' "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}}" 2>/dev/null || true
fi

exit 0
