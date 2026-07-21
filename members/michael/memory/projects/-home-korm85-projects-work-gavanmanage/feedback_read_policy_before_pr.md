---
name: feedback_read_policy_before_pr
description: "Read gavan-cicd/WORKFLOW.md before creating a PR, don't rely on memory of the policy"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5441fdf6-df83-42e2-9683-94c8f5effd6c
  modified: 2026-07-21T07:02:02.497Z
---

Before running `gh pr create`, actually open `~/projects/work/gavan-cicd/WORKFLOW.md` (pointed to from `gavanmanage/CLAUDE.md`) rather than acting from memory of what the policy says.

**Why:** On 2026-07-21, created PR #172 with base `main` instead of `staging` because I assumed "PR required" from `gavanmanage/CLAUDE.md` without checking which branch it targets. `staging` is where branch protection and the E2E gate actually live; `fix/*`/`feat/*` branches always PR to `staging`, never `main` — `main` is promote-only (`staging` -> `main`), per WORKFLOW.md. Michael caught it, not me.

**How to apply:** Every PR from a `fix/*`/`feat/*` branch targets `staging` unless explicitly doing a staging->main promote. Read WORKFLOW.md fresh each time policy-relevant decisions come up (branch base, review gate, auto-merge expectations) instead of reasoning from CLAUDE.md summaries or prior-session recall.
