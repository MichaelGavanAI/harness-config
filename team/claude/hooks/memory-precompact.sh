#!/usr/bin/env bash
# PreCompact hook — fires BEFORE the transcript is compacted (matcher: manual|auto).
#
# Important capability note: PreCompact does NOT support additionalContext injection
# (only SessionStart, UserPromptSubmit, and PostToolUse do — verified against the
# claude binary in this install). It also cannot force the model to take a
# consolidation turn first, because compaction is a system operation, not a model
# turn. So this hook only surfaces a user-visible systemMessage warning.
#
# The actual post-compaction recovery is handled by the existing SessionStart hook
# wired to the "compact" matcher (global-session-start.sh), which re-injects memory
# and the MEMORY_CONSOLIDATE_ON_START notice — now covering the per-project journal
# too. Journal files live on disk and survive compaction, so nothing is lost.

INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('trigger',''))" 2>/dev/null || echo "")

CONTEXT=$(cat "$HOME/.claude/.session-context" 2>/dev/null || echo "none")

PROJECT_SLUG=$(printf '%s' "$PWD" | sed 's/[/.]/-/g')
PROJECT_JOURNAL="$HOME/.claude/projects/$PROJECT_SLUG/memory/journal.md"

# Collect journals that currently have unprocessed entries.
PENDING=""
[[ -s "$PROJECT_JOURNAL" ]] && PENDING+=" $PROJECT_JOURNAL"
if [[ "$CONTEXT" != "none" ]]; then
    CTX_JOURNAL="$HOME/.claude/projects/$CONTEXT/memory/journal.md"
    [[ -s "$CTX_JOURNAL" ]] && PENDING+=" $CTX_JOURNAL"
fi

# Nothing pending — stay silent.
[[ -z "$PENDING" ]] && exit 0

MSG="Memory: compaction ($TRIGGER) is about to run with unprocessed journal entries in:$PENDING. These files survive compaction; the SessionStart:compact hook will re-inject a consolidation reminder afterward."
echo "{\"systemMessage\":$(echo "$MSG" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().strip()))')}"
exit 0
