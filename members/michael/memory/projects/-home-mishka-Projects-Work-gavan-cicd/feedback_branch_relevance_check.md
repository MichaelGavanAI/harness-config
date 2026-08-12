---
name: feedback_branch_relevance_check
description: "Always check whether the current git branch is relevant to the task before editing files on it — don't assume the checked-out branch is the right one"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1962b4c6-6eed-4443-802e-4a30f63d0033
---

Before editing any tracked file, check whether the currently checked-out branch actually relates to the task at hand. Don't just edit in place on whatever branch happens to be checked out.

**Why:** Michael caught me editing `gavanmanage/.github/workflows/e2e.yml` (a CI fix for Roy's case 2) directly on `feat/calibration-multi-media` — an unrelated in-progress feature branch with its own uncommitted work. His correction: "this feat has nothing to do with cicd changes — always check for context relevance before using a branch."

**How to apply:**
- Before writing to a tracked or new file, run `git status`/`git branch --show-current` and ask: does this branch's name/purpose match what I'm about to change?
- If not, isolate the new work: `git stash push -u -m "<desc>" -- <exact paths>` (list files explicitly to avoid sweeping up unrelated changes), then create the right branch and `git stash pop` there.
- If the current branch has other unrelated uncommitted changes that block a plain `git switch`, use `git worktree add ../<name> -b <new-branch> origin/<base>` instead of fighting the checkout — never touch or stash someone else's in-progress unrelated edits to force a switch.
