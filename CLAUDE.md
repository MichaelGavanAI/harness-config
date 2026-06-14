# Gavan Agent Config — AI Restore Instructions

You are an AI agent setting up a Claude Code environment for a Gavan AI Labs team member.
Read this entire file before taking any action. Execute all steps sequentially. Do not skip steps.

---

## Step 0 — Identify scenario

Ask the user ONE question before doing anything else:

> "Are you:
> A) Restoring Michael's existing setup on a new machine
> B) Setting up as a new Gavan team member (Roy, Yael, Matan, or someone new)?"

Wait for their answer, then follow the matching path below.

---

## PATH A — Restoring Michael's setup

### A1. Install system dependencies

Check and install if missing:
```bash
# Node.js via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install 22
nvm use 22

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Supabase CLI
brew install supabase/tap/supabase   # macOS
# or: curl -sL https://supabase.com/install.sh | sh   # Linux

# GitHub CLI
gh auth login   # korm85 account — follow prompts
```

### A2. Set up SSH keys (two GitHub accounts)

```bash
ssh-keygen -t ed25519 -C "korm85@gmail.com" -f ~/.ssh/id_ed25519_personal
ssh-keygen -t ed25519 -C "michael@gavan.ai" -f ~/.ssh/id_ed25519_work
```

Create `~/.ssh/config`:
```
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
```

Tell the user:
> "Add these public keys to each GitHub account before continuing:
> - Personal (korm85): paste contents of ~/.ssh/id_ed25519_personal.pub
> - Work (MichaelGavanAI): paste contents of ~/.ssh/id_ed25519_work.pub
> Go to each account → Settings → SSH and GPG keys → New SSH key"

Wait for user to confirm both keys are added.

### A3. Copy Claude config files

```bash
mkdir -p ~/.claude/hooks ~/.claude/projects/global/memory ~/.claude/projects/work/memory

# Global config
cp team/claude/CLAUDE.md ~/.claude/CLAUDE.md
cp team/claude/hooks/* ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# Install push-to-git local plugin
mkdir -p ~/.claude/plugins/cache/user/push-to-git/local/skills/push-to-git
cp team/claude/plugins/push-to-git/skills/push-to-git/SKILL.md \
   ~/.claude/plugins/cache/user/push-to-git/local/skills/push-to-git/

# Restore Michael's memories
cp members/michael/memory/global/* ~/.claude/projects/global/memory/
cp members/michael/memory/work/* ~/.claude/projects/work/memory/
```

### A4. Configure settings.json

Detect node path and write settings:
```bash
NODE_PATH=$(which node)
CLAUDE_DIR="$HOME/.claude"
sed "s|{{NODE_PATH}}|$NODE_PATH|g; s|{{CLAUDE_DIR}}|$CLAUDE_DIR|g" \
    team/claude/settings.json.template > ~/.claude/settings.json
```

### A5. Configure mcp.json — collect secrets

Ask the user for each secret ONE AT A TIME:

1. "What is your Figma API key? (figma.com → Account → Security → Personal access tokens)"
2. "What is your Windows username? (for the LinkedIn MCP path — check C:\Users\<name>)"

Then write `~/.claude/mcp.json` using `team/mcp.json.template` with the values substituted.

NEVER log or echo secret values. Write directly to file.

### A6. Install Claude Code plugins

```bash
# Add custom marketplace first
claude plugin marketplace add JuliusBrussee/caveman

# Install all plugins
claude plugin install superpowers
claude plugin install caveman
claude plugin install figma
claude plugin install slack
claude plugin install vercel
claude plugin install cloudflare
claude plugin install supabase
claude plugin install frontend-design

# Register local plugin
# (push-to-git is already copied in A3 — just enable it in Claude Code settings)
```

### A7. Clone project repos

```bash
mkdir -p ~/projects/work ~/projects/personal

git clone git@github-work:Gavan-AI-Labs-LTD/gavanmanage.git ~/projects/work/gavanmanage
git clone git@github-work:Gavan-AI-Labs-LTD/gavan-cicd.git ~/projects/work/gavan-cicd
```

