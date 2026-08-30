---
name: project_material_advisor_wizard_gaps
description: "Material Advisor wizard clinical-logic gap-fix task (T-20260813-001) - status, what's fixed, what's open"
metadata: 
  node_type: memory
  type: project
  originSessionId: f35a90e9-baf0-4dbd-9a3f-baa184002ab8
  modified: 2026-08-19T12:30:36.591Z
---

Task T-20260813-001 tracked 6 clinical-logic gaps in the Material Advisor wizard found by an agy audit 2026-08-16, catalogued in `docs/reference/material-advisor-kb/open-gaps.md` #31-36. As of 2026-08-17, ALL SIX ARE FIXED, tested, and committed on `fix/material-advisor-wizard-back-navigation-chips` (not yet pushed as of last check):
- #31/#32 (masking credit into translucency gate) — commits ad9f5e1, cf94987.
- #34 (direction-aware shade-gap penalty) — commit e21ca10, merged at a4c21d5.
- #36 (occlusal brake on esthetics push) — commit 2efdb6c.
- #33 (bridge-strength recheck) — investigation overturned the gap's own premise: `bridge_units_fit` was never stale (each translucency grade is its own catalog row with its own limits). The real bug was sibling gap #3 (`connector_fit` had a working renderer but was never emitted as a fact in production) — fixed both, commit ad03c53.
- #35 (opalescence filtering) — commit b636099. Added as an independent narrowing check parallel to fluorescence's existing mechanism, since FIELD_BY_STEP only tracks one field per wizard step.

**Why:** Gaps were found because later wizard steps didn't feed back into earlier hard gates, and because two audit-identified "bugs" (#33, and dead tier-constant exports during #34) turned out on investigation to be either non-issues or misdiagnosed — investigate before implementing a fix, even when the gap doc sounds confident.

**How to apply:** All 6 gaps in this task's scope are done and pushed. PR #307 (fix/material-advisor-wizard-back-navigation-chips -> staging) went through several more E2E-driven fix rounds on 2026-08-19, each uncovering the next layer once the previous one let the wizard get further than ever before:
1. bfca8aa - process step had no default value on forward entry (Continue stayed disabled forever), plus two related safety gaps (narrowing-step defaults/rerank-preservation using raw catalog options instead of business-rule-aware displayedOptions; apply() not blocking a not_compatible value on non-material steps the way material already did). User confirmed the wizard's per-step-local-vs-global-best mismatch (each step's own recommended default doesn't guarantee landing on the catalog's true best-match candidate) is intentional - fix was on the E2E test side (gavan-cicd 7d20d14) to clear the resulting override-reason dialog, not a wizard redesign.
2. 5bef546 - the ACTUAL final root cause: `resolveStockChoices` (materialCatalog/materialAdvisorWizard.ts) set gradient_block/single_shade_block's `status` purely from top-score, never checking whether any real candidate actually backed that value (gradientActive/singleActive were only wired to `disabled`, not `status`). A phantom stock pick with zero backing candidates sailed through apply()'s not_compatible gate, then ShadeAnalysisPanel's `reconcileWizardSelection` independently caught the mismatch and silently reverted the WHOLE completed wizard back to status=wizard - discarding the technician's finished selection with no error, no visible state. This is a pre-existing bug, unreachable before this PR because the wizard could never complete all 8 steps in E2E until fix #1 landed. Root-caused via a dedicated Sonnet debugging subagent (T-20260819-002) after static log analysis wasn't enough - needed a live Vitest repro to pin the exact step/value mismatch.

**RESOLVED 2026-08-19: PR #307 merged into staging (squash commit aa2be71). PR #322 (test hardening) merged too.** Full round history, in order: bfca8aa (process default), 5bef546 (stock status/activity), 4dd0f6e (process gradient/layered normalization), 2080360 (fixed 4 issues - 1 P0 clinical-safety regression + 2 P1 + 1 P2 - an independent Opus adversarial review caught in a large exhaustive-audit diff BEFORE it was committed; the tests alone did not catch the P0), c3f717f (unrelated 4th blocker: MaterialAdvisorEvaluationDialog "Was this recommendation correct?" popup not handled by the E2E helper). 4 separate gavan-cicd commits were needed too (7d20d14, b4e484d) since e2e.yml pins that repo to an exact SHA - see [[feedback_ci_pinned_ref_gotcha]].

Lesson: when a wizard/multi-step-form fix makes previously-unreachable code paths reachable for the first time, expect a new layer of pre-existing bugs to surface - each CI failure after a fix may be a genuinely new bug, not the same one recurring. This PR hit FOUR distinct root causes across 5 CI cycles before going green. See [[feedback_adversarial_review_before_large_clinical_diffs]] for the review-before-commit lesson from round 3. Repo's GitHub Ruleset sets `required_approving_review_count = 0` intentionally (gavan-cicd/WORKFLOW.md) so a stalled PR is a CI-check problem, never a missing-review problem.

Next step: decide whether to pick up any of the other 30 catalogued gaps in `open-gaps.md` (#1-30, untouched, out of scope this task). See [[feedback_cost_conscious_subagent_model_choice]] for the mid-task model-tier correction that applied to #33/#35.
