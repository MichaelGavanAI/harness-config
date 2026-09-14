---
name: feedback_ask_branch_topology_upfront
description: "In any repo, ask the user to define the feature/staging/production branch topology up front instead of inferring or guessing branch names/roles"
metadata:
  type: feedback
---

When working in a repo whose branch model (which branch is the safe feature-integration
target, which is production, whether there's an intermediate staging tier, what the branches
are actually named) is not already established in this conversation or in project CLAUDE.md,
ask the user to state it explicitly before opening PRs, pushing, or writing any repo-specific
tooling (hooks, scripts, CI config) that encodes branch names/roles.

**Why:** During a `gavanmanage` PR push, a project-level hook (`guard-gh-pr-create.mjs`)
hardcoded the assumption "the safe target is a branch literally named `staging`, production is
`main`, promoted via a specific PR flow." That assumption happened to be correct for
`gavanmanage`, discovered only by trial/error (a failed push) and by reading docs
(`gavan-cicd/WORKFLOW.md`) after the fact — not asked up front. The user pointed out this is a
harness-level gap: I should proactively elicit the feature → staging → production topology
(even when branch names differ from repo to repo) rather than assuming or reverse-engineering
it mid-task.

**How to apply:**
- On first push/PR/branch-related action in a repo I haven't worked in this session, check
  CLAUDE.md and existing tooling (`.claude/hooks/`, CI configs) for an already-documented branch
  topology first.
- If none is found, ask directly: "What's this repo's branch flow? (e.g. feature branches → an
  integration branch → production, or straight to production) and what are the actual branch
  names?" before pushing, opening a PR, or writing anything (hooks, scripts) that encodes those
  names.
- Do not infer topology solely from branch names appearing to match common patterns
  (`staging`, `main`, `develop`, `prod`) — confirm with the user, since names vary and getting
  it wrong risks pushing to the wrong target or writing incorrect guard logic.
