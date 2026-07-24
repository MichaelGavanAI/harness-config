# Agent Workflow Parity Uplift Plan

**Status:** proposed — implementation has not started  
**Audience:** Claude Code and Codex maintainers  
**Purpose:** allow either agent to resume and advance the same feature without a manual state briefing, while keeping each harness's private configuration and runtime state separate.

## Outcome

For every meaningful feature, both agents can read one product-facing task record that answers:

1. What are we trying to deliver?
2. What phase are we in, and what is the next action?
3. Which spec and implementation plan govern the work?
4. What decisions, verification evidence, failures, and recoveries occurred?
5. Is the work complete, blocked, or awaiting a product decision?

At closure, the record produces a concise retrospective. Neither harness stores raw prompts, secrets, patient data, patient media, or raw tool payloads in this shared record.

## Non-negotiable boundaries

- **Do not share or symlink full agent homes.** Claude and Codex retain separate session, authentication, cache, plugin, and local database state.
- **Do not modify Claude-owned paths from Codex work.** `team/claude/**` and root `CLAUDE.md` remain Claude-owned.
- **Do not make Codex depend on Claude's private memory paths**, or Claude depend on Codex's private `~/.codex` state.
- **Use only project-facing, sanitized records for interchange.** The shared contract and task records must be safe to commit after review; access-sensitive task artifacts may remain local but must retain the same schema.
- **Hooks fail open.** A logging or health-check problem must never prevent a developer from using either agent.
- **No raw clinical data.** Patient names, images, case files, identifiers, and export paths are prohibited from task text and evidence references.

## Current evidence and gaps

| Area | Existing evidence | Gap to close |
|---|---|---|
| Claude lifecycle | `team/claude/settings.json.template` wires SessionStart, UserPromptSubmit, PreToolUse, and PostToolUse hooks. | Its memory/journal flow is Claude-private and prose-first; it has no shared task contract, structured failure record, or closure retrospective. |
| Claude resume | `team/claude/hooks/global-session-start.sh` restores global/work/personal memory and requests journal consolidation. | It does not load a concise active feature state that Codex can also produce. |
| Claude journal | `memory-journal.sh` and `memory-git-consolidate.sh` prompt consolidation around compact and Git events. | The journal has no common event schema, task identity, requirements trace, or machine-verifiable closure. |
| Codex audit | `/home/korm85/.codex/harness/audit/audit.py` supports sanitized, hash-linked event runs, validation, finalization, summaries, and tests. | It is not yet wired to Codex lifecycle hooks, lacks an active-task index and product-readable current status, and is not a shared project contract. |
| Codex memory | Codex memories are enabled, but the current durable-memory files are stale and do not represent active work. | Memory must be a convenience cache; the task record must become authoritative. |
| Cross-tool continuity | Both tools can read repository documentation. | There is no shared schema, task location rule, handoff rule, or health check. |

## Shared workflow contract

Create this contract first, in a neutral project location:

```text
<repository>/docs/agent-workflow/
  CONTRACT.md                 # Stable schema and behavioral rules
  active-task.md              # One concise, current read model
  tasks/<task-id>/
    task.json                 # Structured current state
    events.jsonl              # Sanitized append-only timeline
    retrospective.md          # Present only after closure
```

For repositories that must not commit task history, use the same layout under a local ignored directory and commit only the plan/spec references and approved retrospective. The chosen location must be stated in the repository's `AGENTS.md` and Claude project instructions so both agents resolve it identically.

### Required task state

`task.json` must include these fields:

| Field | Meaning |
|---|---|
| `task_id` | Stable identifier shared by both agents. |
| `title` and `goal` | Product outcome in plain language. |
| `status` | `active`, `blocked`, `awaiting_product_decision`, `complete`, or `cancelled`. |
| `phase` | `assessment`, `design`, `planning`, `implementation`, `verification`, or `closure`. |
| `spec_refs` and `plan_refs` | Relative links to the governing documents. |
| `next_action` | One concrete action that either agent may take. |
| `blocker` | `null` or a concise, sanitized blocker statement. |
| `requirements` | Stable requirement IDs and outcomes. |
| `updated_at` and `last_actor` | Freshness and handoff information. |

`events.jsonl` records only material events: assessment, route or design decision, plan update, implementation milestone, verification, review finding, blocker, recovery, product decision request, final outcome, and retrospective completion. Every event has a timestamp, agent identity, summary, rationale, requirement links, and evidence references. Evidence references point to a test name, commit hash, PR/CI URL, or file path—never command output containing sensitive values.

`active-task.md` is generated from `task.json`. It must stay under one screen on a phone: goal, status, phase, plan/spec links, next action, blocker, and last verified evidence.

## Uplift workstreams

### 1. Shared contract and repository adoption

**Owner:** either agent; first implementation should be reviewed by the other.

1. Add `docs/agent-workflow/CONTRACT.md` to `gavan-agent-config` as the canonical schema and privacy policy.
2. Add a repository template or bootstrap helper that creates the task directory and active read model without copying private state.
3. Add a short repository instruction that directs both agents to read `active-task.md` before work and update the task record after material progress.
4. Define how a task record is handled on branches and worktrees: task identity stays stable; concurrent writers must use atomic writes and an append lock.
5. Define completion: all requirements have outcomes, verification evidence is present, unresolved findings are resolved or explicitly accepted, and a retrospective exists.

