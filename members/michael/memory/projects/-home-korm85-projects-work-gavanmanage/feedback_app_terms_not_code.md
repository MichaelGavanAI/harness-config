---
name: feedback_app_terms_not_code
description: "Michael wants explanations in application/screen terms, not code/DB terms — code is Roy's and Claude's territory"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b6c21fa9-3183-4f4b-9b11-b4572cd9a0b9
---

Always explain findings in terms of what Michael and Haim actually see and click in the app (screen names, field labels, buttons) — never file names, DB columns, function names, or code identifiers in user-facing explanations.

**Why:** Michael and Haim interact with the application only. The code underneath is Roy's and Claude's territory — surfacing code-level details (file:line, `enum_value`, table.column) breaks his mental model and adds noise he can't act on.

**How to apply:**
- Research/tracing can and should read code (that's how to get ground truth) — but translate results to on-screen names before presenting: e.g. "Select Restoration screen" not `RestorationDetailsStep.tsx`, "Material Advisor list" not `layeringStructure` column.
- Diagrams/artifacts for Michael or Haim: label nodes with screen/button names, put technical citations (if needed at all) in a collapsed footer or drop them entirely.
- If a concept only exists in code with no on-screen equivalent yet (e.g. an enum value never exposed in the UI), say so plainly — "this exists behind the scenes but you never see it" — rather than naming the enum.
- Related: [[project_lab_nav_redesign]], [[feedback_verify_before_reporting]] (verify against code, then present in app terms).
