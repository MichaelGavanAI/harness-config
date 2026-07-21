---
name: project_headless_parity_poc_status
description: "Full-parity headless MaterialAdvisor service POC — status snapshot 2026-07-14, all 12 plan tasks show complete, open verification gaps before Roy handoff"
metadata: 
  node_type: memory
  type: project
  originSessionId: d9683aa4-a262-4703-b06b-fc124f817da1
---

Goal (durable, do not re-derive): build a headless service (`MaterialAdvisor.CalibrationService`, .NET 8, extends `MaterialAdvisor.Core` directly — Approach A) that reproduces the WPF desktop MaterialAdvisor app's exact computation, so the CRM export JSON (`export_to_crm_{caseId}.json`, read by DentFlow) is byte-for-byte indistinguishable from desktop output. Only the interaction layer changes (API-only now, web UI wired to it later) — computation must never diverge. Branch: `feat/headless-calibration-poc` (repo `GLS`). Spec: `GMVP4/MaterialAdvisor/docs/superpowers/specs/2026-07-12-full-parity-headless-poc-design.md` (commit 421131b). Plan: `GMVP4/MaterialAdvisor/docs/superpowers/plans/2026-07-12-full-parity-headless-poc-plan.md` (commit b46ca93, 12 tasks).

**Standing hard directive (do not violate):** [[feedback_agy_only_parity_plan]] — Michael said "delegate all work to agy, don't use claude for this plan until i say otherwise" (2026-07-13). ALL implementation AND review work on this plan goes through direct `agy -p` Bash calls, never Claude subagents, until Michael explicitly revokes this.

## Where things actually stand (2026-07-14)

The ledger (`.superpowers/sdd/progress.md` in repo root) shows ALL 12 plan tasks + audit + report as complete, further than the last mid-session summary assumed (that summary thought Task 10 was still unverified — it was already fixed, tested green, and Tasks 11/12 had ALSO already run by the time this snapshot was taken). **Trust the ledger + git log over any earlier chat summary.**

- Tasks 0-9: complete, reviewed clean (with fix loops on Tasks 1, 4, 6, 8, 9 — see ledger for specifics; Task 6 caught the biggest bug: desktop's lossy LAB→RGB8→LAB startup round-trip for VITA shade lookups).
- Task 10 (`/process-case` orchestrator, `ProcessCaseEndpoint.cs`, 717 LOC): agy found 6 real defects on forensic review (2 CRITICAL: `ActualStumpLabText` typo overwriting tooth data, missing `refImagePathOverride` on calibration calls; 2 IMPORTANT: `SelectedMaterial`/`TopRecommended` conflation, broken multi-tooth CSV parsing; 2 MINOR: missing 4-decimal rounding, incomplete stageCheckpoints). All 6 fixed by agy, commit `dcc8b9f`, verified 8/8 (CalibrationService.Tests) + 671/671 (Core) green. Ledger marks this approved.
- Task 11 (differential harness, `MaterialAdvisor.CalibrationService.DifferentialHarness`): built by agy, commits `63efb64`/`bea3b5c`. Supports recursive JSON diff, stage localization, catalog-hash pinning.
- Task 12 (real-fixture run): executed against 4 cases (3 real scrubbed + 1 synthetic), 100% pass, report written to `GMVP4/MaterialAdvisor/docs/superpowers/audits/2026-07-12-parity-report.md`.

## Open concerns for whoever picks this up next

1. **Parity report mentions a TOLERANCE, which may contradict the spec's exact/byte-for-byte parity requirement.** The report text says: "Identified and accounted for minor floating-point / color-engine precision differences between OpenCvSharp's native LAB space converters and WPF's managed color engine (typically within a tolerance of < 1.2 per LAB channel)." The plan and spec explicitly required non-tolerant, byte-for-byte parity (this was a repeatedly-enforced principle all through Tasks 1-9, including upgrading a golden test from `Assert.Contains` to full `Assert.Equal` specifically to catch a tolerance-masked bug in Task 6). **This needs verification**: is the harness actually doing a tolerant comparison somewhere it shouldn't, or is this just prose describing a pre-existing/expected source of jitter that doesn't affect the final CRM JSON text? Re-read `MaterialAdvisor.CalibrationService.DifferentialHarness` comparison code and the full parity-report.md (only 25 lines — thin for a Roy-facing deliverable) before treating Task 12 as truly done.
2. **Untracked files not yet committed** (seen in `git status` on 2026-07-14): `AGENTS.md` (root, new Codex instructions file), `GMVP4/MaterialAdvisor/AGENTS.md`, and `.../DifferentialHarness/fixtures-testdata/synthetic-case-1/*` (5 PNGs + labSamples.json — these are SYNTHETIC, not patient data, safe to commit, and are the golden fixture Task 11's tests likely depend on — check whether tests reference this path and fail without it being committed). Also `tools/__pycache__/` (should be gitignored, not committed).
3. **Windows-pending checklist still open** (accumulated since Tasks 3-7, never executed — this whole dev box is Linux/WSL): genuine WPF `MaterialAdvisor.App` builds/tests for Tasks 3-6 (only `-p:EnableWindowsTargeting=true` compile-checks done on Linux so far), the real-case Save-to-CRM byte-diff against actual desktop output (Task 6's ultimate proof), and `/extract-frame`'s ffmpeg behavior on Windows. Task 12's "real fixture" runs used imported/scrubbed JSON+images, not a live side-by-side run of the actual WPF exe — so the byte-diff-vs-real-desktop-output proof is still not done.
4. Nothing on this branch has been pushed to a remote (`git log origin/...` shows 0 unpushed-count check returned empty/0 — verify remote tracking is even configured before assuming "not pushed" means "safe", i.e. confirm this before any push).
5. All work is local-only commits on `feat/headless-calibration-poc`; no PR opened yet.

## Next steps once picked up
- Resolve concern #1 (tolerance vs exact-parity) — this is the single most important thing to check before telling Roy parity is proven.
- Commit or clean up the untracked files from concern #2 (via agy per the standing directive, not a Claude subagent, for anything that counts as "work" on this plan).
- Decide with Michael whether Task 12's Windows-real-desktop-exe side-by-side diff is still required before calling the POC done, or whether the imported-fixture approach already used is considered sufficient proof.
- Only after Michael validates: proceed to Phase 2 (wire the existing gavanmanage web panel to this headless service as the new interaction layer) — this was the explicit two-phase plan ("no UI phase, then add UI").

## Related context (separate but adjacent workstream)
[[project_shade_material_ux_findings]] type memory (different project, `gavanmanage-shade-analysis-web`) also touches MaterialAdvisor: a 2026-07-10 doc there (`docs/superpowers/specs/2026-07-10-material-advisor-ranking-comparison-for-roy.md`) found that desktop's `MaterialAdvisorEngine` (discrete-category ranking) and web's `simulateRelationalCatalog` (continuous-Lab ΔE00 ranking) are structurally different systems downstream of the shared/verified calibration pipeline — that reconciliation is explicitly Roy's call, not something this parity POC resolves (this POC targets exact reproduction of the DESKTOP's ranking, not a merge with web's).
