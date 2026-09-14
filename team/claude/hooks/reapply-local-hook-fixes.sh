#!/usr/bin/env bash
# PostToolUse:Bash — self-heal local, uncommitted fixes to repo-tracked files that a git
# operation (pull/reset/checkout/stash) can silently discard, since git has no memory of an
# edit that was never committed. Purely local enforcement -- never touches the target repo's
# git history, only the working-tree file on disk.

set -euo pipefail

node "$(dirname "${BASH_SOURCE[0]}")/reapply-local-hook-fixes.mjs" 2>&1 || true
exit 0
