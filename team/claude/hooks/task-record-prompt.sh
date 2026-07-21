#!/usr/bin/env bash
# UserPromptSubmit hook — reminds Claude to continue/start the shared task record.
# Never persists or echoes the raw prompt text. Fail-open on any error.

MSG="TASK RECORD: if repo has an active shared task (see active-task.md above), continue it — don't restate it to the user. If this prompt starts new feature-shaped work with a spec/plan, run: python3 ~/.claude/hooks/task_record.py init-task '<json>'. Never write raw prompt text into the task record."

echo "{\"hookSpecificOutput\":{\"hookEventName\":\"UserPromptSubmit\",\"additionalContext\":$(printf '%s' "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')}}" 2>/dev/null || true
