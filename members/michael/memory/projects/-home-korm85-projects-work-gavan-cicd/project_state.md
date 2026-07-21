---
name: project-state
description: "CI pipeline status, open backlog items, recent fixes for gavan-cicd / gavanmanage"
metadata: 
  node_type: memory
  type: project
  originSessionId: 71bee85d-e33b-4e83-99f9-4a3b609d6bb5
---

## Session snapshot — 2026-07-15 (second session, later that day)

**Why:** Michael flagged the live board still showing a pileup of `feat/sync-main-to-staging-*` cards in Private, asking why despite yesterday's zero-diff fast-path fix. Investigated end to end.

**Findings:**
- Backend fix from earlier the same day works correctly — confirmed PR #148 (a real auto-generated sync PR) fast-merged in ~29s, no full pipeline run. Not the cause.
- Root cause was a **separate, previously-unknown bug** in `cicd-manager/index.html`'s Private-column filter: it relied solely on a `mergedStagingRes` fetch (`doneBranches` set) to hide already-merged sync branches from Private. Any silent fetch failure left `doneBranches` empty with no fallback, so every historical sync branch (even merged days ago) reappeared as pending work — matches the screenshot exactly. Distinct from the PR #6 fix from the prior session (that one excluded sync PRs from the *Recent Merges* list, a different code path).
- Fix: added `"feat/sync-main-to-staging-"` and `"sync/main-to-staging-"` to `EXCLUDED_PREFIXES` (`gavan-cicd/cicd-manager/index.html`) — hard branch-name filter, independent of the flaky fetch.

**Branch-relevance catch mid-session:** initially committed the fix directly onto `feat/multi-repo-monitor` (the branch checked out at session start) without checking deploy target first — that branch is unmerged WIP, 622-line diff from `main` on the same file, and Cloudflare only deploys `main`. Caught this before declaring done, asked Michael, he chose immediate deploy. Re-applied the same 1-line fix via a fresh worktree off `origin/main` (cherry-pick hit a conflict due to line-number drift between the two versions of `EXCLUDED_PREFIXES`, so applied manually instead) — see [[feedback_branch_relevance_check]], this is exactly the failure mode that memory exists to catch, and this time the check happened *after* the first commit, not before. **Lesson reinforced: check deploy-target/branch relevance before editing, not after landing a commit.**

**Final state:**
- `gavan-cicd` PR #7 (`fix/exclude-sync-branches-private-column` → `main`) merged 2026-07-15 15:18, live via Cloudflare Pages.
- `feat/multi-repo-monitor` also still carries the same one-line fix (from the first, unintended commit) — harmless duplication, will just no-op when that branch eventually merges to main (line already present).
- Worktree used for the main-targeted fix removed after merge.

**Blocked on:** nothing. Michael confirmed fix good after hard refresh — was a stale tab, not a deploy issue. Session closed.

## Session snapshot — 2026-07-15, end of session (earlier session, same day)

**Why:** Roy sent a Slack list of 4 CI/monitor pain points + 1 more raised mid-session (his "Case 5"), plus an RLS heads-up. Goal: investigate each, fix what's safe/contained, leave the rest for a deliberate decision rather than guessing.

**Current state — 3 of 5 cases done and verified live, 1 needs no work, 1 on hold:**
- Case 1 (promote-to-main PR title hardcoded) — done, live. Also caught and fixed a second bug while verifying it (sync PRs weren't actually excluded from the recent-merges list, so they'd have polluted the new title).
- Case 2 (e2e always full-rebuilds DB) — done, live, verified on a real PR.
- Case 3 (no re-run button) — needs no new work. Already exists: every PR card already shows a clickable CI chip per check-run, linking straight to the GitHub Actions run.
- Case 4 (no cherry-pick-from-staging flow) — **on hold**. You said you're not sure yet if it's wanted. Don't implement without asking first.
- Case 5 (sync-staging wastes CI on zero-diff PRs) — done, live, verified end-to-end on a real auto-generated sync PR (29s fast-merge vs ~5-6min full pipeline before).
- RLS on `michael._migrations` (Roy's heads-up) — checked, no impact on current tooling (table only touched by dormant `db:sync`/`db:bootstrap` scripts that can't even run yet, missing `SUPABASE_DB_URL`).
- Sent Roy a Slack summary of all of the above.

**Blocked on:** nothing external. Case 4 is blocked on your own decision, not anyone else.

**Next steps, if resuming:**
1. If you decide case 4 is wanted, that needs its own spec+plan cycle (multi-step git surgery: branch off staging, cherry-pick, push, open PR — real risk of merge-conflict edge cases), not a quick pass.
2. No other open threads from this session — everything else reached a clean, verified end state.

