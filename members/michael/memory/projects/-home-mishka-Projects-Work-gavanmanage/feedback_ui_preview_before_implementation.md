---
name: feedback_ui_preview_before_implementation
description: "For UI/UX changes, show Michael a preview (mockup/screenshot/before-after) before full implementation — don't build blind off a text description or a mockup image alone"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e6ef3db3-1d8b-4431-9a7a-bcdf3fa1997f
---

Before implementing a UI/UX change, show what the page will look like first, rather than going straight to full code implementation.

**Why:** the Kanban board redesign (2026-07-07, `feat/lab-navigation-redesign`) took 3+ rounds of dispatch-fix-push-screenshot-repeat because each round's fix was verified only by reading code/diffs, not by looking at the actual rendered result — twice the code "looked right" but the deployed page still didn't match what Michael asked for (still boxed/white background, not full width). Guessing from a mockup image or a text description and shipping straight to implementation burns real time and tokens when the result doesn't match.

**How to apply:**
- For a layout/visual change of any real size, produce a quick preview before writing the final implementation — a rendered screenshot from a real dev-server check (preferred, see [[reference_supabase_dev_env]] for how to get an authenticated local repro fast), a quick static mockup, or at minimum an explicit before/after description of the exact classes/DOM changes — and get a nod before finishing the round.
- When implementing from an external mockup (e.g. a Stitch/Figma export), don't assume the mockup's structure maps 1:1 onto the current DOM — verify the actual rendered result against the mockup image side by side before declaring a round done, not just against the code diff.
- Small/mechanical UI tweaks (spacing, a single color, a label rename) don't need this — reserve it for layout-level changes (container structure, width/height behavior, whole-component restructuring) where a static code read is genuinely unreliable at predicting the rendered result.
