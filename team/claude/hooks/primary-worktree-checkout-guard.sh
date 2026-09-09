#!/usr/bin/env bash
# primary-worktree-checkout-guard.sh — thin wrapper.
# All logic is in primary-worktree-checkout-guard.py; macOS bash 3.2 mis-parses
# `$(... <<'EOF' ...)` command substitution, which broke the all-in-one shell
# version. Fails OPEN if python3 is missing.
HERE=$(dirname "$0")
command -v python3 >/dev/null 2>&1 || exit 0
exec python3 "$HERE/primary-worktree-checkout-guard.py"
