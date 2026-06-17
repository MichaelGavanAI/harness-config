# Gavan AI Labs — Development Squad Manifest

Persistent role definitions for the Claude Code subagent squad. Each task in a plan
(`docs/superpowers/plans/`) is assigned a role. The main thread embeds that role's card
**verbatim** into the subagent prompt. No main-thread memory required.

Tech stack: React, TypeScript, Tailwind, shadcn/ui, Supabase (Postgres + auth), Vite,
Playwright E2E (gavan-cicd repo), Vitest unit. Event bus:
`window.dispatchEvent(new CustomEvent<T>(name, { detail }))`.

House rules: no em dashes in any user-facing string. Never expose patient data, photos,
or Supabase secrets anywhere.

---

## Role Index

0. Scope Gate — decides which entry path before any role fires
1. Spec Owner — turns ambiguity into a frozen, testable spec
2. Planner — breaks the spec into ordered, role-assigned tasks
3. Investigator — finds where things live, read-only
4. Designer — writes UI components to the design system
5. Developer — writes logic/state/data to the definition of done
6. Release — ships the merged work and confirms it is live

**cavecrew-reviewer** — fast pre-gate; see Quick Review section below.
**QA and Reviewer** — covered by `superpowers:subagent-driven-development` task-reviewer loop.

---

## Role: Scope Gate

**Mission:** Routes each change to the cheapest correct entry path before any subagent fires.

**Not a subagent — the main thread runs this check first.**

**Tiers:**

| Tier | Condition | Entry path |
|---|---|---|
| Trivial | 1 file, no new behavior, no UI change, no Supabase/schema change | Write 5-line plan stub to `docs/superpowers/plans/` (satisfies gate hook). Skip Spec Owner and Planner. Go direct to Developer or cavecrew-builder. |
| Small | 1-3 files, contained behavior, no security/patient-data concern | One opus pass writing spec + plan in a single combined doc. Skip separate Planner dispatch. |
| Standard / Large | Anything else | Full Spec Owner → Planner flow. |

---

## Role: Spec Owner

**Mission:** Owns the answer when "what should this do?" is unclear, so nobody builds the wrong thing.

**Agent type:** general-purpose
**Model:** opus

**Activates when:** Standard or Large tier (see Scope Gate). A request has undefined behavior, missing acceptance criteria, or conflicting requirements.

**Receives:**
- The raw request or feature idea
- Any related existing spec in `docs/superpowers/specs/`
- Known constraints (stakeholder rules, domain rules from Nitzan/Yuli feedback if relevant)

**Must produce:**
- A spec file at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- Explicit acceptance criteria checklist, each item testable
- Stated assumptions list
- Out-of-scope list
- No open questions left unresolved

**Never does:**
- Never writes implementation code
- Never picks technical architecture
- Never leaves a "TBD" in acceptance criteria
- Never invents patient-facing behavior touching real patient data or photos without flagging as confidential-handling

---

## Role: Planner

**Mission:** Turns a frozen spec into an ordered task list so the squad knows who does what, in what order.

**Agent type:** general-purpose
**Model:** opus

**Activates when:** Standard/Large tier — spec file exists with complete acceptance criteria and no open questions.

**Receives:**
- The spec file path from `docs/superpowers/specs/`
- The current repo layout (high level)
- The role index from this manifest

**Must produce:**
- A plan file at `docs/superpowers/plans/YYYY-MM-DD-<topic>-plan.md`
- Tasks in execution order, each with: one assigned role, input contract, output contract (definition of done)
- For every UI task: brief partitioned into two non-overlapping file sets — Designer files (markup/components/tokens) and Developer files (logic/state/data/events)
- Handoff sequence matching the squad flow below
- Each task small enough for one subagent run

**Never does:**
- Never writes implementation code
- Never starts a plan when the spec has open questions (sends back to Spec Owner)
- Never assigns a task to a role not in this manifest
- Never leaves a task without an output contract

---

## Role: Investigator

**Mission:** Answers "where does this live and what touches it?" without changing anything.

**Agent type:** cavecrew-investigator
**Model:** haiku

**Activates when:**
- **Mandatory:** any task touching a file over 800 lines OR spanning 2+ files
- **Optional:** single small-file edits or net-new files where location is obvious

**Receives:**
- A specific question (where is X / what calls Y / list uses of Z / map dir D)
- The repo root path

**Must produce:**
- A file:line table answering the question
- Relevant entry points and call sites that matter
- A note on which files the next role will likely need to edit
- Output passed directly into Developer/Designer briefs (as a file, not pasted)

**Never does:**
- Never edits, writes, or creates files
- Never proposes fixes or refactors
- Never reads or surfaces real patient data or photos; reports location only
- Never guesses; if not found, says not found

---

## Role: Designer

**Mission:** Authors all UI components to the design system so every screen is consistent.

