# Agent Workflow Contract

**Version:** 1.0.0  
**Applies to:** Claude Code and Codex when working in a Gavan repository

This is the shared, project-facing source of truth for an in-flight feature. Agent-specific session history, memory, credentials, caches, raw prompts, and tool inputs are outside this contract.

## Location

`CONTRACT.md` is copied or linked into `docs/agent-workflow/` in each repository adopting this
contract, from this canonical version.

Task records themselves live **outside** the tracked working tree, under the repository's shared
`.git` (`git rev-parse --git-common-dir`), keyed by which worktree is calling:

```text
<git-common-dir>/agent-workflow/<worktree-slug>/
  active-task.md
  tasks/<task-id>/
    task.json
    events.jsonl
    retrospective.md
```

**Why not inside the repo:** a task record committed into the working tree diverges per branch —
each `git worktree` checkout only ever sees whatever was last committed to *its own* branch
history, not live state, and a repo run with many parallel worktrees (this org's normal pattern)
ends up with as many stale, disagreeing copies as it has worktrees. Storing under the shared
`.git` instead means every worktree of one repo sees the same physical location, live, never
committed, never merged.

**Per-worktree isolation:** `<worktree-slug>` is a filesystem-safe encoding of the calling
worktree's own `git rev-parse --show-toplevel`, so two worktrees of the same repo never contend
over one "active task" — each gets its own lineage. There is currently no cross-worktree "list all
active tasks" view; an agent only sees the task for the worktree it is actually running in.

Repos on an older layout may still have historical, already-committed records under
`docs/agent-workflow/tasks/` in the tracked tree — left as read-only history, never written to
again once an adapter has moved to the git-common-dir location above.

## Privacy and safety

Never place any of the following in `task.json`, `events.jsonl`, `active-task.md`, or `retrospective.md`:

- raw user prompts or model reasoning;
- secrets, tokens, credentials, cookies, connection strings, or environment-variable values;
- patient names, identifiers, photographs, clinical records, case exports, or paths that expose them;
- raw terminal output, tool input, or tool output.

Evidence is a short reference only: a test name, commit hash, pull-request/CI URL, or safe repository-relative file path. Writers must reject unsafe content and must not echo it in error messages.

## `task.json` schema

`task.json` is the current state. It is replaced atomically. The file must be valid UTF-8 JSON with exactly these fields:

```json
{
  "contract_version": "1.0.0",
  "task_id": "T-20260715-001",
  "title": "Short feature name",
  "goal": "Product outcome in plain language.",
  "status": "active",
  "phase": "implementation",
  "spec_refs": ["docs/superpowers/specs/2026-07-15-example.md"],
  "plan_refs": ["docs/superpowers/plans/2026-07-15-example.md"],
  "requirements": [
    {"id": "R1", "text": "Outcome is verified.", "outcome": null}
  ],
  "next_action": "Run the focused verification suite.",
  "blocker": null,
  "last_verified_evidence": [
    {"kind": "test", "reference": "tests/example_test.py::test_example"}
  ],
  "last_actor": "codex",
  "updated_at": "2026-07-15T12:00:00+00:00"
}
```

### Allowed values

| Field | Allowed values or rules |
|---|---|
| `status` | `active`, `blocked`, `awaiting_product_decision`, `complete`, or `cancelled` |
| `phase` | `assessment`, `design`, `planning`, `implementation`, `verification`, or `closure` |
| `task_id` | `T-YYYYMMDD-NNN`, stable for the lifetime of one feature task |
| `requirements[].outcome` | `null`, `met`, `accepted_residual_risk`, `blocked`, or `cancelled` |
| `blocker` | `null` unless status is `blocked` or `awaiting_product_decision` |
| references | repository-relative, sanitized paths or URLs; no local home paths |
| timestamps | ISO-8601 timestamps with an explicit offset |

## `events.jsonl` schema

Events are append-only and material. Do not log routine file reads, commands, or agent chatter. Each line is one JSON object:

```json
{
  "event_id": "E0001",
  "timestamp": "2026-07-15T12:00:00+00:00",
  "task_id": "T-20260715-001",
  "actor": "codex",
  "type": "assessment",
  "summary": "Located the existing upload flow and its governing plan.",
  "rationale": "The next implementation step is now bounded.",
  "requirement_ids": ["R1"],
  "evidence": [{"kind": "file", "reference": "src/upload.ts"}],
  "outcome": {}
}
```

Allowed `type` values are: `assessment`, `decision`, `plan_updated`, `implementation_milestone`, `verification`, `review_finding`, `finding_resolved`, `blocked`, `recovery`, `product_decision_requested`, `final_outcome`, and `retrospective_completed`.

## Generated read models

`active-task.md` is generated from `task.json`; agents do not hand-edit it. It contains only:

1. goal and task ID;
2. status and phase;
3. spec and plan references;
4. next action;
5. blocker, if present;
6. last verified evidence and update time.

It must fit on one phone screen without expanding sections.

`retrospective.md` is generated when a task reaches `complete`, `cancelled`, or a resolved terminal block. It contains the goal, delivered result, requirement outcomes, verified evidence, decisions, failures and recovery, residual risks, and follow-up items. It must not reveal prohibited content.

## Lifecycle rules

1. **Start or resume:** read `active-task.md` before planning or implementation. If an active record is stale, report it and continue only after updating its next action or blocker.
2. **Meaningful progress:** after assessment, decision, plan change, implementation milestone, verification, finding, blocker, recovery, or closure, append one sanitized event and atomically refresh `task.json` and `active-task.md`.
3. **Compaction and stop:** if task state changed during the turn, persist the concise state before context compaction or the end of the turn.
4. **Handoff:** the receiving agent reads the current state and event timeline; it must not require a manual summary to proceed.
5. **Closure:** mark every requirement outcome, attach verification evidence, resolve or explicitly accept findings, generate a retrospective, then set status to `complete` or `cancelled`.

## Concurrency and failure behavior

- Writers use an exclusive lock around event append and state regeneration.
- Writers use atomic replacement for `task.json` and `active-task.md`.
- If the shared record cannot be written, the agent warns that traceability is degraded but does not block the user’s work.
- Session-start and prompt hooks may run concurrently; neither can assume the other ran first.

## Contract validation

A conforming harness provides a doctor/check command that reports:

- contract version and resolved task-record location;
- readable current task and valid event sequence;
- stale active task status;
- privacy rejection works without revealing the rejected content;
- a write/read/refresh smoke check; and
- harness-specific hook health.

## Adoption gate

Interchangeable use is not claimed until Claude starts a synthetic task, Codex resumes and advances it, Claude records and resolves a finding, and Codex finalizes it. Both harness checks must then report the same task ID, phase, next action, and contract version.
