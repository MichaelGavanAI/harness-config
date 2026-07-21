# Claude Code Harness Capture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `gavan-agent-config` to real parity with Michael's live Claude Code setup (memory, hooks, settings, skills, plugins), give him an on-demand tool to keep it that way, and give him a plain-language restore guide.

**Architecture:** One bash script (`tools/harness-sync.sh`) with `check`/`apply` modes does the mechanical diffing and copying for the categories that are safe to automate (memory, hooks, skills, plugin-list). Settings and MCP config are structurally checked (are the right hook events / server names present) but never auto-copied in full, because they carry secrets and machine-specific paths that only a human should scrub — the script flags drift there for manual review instead of guessing at redaction. `RESTORE.md` is then a thin, plain-language wrapper that tells Michael what to say to Claude Code; the technical steps underneath (including plugin reinstall and skill restore) get added to `CLAUDE.md`, which stays the AI-facing layer.

**Tech Stack:** bash, python3 (already used for JSON handling elsewhere in this repo's docs), no new dependencies.

## Global Constraints

- Never write real secrets (API keys, tokens) into any file this plan creates or touches. `settings.json` and `mcp.json` are never auto-copied in full by `harness-sync.sh` — only diffed structurally (hook event names / MCP server names), matching the scope-narrowing decided during planning (the spec's "replace secrets with PLACEHOLDER" auto-copy idea was judged too risky to implement generically; manual review is safer).
- `harness-sync.sh` never runs `git add`/`commit`/`push` — every change it makes to the repo stays as an uncommitted diff for a human (or AI, with the human still reviewing) to commit deliberately.
- Codex and Antigravity get placeholder folders only — no real capture logic in this plan.
- Marketplace-sourced plugins are captured as name + marketplace-source references only (for reinstall), never vendored source code.
- `RESTORE.md` must contain zero terminal commands as things to literally type — every step is phrased as what to say to Claude Code or what you'll observe, per the approved design.

---

### Task 1: `harness-sync.sh` — check mode (memory, hooks, skills, plugins, settings/mcp structural checks)

**Files:**
- Create: `tools/harness-sync.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks (first task).
- Produces: `harness-sync.sh check` (read-only) and `harness-sync.sh apply` (writes files, never commits) — later tasks and RESTORE.md/CLAUDE.md reference these two invocations by name.

- [ ] **Step 1: Write `tools/harness-sync.sh`**

```bash
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
  local repo_dir="$REPO_ROOT/members/michael/memory/projects"
  mkdir -p "$repo_dir"
  for proj_dir in "$LIVE_CLAUDE"/projects/-home-korm85-projects-*/; do
    [ -d "${proj_dir}memory" ] || continue
    local proj_name
    proj_name=$(basename "$proj_dir")
    local repo_proj_dir="$repo_dir/$proj_name"
    mkdir -p "$repo_proj_dir"
    for f in "${proj_dir}memory"/*.md; do
      [ -f "$f" ] || continue
      local bn repo_f
      bn=$(basename "$f")
      repo_f="$repo_proj_dir/$bn"
      if [ ! -f "$repo_f" ]; then
        report "memory" "missing-in-repo" "$proj_name/$bn"
        [ "$MODE" = "apply" ] && cp "$f" "$repo_f"
      elif ! diff -q "$f" "$repo_f" >/dev/null 2>&1; then
        report "memory" "changed" "$proj_name/$bn"
        [ "$MODE" = "apply" ] && cp "$f" "$repo_f"
      fi
    done
  done
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
sync_hooks
sync_skills
sync_settings
sync_mcp
sync_plugins

if [ "$DRIFT_FOUND" -eq 0 ]; then
  echo "Clean — no drift found."
elif [ "$MODE" = "check" ]; then
  echo ""
  echo "Run 'harness-sync.sh apply' to copy over memory/hooks/skills/plugins drift."
  echo "settings/mcp drift above needs a manual look — never auto-copied (secrets)."
fi
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x tools/harness-sync.sh
```

- [ ] **Step 3: Run check mode against current live state**

```bash
./tools/harness-sync.sh check
```

Expected: prints `[hooks] changed: global-session-start.sh`, `[hooks] changed: memory-git-consolidate.sh`, `[hooks] changed: memory-journal.sh`, `[hooks] missing-in-repo: memory-precompact.sh`, `[hooks] missing-in-repo: todos-policy-injector.sh`, `[hooks] stale-in-repo: slack-fetch.sh (...)`, `[skills] missing-in-repo: harness-health`, `[settings] missing-hook-event: PreCompact (...)`, `[plugins] changed: ...`. This must match the drift already documented in `docs/superpowers/specs/2026-07-21-harness-capture-design.md`'s Problem section — if it doesn't, the script has a bug, not the repo.

- [ ] **Step 4: Commit**

```bash
git add tools/harness-sync.sh
git commit -m "feat(harness-sync): add check/apply drift tool for hooks/skills/settings/mcp/plugins/memory"
```

---

### Task 2: Run `apply` for real — close the hooks/skills/plugins/memory drift

**Files:**
- Modify: `team/claude/hooks/global-session-start.sh`, `team/claude/hooks/memory-git-consolidate.sh`, `team/claude/hooks/memory-journal.sh` (content sync)
- Create: `team/claude/hooks/memory-precompact.sh`, `team/claude/hooks/todos-policy-injector.sh`, `team/claude/skills/harness-health/` (full copy), `team/claude/installed-plugins.json`
- No test file — this task's own re-run of `check` is its test.

**Interfaces:**
- Consumes: `tools/harness-sync.sh` from Task 1.
- Produces: an up-to-date `team/claude/hooks/`, `team/claude/skills/`, `team/claude/installed-plugins.json` that Task 5 (CLAUDE.md restore steps) and Task 6 (RESTORE.md) both reference by path.

- [ ] **Step 1: Run apply**

```bash
./tools/harness-sync.sh apply
```

Expected: same category lines as Task 1 Step 3's `check` output, but this time the files actually land on disk (hooks/skills/memory copied, `installed-plugins.json` written). `settings`/`mcp` lines still print — those are never auto-applied.

- [ ] **Step 2: Re-run check, confirm the auto-syncable categories are now clean**

```bash
./tools/harness-sync.sh check
```

Expected: no more `[hooks]`, `[skills]`, `[memory]`, `[plugins]` lines except the pre-existing `[hooks] stale-in-repo: slack-fetch.sh` (not auto-removed by design — leave it, it's a decision for a human, not a bug). `[settings] missing-hook-event: PreCompact` still prints — that's Task 3's job.

- [ ] **Step 3: Decide on the stale `slack-fetch.sh`**

Check whether it's still wanted:

```bash
git log --all --oneline -- team/claude/hooks/slack-fetch.sh | head -3
```

If it was intentionally removed live and isn't needed, delete it from the repo:

```bash
git rm team/claude/hooks/slack-fetch.sh
```

If unsure, leave it — it causes no harm sitting in the repo unused, just document it stays until confirmed dead (add nothing further; this step is a judgment call, not a hard requirement).

- [ ] **Step 4: Commit**

```bash
git add team/claude/hooks/ team/claude/skills/ team/claude/installed-plugins.json
git commit -m "feat(harness): sync drifted hooks, add missing hooks/skills, capture plugin list"
```

---

### Task 3: Fix `settings.json.template`'s missing `PreCompact` wiring

**Files:**
- Modify: `team/claude/settings.json.template`

**Interfaces:**
- Consumes: nothing new.
- Produces: nothing new — no later task depends on this file's exact shape beyond "has `PreCompact`."

- [ ] **Step 1: Add the missing hook block**

Open `team/claude/settings.json.template`, and inside the top-level `"hooks"` object, add:

```json
"PreCompact": [
  {
    "matcher": "manual",
    "hooks": [
      { "type": "command", "command": "${HOME}/.claude/hooks/memory-precompact.sh", "timeout": 5 }
    ]
  },
  {
    "matcher": "auto",
    "hooks": [
      { "type": "command", "command": "${HOME}/.claude/hooks/memory-precompact.sh", "timeout": 5 }
    ]
  }
]
```

(No secrets in this block — `${HOME}` is a portable env var reference, not a real path, and `memory-precompact.sh` was just captured in Task 2.)

- [ ] **Step 2: Validate JSON**

```bash
python3 -m json.tool team/claude/settings.json.template > /dev/null && echo "valid JSON"
```

Expected: `valid JSON`.

- [ ] **Step 3: Re-run check, confirm settings drift is gone**

```bash
./tools/harness-sync.sh check
```

Expected: no more `[settings]` lines. `[mcp]` may still print if `team/mcp.json.template` is missing a server — check its output; if it prints a `[mcp] missing-server` line, add that server to `team/mcp.json.template` by hand with real values replaced by `{{PLACEHOLDER}}` (matching the existing `figma`/`linkedin-browser` entries' style), then re-run check again to confirm clean.

- [ ] **Step 4: Commit**

```bash
git add team/claude/settings.json.template team/mcp.json.template
git commit -m "fix(harness): add missing PreCompact hook wiring to settings template"
```

---

### Task 4: Codex and Antigravity placeholder folders

**Files:**
- Create: `codex/README.md`
- Create: `antigravity/README.md`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing later tasks depend on — these are inert placeholders.

- [ ] **Step 1: Create `codex/README.md`**

```markdown
# Codex harness capture

Not yet captured — this repo's Codex support is a placeholder for a future round. Claude Code is the only tool with real capture today (see `team/claude/`).
```

- [ ] **Step 2: Create `antigravity/README.md`**

```markdown
# Antigravity harness capture

Not yet captured — this repo's Antigravity support is a placeholder for a future round. Claude Code is the only tool with real capture today (see `team/claude/`).
```

- [ ] **Step 3: Commit**

```bash
git add codex/README.md antigravity/README.md
git commit -m "chore: reserve codex/ and antigravity/ folders for future harness capture"
```

---

### Task 5: Extend `CLAUDE.md` restore instructions — skills and plugin reinstall

**Files:**
- Modify: `CLAUDE.md` (append new restore steps after the existing per-project memory loop, without rewriting what's already there)

**Interfaces:**
- Consumes: `team/claude/skills/` and `team/claude/installed-plugins.json` from Task 2.
- Produces: the restore steps `RESTORE.md` (Task 6) points to as "the technical layer underneath."

- [ ] **Step 1: Find the existing memory-restore loop's location**

```bash
grep -n "for proj_dir in members/michael/memory/projects" CLAUDE.md
```

Expected: prints the line number of the existing loop (documented at CLAUDE.md's restore section). Note that line number — new steps get inserted immediately after that loop's closing, not before or in the middle of it.

- [ ] **Step 2: Add a skills-restore step right after the memory loop**

Insert this block immediately after the existing memory-restore loop in `CLAUDE.md`:

```bash
# Restore personal skills (e.g. harness-health)
mkdir -p ~/.claude/skills
cp -r team/claude/skills/* ~/.claude/skills/
```

- [ ] **Step 3: Add a plugin-reinstall step**

Insert this block right after the skills-restore step:

```markdown
### Reinstall plugins

Read `team/claude/installed-plugins.json` — for each entry, add its marketplace first (if not already known), then install the plugin:

```
/plugin marketplace add <marketplaceSource.repo-or-url from the entry>
/plugin install <name>@<marketplace>
```

Repeat for every entry in the file. This reinstalls the *current* version from each marketplace — it does not restore a frozen old version, since marketplace plugins are meant to stay current (see `docs/superpowers/specs/2026-07-21-harness-capture-design.md`'s Plugin capture decision).
```

- [ ] **Step 4: Verify the file is still well-formed markdown (no broken headers/fences)**

```bash
grep -c '^```' CLAUDE.md
```

Expected: an even number (every opened code fence has a matching close). If odd, find the unclosed fence from Step 2 or 3's insertion and fix it.

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "docs(claude): extend restore instructions for skills and plugin reinstall"
```

---

### Task 6: `RESTORE.md` — the plain-language front door

**Files:**
- Create: `RESTORE.md`

**Interfaces:**
- Consumes: nothing programmatically — it's a doc that references `CLAUDE.md` (Task 5) and `tools/harness-sync.sh check` (Task 1) by name for humans to act on.
- Produces: nothing later tasks depend on.

- [ ] **Step 1: Write `RESTORE.md`**

```markdown
# Getting your Claude Code setup back

## When to use this

- You got a new laptop.
- Your old laptop was wiped, lost, or died.
- You're setting up a second computer and want it to work the same way.

## Before you start

Claude Code itself needs to be installed first — that's the one manual step this guide doesn't cover. If it's not already installed, go to Anthropic's own Claude Code page and follow their install steps. Once you can open a Claude Code session, come back here.

## The one thing to say

Open a fresh Claude Code session anywhere on your computer, and say exactly this:

> Restore my Claude Code setup from github.com/MichaelGavanAI/gavan-agent-config

Claude will read this repository and start putting your setup back together — your saved notes about past projects, your custom shortcuts and automations, and your installed add-ons.

## What you'll be asked for

At some point, Claude will likely ask you to paste in an API key or similar secret (for example, a Figma key). This is expected — those are never saved in this repository on purpose, so nothing sensitive sits on GitHub. Just paste the value in when asked.

## How you'll know it worked

- **Ask Claude about an old project** ("what were we working on in gavanmanage last week?"). If it remembers real details, your notes came back correctly.
- **Try a shortcut you used before** (a slash command or a phrase you'd normally use, like caveman mode). If it responds the way it used to, your automations came back correctly.
- **Check your add-ons are there.** If you had specific plugins installed before (ask Claude "what plugins do I have installed?"), they should be reinstalled and listed.

## If something looks wrong

- **Claude doesn't remember anything about your past work** — tell Claude directly: "my memory doesn't seem to have come back, can you check?" It can run a diagnostic (`tools/harness-sync.sh check`) to see what's missing.
- **A shortcut or automation you used before seems to not exist anymore** — same thing: describe what you expected to Claude, and it can look for the gap.
- **You're not sure if something is missing at all** — just ask Claude to double check your setup against this repository. That's exactly what it's built to do.
```

- [ ] **Step 2: Verify markdown renders sanely (no unclosed fences, matches repo style)**

```bash
grep -c '^```' RESTORE.md
```

Expected: an even number. There are no code fences opened in this file (it deliberately shows zero literal commands per the design), so this should print `0`.

- [ ] **Step 3: Commit**

```bash
git add RESTORE.md
git commit -m "docs: add plain-language RESTORE.md for non-technical recovery"
```

---

### Task 7: Final full run-through and push

**Files:** none new — verification only.

**Interfaces:** none — terminal task.

- [ ] **Step 1: Full clean check**

```bash
./tools/harness-sync.sh check
```

Expected: `Clean — no drift found.` (or only the intentionally-left `slack-fetch.sh` stale-hook line from Task 2 Step 3, if that judgment call was to keep it).

- [ ] **Step 2: Confirm all commits are present**

```bash
git log --oneline -8
```

Expected: sees the 6 commits from Tasks 1–6 (harness-sync tool, hooks/skills/plugins sync, settings template fix, codex/antigravity placeholders, CLAUDE.md restore steps, RESTORE.md) at the top.

- [ ] **Step 3: Push**

```bash
git push origin main
```

- [ ] **Step 4: Hand off `RESTORE.md` to Michael for a read-through**

This is the spec's actual acceptance test (not a technical check): Michael reads `RESTORE.md` himself and confirms he could follow it without help. Report to him that everything is pushed and ask him to do this read-through before considering the work fully done.