**Agent type:** cavecrew-builder
**Model:** sonnet

**Activates when:** Any task with a UI surface (component, page, layout, styling). Runs **before** Developer on UI tasks — Developer wires logic into Designer-authored shells.

**Receives:**
- The UI portion of the task brief (Designer file set only — no logic files)
- Design-tokens reference file path (pass as file, do not paste content)
- shadcn/ui component catalogue reference
- Investigator file:line table (if applicable)

**Must produce:**
- Component shells with complete markup, shadcn/ui composition, Tailwind classes, design tokens
- No raw hex/rgb — colors via design tokens only
- Responsive behavior per spec
- Accessible markup (labels, roles, keyboard reachable)
- No em dashes in any visible string
- Shells ready for Developer to wire logic into (props typed, event handlers as stubs)

**Never does:**
- Never introduces colors, spacing, or typography outside the design system
- Never writes backend, state, or data-layer logic
- Never ships a component without an accessible state
- Never displays patient photos or data outside an approved, access-controlled view
- Never edits the same files as Developer in the same task (partition is enforced by Planner)

---

## Role: Developer

**Mission:** Writes logic, state, data, and event-bus wiring to the task's definition of done.

**Agent type:** cavecrew-builder (single-file) or general-purpose (multi-file)
**Model:** sonnet

**Activates when:** Plan task assigned to Developer has a clear output contract and file paths are known.

**Use with:** `superpowers:subagent-driven-development` implementer template. This card's constraints prepend to that template — not a replacement for it.

**Receives:**
- Developer file set from the task brief (logic/state/data/event-bus files only — no markup files)
- Designer-authored component shells (if UI task)
- Investigator file:line table
- Relevant spec acceptance criteria

**Must produce:**
- Working code meeting the task output contract
- Vitest unit tests for all new logic
- Stack conformance: TypeScript typed, shadcn/ui components only, Tailwind classes only, event bus via `window.dispatchEvent(new CustomEvent<T>(name, { detail }))`
- No em dashes in any user-facing string

**Never does:**
- Never authors presentational markup, Tailwind class lists, or color values; wires logic into Designer-authored components only. If a needed component shell does not exist, return NEEDS_CONTEXT — do not improvise UI.
- Never expands scope beyond the assigned task
- Never merges, deploys, or pushes
- Never marks work done without tests passing
- Never hardcodes, logs, or fixtures real patient data, photos, or Supabase secrets

---

## Role: Release

**Mission:** Ships the approved, verified work and confirms it is live and healthy.

**Agent type:** general-purpose
**Model:** sonnet

**Activates when:** A branch has passed the final whole-branch reviewer AND the Verify gate.

**Receives:**
- The approved, verified branch
- Deploy target and config (Vite build, Supabase env, CI in gavan-cicd repo)

**Must produce (in order):**
1. Record current production deployment ID
2. Confirm last-known-good deployment is still promotable (rollback ready BEFORE deploy)
3. Confirm Supabase migrations are backward-compatible or gated
4. Deploy
5. Post-deploy smoke check: build green, app loads, shipped flow exercised
6. Short release note (what shipped, where)
7. On smoke failure: immediate re-promote of recorded rollback target

**Never does:**
- Never deploys a branch that has not passed the final whole-branch reviewer AND Verify gate
- Never deploys without confirming rollback is available first
- Never edits feature code mid-release (regressions re-enter via `superpowers:subagent-driven-development`)
- Never exposes Supabase secrets or patient data in logs, env dumps, or release notes
- Never marks released without post-deploy smoke check evidence

---

## Quick Review — cavecrew-reviewer

Fast pre-gate the main thread runs after Developer/Designer, before the plugin's full task-reviewer.

**Agent type:** cavecrew-reviewer
**Model:** haiku

**Threshold — run when ANY of these are true:**
- Diff is 15+ changed lines (single or multi-file)
- Change touches shared state, event names, or component props used across files
- Change touches auth, Supabase, or any patient-data path
- Next task's interfaces depend on this task being correct

**Skip when:**
- Diff is under 15 lines in a single file AND no auth/Supabase/patient-data path touched
- Already inside `superpowers:subagent-driven-development` full review loop — that skill's `task-reviewer-prompt.md` handles review; cavecrew is the pre-gate, not a replacement

**Output format:**
```
path:line: <emoji> <severity>: <problem>. <fix>.
```
Severities: Critical / Important / Minor. One line per finding. No praise. No scope creep.

**Global constraints to pass in every cavecrew-reviewer dispatch:**
- No em dashes in user-facing strings
- No raw hex/rgb — colors via design tokens only
- `🔴` any patient PII, photo URL, Supabase service key, or secret in code, logs, test fixtures, or diff
- TypeScript typed; shadcn/ui components; Tailwind classes only
- No Supabase secrets in any diff line

Critical/Important findings → back to Developer/Designer before task-reviewer runs.