### A8. Set up gavan-cicd local env

```bash
cd ~/projects/work/gavanmanage
supabase start
SERVICE_KEY=$(supabase status --output json | python3 -c "import sys,json; print(json.load(sys.stdin)['SERVICE_ROLE_KEY'])")

cat > ~/projects/work/gavan-cicd/.env.local << EOF
SUPABASE_URL=http://127.0.0.1:54321
SUPABASE_SERVICE_KEY=$SERVICE_KEY
EOF
```

### A9. Verify

Run these checks and report status for each:
```bash
# Node
node --version

# Claude Code
claude --version

# gh CLI
gh auth status

# SSH keys
ssh -T git@github-personal 2>&1 | grep "successfully authenticated"
ssh -T git@github-work 2>&1 | grep "successfully authenticated"

# Supabase local
cd ~/projects/work/gavanmanage && supabase status

# E2E tests
cd ~/projects/work/gavan-cicd && npx playwright test --reporter=list
```

Report to user: what passed, what failed, what needs manual action.

---

## PATH B — New Gavan team member onboarding

### B1. Collect member info

Ask the user:
1. "What is your name?"
2. "What is your role at Gavan? (CTO / Data Scientist / other)"
3. "What is your GitHub username?"
4. "What is your work email (@gavan.ai)?"

### B2. Install system dependencies

Same as A1 above.

### B3. Set up SSH key (single GitHub account)

```bash
ssh-keygen -t ed25519 -C "<their-work-email>" -f ~/.ssh/id_ed25519_gavan
```

Add to `~/.ssh/config`:
```
Host github-gavan
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_gavan
```

Tell the user to add the public key to their GitHub account.

### B4. Copy shared Claude config

```bash
mkdir -p ~/.claude/hooks ~/.claude/projects/global/memory ~/.claude/projects/work/memory

cp team/claude/CLAUDE.md ~/.claude/CLAUDE.md
cp team/claude/hooks/* ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# Local plugin
mkdir -p ~/.claude/plugins/cache/user/push-to-git/local/skills/push-to-git
cp team/claude/plugins/push-to-git/skills/push-to-git/SKILL.md \
   ~/.claude/plugins/cache/user/push-to-git/local/skills/push-to-git/
```

### B5. Configure settings.json

Same as A4 above.

### B6. Configure mcp.json

Ask for Figma API key only. LinkedIn MCP is optional — ask if they want it.
Write `~/.claude/mcp.json` from template.

### B7. Install plugins

Same as A6 above.

### B8. Initialize fresh work memory

Write `~/.claude/projects/work/memory/MEMORY.md`:
```markdown
# Memory Index — Work

```

Write `~/.claude/projects/work/memory/project_gavan_ai_labs.md` — copy from
`members/michael/memory/work/project_gavan_ai_labs.md` (the company context is shared).

### B9. Clone repos

```bash
mkdir -p ~/projects/work

git clone git@github-gavan:Gavan-AI-Labs-LTD/gavanmanage.git ~/projects/work/gavanmanage
git clone git@github-gavan:Gavan-AI-Labs-LTD/gavan-cicd.git ~/projects/work/gavan-cicd
git clone git@github-gavan:Gavan-AI-Labs-LTD/gavan-agent-config.git ~/projects/work/gavan-agent-config
```

### B10. Verify

Same checks as A9.

---

## About this repo

This repo contains the full AI agent configuration for Gavan AI Labs development.

| Directory | Contents |
|-----------|----------|
| `team/claude/` | Shared Claude Code config (CLAUDE.md, settings, hooks) |
| `team/claude/hooks/` | Custom hook scripts (model routing, context guard, superpowers gate, caveman) |
| `team/claude/plugins/` | Local custom plugins |
| `team/mcp.json.template` | MCP server config template (fill in secrets on restore) |
| `members/michael/` | Michael's personal memory + profile |

## Keeping this repo up to date

When memories, hooks, or global config change significantly, invoke the `push-to-git` skill:
```
/push-to-git
```
It snapshots the current state and pushes here.
