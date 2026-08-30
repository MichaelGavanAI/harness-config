---
name: feedback_git_branch_divergence_before_push
description: "Before pushing a long-lived feature branch, check both origin/staging divergence AND origin's own copy of the same branch - both can hold unbacked-up work"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f35a90e9-baf0-4dbd-9a3f-baa184002ab8
  modified: 2026-08-17T06:28:15.399Z
---

Before pushing a feature branch that has been open a while, check for divergence in two separate places, not just one:

1. `git pull origin staging --rebase` (or the repo's pre-push hook) can trigger a replay of the branch's *entire* commit history against staging if the branch base has drifted far enough - not just the new commits. If a rebase wants to replay far more commits than you just made, abort (`git rebase --abort`, safe and non-destructive) and use `git merge origin/<base>` instead: one conflict-resolution pass against current state, rather than replaying every old commit one at a time against progressively-different history.
2. Separately, `git fetch origin <branch>` before push, even if `git rev-parse --abbrev-ref @{u}` says no upstream is configured - a remote copy of the same branch name can still exist with commits from a prior session that were never pulled locally. A plain `git push` will be rejected as non-fast-forward in that case (safe), but do not resolve that by force-pushing - fetch, merge, and verify.

**Why:** Hit this on `fix/material-advisor-wizard-back-navigation-chips` (2026-08-17). A `pull --rebase` wanted to replay 40 commits (aborted). After merging staging and pushing, the push was rejected - it turned out origin already had 5 commits on that exact branch name from a prior session (chip-row UI, masking/coping step work) that existed nowhere else - not on staging, not in the local clone. A force-push at that point would have destroyed real, unbacked-up work with zero recovery path.

**How to apply:** Never treat "no upstream configured" as "safe to push straight through." Always fetch the target branch name explicitly first. When two divergent histories both contain real work, merge (don't cherry-pick blindly) and diff each conflicted file against both parents to check whether one side's changes are a strict superset, a stale pre-review duplicate (check for the same PR number merged under a different commit hash), or genuinely independent work needing manual reconciliation - then run the full affected test suite before committing the resolution, never after.