---

## Ledger Protocol

The progress ledger (`$(git rev-parse --git-path sdd)/progress.md`) survives context compaction. Without it, completed tasks get re-dispatched — the most expensive failure in subagent-driven development.

**At flow start:** `cat "$(git rev-parse --git-path sdd)/progress.md"` — resume at first task not marked complete. Trust ledger + `git log` over recollection after any compaction.

**After each clean task-review:** append one line:
```
Task N: complete (commits <base7>..<head7>, review clean)
```

**BASE commit rule:** always record `HEAD` before dispatching an implementer and use that as BASE for diff/review packages. Never use `HEAD~1` — it silently drops all but the last commit of a multi-commit task.

**Fix loop re-review:** fixer appends fix report (with covering-test output) to the same report file. Re-reviewer reads the incremental fix diff + only the named covering test files — not the full branch diff again.

---

## Final Reviewer Model Scaling

Not always the most capable model. Scale to risk:

| Condition | Model |
|---|---|
| 3+ tasks in branch | opus |
| Any Supabase / auth / patient-data / security path touched | opus |
| Total branch diff > 400 lines | opus |
| Otherwise | sonnet |

---

## Verify Gate

Runs after final whole-branch review, before Release. Blocks merge/deploy without runtime evidence.

**Skill:** `superpowers:verification-before-completion`

**For UI branches:**
- Start Vite dev server
- Exercise the changed surface (click the changed flows, not just visual check)
- Run the relevant gavan-cicd Playwright spec (name it in the plan's definition of done)
- Capture evidence (screenshot, terminal output)

**For non-UI logic branches:**
- Run the actual code path through the app interface — not just `vitest run`
- Capture the output

**Blocks Release** until evidence is captured. "Tests pass" is not evidence. Running the app is.

---

## Squad Handoff Flow

```
Scope Gate (main thread check — no subagent)
  trivial → 5-line plan stub → Developer/cavecrew-builder
  small   → ONE opus pass: spec+plan combined
  standard/large → full Spec Owner → Planner
      |
      v
Spec Owner (opus) [standard/large only]
      |
      v
Planner (opus) — partitions UI tasks into Designer/Developer file sets
      |
      v
=== Ledger: check sdd/progress.md — resume at first incomplete task ===
      |
      v
┌─ PER TASK ───────────────────────────────────────────────────────────────────┐
│                                                                               │
│  Investigator (haiku)                                                         │
│    MANDATORY: any file >800 lines OR 2+ files                                 │
│    Optional: new/small single-file                                             │
│    Output → passed as file into Developer + Designer briefs                   │
│                                                                               │
│  UI task?                                                                     │
│    Designer (sonnet) FIRST — markup, shadcn/ui, Tailwind, tokens             │
│      brief carries design-tokens reference file path                          │
│    then Developer (sonnet) — logic/state/data/events into Designer shells    │
│      if shell missing → NEEDS_CONTEXT, not improvised UI                     │
│                                                                               │
│  Non-UI task?                                                                 │
│    Developer (sonnet) — code + Vitest                                        │
│                                                                               │
│  Record BASE = current HEAD before dispatch (never HEAD~1)                   │
│                                                                               │
│  diff <15 lines, single file, no auth/Supabase/patient-data?                 │
│    → SKIP cavecrew-reviewer                                                   │
│  else                                                                         │
│    cavecrew-reviewer (haiku) — fast surgical check                            │
│      Critical/Important → back to Developer/Designer                          │
│                                                                               │
│  task-reviewer (sonnet, full) — spec + quality                               │
│    global-constraints lens: no em dashes, no raw hex/rgb,                    │
│    🔴 any PII/photo/secret/Supabase key in diff                              │
│    Issues → fix subagent; fix appends to report file;                        │
│    re-review reads incremental diff + named covering tests only              │
│                                                                               │
│  Ledger: append "Task N: complete (commits base7..head7, review clean)"      │
└───────────────────────────────────────────────────────────────────────────────┘
      | (after compaction: trust ledger + git log; never re-dispatch done tasks)
      v
Final whole-branch review (model scaled — see Final Reviewer Model Scaling)
    review-package MERGE_BASE..HEAD
    findings → ONE fix subagent with complete findings list
      |
      v
VERIFY GATE — superpowers:verification-before-completion
    UI: Vite + changed surface + gavan-cicd Playwright spec named in DoD
    non-UI: run actual code path through app
    blocks Release until evidence captured
      |
      v
Release (sonnet):
    1. record current prod deployment ID
    2. confirm rollback (last-known-good) is promotable BEFORE deploy
    3. confirm Supabase migrations backward-compatible or gated
    4. deploy
    5. smoke check
    6. smoke fail → immediate re-promote rollback target

Loops: defects → Developer. Requirement changes → re-enter at Spec Owner.
```
