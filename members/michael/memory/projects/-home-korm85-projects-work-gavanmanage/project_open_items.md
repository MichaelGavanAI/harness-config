---
name: project_open_items
description: Open action items for gavanmanage — Roy items + Michael items recovered from session 5e4966b5
metadata: 
  node_type: memory
  type: project
  originSessionId: 3c979cab-abff-44ef-8895-920339c66e8e
---

Recovered from CI/CD setup session (2026-06-17).

## Roy (needs him to act)

1. **Staging Ruleset — squash-only + typecheck required check** — needs Roy as admin in GitHub UI at `gavanmanage` repo settings → Rulesets
2. **5 unknown guided-tour bugs** — PR #28 merged with Roy finding 11 bugs; 6 fixed in PR #29; 5 remaining bugs never shared. Need the list from Roy.
3. **Roy pushing directly to `main`** — flagged as a gap (no CI gate on main); deferred, not enforced yet
4. **CI/CD Manager v2 — Roy setup tasks (blocking deployment)**
   - **LIVE at https://gavan-cicd.pages.dev** (2026-06-25) — Roy setup complete
   - Latest: commit 16127a8 — dark mode readability (card contrast, chip colors, banner, buttons); global filter bar; font sizes bumped; equal 3-col layout; staging shows only PRs since last release
   - Design doc: `feat/cicd-manager-v2-design` branch (PR #1 in gavan-cicd, needs merge to main too)
5. **PR #55 in gavanmanage** — `feat--enhance-workdata-folder-handling` all CI green, needs manual merge by Roy (auto-merge not configured on this PR)

## Michael

6. **Re-run `install-hooks.sh`** — `bash ~/projects/work/gavan-cicd/hooks/install-hooks.sh` — 1 command, installs pre-push hook into gavanmanage
7. **cicd-monitor.html uncommitted changes** — files-based divergence logic updated; pending commit once CI/CD Manager v2 is decided (may be superseded by v2)
8. **harness-diagram v3 — SHIPPED** (2026-06-25) — pillar-based layout, 6 cards, agy nodes wired into Cost Control + Dev Discipline flows, plain-language tooltips, pushed to `gavan-agent-config/main`. Next: Michael refines visually via Claude design tool online.

## Recently Shipped

- **2026-06-28** — Fixed 5 logic bugs in `gavan-cicd` cicd-manager: ahead/behind commit count swap, false "CI running" chip for blocked/unknown PRs, CI chip class priority (in_progress before conclusion), silent fetch errors now show "CI error" chip, journey overlay fetched wrong branch runs, workflow poll used fuzzy name match. Pushed to `gavan-cicd` main (32f41dc).
- **2026-06-28** — PRs #80 (sync-staging) and #81 (code-review-strategy) merged to staging. ai-review job worked first run. zizmor fix: persist-credentials false + explicit token in sync-staging.yml push step.
- **2026-06-25** — `fix/tooltip-light-theme` pushed (2 commits). Final style: `border-clinical-turquoise bg-popover text-popover-foreground shadow-clinical-md` + turquoise arrow. PR #69 open → staging.

## Context
- PR #28: guided tour merged; Roy found 11 bugs
- PR #29: fixed 6 of Roy's bugs; E2E green; merged
- CF Pages was broken (bun lockfile), fixed in PR #31
- DB assertions exist in all 5 E2E specs (done, not pending)
