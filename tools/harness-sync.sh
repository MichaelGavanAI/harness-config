#!/usr/bin/env bash
# harness-sync.sh check|apply
#
# Compares live ~/.claude/ Claude Code harness state against this repo's
# captured copies. `check` only reports drift. `apply` copies over the
# categories that are safe to automate (memory, hooks, skills, plugin
# list) — settings.json and mcp.json are only structurally checked
# (which hook events / MCP servers exist) because they carry secrets
# and machine paths that need a human's judgment to redact, not a
# script's guess. Never runs git add/commit/push.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE_CLAUDE="$HOME/.claude"
MODE="${1:-check}"

if [ "$MODE" != "check" ] && [ "$MODE" != "apply" ]; then
  echo "Usage: harness-sync.sh check|apply" >&2
  exit 1
fi

DRIFT_FOUND=0

report() {
  echo "[$1] $2: $3"
  DRIFT_FOUND=1
}

sync_memory() {
  # Live per-project buckets are keyed by escaped-cwd (e.g. -home-mishka-Projects-Work-gavanmanage)
  # and vary by machine username/path casing — never hardcode a machine's own username/path here.
  # Discover buckets dynamically instead: any $LIVE_CLAUDE/projects/*/memory dir is in scope.
  # global/work/personal are shared buckets (not per-project) and map to a flat repo dir instead
  # of members/michael/memory/projects/<bucket>.
  local proj_repo_dir="$REPO_ROOT/members/michael/memory/projects"
  mkdir -p "$proj_repo_dir"

  for bucket_dir in "$LIVE_CLAUDE"/projects/*/; do
    [ -d "${bucket_dir}memory" ] || continue
    local bucket_name repo_dest
    bucket_name=$(basename "$bucket_dir")
    case "$bucket_name" in
      global|work|personal)
        repo_dest="$REPO_ROOT/members/michael/memory/$bucket_name"
        ;;
      -*)
        repo_dest="$proj_repo_dir/$bucket_name"
        ;;
      *)
        continue
        ;;
    esac
    mkdir -p "$repo_dest"
    for f in "${bucket_dir}memory"/*.md; do
      [ -f "$f" ] || continue
      local bn repo_f
      bn=$(basename "$f")
      repo_f="$repo_dest/$bn"
      if [ ! -f "$repo_f" ]; then
        report "memory" "missing-in-repo" "$bucket_name/$bn"
        [ "$MODE" = "apply" ] && cp "$f" "$repo_f"
      elif ! diff -q "$f" "$repo_f" >/dev/null 2>&1; then
        report "memory" "changed" "$bucket_name/$bn"
        [ "$MODE" = "apply" ] && cp "$f" "$repo_f"
      fi
    done
  done
}

sync_claude_md() {
  local live_file="$LIVE_CLAUDE/CLAUDE.md"
  local repo_file="$REPO_ROOT/team/claude/CLAUDE.md"
  [ -f "$live_file" ] || return 0
  if [ ! -f "$repo_file" ]; then
    report "claude-md" "missing-in-repo" "CLAUDE.md"
    [ "$MODE" = "apply" ] && cp "$live_file" "$repo_file"
  elif ! diff -q "$live_file" "$repo_file" >/dev/null 2>&1; then
    report "claude-md" "changed" "CLAUDE.md"
    [ "$MODE" = "apply" ] && cp "$live_file" "$repo_file"
  fi
}

sync_hooks() {
  local live_dir="$LIVE_CLAUDE/hooks"
  local repo_dir="$REPO_ROOT/team/claude/hooks"
  mkdir -p "$repo_dir"

  for f in "$live_dir"/*; do
    [ -f "$f" ] || continue
    local bn repo_f
    bn=$(basename "$f")
    case "$bn" in
      *.bak*) continue ;;
    esac
    repo_f="$repo_dir/$bn"
    if [ ! -f "$repo_f" ]; then
      report "hooks" "missing-in-repo" "$bn"
      [ "$MODE" = "apply" ] && cp "$f" "$repo_f"
    elif ! diff -q "$f" "$repo_f" >/dev/null 2>&1; then
      report "hooks" "changed" "$bn"
      [ "$MODE" = "apply" ] && cp "$f" "$repo_f"
    fi
  done

  for f in "$repo_dir"/*; do
    [ -f "$f" ] || continue
    local bn
    bn=$(basename "$f")
    if [ ! -f "$live_dir/$bn" ]; then
      report "hooks" "stale-in-repo" "$bn (no longer exists live — not auto-removed, review and delete manually if intentional)"
    fi
  done
}

sync_skills() {
  local live_dir="$LIVE_CLAUDE/skills"
  local repo_dir="$REPO_ROOT/team/claude/skills"
  [ -d "$live_dir" ] || return 0
  mkdir -p "$repo_dir"

  for skill_dir in "$live_dir"/*/; do
    [ -d "$skill_dir" ] || continue
    local name repo_skill_dir
    name=$(basename "$skill_dir")
    repo_skill_dir="$repo_dir/$name"
    if [ ! -d "$repo_skill_dir" ]; then
      report "skills" "missing-in-repo" "$name"
      [ "$MODE" = "apply" ] && cp -r "$skill_dir" "$repo_skill_dir"
    elif ! diff -rq "$skill_dir" "$repo_skill_dir" >/dev/null 2>&1; then
      report "skills" "changed" "$name"
      [ "$MODE" = "apply" ] && cp -r "$skill_dir" "$repo_skill_dir"
    fi
  done
}

