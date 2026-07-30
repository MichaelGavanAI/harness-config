#!/usr/bin/env bash
# PreToolUse:Bash — deny recursive deletes of source/config directories.
# Enforcement by blocking, not by reminding. Fail-open on any parse error.

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null) || exit 0

# rm with a recursive flag targeting a source-ish directory
if printf '%s' "$CMD" | grep -Eqi 'rm[[:space:]]+(-[a-z]*r[a-z]*[[:space:]]+)+.*(src|app|components|lib|hooks|\.claude|node_modules/\.\.)'; then
    REASON="Blocked: recursive delete targeting a source directory. Delete specific files after confirming with 'git status' that they are untracked, or ask the user first."
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}' \
        "$(printf '%s' "$REASON" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')"
    exit 0
fi

# rm -rf against a bare path at filesystem root or $HOME
if printf '%s' "$CMD" | grep -Eq 'rm[[:space:]]+-[a-z]*r[a-z]*f?[[:space:]]+(/|~|\$HOME)[[:space:]]*$'; then
    REASON="Blocked: recursive delete of / or \$HOME."
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":%s}}' \
        "$(printf '%s' "$REASON" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')"
    exit 0
fi

exit 0
