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

# Supabase CLI (needed for `supabase db diff --schema michael`, not for local Docker — Michael no longer runs local Supabase)
brew install supabase/tap/supabase   # macOS
# or: curl -sL https://supabase.com/install.sh | sh   # Linux

# postgresql-client (psql) — needed to query/verify the michael schema directly
brew install libpq && brew link --force libpq   # macOS
# or: sudo apt-get install -y postgresql-client   # Linux/WSL

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
mkdir -p ~/.claude/hooks ~/.claude/projects/global/memory ~/.claude/projects/work/memory \
         ~/projects/work/.claude ~/projects/work/docs/superpowers

# Global config
cp team/claude/CLAUDE.md ~/.claude/CLAUDE.md
cp team/claude/hooks/* ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# Work project config (Dev Squad rules, Gavan context)
cp team/claude/work-project-CLAUDE.md ~/projects/work/.claude/CLAUDE.md

# Squad manifest (team roles, handoff flow, reviewer triggers)
cp team/squad-manifest.md ~/projects/work/docs/superpowers/team-manifest.md

# Per-project memory buckets — global/work buckets alone are NOT enough. Claude Code keeps a
# THIRD memory bucket per project directory, keyed by that directory's absolute path with every
# "/" replaced by "-" (e.g. a session opened in ~/projects/work/gavanmanage gets bucket
# ~/.claude/projects/-home-<user>-projects-work-gavanmanage/memory — the exact string depends on
# THIS machine's home dir and OS, so it can never be snapshotted verbatim). Most of the real
# day-to-day project knowledge (schema state, in-flight work, bug history) lives here, not in
# global/work.
#
# members/michael/memory/projects/{work,personal}/<relative-path>/ mirrors each project's path
# *relative to ~/projects/work or ~/projects/personal* (not the old machine's absolute path), so
# it stays correct across machines/OSes/usernames. A `_root` subfolder holds memory for a session
# opened directly in ~/projects/work (or personal) with no project subdirectory. Nesting is
# supported (e.g. GLS/GMVP4-MaterialAdvisor was its own separate project directory, hence its
# own separate bucket) — every directory that itself contains memory files is restored to its
# own bucket, computed fresh for this machine. The one exception: a subfolder literally named
# `archive` is always part of its PARENT project's own bucket (curated old memory kept inside
# one project, never a distinct project directory on disk) — its files land in that parent
# bucket's memory/archive/, not a bucket of their own:
for kind in work personal; do
  base="members/michael/memory/projects/$kind"
  [ -d "$base" ] || continue
  find "$base" -type f -print0 | while IFS= read -r -d '' f; do
    proj_dir=$(dirname "$f")
    rel="${proj_dir#"$base"}"
    rel="${rel#/}"
    archive_suffix=""
    case "$rel" in
      */archive) archive_suffix="archive/"; rel="${rel%/archive}" ;;
      archive) archive_suffix="archive/"; rel="" ;;
    esac
    if [ -z "$rel" ] || [ "$rel" = "_root" ]; then
      abs="$HOME/projects/$kind"
    else
      abs="$HOME/projects/$kind/$rel"
    fi
    hash=$(printf '%s' "$abs" | sed 's#/#-#g')
    mkdir -p ~/.claude/projects/"$hash"/memory/"$archive_suffix"
    cp "$f" ~/.claude/projects/"$hash"/memory/"$archive_suffix"
  done
done

