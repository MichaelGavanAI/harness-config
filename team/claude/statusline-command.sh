#!/bin/bash
# Claude Code statusLine — converted from the color PS1 in ~/.bashrc:
#   '${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# Trailing "\$ " dropped (status lines shouldn't end in a fake prompt char).
#
# Also preserves the caveman plugin's mode badge, which previously owned
# this statusLine slot, by delegating to its script first.

CAVEMAN_SCRIPT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/caveman-statusline.sh"

input=$(cat)

# Prompt-cache metrics side-channel (fire-and-forget, never blocks the status line).
if [ -n "$input" ]; then
  printf '%s' "$input" | bash "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/hooks/cache-metrics-logger.sh" >/dev/null 2>&1 &
fi

# Capture official Anthropic rate limits from Claude Code session
if [ -n "$input" ]; then
  mkdir -p "$HOME/.config/ai-quota-overlay" 2>/dev/null
  printf '%s' "$input" > "$HOME/.config/ai-quota-overlay/official_claude_session.json" 2>/dev/null
  (ai-quota-overlay refresh >/dev/null 2>&1 &)
fi

cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
[ -z "$cwd" ] && cwd=$(pwd)

user=$(whoami)
host=$(hostname -s 2>/dev/null || hostname)
chroot="${debian_chroot:+($debian_chroot)}"

# 1. Caveman mode badge (reads its own state; ignores stdin, so give it none).
if [ -x "$CAVEMAN_SCRIPT" ] || [ -f "$CAVEMAN_SCRIPT" ]; then
  CAVEMAN_OUT=$(bash "$CAVEMAN_SCRIPT" </dev/null 2>/dev/null)
  [ -n "$CAVEMAN_OUT" ] && printf '%s ' "$CAVEMAN_OUT"
fi

# 2. PS1-derived prompt: [chroot]user@host:cwd
printf '%s\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$chroot" "$user" "$host" "$cwd"

# 3. Active git branch, if cwd is inside a repo.
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
[ -n "$branch" ] && printf ' \033[01;33m(%s)\033[00m' "$branch"

# 4. PR state (OPEN/DRAFT/MERGED/CLOSED) for the branch, via gh, cached 30s to
# avoid a network call on every statusline render.
if [ -n "$branch" ] && command -v gh >/dev/null 2>&1; then
  repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$repo_root" ]; then
    cache_file="/tmp/.claude-statusline-pr-$(echo "$repo_root-$branch" | md5sum | cut -d' ' -f1)"
    now=$(date +%s 2>/dev/null)
    cache_age=9999
    if [ -f "$cache_file" ]; then
      cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
      cache_age=$((now - cache_mtime))
    fi
    if [ "$cache_age" -ge 30 ]; then
      pr_json=$(timeout 2 gh pr view --json number,state,isDraft -q '"\(.number)\t\(.state)\t\(.isDraft)"' 2>/dev/null)
      printf '%s' "$pr_json" > "$cache_file"
    else
      pr_json=$(cat "$cache_file" 2>/dev/null)
    fi
    if [ -n "$pr_json" ]; then
      pr_num=$(printf '%s' "$pr_json" | cut -f1)
      pr_state=$(printf '%s' "$pr_json" | cut -f2)
      pr_draft=$(printf '%s' "$pr_json" | cut -f3)
      [ "$pr_draft" = "true" ] && pr_label="DRAFT" || pr_label="$pr_state"
      printf ' \033[01;36m[%s]\033[00m' "$pr_label"
    fi
  fi
fi
