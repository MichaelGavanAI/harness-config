# Michael Korenevsky — Member Profile

## Role
Application Lead, Gavan AI Labs

## GitHub Accounts
- Personal: `korm85` / korm85@gmail.com — SSH key needed
- Work: `MichaelGavanAI` / michael@gavan.ai — SSH key needed (separate from personal)

## GitHub Orgs
- `Gavan-AI-Labs-LTD` — work org (both accounts are members)

## SSH Setup Required
Two separate SSH keys — one per GitHub account:
```bash
ssh-keygen -t ed25519 -C "korm85@gmail.com" -f ~/.ssh/id_ed25519_personal
ssh-keygen -t ed25519 -C "michael@gavan.ai" -f ~/.ssh/id_ed25519_work
```

~/.ssh/config:
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

Add public keys to each GitHub account:
- `~/.ssh/id_ed25519_personal.pub` → github.com (korm85 account) → Settings → SSH keys
- `~/.ssh/id_ed25519_work.pub` → github.com (MichaelGavanAI account) → Settings → SSH keys

## Project Repos
```bash
mkdir -p ~/projects/work ~/projects/personal

# Work repos (use github-work SSH host)
git clone git@github-work:Gavan-AI-Labs-LTD/gavanmanage.git ~/projects/work/gavanmanage
git clone git@github-work:Gavan-AI-Labs-LTD/gavan-cicd.git ~/projects/work/gavan-cicd
git clone git@github-work:Gavan-AI-Labs-LTD/gavan-agent-config.git ~/projects/work/gavan-agent-config
```

## Secrets Required
| Secret | Where to get it | Where it goes |
|--------|----------------|---------------|
| Figma API key | figma.com → Account → Security → Personal access tokens | `~/.claude/mcp.json` |
| GitHub PAT (korm85) | github.com → Settings → Developer settings → Tokens (classic) | Secure note / password manager |
| Supabase service key | `supabase status` in gavanmanage dir (local only, changes per machine) | `~/projects/work/gavan-cicd/.env.local` |

## Context Routing
- Work sessions: launch Claude Code from `~/projects/work/` or subdirs
- Personal sessions: launch Claude Code from `~/projects/personal/` or subdirs
- context-guard.js hook warns if you mix contexts
