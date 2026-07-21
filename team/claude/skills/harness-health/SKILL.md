---
name: harness-health
description: Diagnose the Claude Code hook and memory harness (~/.claude/settings.json + ~/.claude/hooks/) for dead, broken, or orphaned wiring. Use whenever the user asks to check, audit, diagnose, or verify their hooks, their memory system, whether a hook is actually working, why a memory bucket doesn't seem to load, or generally "is my setup healthy" for Claude Code's hook/memory configuration. Also use proactively right after any hook script or settings.json edit, to confirm the change didn't silently break something else.
---

Run a full audit of the hook/memory harness and report findings clearly, grouped by what's actually wrong versus what's fine. The core discipline: verify against the real files and the real installed binary, never assume from documentation or from what a script's comments claim it does. A hook script's own comments can be stale or aspirational — only its actual code, and whether that code's target event genuinely exists in the installed Claude Code version, count as ground truth.

## Why this matters

Hook/memory configuration rot silently. A hook can be edited to reference a memory bucket that later gets renamed. A script can be wired to an event name that doesn't exist in the currently-installed Claude Code version (nothing errors — it just silently never fires). A memory bucket can exist on disk with real content that nothing reads. None of these produce an error message anywhere — they just quietly stop doing their job. This skill exists because exactly this happened once already (a per-project memory bucket existed and had real content, but no hook read from it — discovered only by manually reading every script).

## Step 1: run the mechanical checks

```bash
bash ~/.claude/skills/harness-health/scripts/audit.sh
```

This script is read-only and safe to run anytime. It checks:
- `settings.json` is valid JSON
- which hook events (`SessionStart`, `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `PreCompact`, `PostCompact`, `SessionEnd`, `Stop`, `SubagentStop`, `Notification`) actually exist in the currently-installed `claude` binary — found via `strings` on the resolved binary path, not from documentation, since documentation can lag or not match the user's installed version
- every hook command referenced in `settings.json`: does the script file actually exist, does it pass a syntax check (`bash -n` or `node --check`)
- hook scripts that exist on disk in `~/.claude/hooks/` but aren't referenced by any entry in `settings.json` at all (orphaned)
- which hook scripts reference each of the three memory buckets (global, the shared work/personal bucket, the per-project escaped-cwd bucket) — a bucket nothing references is a bucket that's write-only
- `journal.md` files that exist and their size, including the current directory's own per-project journal

Treat this script's output as raw material, not the final report — some of it needs your judgment on top (Step 2).

## Step 2: judgment calls the script can't make

The script tells you facts; you still need to reason about a few things it can't check mechanically:

1. **Configured events that aren't in the supported list.** If `settings.json` has a hook wired to an event name the binary's `strings` output didn't include, that hook is dead — it will never fire, silently. This is the highest-severity finding possible; call it out first if found.

2. **Matchers that can never realistically match.** A `matcher` field that's a typo'd tool name, an empty string where a specific tool was clearly intended, or a regex that can't match anything real, means the hook is wired but inert. Read the matcher against the actual tool names Claude Code uses (`Write`, `Edit`, `Bash`, `Agent`, `Read`, etc. — check other working matchers in the same file for the real spelling/casing convention) rather than guessing.

3. **A hook that fires but silently no-ops for the common case.** Read the actual logic of each memory-related hook, not just confirm it exists. For example: does a consolidation-reminder hook bail out early for some context (like a `CONTEXT_LABEL == "none"` case) in a way that quietly skips the exact scenario it was meant to help with? This was a real bug found and fixed once already — check for regressions of the same shape.

4. **A memory bucket with content but no reader**, or **a bucket every hook assumes exists but nothing ever creates.** Cross-reference the script's bucket-reference output against which bucket directories actually exist on disk (`ls ~/.claude/projects/global/memory/`, `~/.claude/projects/work/memory/`, and the current project's own bucket) — a mismatch either way is worth flagging.

## Step 3: report format

Lead with a one-line verdict (healthy / N issues found), then group findings by severity, not by check-number:

```
## Harness health: <N issues found | all clear>

### Dead (wired but will never fire)
- <event/hook>: <why — e.g. "PreCompact hook present, but `Notification` matcher typo'd as `Notifcation`">

### Orphaned (exists, not wired anywhere)
- <script path>: <what it looks like it was meant to do, inferred from its content>

### Silent no-op (fires, but its own logic skips the case that matters)
- <hook>: <the condition that causes the skip, and why that's the common case not an edge case>

### Bucket mismatches
- <bucket>: <e.g. "has 3 memory files, but no hook script references its path — write-only">

### Confirmed healthy
- <brief list of what's actually working correctly, so the user isn't left wondering if anything was checked and passed>
```

If nothing is wrong, say so plainly and briefly — don't manufacture findings to seem thorough. A clean report is a valid, useful outcome.

## Notes

- This audits `~/.claude/` global configuration, not anything project-specific — it's the same report regardless of which project directory you're standing in, except for the per-project memory bucket check (Step 1's last item), which is relative to the current working directory.
- Never edit anything as part of this skill unless the user explicitly asks you to fix a specific finding afterward — this is diagnosis only. If asked to fix something found, treat that as its own follow-up task: back up the file first, make the narrowest change that closes the specific gap, and re-run the audit to confirm the fix actually worked.
