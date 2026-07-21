---
name: project_shade_material_ux_findings
description: "DentFlow shade/material/staining pipeline UX audit — 7 code-verified findings, doc + artifact locations"
metadata: 
  node_type: memory
  type: project
  originSessionId: e6ef3db3-1d8b-4431-9a7a-bcdf3fa1997f
---

Michael ran a deep discovery on how DentFlow's shade/material/staining pipeline matches real dental technician workflow, then a follow-up UX audit session on 2026-07-06 that produced 7 code-verified findings.

**Why:** validate the product doesn't introduce friction (irrelevant settings) or miss real workflow needs (e.g. can't select a monolithic-gradient material), ahead of the September/October 2026 beta.

**Deliverables and where they live:**
- `docs/discovery/2026-07-05-technician-workflow-discovery.md` — full mapping of current implementation (OrderWizard, labStageGates, material catalog schema) as a brief for external research.
- `docs/agy/research/2026-07-05-dental-technician-ceramist-workflow-material-shade-gap-analysis.md` — agy (Gemini) deep-research output, 6 gap findings against real dental lab practice, 18 references.
- `docs/discovery/2026-07-06-material-layering-ux-feedback.md` — the 7 code-verified findings from the 2026-07-06 session (see below).
- Artifact — gap-evaluation tool (6 findings from the 2026-07-05 agy report, accept/discuss/reject workflow): `https://claude.ai/code/artifact/bc905e75-04a1-4c07-8540-73e381bb1c44`
- Artifact — shade-journey explainer (interactive walkthrough of stump+material+thickness → compensated color → shade pick → ΔE gap → staining, built for Michael's own conceptual clarity, not a stakeholder deliverable): `https://claude.ai/code/artifact/ffa7971f-bc53-4609-a457-4eb0633e7a17`

**The 7 findings in `2026-07-06-material-layering-ux-feedback.md`, ranked by risk:**
1. Selected Material summary doesn't show the material's `layering_structure` (Monolithic/Cutback/Gradient) — same ΔE number reads identically whether staining work is mostly done by the block or left to the technician.
2. Case-creation Architecture step is a false binary (Monolithic/Layered) with no way to select monolithic-gradient — confirmed `ARCHITECTURE_OPTIONS` is hardcoded to 2 values (`formatRestorationType.ts:53`) and the choice doesn't even reach the recommendation engine (`RelationalSimInput` has no architecture field).
3. Per-zone shade data (9-point ΔE spread, computed in `materialCatalogCheckSimulate.ts:830-857`) is genuinely computed but never used to auto-decide single-shade vs. gradient — confirmed by code.
4. **Correctness bug:** editing target shade after shade analysis has run does not invalidate/reset that stage — gates are monotonic-forward-only, no DB trigger on `cases.target_shade`.
5. **Data-loss bug:** opening Material Catalog mid-case (Header nav link) discards in-progress OrderWizard/LabWorkbench state with zero warning — no state persistence, `beforeunload` guard doesn't fire on in-app nav.
6. Staining Instructions (Stage 4) clarity audit, 7 sub-issues (6a-6g) — worst is **6g: stain product names (e.g. "MiYO Mallow") are invented by Gemini per-generation, not sourced from any real catalog** — a technician could be sent looking for a nonexistent product. Also flagged: raw AI/model internals exposed to technician (Temp/TopP/TopK sliders), a typo in a generated worksheet with no QA gate.
7. Material recommendation only soft-warns (score penalty, not exclusion) when a material's minimum thickness requirement isn't met by the case's given wall thickness — confirmed via explicit code comment: `"Prep thinner than material minimum → warn; hard-remove only via org exclude / bridge caps."`

**Scope correction that shaped Finding 7:** CAD/shape design (wall thickness entry) is an upstream given for DentFlow, not something the product itself designs — findings should stay scoped to the shade/material *recommendation* logic, not CAD authorship. [[feedback_verify_before_reporting]]

**Process note:** Michael repeatedly caught claims I hadn't verified in code (false Architecture binary, unused per-zone data, thickness source) before I wrote them into the doc — all held up on verification, but the pattern is: verify in code before asserting, especially for domain/architecture claims. See [[feedback_verify_before_reporting]].

**Branch/phase assignment (added to the doc 2026-07-06):** Findings 1/2/3/7 → `feat/lab-ux-material-recommendations` (the branch this was requested for). Findings 4/5 → separate `fix/*` branches, don't gate on UX review since they're correctness/data-loss bugs. Finding 6 → next UX phase (different pipeline stage), except 6g (invented stain names) which should probably jump the queue given its severity.

**Tracked in `MichaelGavanAI/todos` issue #1:** T018 (findings 1/2/3/7, the branch work), T019 (finding 4), T020 (finding 5), T021 (finding 6) — added under `## Coding`. T005 (a pre-existing near-duplicate item) was superseded, not duplicated. See [[feedback_todo_impact_wording]].
