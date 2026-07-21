---
name: project_sidebar_topbar_stacking_fix
description: "Sidebar hover-overlay vs sticky sub-header z-index fix, PR #172, targeting staging"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5441fdf6-df83-42e2-9683-94c8f5effd6c
  modified: 2026-07-21T07:02:25.159Z
---

Sidebar's "expand on hover" overlay used `z-10` (`src/components/ui/sidebar.tsx:220`), sticky lab/clinic sub-header used `z-30` (`src/components/layout/LabAppLayout.tsx:209`) — sub-header painted over the expanded sidebar, hiding the Gavan.ai logo. Fixed by raising the overlay to `z-40` (still below the `z-50` tier every Radix dropdown/dialog/sheet/toast already uses) and adding a shared-order comment in both files. Scope deliberately limited to these two files — Michael explicitly declined a repo-wide z-index token system.

Spec: `docs/superpowers/specs/2026-07-21-sidebar-topbar-stacking-order-design.md`. Plan: `docs/superpowers/plans/2026-07-21-sidebar-topbar-stacking-order.md`. Fix commit `34a866b` on branch `fix/scroll-hidden-behind-sticky-header`, PR #172 -> `staging`.

**Why this branch is messy:** reused an already-merged branch (see [[feedback_branch_reuse_and_retarget]]) and initially opened the PR against the wrong base (`main` instead of `staging`, see [[feedback_read_policy_before_pr]]). Retargeting via API didn't retrigger E2E; had to push an empty commit to force it.

**How to apply:** as of 2026-07-21 07:01, E2E is running on the retriggered commit `97cc610`. Check `gh pr view 172` for merge status before assuming this shipped — don't treat "PR opened" as "fix is live," staging only has it once #172 actually merges.
