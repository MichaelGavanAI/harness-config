#!/bin/bash
# superpowers-gate.sh — PreToolUse hook
# Blocks writing source code files when no implementation plan exists in the project.
# Forces brainstorming → spec → plan workflow before any code is written for new features.

INPUT=$(cat)

# Extract the file path from the tool input JSON
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    inp = d.get('tool_input', {})
    print(inp.get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

# Only gate on source code files
if ! echo "$FILE_PATH" | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|vue|svelte)$'; then
    exit 0
fi

# Allow writing spec and plan files themselves (the gate artifacts)
if echo "$FILE_PATH" | grep -q "docs/superpowers"; then
    exit 0
fi

# Resolve the git root from the file's directory
DIR=$(dirname "$FILE_PATH")
if [ ! -d "$DIR" ]; then
    # New file — try parent directory
    DIR=$(dirname "$DIR")
fi

GIT_ROOT=$(cd "$DIR" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)

# Not in a git repo — skip gate (can't determine project root)
if [ -z "$GIT_ROOT" ]; then
    exit 0
fi

cd "$GIT_ROOT" || exit 0

# Find the merge-base against main/staging to scope "this branch's work"
BASE=""
for REF in origin/main origin/staging main staging; do
    B=$(git merge-base HEAD "$REF" 2>/dev/null)
    if [ -n "$B" ]; then
        BASE="$B"
        break
    fi
done

# No base found (e.g. detached, no remote) — fall back to old lifetime check
if [ -z "$BASE" ]; then
    PLAN_COUNT=$(find "$GIT_ROOT/docs/superpowers/plans" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    [ "$PLAN_COUNT" -gt 0 ] && exit 0
else
    # Scope gate: what got touched matters more than how much. Mirrors the
    # project's own reviewer-escalation rule (Supabase/auth/patient-data/security
    # touched, OR diff size) rather than a bare file-count cutoff.
    CHANGED_FILES=$(git diff "$BASE" --name-only 2>/dev/null)
    CHANGED_COUNT=$(echo "$CHANGED_FILES" | grep -c . || true)

    SENSITIVE=$(echo "$CHANGED_FILES" | grep -qE 'migrations/|supabase/|/auth|quota|patient|/v1/' && echo yes || true)
    NEW_FILES=$(git diff "$BASE" --diff-filter=A --name-only 2>/dev/null | grep -qE '\.(ts|tsx|js|jsx|py|go|rs|vue|svelte)$' && echo yes || true)
    LINES=$(git diff "$BASE" --shortstat 2>/dev/null | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)

    if [ -z "$SENSITIVE" ] && [ -z "$NEW_FILES" ] && [ "${LINES:-0}" -le 150 ]; then
        exit 0
    fi

    # Otherwise require a plan file written DURING this branch's work, not just
    # anywhere in repo history — a plan from three weeks ago on an unrelated
    # feature must not silently authorize today's changes.
    BASE_TIME=$(git log -1 --format=%ct "$BASE" 2>/dev/null || echo 0)
    NEWEST_PLAN_TIME=0
    if [ -d "$GIT_ROOT/docs/superpowers/plans" ]; then
        while IFS= read -r f; do
            T=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null || echo 0)
            [ "$T" -gt "$NEWEST_PLAN_TIME" ] && NEWEST_PLAN_TIME="$T"
        done < <(find "$GIT_ROOT/docs/superpowers/plans" -name "*.md" 2>/dev/null)
    fi

    if [ "$NEWEST_PLAN_TIME" -gt "$BASE_TIME" ]; then
        exit 0
    fi
    PLAN_COUNT=0
fi

if [ "$PLAN_COUNT" -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  SUPERPOWERS GATE — SOURCE CODE BLOCKED                      ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║  Triggered by: sensitive=${SENSITIVE:-no} new_files=${NEW_FILES:-no} lines=${LINES:-0} files=${CHANGED_COUNT:-?}"
    echo "║  No plan written since branch start.                          ║"
    echo "║  Plans dir: $GIT_ROOT/docs/superpowers/plans/"
    echo "║                                                              ║"
    echo "║  Required workflow BEFORE writing source code:               ║"
    echo "║  1. Skill: superpowers:brainstorming                         ║"
    echo "║     → Write spec to docs/superpowers/specs/YYYY-MM-DD-*.md  ║"
    echo "║  2. Skill: superpowers:writing-plans                         ║"
    echo "║     → Write plan to docs/superpowers/plans/YYYY-MM-DD-*.md  ║"
    echo "║  3. Skill: superpowers:executing-plans                       ║"
    echo "║     → Load plan, then proceed with implementation            ║"
    echo "║                                                              ║"
    echo "║  File blocked: $FILE_PATH"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    exit 2
fi

exit 0
