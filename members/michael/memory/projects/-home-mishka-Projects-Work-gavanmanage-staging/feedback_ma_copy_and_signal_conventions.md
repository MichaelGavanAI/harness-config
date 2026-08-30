---
name: feedback_ma_copy_and_signal_conventions
description: "Michael's standards for technician-facing copy and status signals in Material Advisor UI — no abstract fallback text, reuse the sentence library, keep notes short and non-alarming"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ec23a6ed-c643-4ebf-b5ba-685b659ebb1e
  modified: 2026-08-19T20:01:16.593Z
---

Never write an invented generic fallback sentence ("Best fit found for this case.") when real
per-item data is missing — use the app's own sentence library / reasoning language instead.

**Why:** caught live when a "no reasons available" fallback in
`MaterialAdvisorSimulatorDialog.tsx` used abstract made-up copy. Michael's fix: pull from
`materialAdvisorSentenceLibrary.ts`'s existing `wizard.option.material.best_match_reason`
template (`"Closest shade match ({target}) · Strength {strength} MPa · In stock in lab."`),
filled with that item's real fields, not prose I authored myself. General rule: when a UI needs
filler text, check first whether the app already has a sentence library or reasoning helper for
that domain object before writing new copy.

**Also established this session, same UI:**
- Never leave a card/row with literally nothing under its title — always have at least a short
  reason, real or template-filled, never blank.
- Status/count notes ("only 1 material fits") must read as neutral info: inline text on the
  existing header line, no border/background/warning color, and must never shift other elements
  on the page. Bordered alert-style boxes for non-error info reads as alarming and wastes space.
- No em dashes in any user-facing string (already in project CLAUDE.md, but concretely enforced
  broadly this session — colons or periods instead).
- Keep tooltip/chip copy to a few words visible, full sentence only in the hover tooltip — don't
  default to long visible sentences.
- See [[project_material_advisor_confirmed_page_redesign]] for the feature this applied to.
