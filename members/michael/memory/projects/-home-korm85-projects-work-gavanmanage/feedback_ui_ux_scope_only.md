---
name: feedback_ui_ux_scope_only
description: "Michael's standing scope rule — improve existing functionality via UI/UX only; no schema changes, no Material Advisor changes, no server/infra additions unless asked"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 55a5e091-322b-43e2-830d-83cf06c2279d
---

On 2026-07-13, after round 7 shipped, Michael set a hard scope boundary: "i don't want any changes which cause a change in schema, changes in material advisor code - the goal is to improve on existing functionality... make sure changes are ui and ux focused, not infrastructure." He also rejected an unrequested phone-photo feature ("phone photos is not something we touch now, i did not ask for it") — reverted in `abd390a`.

**Why:** Pre-seed, beta-focused. Schema/MA/infra changes create cross-team dependencies (Roy deploys, Yael's MA app) and risk; UI/UX polish is the current beta priority. Adjacent-flow "completeness" additions (like widening a server allowlist so a sibling flow also works) read as scope creep, not thoroughness.

**How to apply:** Before implementing any feature item, split the plan into UI/UX vs anything touching `supabase/migrations`, `supabase/functions`, the MA export contract, or CI/deploy. Ship the UI/UX part; surface the infra part as a question first, even when it seems like a natural completion of the feature. Related: [[project_lab_nav_redesign]], [[feedback_autonomous_decisions]].