sync_settings() {
  local live_file="$LIVE_CLAUDE/settings.json"
  local repo_file="$REPO_ROOT/team/claude/settings.json.template"
  [ -f "$live_file" ] || return 0

  local live_events repo_events
  live_events=$(python3 -c "import json;print(' '.join(sorted(json.load(open('$live_file')).get('hooks',{}).keys())))")
  repo_events=""
  [ -f "$repo_file" ] && repo_events=$(python3 -c "import json;print(' '.join(sorted(json.load(open('$repo_file')).get('hooks',{}).keys())))" 2>/dev/null)

  for ev in $live_events; do
    if ! printf ' %s ' "$repo_events" | grep -q " $ev "; then
      report "settings" "missing-hook-event" "$ev (live settings.json wires this up, template does not — add it to team/claude/settings.json.template by hand, no secrets involved in hook event wiring)"
    fi
  done
}

sync_mcp() {
  local live_file="$LIVE_CLAUDE/mcp.json"
  local repo_file="$REPO_ROOT/team/mcp.json.template"
  [ -f "$live_file" ] || return 0

  local live_servers repo_servers
  live_servers=$(python3 -c "import json;print(' '.join(sorted(json.load(open('$live_file')).get('mcpServers',{}).keys())))")
  repo_servers=""
  [ -f "$repo_file" ] && repo_servers=$(python3 -c "import json;print(' '.join(sorted(json.load(open('$repo_file')).get('mcpServers',{}).keys())))" 2>/dev/null)

  for srv in $live_servers; do
    if ! printf ' %s ' "$repo_servers" | grep -q " $srv "; then
      report "mcp" "missing-server" "$srv (live mcp.json has this server, team/mcp.json.template does not — add it by hand with secrets replaced by {{PLACEHOLDER}})"
    fi
  done
}

sync_plugins() {
  local live_file="$LIVE_CLAUDE/plugins/installed_plugins.json"
  local marketplaces_file="$LIVE_CLAUDE/plugins/known_marketplaces.json"
  local repo_file="$REPO_ROOT/team/claude/installed-plugins.json"
  [ -f "$live_file" ] || return 0

  local generated current
  generated=$(python3 - "$live_file" "$marketplaces_file" <<'PYEOF'
import json, os, sys
plugins = json.load(open(sys.argv[1]))["plugins"]
marketplaces = json.load(open(sys.argv[2])) if os.path.exists(sys.argv[2]) else {}
out = []
for key, entries in plugins.items():
    name, _, marketplace = key.partition("@")
    scope = entries[0].get("scope", "user") if entries else "user"
    src = marketplaces.get(marketplace, {}).get("source", {"source": "unknown"})
    out.append({"name": name, "marketplace": marketplace, "scope": scope, "marketplaceSource": src})
out.sort(key=lambda p: (p["name"], p["marketplace"]))
print(json.dumps(out, indent=2))
PYEOF
)
  current=""
  [ -f "$repo_file" ] && current=$(cat "$repo_file")

  if [ "$generated" != "$current" ]; then
    report "plugins" "changed" "installed-plugins.json differs from live plugin list"
    if [ "$MODE" = "apply" ]; then
      echo "$generated" > "$repo_file"
    fi
  fi
}

echo "=== harness-sync.sh $MODE ==="
sync_memory
sync_claude_md
sync_hooks
sync_skills
sync_settings
sync_mcp
sync_plugins

if [ "$DRIFT_FOUND" -eq 0 ]; then
  echo "Clean — no drift found."
elif [ "$MODE" = "check" ]; then
  echo ""
  echo "Run 'harness-sync.sh apply' to copy over memory/CLAUDE.md/hooks/skills/plugins drift."
  echo "settings/mcp drift above needs a manual look — never auto-copied (secrets)."
fi
