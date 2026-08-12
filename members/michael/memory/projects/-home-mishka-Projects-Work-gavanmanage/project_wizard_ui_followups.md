---
name: project-wizard-ui-followups
description: "Follow-up UI bugs/inconsistencies found while building the wizard step shared shell, deliberately out of scope for that PR"
metadata: 
  node_type: memory
  type: project
  originSessionId: f037891a-5792-4a35-8919-be4231422fd1
  modified: 2026-07-20T19:21:36.483Z
---

Found while brainstorming/reviewing `feat/wizard-step-shared-shell` (2026-07-20), deliberately kept out of that PR's scope to stay safe/reviewable. Not yet spec'd or scheduled.

1. **Nested sub-box background inconsistency** — each lab wizard panel uses a different opacity on a different semantic token for its internal content boxes: `ShadeAnalysisPanel.tsx` uses `bg-muted/15`, `ColorInstructionsPanel.tsx` uses `bg-secondary/20`/`bg-secondary/30`, `InteractiveRecipeViewer.tsx` uses `bg-background/80`. The outer card background (`clinical-card` → `bg-card`) is already shared and consistent — this is specifically about nested boxes *inside* each panel. Bigger change than the shell (touches internal classNames across 3 large files), real design-system gap for a future round.

2. **Sidebar collapse glitch** — collapsing/expanding the left nav sidebar shows a broken/blank transitional state (screenshot: mostly empty dark canvas, floating misaligned card) on the Production step. Different subsystem from the wizard step cards entirely (left-nav component, not `LabWorkbench.tsx`/panel roots). Needs its own investigation.

3. **Toolbar tag-row truncation** — the shared toolbar above all 6 tabs (`LabWorkbench.tsx:3056`, `clinical-card p-3 lg:p-4 mb-2 lg:mb-3 flex-shrink-0 overflow-hidden`) clips its own tag list (`Standard`, `Veneer / Monolithic / Tooth-s...`) when there are many tags. `overflow-hidden` on that row is the likely culprit. Small, isolated fix — own PR.

**Why:** Michael wants a robust, future-proofed design system foundation for the lab wizard, but insists on safe, incremental changes that don't risk breaking or cropping content (burned once already this session when a blind restructuring attempt on `ColorInstructionsPanel.tsx` broke real JSX — a `Dialog` nested where it wasn't expected).

**How to apply:** Don't fold these into `feat/wizard-step-shared-shell`. Bring them up as candidate next-round work once that PR ships. See [[project_haim_feedback_tracker]] for the separate, older "on-screen score visibility" open item, and the shared shell's own spec (`docs/superpowers/specs/2026-07-20-wizard-step-shared-shell-design.md`) for the already-out-of-scope per-tab scroll/overflow unification (confirmed deliberate, not drift).
