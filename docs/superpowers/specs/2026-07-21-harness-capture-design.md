# Claude Code harness capture — full parity restore

## Problem

This repo's stated goal (README): let any team member, or Michael on a new/wiped machine, clone one repo and get a fully working Claude Code setup. In practice, that promise is only partly true today:

- **Memory** (`members/michael/memory/projects/`) existed on disk but had never once been committed to this repo, in any commit. Fixed 2026-07-21 (34 files, see commit "feat(memory): commit per-project memory snapshots for the first time") — but no repeatable way to keep it current going forward.
- **Hooks** (`team/claude/hooks/`) have drifted: 3 files differ in content from what's actually running (`global-session-start.sh`, `memory-git-consolidate.sh`, `memory-journal.sh`), 2 live hooks aren't captured at all (`memory-precompact.sh`, `todos-policy-injector.sh`), and 1 repo file (`slack-fetch.sh`) no longer exists live.
- **Settings** (`team/claude/settings.json.template`) is missing the entire `PreCompact` hook-event wiring that live `settings.json` has — consistent with `memory-precompact.sh` being uncaptured.
- **Skills** — the personal `~/.claude/skills/harness-health/` skill isn't in this repo anywhere.
- **Plugins** — the repo records two custom in-house plugins (`push-to-git`, `standup`) but has no record of which marketplace-sourced plugins (caveman, antigravity, superpowers, etc.) are enabled, so a restore wouldn't reinstall them.

## Goal

1. Bring every category (memory, hooks, settings, skills, plugins) up to date once.
2. Give Michael an on-demand way to check and re-sync going forward, without any background/automatic git activity.
3. Give Michael (non-coder) a plain-language `RESTORE.md` that walks him through recovery on a new machine by telling him what to say to Claude Code, not what commands to run.
4. Reserve, but do not fill in, space for Codex and Antigravity harness capture — Claude Code is the only tool actually captured this round.

## Scope

**In scope:** Claude Code harness only (memory, hooks, settings, skills, plugin references), the `harness-sync.sh` check/apply tool, `RESTORE.md`.

**Out of scope (explicitly deferred):**
- Real Codex/Antigravity capture — placeholder folders only (`codex/`, `antigravity/`, each with a one-line "not yet captured" note).
- Vendoring marketplace plugin source code — reference-only (name + marketplace), matching how plugin updates already work live.
- Automatic/background sync — every sync action is something Michael or an AI explicitly runs and reviews before committing.

## Repo structure changes

```
gavan-agent-config/
  RESTORE.md                          <- NEW, plain-language front door (see below)
  CLAUDE.md                           <- existing AI-facing restore instructions, extended (not rewritten) to cover skills + plugin reinstall
  team/claude/
    hooks/                            <- existing dir, content re-synced (drift fixed once)
    skills/                           <- NEW dir, personal skills copied in (harness-health/ first)
    plugins/                          <- existing (push-to-git, standup), unchanged
    settings.json.template            <- existing, gets the missing PreCompact hook entry added
    installed-plugins.json            <- NEW: [{"name": "...", "marketplace": "..."}] for marketplace-sourced plugins
    mcp.json.template                 <- existing per README; confirmed secrets are placeholders, not real values
  members/michael/memory/projects/    <- existing (first real commit landed 2026-07-21), ongoing sync via harness-sync.sh
  tools/
    harness-sync.sh                   <- NEW, the check/apply tool (see below)
  codex/
    README.md                         <- NEW, one line: "Not yet captured — planned for a future round."
  antigravity/
    README.md                         <- NEW, same one-liner.
```

## `tools/harness-sync.sh`

A single script, two modes, no configuration file — reads live paths under `~/.claude/` directly.

- **`harness-sync.sh check`** — for each category (memory, hooks, settings, skills, plugin list), diffs the live copy against the repo's copy. Prints a plain-language report per category: unchanged / added / changed / removed-live-but-in-repo. Makes no changes to any file.
- **`harness-sync.sh apply`** — re-runs the same diff, then for every drifted item: copies memory/hooks/skills files as-is; for `settings.json` and `mcp.json` specifically, copies the file but replaces known secret-bearing values with `PLACEHOLDER` before writing (matching the existing `settings.json.template` convention — the diffing logic must compare against the placeholder'd form, not raw values, so a secret rotating alone doesn't show as drift); writes `installed-plugins.json` from `~/.claude/plugins/installed_plugins.json` (name + marketplace source only, no plugin code). Never runs `git add`/`commit`/`push` itself — leaves that to Michael or whoever ran it, so every change is reviewed before it lands in history.

Running `check` regularly (manually, whenever Michael or an AI session remembers to) is how "on-demand" sync happens — no cron, no hook, no background job.

## `RESTORE.md`

Plain language, no terminal commands shown as things to type — every step phrased as "say this to Claude Code" or "you'll see this happen." Structure:

1. **When to use this** — new laptop, wiped machine, or setting up a second computer.
2. **Before you start** — the one manual thing that can't be automated: making sure Claude Code itself is installed (link to Anthropic's own install instructions, not reproduced here).
3. **The one thing to say** — a single sentence Michael types into a fresh Claude Code session (e.g. "Restore my Claude Code setup from github.com/MichaelGavanAI/gavan-agent-config") that kicks off the AI following `CLAUDE.md`'s technical steps.
4. **What you'll be asked for** — secrets (API keys, tokens) explicitly called out as an expected prompt, with one sentence on why they were never stored in the repo.
5. **How you'll know it worked** — one plain-language check per category (e.g. "ask Claude about an old project — it should remember details from before," not "verify `~/.claude/projects/*/memory/MEMORY.md` exists").
6. **If something looks wrong** — 2-3 plain symptoms (Claude doesn't remember anything, a skill/command seems missing) each pointing back to "tell Claude Code what you're seeing and it can diagnose using `tools/harness-sync.sh check`," not a troubleshooting flowchart Michael has to self-serve.

`RESTORE.md` is the only doc Michael is expected to read directly; `CLAUDE.md` remains the AI-facing technical layer underneath it, extended per the "Repo structure changes" section above but not rewritten in nature.

## Testing / verification

- After building `harness-sync.sh check`, run it against the current (already-drifted-in-known-ways, now partly fixed) machine state and confirm its report matches the drift already documented in this spec's Problem section — i.e. the tool actually finds what we already know is wrong, not a false-clean report.
- After building `harness-sync.sh apply`, run it once for real, then re-run `check` and confirm it reports clean (proves apply actually closed the gaps it found).
- `RESTORE.md` gets a read-through from Michael (non-coder) before this is considered done — his own confirmation that he could follow it without help is the actual acceptance test, not a technical review.