# Restore personal skills (e.g. harness-health)
mkdir -p ~/.claude/skills
cp -r team/claude/skills/* ~/.claude/skills/

# Install push-to-git local plugin
mkdir -p ~/.claude/plugins/cache/user/push-to-git/local/skills/push-to-git
cp team/claude/plugins/push-to-git/skills/push-to-git/SKILL.md \
   ~/.claude/plugins/cache/user/push-to-git/local/skills/push-to-git/

# Restore Michael's memories
cp members/michael/memory/global/* ~/.claude/projects/global/memory/
cp members/michael/memory/work/* ~/.claude/projects/work/memory/
```

### Reinstall plugins

Read `team/claude/installed-plugins.json` — for each entry, add its marketplace first (if not already known), then install the plugin:

```
/plugin marketplace add <marketplaceSource.repo-or-url from the entry>
/plugin install <name>@<marketplace>
```

Repeat for every entry in the file. This reinstalls the *current* version from each marketplace — it does not restore a frozen old version, since marketplace plugins are meant to stay current (see `docs/superpowers/specs/2026-07-21-harness-capture-design.md`'s Plugin capture decision).

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
# Add custom marketplaces first
claude plugin marketplace add JuliusBrussee/caveman
claude plugin marketplace add google-labs-code/stitch-skills
claude plugin marketplace add MarcosNahuel/antigravity-plugin-cc

# Install all plugins
claude plugin install superpowers
claude plugin install frontend-design
claude plugin install caveman
claude plugin install figma
claude plugin install slack
claude plugin install vercel
claude plugin install skill-creator
claude plugin install stitch-skills
claude plugin install antigravity
```

### A7. Clone project repos

```bash
mkdir -p ~/projects/work ~/projects/personal

git clone git@github-work:Gavan-AI-Labs-LTD/gavanmanage.git ~/projects/work/gavanmanage
git clone git@github-work:Gavan-AI-Labs-LTD/gavan-cicd.git ~/projects/work/gavan-cicd
```

### A8. Set up gavanmanage against the michael schema (dev project — no local Docker)

Michael no longer runs local Docker Supabase for `gavanmanage`. He develops directly against
his own Postgres schema (`michael`) inside the shared dev project (`rmgkldfqlnaenanzjhnn`,
dashboard name "GavanManage" — NOT production, which is the separate `ydznkrhjbojturkjwqun`
project). Full design/rationale: `gavanmanage/docs/superpowers/plans/2026-07-02-per-developer-schema-phase1-plan.md`.

```bash
cd ~/projects/work/gavanmanage
npm install   # picks up the `pg` devDependency used by db:bootstrap/db:sync

cat > .env.local << EOF
VITE_SUPABASE_URL="https://rmgkldfqlnaenanzjhnn.supabase.co"
VITE_SUPABASE_PUBLISHABLE_KEY="<anon/publishable key — Dashboard > Project Settings > API>"
VITE_SUPABASE_SCHEMA="michael"
EOF
```

Ask the user for the publishable key (Dashboard → Project Settings → API) — never hardcode it,
never echo `SUPABASE_DB_URL` if they share it, write straight to the file.

The `michael` schema should already exist on the dev project (created once during Phase 1). If
this is a genuinely fresh schema (new machine does NOT mean re-bootstrap the schema — the schema
lives in the database, not on disk):
```bash
export SUPABASE_DB_URL="<direct connection string, port 5432 — Dashboard > Project Settings > Database>"
npm run db:bootstrap -- --schema=michael   # idempotent — safe to (re-)run
```
Otherwise just confirm it's reachable (see A9) and skip straight to `npm run dev`.

For `gavan-cicd`'s own E2E suite (separate from the app's dev server), it still runs against
local Docker Supabase — that's unrelated to `michael` and unchanged:
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

# michael schema reachable on the real dev project (via PostgREST — no error means exposed correctly)
curl -s "https://rmgkldfqlnaenanzjhnn.supabase.co/rest/v1/cases?select=id&limit=1" \
  -H "apikey: <publishable key from .env.local>" \
  -H "Authorization: Bearer <publishable key from .env.local>" \
  -H "Accept-Profile: michael"
# Expect: [] or rows — NOT a PGRST106 error (that means the schema isn't exposed on Data API settings)

# gavanmanage dev server
cd ~/projects/work/gavanmanage && npm run dev   # should serve on localhost:8080, Vite ready in <1s

# gavan-cicd E2E suite (local Docker, unrelated to michael)
cd ~/projects/work/gavanmanage && supabase status
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
git clone git@github-gavan:MichaelGavanAI/harness-config.git ~/projects/work/harness-config
```

### B10. Verify

Same checks as A9.

---

## About this repo

This repo contains the full AI agent configuration for Gavan AI Labs development.

| Directory | Contents |
|-----------|----------|
| `team/claude/` | Shared Claude Code config (CLAUDE.md, settings, hooks) |
| `team/claude/CLAUDE.md` | Global Claude config — copied to `~/.claude/CLAUDE.md` |
| `team/claude/work-project-CLAUDE.md` | Work project Claude config — copied to `~/projects/work/.claude/CLAUDE.md` |
| `team/claude/hooks/` | Custom hook scripts (model routing, context guard, superpowers gate, caveman, shared task-record adapter) |
| `team/claude/plugins/` | Local custom plugins |
| `team/squad-manifest.md` | Dev squad roles, handoff flow, reviewer triggers — canonical source |
| `team/mcp.json.template` | MCP server config template (fill in secrets on restore) |
| `members/michael/` | Michael's personal memory + profile |
| `members/michael/memory/global/`, `.../work/` | Global and work-bucket memory snapshots |
| `members/michael/memory/projects/<escaped-cwd>/` | Per-project memory bucket snapshots (e.g. `gavanmanage`, `gavan-cicd`) — restored by A3's loop into `~/.claude/projects/<name>/memory/`. This is where most real day-to-day project knowledge lives; global/work buckets alone are not a full restore. |

## Keeping this repo up to date

When memories, hooks, or global config change significantly, invoke the `push-to-git` skill:
```
/push-to-git
```
It snapshots the current state and pushes here.
