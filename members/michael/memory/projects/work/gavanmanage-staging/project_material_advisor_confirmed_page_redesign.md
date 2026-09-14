---
name: project_material_advisor_confirmed_page_redesign
description: "Confirmed Material Advisor page redesign (material-led recap + unified Change material dialog) — pushed to fix/material-advisor-ux, not yet PR'd/merged"
metadata: 
  node_type: memory
  type: project
  originSessionId: ec23a6ed-c643-4ebf-b5ba-685b659ebb1e
  modified: 2026-08-19T20:01:02.359Z
---

Redesigned the confirmed Material Advisor page (`ShadeAnalysisPanel.tsx` results area) and
consolidated its material-picking entry points. Pushed as commit `fc07c21` on new branch
`fix/material-advisor-ux` (branched off `fix-MA-UX` at commit `ece454e`). Not yet opened as a
PR or merged.

**What changed:**
- Replaced the old "Step 3 shade summary" grid (shade-analysis facts) with a material-led recap
  card: confirmed material + order shade lead, stump→target + shade-fit pill, a "why this
  recipe" chip row (one per wizard decision: Esthetics/Masking/Process/Class/Stock/Translucency/
  Optics) with a 3-4 word label plus full reason in a native tooltip, sourced from a new pure
  helper `describeMaterialAdvisorStepChoice()` in `materialAdvisorWizard.ts`.
- Consolidated "Select Other" + "Try other choices" into one "Change material" button opening
  `MaterialAdvisorSimulatorDialog`, now with a Guided/Browse-all toggle (Guided = original live
  decision-editing simulator; Browse-all = flat list of every catalog material with the same
  status/shade-fit signal language, via a new `allOptions` memo sourced from the full
  unfiltered `candidates`, not the wizard-narrowed set).
- Moved "Back to wizard" from a header slot to the bottom action bar next to Confirm Material
  (single re-entry point, same button style).
- Fixed `ColorJourneyPanel`'s technician-mode candidate cards, which were hiding all ΔE/score
  signals with no replacement — now show `Recommended`/`Compatible`/`Not compatible` + `Shade
  fit: Good/Fair/Poor` (same classification the wizard uses, via `assignMaFitStatuses`), and
  populated the previously-empty "Selected Material Detail" panel (restoration-on-stump SVG +
  plain-language reasons via `renderMaReason`).
- Kept "Edit inputs" untouched — it edits raw case inputs (target/stump shade override,
  restoration type, dark stump, wall thickness, cement), a genuinely different, still-needed
  capability, not redundant with the wizard-decision consolidation above.

**Known gap, deliberately not fixed:** the old "Select Other" dialog (`MaManualMaterialSelectDialog`,
now unreachable/dead code, left in place not deleted) let a technician type an exact custom
ordering shade code per material. "Browse all" mode only picks a material at its default shade.
Flagged to the user; not resolved as of this push.

**How to apply:** if resuming this work, read `fix/material-advisor-ux`'s single commit
`fc07c21` for the full diff. `fix-MA-UX` (no slash) is Roy's actively-used branch — never rename
or force-push it; this work intentionally forked to a new branch instead.
