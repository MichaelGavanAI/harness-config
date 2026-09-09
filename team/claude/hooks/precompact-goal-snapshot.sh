#!/usr/bin/env bash
# PreCompact hook (matcher: manual|auto). Writes a durable "where we are / where
# we're going" snapshot to disk BEFORE the transcript is compacted, so the goal,
# plan pointer, branch state, and recent journal survive the summary.
#
# PreCompact cannot inject context into the compactor in this build, so recovery
# is on the read side: the snapshot lives in the project memory dir (loaded at
# SessionStart) and precompact-snapshot-reinject.sh re-injects it on the
# SessionStart:compact event.

set -uo pipefail

INPUT=$(cat 2>/dev/null || true)
py() { python3 -c "$1" 2>/dev/null; }
TRIGGER=$(printf '%s' "$INPUT" | py "import sys,json;print(json.load(sys.stdin).get('trigger',''))")
SID=$(printf '%s' "$INPUT" | py "import sys,json;print(json.load(sys.stdin).get('session_id',''))")

CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SLUG=$(printf '%s' "$PWD" | sed 's/[/.]/-/g')
MEM_DIR="$CFG_DIR/projects/$SLUG/memory"
mkdir -p "$MEM_DIR" 2>/dev/null
SNAP="$MEM_DIR/precompact-snapshot.md"
LATEST="$CFG_DIR/.precompact-latest.md"

ACTIVE_TASK=""
for p in "$PWD/docs/agent-workflow/active-task.md" \
         "$(git -C "$PWD" rev-parse --git-path sdd 2>/dev/null)/active-task.md"; do
  [ -f "$p" ] && { ACTIVE_TASK=$(cat "$p" 2>/dev/null); break; }
done

BRANCH=$(git -C "$PWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
GIT_STATUS=$(git -C "$PWD" status --porcelain 2>/dev/null | head -40)
GIT_LOG=$(git -C "$PWD" log --oneline -5 2>/dev/null)

PLAN_FILE=$(ls -t "$PWD"/docs/superpowers/plans/*.md 2>/dev/null | head -1)
PLAN_HEAD=""
[ -n "$PLAN_FILE" ] && PLAN_HEAD=$(head -50 "$PLAN_FILE" 2>/dev/null)

LEDGER=$(cat "$(git -C "$PWD" rev-parse --git-path sdd 2>/dev/null)/progress.md" 2>/dev/null | tail -30)

JOURNAL="$MEM_DIR/journal.md"
JOURNAL_TAIL=$(tail -20 "$JOURNAL" 2>/dev/null)

{
  echo "# Pre-compaction snapshot"
  echo
  echo "- Written: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Trigger: ${TRIGGER:-unknown}"
  echo "- Session: ${SID:-unknown}"
  echo "- CWD: $PWD"
  echo "- Branch: $BRANCH"
  echo
  echo "## Active task (docs/agent-workflow/active-task.md)"
  echo '```'
  echo "${ACTIVE_TASK:-<none>}"
  echo '```'
  echo
  echo "## Newest plan file: ${PLAN_FILE:-<none>}"
  [ -n "$PLAN_HEAD" ] && { echo '```'; echo "$PLAN_HEAD"; echo '```'; }
  echo
  echo "## SDD ledger tail"
  echo '```'
  echo "${LEDGER:-<none>}"
  echo '```'
  echo
  echo "## git status (porcelain, first 40)"
  echo '```'
  echo "${GIT_STATUS:-<clean>}"
  echo '```'
  echo
  echo "## git log -5"
  echo '```'
  echo "${GIT_LOG:-<none>}"
  echo '```'
  echo
  echo "## journal.md tail (last 20)"
  echo '```'
  echo "${JOURNAL_TAIL:-<none>}"
  echo '```'
} > "$SNAP" 2>/dev/null

cp "$SNAP" "$LATEST" 2>/dev/null

MSG="Pre-compaction snapshot written to $SNAP (branch $BRANCH, trigger ${TRIGGER:-?}). It will be re-injected on the post-compaction SessionStart."
printf '{"systemMessage":%s}\n' "$(printf '%s' "$MSG" | py 'import sys,json;print(json.dumps(sys.stdin.read().strip()))')"
exit 0