**Files touched, all committed and merged (nothing left uncommitted from this session):**
- `gavanmanage` repo: `.github/workflows/e2e.yml`, `.github/scripts/{has-sql-changes,test-has-sql-changes,is-zero-diff,test-is-zero-diff}.sh`, two spec docs under `docs/superpowers/specs/` — merged via PRs #143→#144 (main), #146→#147→#148 (main + live-tested sync).
- `gavan-cicd` repo: `cicd-manager/index.html` (`promoteToMain()` + the sync-PR exclusion fix) — merged via PRs #5 and #6, both to `main`, live on Cloudflare Pages.
- All 4 worktrees created this session for isolation (`gavan-cicd-promote-title`, `gavan-cicd-sync-exclude`, `gavanmanage-fix-e2e-sql-fast-path`, `gavanmanage-sync-zero-diff`) were removed at session end since their branches are merged. `feat/multi-repo-monitor` (gavan-cicd) and `feat/calibration-multi-media` (gavanmanage) — the branches that happened to be checked out when this session started — were deliberately left untouched throughout, confirmed byte-identical to their pre-session state at close.

**Secrets exposed this session:** none new. (Existing exposed-secret note from the schema-phase-1 work, see [[project_michael_schema_phase1]], still stands independently of this session.)

**gh auth note:** `gh` CLI was re-authenticated mid-session via device-flow login (`repo`+`read:org`+`workflow` scopes) because the previously-configured fine-grained PAT for `MichaelGavanAI` had no org-level API visibility into `Gavan-AI-Labs-LTD`, even though the SSH key for the same account could push fine. This should now persist across sessions; if `gh pr create`/`gh api` 404s on this org again, that's the fix, not a typo in the repo name.

## CI Pipeline (gavanmanage)

Workflows in `.github/workflows/`:
- `e2e.yml` — lint-ci → typecheck → ai-review → e2e → auto-merge → notify. Triggers on PR → staging.
- `notify-staging.yml` — Slack on staging push
- `notify-main.yml` — Slack on main push
- `sync-staging.yml` — auto-sync main → staging

**Why:** Private repo, staging-protected (PR required, e2e required status check).

## Roy's 4 CI/monitor cases (Slack DM 2026-07-14 13:05) — investigated, case 2 in progress

1. **Promote-to-main PR title hardcoded** — **DONE**, PR https://github.com/Gavan-AI-Labs-LTD/gavan-cicd/pull/5 merged to `main` 2026-07-14 14:37, live (Cloudflare Pages auto-redeploys from `main`). `promoteToMain()` now builds the title from `boardData.mergedToStaging`'s real feature PR name(s) instead of the hardcoded "Promote staging to main". Note: this repo's `main` is currently BEHIND the in-progress `feat/multi-repo-monitor` branch (which changes API-call shape to `repoPath()`-based multi-repo paths) - fix was written against main's current single-repo form directly (`boardData.mergedToStaging` has the same shape in both) so Roy got it now rather than waiting; will need to merge forward cleanly when multi-repo-monitor lands. Applied via a separate `main`-based worktree/branch, not on `feat/multi-repo-monitor` (see [[feedback_branch_relevance_check]]) - that branch had unrelated in-progress work (`CLAUDE.md`, `policy.js`, `hooks/pre-push`, plus an unrelated pre-existing uncommitted hunk in the same `index.html` file, a `detectCaps()`/`caps.unsupported` refactor with a suspected bug: computing `unsupported` directly from `meta.default_branch !== "main"` without the same `|| "main"` fallback `caps.defaultBranch` uses, so a repo whose metadata lacks `default_branch` would wrongly compute `unsupported: true` — flagged but not fixed, not mine, left for whoever owns that WIP).

