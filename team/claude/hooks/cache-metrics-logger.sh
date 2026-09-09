#!/usr/bin/env bash
# statusLine side-channel: append one JSONL row per API request with prompt-cache
# metrics, so a session can be reviewed later for uncached-token waste.
#
# Fed the raw statusLine stdin JSON (Claude Code >= 2.1.251, which carries the
# `prompt_cache` object). Invoked fire-and-forget from statusline-command.sh;
# never writes to stdout, never blocks the status line.
#
# Output: ~/.claude/cache-metrics/<session_id>.jsonl
# Dedup:  the status line re-renders many times per turn; we only append when
#         prompt_cache.requests changes (one bump per real API request).

set -euo pipefail

CFG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
OUT_DIR="$CFG_DIR/cache-metrics"
mkdir -p "$OUT_DIR" 2>/dev/null || exit 0

input=$(cat 2>/dev/null || true)
[ -z "$input" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
[ -z "$sid" ] && exit 0

# Only log when prompt_cache is actually present.
has_pc=$(printf '%s' "$input" | jq -r 'has("prompt_cache") and (.prompt_cache != null)' 2>/dev/null || echo false)
[ "$has_pc" = "true" ] || exit 0

reqs=$(printf '%s' "$input" | jq -r '.prompt_cache.requests // 0' 2>/dev/null || echo 0)
last_file="$OUT_DIR/$sid.last"
prev=$(cat "$last_file" 2>/dev/null || echo "")
[ "$reqs" = "$prev" ] && exit 0    # nothing new since last render

row=$(printf '%s' "$input" | jq -c '{
  ts: (now | todate),
  session_id: .session_id,
  session_name: (.session_name // null),
  model: (.model.id // null),
  effort: (.effort.level // null),
  version: (.version // null),
  pc: {
    warm: .prompt_cache.warm,
    ttl: .prompt_cache.ttl,
    requests: .prompt_cache.requests,
    misses: .prompt_cache.misses,
    expected_rebuilds: .prompt_cache.expected_rebuilds,
    hit_ratio: .prompt_cache.hit_ratio,
    cache_write_tokens: .prompt_cache.cache_write_tokens,
    miss_recache_tokens: .prompt_cache.miss_recache_tokens,
    recache_tokens_if_cold: .prompt_cache.recache_tokens_if_cold,
    last_miss_at: .prompt_cache.last_miss_at
  },
  ctx: {
    input_tokens: .context_window.current_usage.input_tokens,
    cache_read: .context_window.current_usage.cache_read_input_tokens,
    cache_creation: .context_window.current_usage.cache_creation_input_tokens,
    total_input_tokens: .context_window.total_input_tokens,
    used_percentage: .context_window.used_percentage
  },
  cost_usd: (.cost.total_cost_usd // null)
}' 2>/dev/null || true)

[ -z "$row" ] && exit 0
printf '%s\n' "$row" >> "$OUT_DIR/$sid.jsonl" 2>/dev/null || true
printf '%s' "$reqs" > "$last_file" 2>/dev/null || true
exit 0
