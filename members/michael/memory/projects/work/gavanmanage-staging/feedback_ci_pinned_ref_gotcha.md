---
name: feedback_ci_pinned_ref_gotcha
description: "gavanmanage's e2e.yml checks out the gavan-cicd test-helper repo at a pinned commit SHA, not a floating branch - a fix pushed to gavan-cicd silently does nothing in CI until that SHA is bumped too"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 924fd0af-d91a-4eed-8b74-6793d0fa134b
  modified: 2026-08-19T09:40:41.801Z
---

`.github/workflows/e2e.yml`'s "Checkout gavan-cicd" step pins `ref:` to an exact commit SHA in `Gavan-AI-Labs-LTD/gavan-cicd`, deliberately not `main` (comment in the workflow: "a test-code change over there should not silently break every gavanmanage PR's CI with no warning"). Caught 2026-08-19 mid-debugging PR #307: pushed a fix to `gavan-cicd/tests/e2e/stageActions.ts` (commit 7d20d14) to fix an E2E helper gap, and it would have had zero effect on the PR's CI run - the pinned SHA in `e2e.yml` was still pointing at the old commit.

**Why:** the pin is intentional and correct (prevents a test-repo change from silently breaking unrelated PRs), but it means "push a fix to gavan-cicd" is only half the job. Missing the second half produces a confusing failure mode: CI re-runs, looks like it picked up the fix, but actually reruns the exact same old test code and fails identically - easy to misread as "the fix didn't work" when really "the fix was never in the run at all."

**How to apply:** any time a fix lands in `gavan-cicd` (test helpers, fixtures, anything under `tests/e2e/`) that's meant to unblock a `gavanmanage` PR, immediately also bump the `ref:` SHA in `gavanmanage/.github/workflows/e2e.yml`'s "Checkout gavan-cicd" step to the new commit, in the same push. Get the real SHA with `git rev-parse HEAD` in the gavan-cicd repo after pushing - do not guess or truncate it (a fabricated SHA breaks the checkout entirely, worse than a stale-but-valid one). Before trusting "the gavan-cicd fix is live in this CI run," diff the pinned `ref:` against the gavan-cicd commit that actually contains the fix.