**Follow-up bug found and fixed same day**: verified case 1 against a real example (gavanmanage PR #147) and found the "exclude sync PRs from Recent Merges" filter was dead code — `pr.head?.ref !== "main"` never matched anything since sync PRs' actual branch is `feat/sync-main-to-staging-<timestamp>`/`sync/main-to-staging-<timestamp>`, never literally `"main"`. Sync PRs were silently leaking into "Recent merges" AND into the new promote-title generation (e.g. would've shown "chore: sync main into staging + <real feature>" instead of just the real feature name). Fixed: PR https://github.com/Gavan-AI-Labs-LTD/gavan-cicd/pull/6 merged to `main` 2026-07-14 14:59, matches sync branches by actual naming prefix instead.
2. **e2e always full-resets DB, ignores 'latest' schema when no SQL changed** — confirmed in `gavanmanage/.github/workflows/e2e.yml`'s `e2e` job (`supabase start` + `supabase db reset` unconditional every run). **DONE**: PR https://github.com/Gavan-AI-Labs-LTD/gavanmanage/pull/143 merged to `staging` 2026-07-14. Took 3 pushes to go green — 2 real CI-environment bugs found only by actually running it, not by review alone: (a) raw `pg_dump` (16.14 on the runner) refused to dump Supabase's local Postgres (17.6, "server version mismatch") — switched to `supabase db dump`, which dumps via the CLI's own managed Postgres so it can't hit a client/server version mismatch; (b) `supabase db dump` doesn't have a `--no-owner`/`--no-privileges` flag at all (unlike raw pg_dump) — dropped it, which also naturally preserves GRANT statements (the exact thing the earlier flag-choice was protecting). Lesson: always watch the actual CI run for infra-adjacent changes, review/YAML-lint alone won't catch runner-vs-container version skew. **Promoted to production**: PR #144 "Promote staging to main" merged 2026-07-14 13:43 (real merge commit, not squash — matches the existing ancestry-preserving pattern used for all prior promotes, e.g. #141). — adds `.github/scripts/has-sql-changes.sh` (same `.sql`-extension rule as the monitor's DB-migration badge, kept in lockstep intentionally) + `actions/cache`-keyed DB snapshot restore via `pg_dump`/`psql` when no SQL touched and cache hits. `/code-review` run inline (8-angle medium effort): found and fixed missing `set -euo pipefail` (a failed `db reset` could silently cache a broken snapshot), `pg_dump --no-privileges` dropping real GRANT statements from 9 migration files (fast-path restore would diverge in permissions from a real reset), an em-dash convention violation, and DB_URL extraction tripling — all fixed before push. `agy` pre-push flagged `[SECURITY]` (mostly a pre-existing `ADMIN_URL` substitution line + already-mitigated concerns); escalated to Opus per org policy — verdict: false positive, safe to merge. `gh` CLI couldn't create the PR at first (`MichaelGavanAI`'s fine-grained PAT and `korm85`'s classic token both lacked org visibility into `Gavan-AI-Labs-LTD` — 404 on `/user/orgs` and repo lookups for both, even though the `github-work` SSH key for `MichaelGavanAI` could push fine). Fixed via `gh auth login --scopes repo,read:org,workflow --web` (device-code flow, user approved in browser) — if this recurs, that's the fix, not a repo-name/typo issue.
3. **No re-run button in monitor after e2e failure** — confirmed gap (monitor has no failed-check re-run action anywhere, only workflow_dispatch polling for admin sync workflows). Not started.
4. **No cherry-pick-from-staging-into-new-PR flow** — confirmed gap, `createPR()` only opens branch→base PRs, no cherry-pick support. Backlog per Michael 2026-07-14 - not sure yet if wanted, don't implement without asking.
5. **sync-staging.yml wastes full CI on zero-diff sync PRs after every promote** — **DONE**. PR https://github.com/Gavan-AI-Labs-LTD/gavanmanage/pull/146 merged to staging, then https://github.com/Gavan-AI-Labs-LTD/gavanmanage/pull/147 promoted to main 2026-07-14 14:22. Real-world validated end-to-end: PR #148 (auto-generated sync PR after the promote) fast-merged in ~29s via the new `zero-diff-check`/`fast-merge` jobs (`gh pr merge --admin`), vs the old ~5-6min full pipeline. Real 2-parent merge commit confirmed, all downstream jobs (lint-ci/typecheck/ai-review/e2e/auto-merge/notify) correctly skipped, no false Slack alert.
   - **Important design note**: the sync mechanism itself (`sync-staging.yml`) was deliberately left untouched - it exists to close the commit-graph ancestry gap after every promote so cicd-manager's ahead/behind badges stay accurate, per [[project_state]]'s earlier design doc `2026-07-01-sync-staging-ancestry-fix-design.md`. This fix only cuts CI cost for the *zero-diff* case, double-gated on branch-name shape (`sync/main-to-staging-*`/`feat/sync-main-to-staging-*`) AND zero file diff.
   - **Two real bugs found by `/code-review` (medium, 8 agents) before first push**: (a) wrongly assumed GitHub Actions' `needs:` chain auto-skips downstream jobs - a *skipped* job still satisfies the implicit `success()` check (skip != failure), so `ai-review`/`e2e`/`auto-merge`/`notify` needed **explicit** `if: needs.zero-diff-check.outputs.fast_merge != 'true'` gates, not reliance on cascade; `notify` in particular would've fired a false "e2e 0/0 FAILED" Slack alert otherwise. (b) expensive `fetch-depth: 0` checkout ran before the cheap branch-name check - reordered so ~95%+ of ordinary PRs never pay for it.
   - **One real security bug found by mandatory Opus escalation** (agy flagged `[SECURITY]` on push, twice - policy requires Opus review given this diff adds a `gh pr merge --admin` branch-protection bypass): `zero-diff-check` checked out the PR's own head content then ran `.github/scripts/is-zero-diff.sh` FROM that checkout - executing the PR author's own copy, not the trusted base version. A collaborator with write access could've rewritten the script to always print "yes" and gotten an unreviewed change merged via `--admin` with zero CI (external/fork PRs can't exploit this - `GH_PAT` isn't available to them). Fixed by inlining `git diff --quiet` directly in the workflow YAML (which GitHub always resolves from the protected base ref for `pull_request` events) instead of shelling out to a script in the PR's own tree.
   - Lesson reinforced: for CI/workflow-adjacent changes, review catches logic bugs but real-world empirical testing (watching an actual live run) is still required - the security bug specifically needed the mandatory Opus pass, not just the standard 8-agent review.

**Why case 2 first:** Michael was mid per-developer-schema rollout ([[project_michael_schema_phase1]]) when Roy raised this, wanted assurance the schema work wasn't the cause / wasn't broken by the fix. Verified: CI's e2e.yml never sets `VITE_SUPABASE_SCHEMA`, so it always resolves to `'public'` — fully isolated from Michael's `michael` schema work.

**How to apply:** Cases 1/3/4 are explicitly deferred (documented in the PR's spec doc, `gavanmanage/docs/superpowers/specs/2026-07-14-e2e-sql-fast-path-design.md`) — pick up as separate follow-up PRs when resuming, don't bundle with case 2.

## Open Backlog Items

### Needs Roy (GitHub admin)
- Staging ruleset: squash-only + add `typecheck` as required status check (currently only `e2e` required)

### Blocked on Roy
- Guided-tour bugs (PR #28): Roy found 11, we fixed 6. Remaining 5 unknown — Roy hasn't shared list.

### Deferred
- Roy pushes direct to `main` bypassing CI. Agreed to tackle after staging workflow stabilizes.

### Roy's org-check request (2026-06-28)
Roy asked to add Gavan GitHub org membership check to the ai-review tool. Since gavanmanage is private, org membership is implicitly gated. Explicit check deferred until agy is added to CI.

## Completed (2026-06-29)

### gavan-cicd fixes (main branch)
- `per_page=8→20` for recentMain fetch — old merges were cut off
- `lastRelease` now sorted by `merged_at` desc before find — `sort=updated` was picking wrong release, causing old staging PRs to reappear
- Auth cookie `Max-Age` 7d → 10yr (effectively permanent session)

### gavanmanage — sync-staging workflow status (2026-06-29)
- PR #97 promoted staging→main (merged) — new sync workflow now in main
- Auto-sync fired but failed: `gh pr list --search` flag broken
- PR #98 `fix/sync-pr-list-query` → staging open, waiting on e2e CI
- Fix: use `headRefName | startswith(...)` jq filter instead of --search
- Known follow-up: add null-check `select(.headRefName and ...)` per agy

### gavanmanage — PR #96 merged to staging
- `sync-staging.yml` rewritten: creates PR to staging instead of direct push (branch protection blocked direct push)
- Guards duplicate PRs: skips if open sync PR already exists
- PR #96 `fix/sync-via-pr` → staging, auto-merge enabled, waiting for e2e

### gavanmanage — PR #94/95 merged (workflow trigger)
- PR #94 merged to main (wrong base — should have been staging, fixed by PR #95)
- PR #95 merged `fix/auto-sync-staging-after-promote` → staging correctly

### gavanmanage — PR #94 merged to staging (superseded)
- `sync-staging.yml` auto-triggers after staging→main promote PR merges
- Guards fork spoofing: `head.repo.full_name == github.repository`
- Eliminates need to manually click "Sync from Main" after every promote
- **Status:** in staging, needs staging→main release to activate

## Completed (2026-06-28)

### PR cards show commit messages (gavan-cicd main)
- Replaced `+additions / -deletions · N files` with list of commit message headers
- DB migration badge kept
- Up to 5 commits shown, "+N more" if over

### Docs updated
- `WORKFLOW.md` — Gemini 2.5 Flash, flaky tracking section, API key header note
- `README.md` — full CI job table, flaky behaviour, E2E step list

## Recent Fixes (2026-06-28)

### PR #83 — fix(ci): gemini-3.0-flash → gemini-2.5-flash, move API key to header
- `gemini-3.0-flash` doesn't exist → returned HTTP 404 → ai-review silently skipped
- Fixed model to `gemini-2.5-flash`
- Moved API key from URL query param to `x-goog-api-key` header (security improvement)
- Branch: `fix/gemini-model-404` → staging

**Why:** agy pre-push advisory flagged API key in query string as pre-existing security risk.
