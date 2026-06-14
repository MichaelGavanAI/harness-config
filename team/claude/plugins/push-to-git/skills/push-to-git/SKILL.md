---
name: push-to-git
description: Push current project + full Claude Code context to GitHub so an AI agent can restore the complete setup on a new machine after a format.
---

# Push to Git — Full Context Backup

## Purpose

Snapshot the entire project — source code, Claude Code config, hooks, memory, plugins, MCP servers, deployment setup, and NUC/infrastructure context — into a single GitHub repo. The output must be complete enough that a fresh AI agent, reading only this repo, can rebuild the entire setup without asking the human any setup questions.

## What Gets Captured

- All project source files (code, config, schema, migrations)
- `.claude-backup/` folder containing:
  - Claude Code global config relevant to this project (CLAUDE.md, settings, hooks, memory)
  - MCP server list and configuration (secrets scrubbed)
  - Installed plugins list
  - Required environment variables (names + descriptions only, no values)
  - Infrastructure context (what services are running, where, how)
- `RESTORE.md` at repo root — the AI agent's instruction manual

## What Is NEVER Committed

- `.env`, `.env.local`, `.env.*` files
- Actual secret values (tokens, API keys, passwords)
- `node_modules/`, `.next/`, `dist/`, build artifacts
- Plugin binary cache

## Execution Steps

### Step 1: Verify prerequisites

Check that `git` and `gh` (GitHub CLI) are available and authenticated:
```bash
git --version
gh auth status
```

If `gh` not authenticated, stop and tell the user to run `gh auth login` first.

### Step 2: Initialize git repo if needed

```bash
git init
git branch -M main
```

Check if `.gitignore` exists. If not, create one containing at minimum:
```
.env
.env.local
.env.*
node_modules/
.next/
dist/
*.log
.DS_Store
```

### Step 3: Create GitHub remote if none exists

Create a **public** repo using the GitHub API (no `gh` CLI required — use stored credentials or a token the user provides):

```bash
curl -X POST \
  -H "Authorization: token <GITHUB_TOKEN>" \
  -H "Content-Type: application/json" \
  https://api.github.com/user/repos \
  -d '{"name":"<repo-name>","private":false,"description":"<one-line project description>"}'
```

Then add the remote using SSH (personal projects always use SSH to avoid credential leakage):
```bash
git remote add origin git@github.com:<username>/<repo-name>.git
```

If remote already exists, skip. If repo already exists on GitHub, just ensure remote is set.

### Step 4: Gather Claude Code context

Create `.claude-backup/` directory in the project root. Collect the following:

**4a. Global CLAUDE.md**
Copy `~/.claude/CLAUDE.md` → `.claude-backup/global-CLAUDE.md`

**4b. Project CLAUDE.md and AGENTS.md**
Copy any `CLAUDE.md`, `AGENTS.md` from the project root (these are already in the repo — confirm they are staged).

**4c. settings.json (scrubbed)**
Read `~/.claude/settings.json`. Replace any string values matching these patterns with `{{ REDACTED }}`:
- Values containing: `sk-`, `Bearer `, `_TOKEN`, `_KEY`, `_SECRET`, `password`, `passwd`, `api_key`, `apikey`, `token`
- The scrub is case-insensitive on the pattern, but only replaces the value, not the key name.
Save scrubbed version to `.claude-backup/settings.json`.

**4d. mcp.json (scrubbed)**
Read `~/.claude/mcp.json`. Apply same scrubbing. Save to `.claude-backup/mcp.json`.

**4e. Hooks**
Copy `~/.claude/hooks/` → `.claude-backup/hooks/` (shell scripts, no secrets expected).

**4f. Project memory**
Find the project's memory directory: `~/.claude/projects/<path-hash>/memory/` or check `~/.claude/projects/` for the entry matching the current working directory. Copy all `.md` files to `.claude-backup/memory/`.

**4g. Plugins list**
List installed plugins from `~/.claude/plugins/marketplaces/` — just the directory names, not binaries.
Write to `.claude-backup/plugins.txt`.

**4h. Required environment variables**
Scan the project for all `process.env.VARNAME` and `os.environ['VARNAME']` references. Also read `.env.example` if it exists. Write a file `.claude-backup/env-vars.md` with each variable name, and for each one write a one-line description of what it is based on how it's used in code. Do NOT include actual values.

**4i. Infrastructure context**
Write `.claude-backup/infrastructure.md` describing what external services this project depends on:
- What databases (provider, how connected)
- What cloud platforms (Vercel, etc.)
- What local/on-premise services (NUC bridge, tunnels, etc.)
- What MCP servers and what they do
- Docker containers and their purpose
- PM2 processes and their purpose
This is written in plain English so an AI agent understands the full picture.

### Step 5: Write README.md

Write or overwrite `README.md` at the project root. This is the public face of the repo — someone landing on GitHub must immediately understand what it is and why it exists. Structure:

```markdown
# <Project Name>

> <One-line value proposition — what problem does it solve for the user>

<2-3 sentence description of what the project does>

## What it does
<ASCII flow diagram showing the user journey / data flow>

## Stack
<Table: Layer | Tech>

## Architecture
<ASCII diagram showing how components connect — cloud, home server, external services>

## Key features
<Bullet list of the 4-6 most impressive capabilities>

## Restoring this setup
<One paragraph pointing to RESTORE.md and .claude-backup/>

## Environment variables
<Table of required vars with one-line descriptions>
```

Make the README visual using ASCII diagrams. No Lorem Ipsum filler. Every section must reflect the actual project.

### Step 6: Write RESTORE.md

Create `RESTORE.md` at the project root. This is the AI agent's master guide. It must be complete enough that a fresh agent on a fresh machine can rebuild everything. Structure:

```markdown
# Restore Guide — <Project Name>

> This file was auto-generated by the push-to-git skill. An AI agent should read this file first and follow it sequentially to restore the full development environment.

## Overview
<2-3 sentence description of what this project is and what it does>

## Prerequisites
<List of things that must exist before restoring: GitHub account, specific hardware like NUC, accounts on Vercel/Neon/etc.>

## Step 1: Clone and install
<git clone command, npm install, etc.>

## Step 2: Configure Claude Code environment
<How to restore .claude-backup/ files to ~/.claude/, which files go where>

## Step 3: Set up environment variables
<Reference .claude-backup/env-vars.md — list each var and where to get the value>

## Step 4: Set up external services
<Reference .claude-backup/infrastructure.md — how to recreate each service>

## Step 5: Set up on-premise infrastructure (if any)
<NUC setup, Docker images, PM2 processes, etc. — exact commands>

## Step 6: Deploy
<How to deploy to production>

## Step 7: Verify
<How to confirm everything is working — what to check>

## Known Gotchas
<Anything non-obvious that tripped up setup before>
```

Fill in each section based on what you know about the project from context, CLAUDE.md files, memory, and the codebase.

### Step 6: Stage and commit everything

```bash
git add .
git commit -m "snapshot: $(date '+%Y-%m-%d %H:%M') — full context backup"
```

### Step 7: Push

```bash
git push -u origin main
```

### Step 8: Report

Tell the user:
- GitHub repo URL
- What was captured in `.claude-backup/`
- Any secrets that were scrubbed (by key name, not value)
- Any gaps — things that couldn't be captured automatically that the user should document manually

## After the Skill Runs

The user can format their machine. To restore:
1. Clone the repo
2. Hand the repo URL to a fresh AI agent with: *"Read RESTORE.md and rebuild the full setup."*
3. The agent handles the rest.
