#!/usr/bin/env bash

CLAUDE_PROJECTS="$HOME/.claude/projects"
GLOBAL_MEM="$CLAUDE_PROJECTS/global/memory"

BASE="GLOBAL: Start every response with [Model: Haiku/Sonnet/Opus]. Route subagents: Haiku=search/reads, Sonnet=code (default), Opus=architecture. Announce every Agent spawn."

inject_dir() {
    local dir="$1" label="$2" out="" base="" status=""
    [[ -d "$dir" ]] || return
    for f in "$dir"/*.md; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        [[ "$base" == "MEMORY.md" ]] && continue  # index only, skip

        # Archival policy: project_*.md files carrying a terminal status
        # (archived/resolved/shipped/merged) in their frontmatter move to
        # archive/ and drop out of injection. feedback_*/reference_* never
        # auto-archive — those stay load-bearing indefinitely.
        if [[ "$base" == project_* ]]; then
            status=$(sed -n '1,10p' "$f" | grep -Eom1 '^[[:space:]]*status:[[:space:]]*(archived|resolved|shipped|merged)' | awk '{print $NF}')
            if [[ -n "$status" ]]; then
                mkdir -p "$dir/archive"
                mv "$f" "$dir/archive/$base"
                continue
            fi
        fi

        out+=$'\n\n--- '"$label/$base"$' ---\n'"$(cat "$f")"
    done
    echo "$out"
}

# Derive the per-project bucket dir name the same way Claude Code does:
# take the absolute CWD and replace every "/" and "." with "-".
# e.g. /home/korm85/projects/work/gavan-cicd -> -home-korm85-projects-work-gavan-cicd
PROJECT_SLUG=$(printf '%s' "$PWD" | sed 's/[/.]/-/g')
PROJECT_MEM="$CLAUDE_PROJECTS/$PROJECT_SLUG/memory"

MEMORY_CONTENT=$(inject_dir "$GLOBAL_MEM" "global")

PWD_LOWER=$(printf '%s' "$PWD" | tr '[:upper:]' '[:lower:]')
WORK_SUFFIX="/projects/work"
if [[ "$PWD_LOWER" == "$HOME/projects/work"* ]]; then
    CONTEXT_LABEL="work"
    echo "work" > "$HOME/.claude/.session-context"
    MEMORY_CONTENT+=$(inject_dir "$CLAUDE_PROJECTS/work/memory" "work")
    # Preserve this machine's actual on-disk casing (e.g. ~/Projects/Work vs ~/projects/work)
    # for paths derived below, rather than assuming lowercase.
    WORK_ROOT="${PWD:0:$((${#HOME} + ${#WORK_SUFFIX}))}"
elif [[ "$PWD_LOWER" == "$HOME/projects/personal"* ]]; then
    CONTEXT_LABEL="personal"
    echo "personal" > "$HOME/.claude/.session-context"
    MEMORY_CONTENT+=$(inject_dir "$CLAUDE_PROJECTS/personal/memory" "personal")
else
    CONTEXT_LABEL="none (launched outside work/ or personal/ — only global + per-project memory loaded)"
    echo "none" > "$HOME/.claude/.session-context"
fi

# Per-project memory bucket — loaded for EVERY cwd, independent of work/personal context.
MEMORY_CONTENT+=$(inject_dir "$PROJECT_MEM" "project")

MEMORY_CONTENT+=$'\n\n--- session-context ---\nCWD: '"$PWD"$'\nLoaded context: '"$CONTEXT_LABEL"

# Slack digest — run fetch if work context and token exists
if [[ "$CONTEXT_LABEL" == "work" ]] && [[ -f "$HOME/.slack_token" ]]; then
    DIGEST_PATH="$WORK_ROOT/slack-digest.md"
    # Refresh if older than 30 minutes or missing
    if [[ ! -f "$DIGEST_PATH" ]] || [[ $(find "$DIGEST_PATH" -mmin +30 2>/dev/null | wc -l) -gt 0 ]]; then
        bash "$WORK_ROOT/slack-fetch.sh" >/dev/null 2>&1 || true
    fi
    if [[ -f "$DIGEST_PATH" ]]; then
        MEMORY_CONTENT+=$'\n\n--- slack-digest ---\n'"$(cat "$DIGEST_PATH")"
    fi
fi

# Journal consolidation check — if any journal.md has entries from a previous
# session, inject instruction to consolidate before doing anything else.
# Checks BOTH the shared work/personal bucket AND the per-project bucket.
JOURNAL_NOTICE=""
PENDING_JOURNALS=""
if [[ "$CONTEXT_LABEL" == "work" || "$CONTEXT_LABEL" == "personal" ]]; then
    CTX_JOURNAL="$CLAUDE_PROJECTS/$CONTEXT_LABEL/memory/journal.md"
    if [[ -f "$CTX_JOURNAL" ]] && [[ -s "$CTX_JOURNAL" ]]; then
        PENDING_JOURNALS+=" $CTX_JOURNAL"
    fi
fi
PROJECT_JOURNAL="$PROJECT_MEM/journal.md"
if [[ -f "$PROJECT_JOURNAL" ]] && [[ -s "$PROJECT_JOURNAL" ]]; then
    PENDING_JOURNALS+=" $PROJECT_JOURNAL"
fi
if [[ -n "$PENDING_JOURNALS" ]]; then
    JOURNAL_NOTICE=$'\n\nMEMORY_CONSOLIDATE_ON_START: these journal.md files have unprocessed entries from a previous session:'"$PENDING_JOURNALS"$'. As your FIRST action (before responding to user), consolidate each into the relevant memory/*.md structured files in the SAME bucket, then clear that journal.md.'
fi

if [[ -n "$MEMORY_CONTENT" ]]; then
    FULL="$BASE"$'\n\nMEMORY:'"$MEMORY_CONTENT""$JOURNAL_NOTICE"
else
    FULL="$BASE""$JOURNAL_NOTICE"
fi

jq -n --arg ctx "$FULL" '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$ctx}}'
