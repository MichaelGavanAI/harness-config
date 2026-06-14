# gavan-agent-config

> New here? Read [VISION.md](VISION.md) first — it explains why every piece of this setup exists.

AI agent configuration and onboarding setup for Gavan AI Labs development team.

## What this is

A self-contained repo that any Gavan team member (or AI agent) can clone to get a fully configured Claude Code environment — including hooks, skills, memory, and project context.

## How to use

```bash
git clone git@github-work:Gavan-AI-Labs-LTD/gavan-agent-config.git
cd gavan-agent-config
claude   # opens Claude Code, reads CLAUDE.md
```

Then tell Claude: **"set up my environment"**

Claude will ask if you're restoring an existing setup or onboarding as a new team member, then guide you through the full setup interactively.

## What gets configured

- Claude Code hooks (model routing, context isolation, caveman mode, superpowers gate)
- Plugin installation (superpowers, figma, caveman, slack, vercel, cloudflare, supabase)
- MCP servers (Figma, LinkedIn)
- Project repos cloned and configured
- Work memory seeded with Gavan AI Labs context

## What requires manual action

- SSH keys (generated during setup, must be added to GitHub manually)
- Secret values: Figma API key, GitHub PAT (you paste them in when prompted)
- Supabase service key (generated locally from `supabase status`)

## Repo structure

```
CLAUDE.md                        ← AI agent restore instructions (read this first)
team/
  claude/
    CLAUDE.md                    ← global AI behavior rules
    settings.json.template       ← Claude Code settings (paths templated)
    hooks/                       ← hook scripts
    plugins/push-to-git/         ← local custom plugin
  mcp.json.template              ← MCP server config (fill secrets on restore)
members/
  michael/
    profile.md                   ← accounts, repos, secrets needed
    memory/                      ← accumulated AI context
```

## Keeping it up to date

Michael: run `/push-to-git` skill periodically to snapshot current state here.
