---
name: feedback_state_snapshot_protocol
description: "When and how to persist project state so a paused task can resume cleanly in a future session, without waiting for the user to ask twice"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f4081777-3b76-42f6-a459-d5c429ee019a
---

Write a durable state snapshot proactively at these trigger points — don't wait for the user to ask "where is this saved":

1. **SessionStart** (existing global protocol), **`/compact`** (existing), **git push/PR merge** (existing).
2. **New trigger, added after this incident**: the moment a task becomes blocked on an external party (a colleague, a third-party approval, anything outside Claude's or the user's direct control) and the session might reasonably end before it unblocks. Don't wait for the user to notice and ask.
3. **New trigger**: any explicit user request to "remember," "snapshot," or "save state" — but the goal is for this to rarely be necessary because triggers 1-2 already fired.

**Why:** During the Phase 1 per-developer-schema rollout (2026-07-05), a long implementation session hit a real external block (waiting on a colleague, Roy, to flip a dashboard setting). Nothing was written to durable memory until the user directly asked "where is the summary saved" — twice, since `journal.md` itself didn't even exist yet despite the global CLAUDE.md's Memory Protocol requiring per-task entries throughout. The task-level tracking (`TaskUpdate`) used throughout the session is session-scoped and doesn't survive to a new session by itself.

**How to apply — the actual snapshot template**, written to a `memory/project_*.md` file (not just `journal.md`, which is for raw chronological entries pending consolidation):

- **Why**: the goal/motivation for this piece of work, one or two sentences.
- **Current state**: what's done, and how it was verified (not just "implemented" — cite the actual check performed).
- **Blocked on**: exactly who/what, the exact ask already made (e.g. a message already sent), and what response unblocks it.
- **Next steps**: ordered, concrete, written so a future session can execute them without re-deriving context.
- **Files touched**: exact paths, and whether committed (with a reminder of any standing commit/push confirmation preference — see [[feedback_git_push_confirm]]).
- **Secrets exposed this session**: if any credential, token, or key hit the plaintext transcript, list it and note whether rotation is recommended. Don't let this silently drop.
- **Reference links**: any plan/spec file paths — prefer the in-repo copy (`docs/superpowers/plans/...`) as the durable source of truth over anything under `~/.claude/plans/`, which is a working-session artifact, not guaranteed long-term. Create the repo copy by default whenever a plan reaches approval, not as an afterthought.

Update the `MEMORY.md` index with a one-line pointer whenever a new project-state file like this is created.
