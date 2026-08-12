# Memory Index — gavanmanage

- [Defined gates not ad hoc](feedback_defined_gates_not_adhoc.md) — use repo's actual CI/test-scope/code-review gates, not self-picked full-suite sweeps
- [fix/sidebar-nav-and-filters branch](project_sidebar_nav_filters_branch.md) — 9-file sidebar/avatar+filter fix, based on staging, uncommitted, punch list pending from Michael

- [E2E setup state](project_e2e_setup_state.md) — paused for Docker WSL2 integration; exact next steps documented
- [Guided tour session 2026-06-08/09](session-2026-06-08-guided-tour.md) — driver.js tour + interactive guided mode; pending: GuidedCasePanel width fix, lab guided mode
- [Open action items](project_open_items.md) — Roy: Ruleset, 5 tour bugs, CI/CD Manager v2 setup (4 steps); Michael: install-hooks.sh, open PR for cicd-manager-v2
- [Guided tour WIP — stashed 2026-06-22](project_guided_tour_wip.md) — 8-step lab onboarding tour, SHIPPED to main PR #61
- [Code review effort scaling](feedback_code_review_effort.md) — match review model to diff risk, not always Opus; per-task reviews are the real gate
- [ColorJourney session 2026-06-29](session-2026-06-29-color-journey.md) — feat/lab-ux-material-recommendations pushed; pending: CF preview deploy setup (needs secrets), Roy review, merge to staging
- [PR #115 conflict + CI badges](project_pr115_conflict_and_cicd_badges.md) — root cause: stale branch, missing hook on Roy's machine; real dashboard is gavan-cicd/cicd-manager, not gavanmanage/tools
- [CI badge design rules](feedback_ci_badge_design.md) — actionable+honest only: no auto-fix, no canned commands, no crying wolf on "policy override"
- [Shade/material UX findings 2026-07-06](project_shade_material_ux_findings.md) — 7 code-verified findings on shade/material pipeline; doc + 2 artifact URLs
- [Verify before reporting](feedback_verify_before_reporting.md) — grep/read code before asserting domain claims; Michael checks and pushes back
- [Todo impact wording](feedback_todo_impact_wording.md) — todo items = product impact not code steps; Coding splits into Product vs Infra & Routine
- [Lab nav redesign](archive/project_lab_nav_redesign.md) — ARCHIVED (shipped): persistent sidebar on feat/lab-navigation-redesign; real cross-task bugs caught in final review; T023/T024 beta-critical perf bugs found along the way
- [Supabase dev env](reference_supabase_dev_env.md) — .env.local already wired to Michael's "michael" dev schema; tell agents directly, don't let them hunt
- [UI preview before implementation](feedback_ui_preview_before_implementation.md) — show rendered preview/screenshot before full build on layout-level UI changes, not just a code diff
- [App terms, not code](feedback_app_terms_not_code.md) — explain in screen/button names Michael+Haim see; code is Roy's/Claude's territory, keep it out of user-facing text- [UI/UX scope only](feedback_ui_ux_scope_only.md) — no schema/MA/infra changes unless asked; surface server-side parts as questions, dont ship as "completeness"
- [Calibration multi-media](project_calibration_multi_media.md) — feat/calibration-multi-media pushed 2026-07-15; open decision: lab-attach RLS ownership mismatch, needs Michael's call
- [Haim feedback tracker scope](project_haim_feedback_tracker.md) — docs/haim-feedback-tracker.md is branch-agnostic living doc, not tied to any feature branch
- [Wizard UI follow-ups](project_wizard_ui_followups.md) — nested-box gray inconsistency, sidebar collapse glitch, toolbar truncation; deliberately out of scope for shared-shell PR
- [Sidebar/topbar stacking fix](project_sidebar_topbar_stacking_fix.md) — PR #172 to staging, z-40 overlay fix; branch reuse + wrong-base mess along the way
- [Read policy before PR](feedback_read_policy_before_pr.md) — open WORKFLOW.md fresh, don't assume base branch from memory
- [Branch reuse + retarget gotchas](feedback_branch_reuse_and_retarget.md) — reused merged branch hid PR from dashboard; base-edit via API doesn't retrigger E2E, needs a real push
