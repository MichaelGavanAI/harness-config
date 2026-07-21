#!/usr/bin/env bash
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

if echo "$cmd" | grep -qi 'MichaelGavanAI/todos'; then
  policy=$(gh api repos/MichaelGavanAI/todos/contents/AGENTS.md --jq '.content' 2>/dev/null | base64 -d 2>/dev/null)
  if [ -n "$policy" ]; then
    jq -n --arg ctx "Todos repo policy (AGENTS.md) — follow before writing to MichaelGavanAI/todos:

$policy" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $ctx}}'
    exit 0
  fi
fi

echo '{}'
