---
name: project_e2e_workflow_no_timeout_gap
description: "e2e.yml has no timeout-minutes on the job/Playwright-install step - a network hang can stall a PR's required check for hours"
metadata: 
  node_type: memory
  type: project
  originSessionId: 924fd0af-d91a-4eed-8b74-6793d0fa134b
  modified: 2026-08-19T08:00:04.636Z
---

`.github/workflows/e2e.yml`'s `e2e` job (and its "Install Playwright + chromium" step at ~line 533, `npm ci && npx playwright install chromium` in `gavan-cicd`) has no `timeout-minutes` set. Observed 2026-08-19: PR #307 sat with `mergeStateStatus: BLOCKED` because this step hung 22+ minutes with no forward progress and no failure — GitHub's default job timeout is 6h, so nothing would have failed it for a long time.

**Why:** commit a1a8bfd already tried fixing a related apt-get stall by dropping `--with-deps` from the playwright install, but the hang recurred anyway (different cause - network/download stall, not apt-get). No timeout means a stuck step reads as "still running," not "broken," so it's easy to mistake for a real long-running test and just wait.

**How to apply:** if a PR's `e2e` check is stuck (not failed, not passed) for more than a few minutes, don't assume it's a legit slow run — check the specific step via `gh run view <id> --json jobs`, and consider it a hang candidate first. Fix is to add `timeout-minutes` at the job or step level in `e2e.yml` so hangs fail fast and can auto-retry, and possibly cache Playwright browsers across runs to reduce install time/flakiness. Not yet applied as of 2026-08-19 - only worked around by cancelling and re-pushing to retrigger a fresh run.
