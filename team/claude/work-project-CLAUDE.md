# Gavan AI Labs — Work Context

## Company
Gavan AI Labs (pre-seed startup)

## Mission
Create patient-tailored coloring instructions for dental aesthetics procedures.
- Patient gets correct shade match first time → no lab rework needed
- Lab knows exact color inventory to stock → no redundant material purchases
- Lowers expertise barrier → experienced technicians not required for every job
- Short clinic lead time → first-time-right shade matching
- Post-MVP: marketplace connecting dental labs and clinics

## Stage
Pre-seed. Beta target: September/October 2026. Fundraising immediately after beta.

## Team
- Matan Bichacho — CEO
- Roy Sterenthal — CTO
- Michael Korenevsky — Application Lead (me)
- Yael Berger — Data Scientist

## Key Stakeholders
- Nitzan Bichacho — KOL in dental aesthetics (Matan's father, advisor)
- Yuli — Expert dental colorist, testing + feedback partner (Yuli's Lab, Rehovot, Israel)

## Identity
- GitHub account: MichaelGavanAI (https://github.com/MichaelGavanAI)
- Email: michael@gavan.ai

## Development Squad

Role definitions live in `docs/superpowers/team-manifest.md` — single source of truth.

### Hard rule — embed before you spawn
Before spawning any squad subagent, the main thread MUST:

1. Open `docs/superpowers/team-manifest.md`.
2. Copy the matching role card VERBATIM (Mission through Never does).
3. Paste that role card into the subagent prompt as the first block, above the task.
4. Then add the task's input contract and the specific files/paths.

No subagent is spawned from memory or paraphrase. Role card is pasted, not summarized.

### Entry path (Scope Gate — run before any subagent)
- Trivial (1 file, no new behavior, no UI, no schema): write 5-line plan stub, skip Spec Owner + Planner, go direct to Developer
- Small (1-3 files, contained): one opus pass for spec+plan combined
- Standard/Large: full Spec Owner → Planner

### Agent type + model mapping
- Spec Owner, Planner → general-purpose / opus
- Investigator → cavecrew-investigator / haiku (mandatory if any file >800 lines OR 2+ files)
- Designer → cavecrew-builder / sonnet (UI first, before Developer)
- Developer → cavecrew-builder or general-purpose / sonnet (prepend manifest card to plugin implementer template)
- Release → general-purpose / sonnet
- QA, full Reviewer → handled internally by `superpowers:subagent-driven-development`

### cavecrew-reviewer trigger (haiku, fast pre-gate)
Run BEFORE the plugin's full task-reviewer when:
- Diff is 15+ changed lines OR multi-file OR touches auth/Supabase/patient-data
Skip for diffs under 15 lines, single file, no sensitive path.

### Final reviewer model
- opus: 3+ tasks, OR Supabase/auth/patient-data/security touched, OR diff >400 lines
- sonnet: everything else

### Ledger
Always check `$(git rev-parse --git-path sdd)/progress.md` at flow start. Append after each clean task-review. After compaction: trust ledger + git log, never re-dispatch done tasks.

### Verify gate (before Release)
After final review, run `superpowers:verification-before-completion`. UI: Vite + Playwright. Non-UI: run actual code path. Blocks Release without evidence.

### Non-negotiables carried into every spawn
- No em dashes in user-facing strings.
- Never expose, log, or fixture real patient data or photos. Synthetic data only.
- Never leak Supabase secrets.
- 🔴 Flag any PII/photo/secret in any diff — cavecrew-reviewer and task-reviewer both check this.
