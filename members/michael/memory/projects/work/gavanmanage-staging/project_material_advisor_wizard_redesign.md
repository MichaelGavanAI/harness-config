---
name: project_material_advisor_wizard_redesign
description: Material Advisor wizard mock redesign (narrowing-funnel philosophy) — status and known gap for real implementation
metadata: 
  node_type: memory
  type: project
  originSessionId: 4cff0a1c-66a2-48b0-b5dd-7b2fd6e701b8
  modified: 2026-08-18T11:21:42.500Z
---

Redesigned the Material Advisor wizard as an HTML mock (not yet applied to real app code) at
`/tmp/claude-1000/-home-mishka-Projects-Work-gavanmanage-staging/*/scratchpad/wizard-proposed.html`,
published at https://claude.ai/code/artifact/18cda6d8-a172-44f7-a778-c50231570368.

**Why:** original 8-step wizard was rejected by CTO Roy as untrustworthy — exposed internal
scoring language, forced clicks on foregone conclusions. New philosophy: narrowing funnel, ask
only real judgment calls, compute everything else silently with a real stated reason, material
is the wizard's output never an input, every verdict chip (Recommended/Compatible/Not
compatible) carries a concrete supporting sentence, physically-impossible options are hard
disabled not just discouraged. Fixed 7-step flow every case (Shade, Esthetics, Process, Masking,
Translucency, Fluor./opal., Material) — steps never disappear, show "already settled" instead.

**Known residual gap for real implementation:** the coping-material picker used for a plain
monolithic case's "opaque coping" masking choice reuses the same 4-material list built for the
layered/cutback context (e.max CAD LT, ZirCAD Prime, Katana UTML/STML — sourced from
`supabase/migrations/20260701000000_add_layering_ceramics.sql`'s cutback_recommended fix list).
All 4 are real, valid coping materials, so nothing shown is factually wrong — but the real
coping-eligible set is wider per `defaultIsCoping.ts` (`COPING_CLASSES` = zirconia, ZLS, PFM,
metal_ceramic, plus e.max/lithium-disilicate, plus titanium/PEEK/PEKK/Co-Cr), and a monolithic
opaque-coping masking choice doesn't need cutback-specific grades at all (no veneer goes on top
in that case). When this moves from mock to real wizard code, widen the coping list for the
non-layered masking context to the full `is_coping = true` catalog set, not just the
cutback-recommended subset.

**How to apply:** don't fix this in the mock (product owner explicitly deferred it, "residual
gap, not urgent for the mock's current purpose") — apply when building the real wizard step,
querying `material_catalog_material_versions.is_coping = true` filtered by the current masking
context (layered build needs cutback_recommended too; monolithic opaque-coping masking doesn't).
