# Codex Instructions: gavan-agent-config

## Project

`gavan-agent-config` stores the Gavan AI Labs agent harness, onboarding context, memory snapshots, and setup docs.

Historically this repo is Claude Code focused. Codex harness work may be added here only after it is proven outside the Claude harness and Michael approves promotion.

## Critical Boundary

Do not modify the working Claude harness unless explicitly asked.

Protected paths:

```text
team/claude/**
CLAUDE.md
```

Read those files for context only.

Codex harness additions should use separate Codex-specific paths, such as:

```text
team/codex/**
docs/codex/**
```

Do not mix Codex behavior into Claude files unless Michael explicitly requests a unified harness change.

## Repo Purpose

This repo documents and restores:

- global agent behavior
- hooks
- skills/plugins
- MCP setup
- memory
- project context
- GitHub account and SSH setup
- team onboarding

## Memory Rules

Memory under `members/michael/memory/**` is source material.

When migrating memory to Codex:

- durable preferences can become Codex memory
- repo conventions belong in repo `AGENTS.md`
- current work state belongs in repo status docs
- history should stay linked, not always loaded
- secrets and PII must never be copied into memory

## Codex Harness Work

For Codex parity tasks:

1. Start from `/home/korm85/projects/CODEX_HARNESS_PLAN.md`.
2. Keep Claude paths read-only.
3. Implement first in `/home/korm85/projects/AGENTS.md`, repo `AGENTS.md`, and `~/.codex/skills`.
4. Verify behavior through smoke prompts.
5. Only then promote stable docs/templates into this repo.

## Safety

- Do not commit API keys, GitHub tokens, Figma tokens, Supabase secrets, or OAuth credentials.
- Do not store private patient data or real patient photos.
- Be careful with restore scripts: they can affect developer machines.

