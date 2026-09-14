---
name: project_pr115_conflict_and_cicd_badges
description: PR
metadata: 
  node_type: memory
  type: project
  originSessionId: 56062749-8002-4414-9aa2-d54577a6c43e
---

PR #115 (`feat--Support-multi-materials` -> staging, author Roy) was stuck with zero CI runs. Root cause: branch was 18 commits behind staging, causing real conflicts (`ShadeAnalysisPanel.tsx`, `maManualSelection.ts`, `sync-staging.yml`) — GitHub can't compute a test-merge commit when a PR is unmergeable, so `pull_request`-triggered workflows (e2e.yml) silently never fire. Not a code bug, not a policy violation — Roy's machine lacks the `gavan-cicd/hooks/pre-push` hook (no `install-hooks.sh` run), so the local "branch >5 commits behind -> block push" check never ran for him.

Roy also manually enabled GitHub's native "auto-merge" on PR #115 before it was mergeable — this is *not* a policy bypass since `staging`'s ruleset requires the `e2e` status check (`required_status_checks: [{"context":"e2e"}]`), enforced server-side regardless of auto-merge toggle.

**Why:** Michael non-coder, needed the failure mode explained from first principles (rebase vs merge, why conflicts happen, what's automated vs manual).

**How to apply:** [[feedback_ci_badge_design]] for the design decisions made about surfacing this in the dashboard. The real dashboard app is `~/projects/work/gavan-cicd/cicd-manager/index.html` (Cloudflare Pages app, own repo) — NOT `gavanmanage/tools/cicd-monitor.html` (stale/unused duplicate, easy to edit by mistake — confirm which file renders before making UI changes here).

Fix pushed: branch `feat/cicd-manager-conflict-badges` on `gavan-cicd`, adds red "Conflict with staging — CI has not run" and blue "Auto-merge primed" banners to private-column PR cards when `mergeable === false` / `auto_merge` is set. Not yet merged to `gavan-cicd` main — needs PR + merge.

Still to send Roy: install hooks (`bash ~/projects/work/gavan-cicd/hooks/install-hooks.sh`), fix branch naming (`feat--Support-multi-materials` should be `feat/support-multi-materials` — hook blocks non-conforming names), and resolve PR #115's conflicts (merge origin/staging in, keep staging's `sync-staging.yml`).

**Deep logic audit (2026-07-02), same branch `fix/duplicate-pr-on-stale-promote-button`:** found and fixed 2 more real bugs while doing a full read-through of `cicd-manager/index.html`:
1. Both closed-PR list queries (`base=main`, `base=staging`) used `sort=updated` with no `direction` — GitHub defaults to ascending, so on a repo with >20/50 closed PRs it silently fetched the OLDEST merged PRs, not newest. This broke `doneBranches` (branch stayed in Private column after merge — the #116/#117 duplicate-PR incident), `lastRelease` detection, and the Staging column's merged-PR list. Fixed with explicit `direction=desc`.
2. The `main-active` (promote-to-production) card only branched on `mergeable_state` clean/blocked/behind/unknown — real value `dirty` (actual conflict) fell through to the catch-all "CI running, wait" message, hiding a conflict on the highest-stakes action in the tool. Also added proper handling for `unstable` (GitHub still permits merge, non-required check failing).

Confirmed NOT a bug: the "main has N commit(s) not in staging" banner is accurate — verified via direct tree-SHA comparison that main and staging genuinely diverge (a real `sync-staging.yml` gap after PR #111's promote, unrelated to the monitor code).

**Root cause of the divergence itself (found 2026-07-02), fixed in gavanmanage PR #118:** `sync-staging.yml`'s "skip if no file changes" optimization exited without ever pushing to `origin/staging` when a fast-forward merge produced zero file diff — the ancestry advance existed only in the ephemeral runner and was discarded. `ahead_by` is graph-based, not content-based, so this left a permanent divergence even when content matched. The dashboard's `treesIdentical` banner-suppression masked it for a day (content coincidentally matched), until unrelated feature work (#116/#117) broke that coincidence and the banner reappeared looking "new." Fix: always push+open the sync PR regardless of file diff — verified safe via `sync-merge-route.sh` (routes `github-actions[bot]`-authored `feat/sync-main-to-staging-*` PRs to a real `--merge`, not squash, so no infinite-loop regression).

Branch `feat--Support-multi-materials` (stale, superseded by #116/#117) deleted on gavanmanage.

**Full chain of gavanmanage CI/CD fixes, 2026-07-02 (all in `.github/workflows/sync-staging.yml`):**
1. `#118` (merged→staging→main via #119): stopped discarding zero-diff ancestry syncs.
2. `#120` (merged→staging, NOT yet on main): fixed the `if:` condition — push-to-main trigger has been dead since it was added (only workflow_dispatch ever worked), condition never matched a plain push event.
3. `#121` (open, staging): switched `gh pr create` from `secrets.GITHUB_TOKEN` (blocked by repo's "Allow Actions to create/approve PRs" = off) to `secrets.GH_PAT` (same token e2e.yml's auto-merge already uses) — found via a live failed workflow_dispatch run. Also added orphan-branch cleanup on PR-create failure (with a re-check to avoid deleting a branch whose PR actually succeeded server-side despite a client-side error).

**Key mechanic to remember:** workflow YAML changes only take effect once they reach the branch the trigger event fires on (`main`, for this workflow) — merging to `staging` alone does nothing for `push`/`workflow_dispatch(ref:main)` triggers. Every fix needs the full staging→main promote before it's live. #120 and #121 both still need that promote as of this writing.

**Also fixed:** `delete_branch_on_merge` was `false` — recommended flipping so merged branches stop lingering (root cause of #116/#117 clutter and the orphaned sync branch). Not yet actioned.

**agy note:** the push-hook's agy review has a high false-positive rate — its keyword-grep flags `[SECURITY]`/`[PII]`/`[PATIENT` even when the review body says "None identified" right next to those brackets (template headers). Always read the actual body before treating an escalation as real. Also times out frequently (3 for 3 on a larger cicd-manager diff) — don't retry more than twice, treat as "unavailable" and rely on direct review.
