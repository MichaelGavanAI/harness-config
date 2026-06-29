#!/usr/bin/env bash

CLAUDE_PROJECTS="$HOME/.claude/projects"
GLOBAL_MEM="$CLAUDE_PROJECTS/global/memory"

BASE="GLOBAL: Start every response with [Model: Haiku/Sonnet/Opus]. Route subagents: Haiku=search/reads, Sonnet=code (default), Opus=architecture. Announce every Agent spawn."

inject_dir() {
    local dir="$1" label="$2" out=""
    [[ -d "$dir" ]] || return
    for f in "$dir"/*.md; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == "MEMORY.md" ]] && continue  # index only, skip
        out+=$'\n\n--- '"$label/$(basename "$f")"$' ---\n'"$(cat "$f")"
    done
    echo "$out"
}

MEMORY_CONTENT=$(inject_dir "$GLOBAL_MEM" "global")

if [[ "$PWD" == "$HOME/projects/work"* ]]; then
    CONTEXT_LABEL="work"
    echo "work" > "$HOME/.claude/.session-context"
    MEMORY_CONTENT+=$(inject_dir "$CLAUDE_PROJECTS/work/memory" "work")
elif [[ "$PWD" == "$HOME/projects/personal"* ]]; then
    CONTEXT_LABEL="personal"
    echo "personal" > "$HOME/.claude/.session-context"
    MEMORY_CONTENT+=$(inject_dir "$CLAUDE_PROJECTS/personal/memory" "personal")
else
    CONTEXT_LABEL="none (launched outside work/ or personal/ — only global memory loaded)"
    echo "none" > "$HOME/.claude/.session-context"
fi

MEMORY_CONTENT+=$'\n\n--- session-context ---\nCWD: '"$PWD"$'\nLoaded context: '"$CONTEXT_LABEL"

# Slack digest — run fetch if work context and token exists
if [[ "$CONTEXT_LABEL" == "work" ]] && [[ -f "$HOME/.slack_token" ]]; then
    DIGEST_PATH="$HOME/projects/work/slack-digest.md"
    # Refresh if older than 30 minutes or missing
    if [[ ! -f "$DIGEST_PATH" ]] || [[ $(find "$DIGEST_PATH" -mmin +30 2>/dev/null | wc -l) -gt 0 ]]; then
        bash "$HOME/projects/work/slack-fetch.sh" >/dev/null 2>&1 || true
    fi
    if [[ -f "$DIGEST_PATH" ]]; then
        MEMORY_CONTENT+=$'\n\n--- slack-digest ---\n'"$(cat "$DIGEST_PATH")"
    fi
fi

# Journal consolidation check — if journal.md has entries from a previous session,
# inject instruction to consolidate before doing anything else
JOURNAL_NOTICE=""
if [[ "$CONTEXT_LABEL" == "work" || "$CONTEXT_LABEL" == "personal" ]]; then
    JOURNAL_PATH="$CLAUDE_PROJECTS/$CONTEXT_LABEL/memory/journal.md"
    if [[ -f "$JOURNAL_PATH" ]] && [[ -s "$JOURNAL_PATH" ]]; then
        JOURNAL_NOTICE=$'\n\nMEMORY_CONSOLIDATE_ON_START: journal.md has unprocessed entries from a previous session. As your FIRST action (before responding to user), consolidate these entries into the relevant memory/*.md structured files, then clear journal.md.'
    fi
fi

if [[ -n "$MEMORY_CONTENT" ]]; then
    FULL="$BASE"$'\n\nMEMORY:'"$MEMORY_CONTENT""$JOURNAL_NOTICE"
else
    FULL="$BASE""$JOURNAL_NOTICE"
fi

jq -n --arg ctx "$FULL" '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}'
