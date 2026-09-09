#!/usr/bin/env bash
# SessionStart hook (matcher: compact). Re-injects the pre-compaction snapshot
# written by precompact-goal-snapshot.sh so the post-compaction turn still knows
# the goal, plan pointer, and branch state. SessionStart supports
# additionalContext; PreCompact does not.

set -uo pipefail

CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SLUG=$(printf '%s' "$PWD" | sed 's/[/.]/-/g')
SNAP="$CFG_DIR/projects/$SLUG/memory/precompact-snapshot.md"
[ -f "$SNAP" ] || SNAP="$CFG_DIR/.precompact-latest.md"
[ -f "$SNAP" ] || exit 0

# Skip if stale (> 6h) — a snapshot that old is from an unrelated session.
if [ "$(find "$SNAP" -mmin +360 2>/dev/null)" ]; then
  exit 0
fi

BODY=$(cat "$SNAP" 2>/dev/null)
[ -z "$BODY" ] && exit 0

CTX="Recovered pre-compaction snapshot (continue toward this goal; do not re-ask for state):

$BODY"

python3 -c "import sys,json;print(json.dumps({'hookSpecificOutput':{'hookEventName':'SessionStart','additionalContext':sys.stdin.read()}}))" <<< "$CTX" 2>/dev/null
exit 0
