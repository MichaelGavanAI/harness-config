---
name: feedback_prefer_agy_over_opus
description: "Delegate to agy instead of spawning an Opus subagent whenever the task isn't reasoning-heavy"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1962b4c6-6eed-4443-802e-4a30f63d0033
---

Default to `agy` (Gemini via Antigravity CLI) for verification/advisory passes — code review, spec review, sanity-checks — rather than spawning an Opus general-purpose agent, unless the task genuinely requires deep multi-step reasoning.

**Why:** Michael pushed back on Opus usage during the `fix/e2e-sql-fast-path` PR flow — I spawned an Opus agent for a security-escalation verdict. Opus is reserved for cases that actually need it.

**How to apply:**
- Org policy's `[SECURITY]`/`[PII]`/`[PATIENT` escalation rule (see project CLAUDE.md) still mandates an Opus-tier reviewer when `agy` flags those tags — that's non-discretionary, keep doing it.
- Outside that mandatory gate: use `agy` directly (via the `antigravity:*` skills or the advisory-gate bash pattern already in CLAUDE.md) for anything that's a review/verification/second-opinion pass, not a "design this from scratch" task.
- Reserve Opus subagents for genuine architecture/planning/design work per the model-routing table, not for double-checking or rubber-stamping something already analyzed.