**Acceptance evidence:** a synthetic task can be started, read from a second shell, updated, finalized, and validated without either agent's private home directory.

### 2. Claude Code uplift

**Owner:** Claude Code harness maintainer. Codex must not edit `team/claude/**` or `CLAUDE.md`.

1. Preserve existing Caveman, context guard, model routing, Superpowers gate, and private memory behavior.
2. Add a Claude-owned task-record adapter that:
   - resolves the repository task directory;
   - reads `active-task.md` at SessionStart and resume;
   - writes a sanitized material event only after Claude has determined its semantic outcome;
   - refreshes `task.json` and generated `active-task.md` atomically.
3. Replace “consolidate private journal before compact” as the only continuity mechanism with a dual write: private Claude memory remains Claude-specific; the shared record receives the concise task fact.
4. Wire lifecycle behavior:
   - **SessionStart / resume / compact:** load concise active-task state; flag an unclosed stale task.
   - **UserPromptSubmit:** detect continuation versus a new meaningful task; do not save the raw prompt.
   - **PostToolUse:** record only a semantic milestone, failed verification, or blocker—not every tool call.
   - **Stop:** snapshot changed task state after a meaningful turn.
   - **Git/PR/CI event:** attach a sanitized evidence reference and request closure review when appropriate.
5. Add a Claude `harness doctor` command/report: hook availability, task directory resolution, stale active task, event write/read test, privacy rejection test, and contract version.
6. Test first-prompt concurrency: SessionStart and UserPromptSubmit must not corrupt the record or rely on a strict ordering.

**Acceptance evidence:** Claude starts and resumes a synthetic task, records a decision and verification, survives compaction, and produces a valid shared retrospective while its existing private journal still works.

### 3. Codex uplift

**Owner:** Codex harness maintainer.

1. Extend `/home/korm85/.codex/harness/audit/audit.py` rather than creating a second event system. Preserve its current secret/patient-data rejection, hash-chain validation, owner-only local artifacts, and finalization rules.
2. Add a task-record adapter around the audit run:
   - create or locate a stable `task_id` from the repository task directory;
   - expose `task.json`, `events.jsonl`, and `active-task.md` in the shared schema;
   - map existing audit events to the shared contract without losing requirement links or validation;
   - generate `retrospective.md` during finalization.
3. Add an active-task index per repository/context so SessionStart can locate one current task without scanning old sessions.
4. Wire Codex hooks so they provide concise context and fail open:
   - **SessionStart:** read active state, detect stale runs, and restore goal/phase/next action/blocker.
   - **UserPromptSubmit:** after model interpretation, start or continue a task; never persist raw prompt text.
   - **PostToolUse:** prompt the agent to record material milestone, verification, blocker, or recovery.
   - **PreCompact and Stop:** require a concise state snapshot only when state changed.
5. Expand `harness doctor` to report effective WSL configuration, enabled hooks, hook heartbeat, task-record resolution, stale active run, bridge drift, contract version, and audit integrity.
6. Keep Codex durable memory as a derived convenience layer: promote only stable preferences and decisions; do not use it as the task system of record.

**Acceptance evidence:** Codex can create, resume, update, validate, and finalize the same synthetic task structure; tests cover privacy rejection, concurrent writer safety, stale-task detection, compaction snapshot, and retrospective generation.

### 4. Cross-agent handoff and release gate

**Owner:** both harness maintainers.

1. Claude starts a synthetic feature task and creates a plan reference.
2. Codex resumes it from the task record, implements a synthetic milestone, and records verification.
3. Claude resumes it again, records a review finding and resolution.
4. Codex finalizes it and generates the retrospective.
5. Both agents' doctor reports must identify the same task ID, phase, next action, and contract version.
6. Repeat with a deliberately sensitive string and a patient-data-shaped path; both writers must reject it without echoing it.

**Release gate:** do not claim interchangeability until this two-direction handoff passes in a real work repository with no manual restatement of task state.

## Delivery order

1. Agree and publish the contract and privacy rules.
2. Implement and test the Codex adapter against the existing audit module.
3. Implement and test Claude's adapter without removing its current journal/memory system.
4. Run the two-direction handoff test in a synthetic repository.
5. Pilot in `gavanmanage` on one non-sensitive feature.
6. Review the generated retrospective and doctor reports; fix any gap before wider rollout.

## Product-manager view

The normal interaction should become:

1. You state the outcome.
2. Either agent creates or resumes the task record, then produces or updates the spec and plan.
3. You see only a short current status: goal, phase, next action, blocker, and verified result.
4. You make decisions only when scope, UX, cost, release risk, or an irreversible product choice requires you.
5. At the end, you receive a retrospective with delivery evidence and any unresolved follow-up.

## Explicit non-goals

- Making Claude and Codex use identical internal hooks, models, plugins, or session formats.
- Storing hidden reasoning, prompts, tool inputs, secrets, or patient data for traceability.
- Replacing existing repository spec/plan conventions.
- Removing Claude's established private memory/journal before the shared contract has passed the handoff gate.

## Instructions for Claude Code

Read this plan, then inspect the existing Claude harness as read/write scope. Produce a Claude-only implementation plan for Workstream 2 and the shared-contract portions of Workstream 1. Do not modify Codex files. Preserve all existing Claude behavior unless it conflicts with this plan's privacy, fail-open, or shared-contract requirements. Report exact changed files, verification evidence, and remaining parity limits.
