---
name: feedback_verify_before_reporting
description: Verify domain/architecture claims in actual code before stating them as fact — Michael checks and pushes back
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e6ef3db3-1d8b-4431-9a7a-bcdf3fa1997f
---

Don't assert how the code/system behaves from inference, a prior doc, or a screenshot alone — grep/read the actual implementation first, especially for claims like "X is hardcoded," "Y is unused," or "Z is derived from data source W."

**Why:** across the 2026-07-06 UX audit session ([[project_shade_material_ux_findings]]), Michael repeatedly asked "did you validate this in the code?" or pushed back on a claim ("i am not sure you are right, check it before writing an answer") before letting it into the written doc. Every claim held up once checked, but two claims were wrong in *how* they were framed until verified: (1) said per-zone Material Advisor data "isn't wired forward" when it's actually just an existing pipeline stage being underused; (2) said wall thickness was "read from CAD geometry" when it's actually manually typed per-zone, not derived from an uploaded mesh. Michael catches these because he knows the domain and the product surface well — he is not a rubber stamp.

**How to apply:** before writing any finding into a shared doc (or answering "is X true about the code"), do the grep/read pass first, cite file:line, and only then state the claim. If a claim can't be directly verified, say so explicitly rather than presenting inference as fact. When corrected, don't just patch the wording — re-verify the corrected framing before writing it back.
