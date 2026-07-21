---
name: feedback_branch_reuse_and_retarget
description: "Don't reuse an already-merged branch for new work; retargeting a PR's base via API doesn't retrigger required CI checks"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5441fdf6-df83-42e2-9683-94c8f5effd6c
  modified: 2026-07-21T07:02:14.947Z
---

Two related gotchas hit together on 2026-07-21 while shipping the sidebar/topbar z-index fix (PR #172, [[project_sidebar_topbar_stacking_fix]]):

1. **Don't reuse a branch whose PR already merged to staging.** `fix/scroll-hidden-behind-sticky-header` had PR #171 merged 9h earlier. New commits (spec/plan/fix docs) were added to the same local branch and pushed as PR #172. This silently breaks `gavan-cicd/cicd-manager`'s dashboard: `doneBranches` (built from all historically-merged PR head-refs) excludes the branch from the Private column unconditionally, so the new open PR becomes invisible on the board even though it's genuinely open on GitHub. Always cut a fresh `fix/*`/`feat/*` branch for new work, even if the old branch name would still "make sense."

2. **Editing a PR's base branch via `gh api ... -X PATCH -f base=...` does not retrigger required status checks.** The repo's `e2e.yml` triggers on `pull_request` with only the GitHub-default event types (`opened`, `synchronize`, `reopened`) — a base-branch edit is an `edited` event, not one of those. Opening #172 against the wrong base (`main`) meant E2E correctly never ran (workflow filters `branches: [staging]`); patching the base to `staging` afterward still didn't make E2E run, because the `edited` event doesn't match the trigger. Result: PR sat `mergeable: true` but `mergeStateStatus: BLOCKED` (required check *missing*, not failing) indefinitely. Fix: push a new commit (a real `synchronize` event) — an empty commit is fine, self-stamp per the code-review skill's zero-diff rule.

**How to apply:** When a base branch was wrong and gets corrected via API/`gh pr edit`, always follow with a push (even `git commit --allow-empty`) to force a `synchronize` event before assuming CI will run.
