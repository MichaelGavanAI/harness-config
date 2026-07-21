#!/usr/bin/env bash
# harness-health audit — mechanical checks only. Interpretation/narration of
# results (dead-matcher judgment calls, prose report) happens in the skill,
# not here. This script never modifies anything, read-only throughout.

set -uo pipefail

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
SETTINGS="$CLAUDE_HOME/settings.json"
HOOKS_DIR="$CLAUDE_HOME/hooks"
PROJECTS_DIR="$CLAUDE_HOME/projects"

section() { printf '\n=== %s ===\n' "$1"; }

# ---------- 1. settings.json validity ----------
section "settings.json"
if [[ ! -f "$SETTINGS" ]]; then
  echo "MISSING: $SETTINGS does not exist"
  exit 1
fi
if ! python3 -c "import json; json.load(open('$SETTINGS'))" 2>/tmp/settings_err.txt; then
  echo "INVALID JSON:"
  cat /tmp/settings_err.txt
  exit 1
fi
echo "OK: valid JSON"

# ---------- 2. supported hook events, verified against the real binary ----------
section "supported hook events (verified against installed binary)"
CLAUDE_BIN=$(readlink -f "$(command -v claude)" 2>/dev/null)
if [[ -z "$CLAUDE_BIN" || ! -f "$CLAUDE_BIN" ]]; then
  echo "WARN: could not resolve the claude binary path — skipping binary verification, falling back to a hardcoded known-good list (may be stale for your installed version)"
  SUPPORTED_EVENTS="Notification PostCompact PostToolUse PreCompact PreToolUse SessionEnd SessionStart Stop SubagentStop UserPromptSubmit"
else
  echo "binary: $CLAUDE_BIN"
  SUPPORTED_EVENTS=$(strings "$CLAUDE_BIN" 2>/dev/null | grep -E "^(PreCompact|PostCompact|SessionEnd|SubagentStop|SessionStart|PreToolUse|PostToolUse|UserPromptSubmit|Notification|Stop)$" | sort -u | tr '\n' ' ')
fi
echo "supported: $SUPPORTED_EVENTS"

# ---------- 3. hooks referenced in settings.json ----------
section "hooks wired in settings.json"
python3 <<'PYEOF'
import json, os, subprocess, sys

settings = json.load(open(os.path.expanduser("~/.claude/settings.json")))
hooks = settings.get("hooks", {})

configured_events = list(hooks.keys())
print(f"configured event keys: {configured_events}")

referenced_scripts = set()
for event, matchers in hooks.items():
    for entry in matchers:
        matcher = entry.get("matcher", "<none>")
        for h in entry.get("hooks", []):
            cmd = h.get("command", "")
            referenced_scripts.add(cmd)
            # does the referenced script actually exist? Prefer the token that
            # LOOKS like the actual script (ends in a script extension) over an
            # interpreter path that happens to appear earlier (e.g. "node" "foo.js"
            # -- the node binary itself exists and would give a false "OK" if we
            # naively took the first path-like token).
            tokens = [t.strip('"') for t in cmd.split()]
            script_token = next((t for t in tokens if t.endswith((".sh", ".js", ".mjs", ".py"))), None)
            path = os.path.expandvars(script_token) if script_token else cmd
            exists = os.path.isfile(path) if path.startswith("/") or path.startswith(os.path.expanduser("~")) else False
            syntax = "n/a"
            if exists and path.endswith(".sh"):
                r = subprocess.run(["bash", "-n", path], capture_output=True, text=True)
                syntax = "OK" if r.returncode == 0 else f"SYNTAX ERROR: {r.stderr.strip()}"
            elif exists and path.endswith((".js", ".mjs")):
                r = subprocess.run(["node", "--check", path], capture_output=True, text=True)
                syntax = "OK" if r.returncode == 0 else f"SYNTAX ERROR: {r.stderr.strip()}"
            print(f"  [{event}] matcher={matcher!r} -> {cmd}")
            print(f"      exists: {exists}   syntax: {syntax}")

print("\nreferenced_scripts_raw:")
for s in sorted(referenced_scripts):
    print(f"  {s}")
PYEOF

# ---------- 4. orphaned hook scripts (on disk, never wired) ----------
section "orphaned hook scripts (exist on disk, not referenced by any hook in settings.json)"
if [[ -d "$HOOKS_DIR" ]]; then
  for f in "$HOOKS_DIR"/*.sh; do
    [[ -f "$f" ]] || continue
    base=$(basename "$f")
    if ! grep -q "$base" "$SETTINGS"; then
      echo "ORPHANED: $f (not mentioned anywhere in settings.json)"
    fi
  done
else
  echo "no hooks directory at $HOOKS_DIR"
fi

# ---------- 5. memory buckets — which hooks actually reference each ----------
section "memory buckets — which hook scripts reference each path pattern"
declare -A BUCKET_PATTERNS=(
  ["global"]='global/memory'
  ["work-or-personal (shared, keyed by .session-context)"]='CONTEXT_LABEL|session-context'
  ["per-project (escaped-cwd bucket)"]='PROJECT_SLUG|PROJECT_MEM'
)
for label in "${!BUCKET_PATTERNS[@]}"; do
  pattern="${BUCKET_PATTERNS[$label]}"
  echo "-- $label --"
  matched=false
  for f in "$HOOKS_DIR"/*.sh; do
    [[ -f "$f" ]] || continue
    if grep -qE "$pattern" "$f" 2>/dev/null; then
      echo "  referenced in: $(basename "$f")"
      matched=true
    fi
  done
  [[ "$matched" == false ]] && echo "  NOT REFERENCED by any hook script — this bucket is write-only if anything writes to it"
done

# ---------- 6. journal.md files that exist, and whether anything checks them ----------
section "journal.md files on disk vs. hook checks"
for j in "$PROJECTS_DIR"/global/memory/journal.md "$PROJECTS_DIR"/work/memory/journal.md "$PROJECTS_DIR"/personal/memory/journal.md; do
  if [[ -f "$j" ]]; then
    size=$(stat -c%s "$j" 2>/dev/null || stat -f%z "$j" 2>/dev/null)
    echo "exists: $j (${size} bytes)"
  fi
done
echo ""
echo "current dir's per-project journal (if any):"
SLUG=$(printf '%s' "$PWD" | sed 's/[/.]/-/g')
PROJ_JOURNAL="$PROJECTS_DIR/$SLUG/memory/journal.md"
if [[ -f "$PROJ_JOURNAL" ]]; then
  size=$(stat -c%s "$PROJ_JOURNAL" 2>/dev/null || stat -f%z "$PROJ_JOURNAL" 2>/dev/null)
  echo "exists: $PROJ_JOURNAL (${size} bytes)"
else
  echo "no per-project journal.md for $PWD (slug: $SLUG)"
fi

section "done — mechanical checks complete, semantic interpretation happens in the calling skill"
