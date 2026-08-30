# Why This Exists — The Vision

> Gavan AI Labs is a 4-person pre-seed startup racing to beta by October 2026.
> We can't hire a 20-person engineering team. So we built a multiplier instead.

---

## The Core Idea

```
Without AI setup                    With this setup
─────────────────────               ──────────────────────────────
1 developer                         1 developer
= 1 developer's output              + consistent AI agent
                                    + enforced planning discipline
                                    + persistent memory across sessions
                                    + correct model for every task
                                    + team-wide identical environment
                                    = 3-4x output, fewer mistakes
```

---

## Why Each Piece Exists

### Claude Code + Hooks
```
Problem: AI assistants drift mid-session.
         They forget instructions. Use wrong models.
         Ignore rules after context gets long.

Solution: Hooks enforce rules at the OS level — not inside the conversation.
          Rules can't be forgotten because they run before every response.

         User message
              ↓
         [Hook fires] ← runs BEFORE Claude sees the message
              ↓
         Rules re-injected into every turn
              ↓
         Claude responds correctly, every time
```

### Model Routing (Haiku → Sonnet → Opus)
```
Problem: Using a powerful model for simple tasks = slow + expensive.
         Using a weak model for architecture = wrong answers.

Solution: Route by task type, enforce via hook.

         Search / grep / read files  →  Haiku   (fast, cheap)
         Write / edit code           →  Sonnet  (default, balanced)
         Architecture / planning     →  Opus    (thorough, expensive — worth it)

         Without routing: everything hits Sonnet = wasted cost on searches,
         underpowered on critical decisions.
```

### Superpowers Gate
```
Problem: Pre-seed means no time to rebuild wrong things.
         AI can write code fast — but fast wrong code is still wrong.

Solution: Block code writes unless a plan file exists.

         Developer asks Claude to write code
                    ↓
              [Gate checks] ← does docs/superpowers/plans/*.md exist?
                    ↓
         NO → BLOCKED. Must brainstorm → spec → plan first.
         YES → Allowed. Code aligns with an agreed plan.

         Result: Every feature has a paper trail. No "why did we build it this way?"
```

### Caveman Mode
```
Problem: AI responses are verbose by default.
         Reading 3 paragraphs to get one answer slows down iteration.

Solution: Caveman mode strips filler, keeps substance.

         Normal: "Sure! I'd be happy to help you with that. The issue you're
                  experiencing is likely caused by a subtle timing problem in
                  the authentication middleware..."

         Caveman: "Auth middleware bug. Token expiry check uses < not <=. Fix:"

         Same information. 5x faster to read.
         For a fast-moving startup, that compounds.
```

### Context Guard
```
Problem: Michael works on Gavan (dental AI) AND personal projects.
         AI with wrong context makes wrong suggestions.
         "shade matching" advice bleeding into personal portfolio = noise.

Solution: Hook detects which context you're in based on working directory.
          Warns if work keywords appear in personal session or vice versa.

         ~/projects/work/     → loads Gavan AI context
         ~/projects/personal/ → loads personal context
         anywhere else        → warns and asks which context
```

### Memory Files
```
Problem: Claude has no memory between sessions by default.
         You repeat company context every conversation.
         "We're a dental AI startup targeting beta October 2026..." — every time.

Solution: Memory files inject persistent context at session start via hook.

         Session starts
              ↓
         Hook reads ~/.claude/projects/work/memory/*.md
              ↓
         Claude already knows: company, team, product, decisions, past work
              ↓
         You start working immediately, not re-explaining

         Memory grows over time. The longer you use it, the smarter the AI
         context becomes for your specific situation.
```

### push-to-git Skill
```
Problem: All this setup lives on one laptop.
         Laptop dies = weeks of lost configuration.

Solution: One command snapshots everything to GitHub.

         /push-to-git
              ↓
         Captures: hooks, settings, memory, plugin list, project context
         Strips: all secrets (API keys, tokens)
         Pushes: to this repo
              ↓
         New machine: clone → "restore my setup" → done in 30 minutes
```

---

## The Bigger Picture

```
                    ┌─────────────────────────────────┐
                    │         Gavan AI Labs           │
                    │   4 people, October 2026 beta   │
                    └──────────────┬──────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │      harness-config         │
                    │   Everyone uses same AI setup   │
                    │   Onboarding: hours, not days   │
                    └──┬──────────┬──────────┬────────┘
                       │          │          │
              ┌────────▼──┐  ┌────▼────┐  ┌─▼────────────┐
              │  Hooks    │  │ Memory  │  │   Skills     │
              │ (enforce  │  │(context │  │ (superpowers,│
              │  rules)   │  │ across  │  │  caveman,    │
              │           │  │sessions)│  │  figma...)   │
              └───────────┘  └─────────┘  └──────────────┘
                       │          │          │
                    ┌──▼──────────▼──────────▼────────┐
                    │        Claude Code CLI          │
                    │   Consistent AI agent output    │
                    │   across all team members       │
                    └─────────────────────────────────┘
                                   │
                    ┌──────────────▼──────────────────┐
                    │         gavanmanage             │
                    │    App code, features, fixes    │
                    │    Protected by gavan-cicd CI   │
                    └─────────────────────────────────┘
```

---

## What This Is NOT

- Not a replacement for engineering judgment
- Not a way to write bad code faster
- Not a tool only Michael can use — it's designed to transfer to the whole team

---

## For New Team Members

You're inheriting a setup that was built while building the product.
Every piece exists because something broke or slowed us down without it.

The best way to understand it: use it for a week, then read this again.
You'll recognize every problem it solves.
