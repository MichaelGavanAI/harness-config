---
name: project-sidebar-nav-filters-branch
description: "fix/sidebar-nav-and-filters branch state — sidebar/avatar restructure + case-filter fixes, reviewed locally, small punch list pending"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0c01fe9e-894c-4344-a5f3-7a3dd485962d
  modified: 2026-07-21T07:23:28.951Z
---

Branch `fix/sidebar-nav-and-filters` (based on `origin/staging`, not `main` — the sidebar/nav code only exists on staging). 9 files changed, uncommitted as of 2026-07-20. Passed local dev-server visual check by Michael; he flagged "a few things to fix" but didn't specify them yet — follow up next session.

**Why based on staging, not main:** first attempt branched off main and discovered `AppSidebarDestinations.tsx`/`LabSidebarDestinations.tsx` don't exist there — the nav-unification work (`feat/*-navigation-redesign`) is merged to staging but not yet main. Re-based cleanly via `git reset --hard origin/staging`.

**Scope shipped:**
1. Sidebar: "Lab Management" renamed to "Production Labs", moved (with Material Catalog, Settings, Color Setup) out of the persistent sidebar into the avatar dropdown (`Header.tsx`) for both clinic and lab roles, gated the same as before (`canUseManufacturingTools` etc).
2. Dark-mode toggle added to the sidebar footer (`LabAppLayout.tsx`), next to the sidebar-display-mode button, always visible — was previously only in the avatar dropdown (kept there too for the 2 standalone-Header pages, LoadCasePage/CatalogPage, that render outside the sidebar layout).
3. Sidebar footer restructured into a proper flex row (was a single floating centered button).
4. Case Management filter bar (`CaseTable.tsx` → shared `CaseFilters.tsx`): now `compact`+`wideLayout` (single row, matches Internal Production), added "Internals" checkbox (wired to the existing `assigned_lab_id === clinic_user_id` internal-order concept, reusing `isLabCreatedInternalCase` from `applyFiltersAndSort`).
5. Clear button in `CaseFilters.tsx`: always rendered (test-verified), but only visually pronounced (secondary variant, count badge) when filters are active — was ghost/invisible-looking either way before.
6. Full filter-state persistence (search/status/late/dates/sort) added via `readPersistedFilters`/`persistFilters` in `CaseFilters.tsx`, wired into both `CaseTable.tsx` and `CaseList.tsx` (Internal Production / Lab Workbench / Lab Production all share `CaseList.tsx`) — previously only queueView/showLabInternalCases survived navigation, the rest reset on remount.
7. Compact-mode select/search widths shrunk (`CaseFilters.tsx`) so controls actually fit a narrow ~320px sidebar column, addressing the "Late chip dislocated" report — this was a real fix at the shared-component level, not yet re-screenshotted at exactly 320px to confirm pixel-perfect.

**Verification done:** `tsc --noEmit` clean, scoped vitest files (CaseFilters, AppSidebarDestinations, LabSidebarDestinations, Header, ClinicDashboardNavigation, OrderWizardLeaveGuard, LabProductionCaseViewLeaveGuard, caseStatus.labQueue) all pass. Full unsca­ped `vitest run` has 5 unrelated pre-existing timeout flakes in Roy's color-science tests (kubelkaMunkStumpPrep, stumpTranslucencyPrep, extractPaletteSwatchesFromImage) — confirmed via stash+baseline compare these pass standalone (26/26), only flake under full-suite parallel load. Not caused by this branch. [See feedback_defined_gates_not_adhoc](feedback_defined_gates_not_adhoc.md) for the process lesson from this.

**Update 2026-07-20:** Committed (`1636e1b`), code-review stamp written after a fresh Sonnet review of the full diff (clean, one cosmetic naming nit only — `labUserId` param reused for clinic's own id in `applyFiltersAndSort`, functionally fine). Pushed and opened [PR #168](https://github.com/Gavan-AI-Labs-LTD/gavanmanage/pull/168) against `staging`.

**Closed 2026-07-20:** PR #168 merged to staging (auto-merge on green CI). e2e caught a real regression (4 specs asserting old sidebar data-tour anchors for the moved items) — fixed via [gavan-cicd PR #11](https://github.com/Gavan-AI-Labs-LTD/gavan-cicd/pull/11) (merged), then [gavanmanage PR #169](https://github.com/Gavan-AI-Labs-LTD/gavanmanage/pull/169) re-pinned the e2e.yml gavan-cicd SHA to the merged main commit (also merged). All branches deleted, both local and remote. Thread closed.

**Still open, not tied to a branch:** Michael saw the sidebar/filter work running locally via dev server and said "a few things to fix" without listing them yet — no ticket, no repro, nothing actionable until he sends specifics. Pick up whenever he does.
