---
name: project_e2e_setup_state
description: "E2E testing stack setup state — where we left off, what's next"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7e6e2d36-8f9c-4f8b-bdeb-ed51b6ef3ccc
---

# E2E Setup State — paused for Docker WSL2 integration

## What's done
- Supabase CLI v2.106.0 installed in WSL2
- `supabase/seed.sql` written — creates 2 test users on `db reset`
- `gavan-qa/CLAUDE.md` updated with local test credentials
- Git SSH: both accounts isolated (MichaelGavanAI + korm85)
- FigJam: pipeline diagram + Test Coverage + Key Decisions tables

## Test users (will exist after db reset)
| Role | Email | Password |
|------|-------|----------|
| Clinic | clinic-test@gavan.ai | testpass123 |
| Lab | lab-test@gavan.ai | testpass123 |

## Immediate next step after restart
1. Open Docker Desktop on Windows
2. Settings → Resources → WSL Integration → enable Ubuntu-24.04 → Apply & Restart
3. Verify in WSL2: `docker --version`
4. Tell me — I run: `cd ~/projects/work/gavanmanage && supabase start` then `supabase db reset`

## After Docker is live
- Build @playwright/test suite in gavan-qa (playwright.config.ts, global-setup, fixtures, 2 spec files)
- Set up GitHub Actions CI
- Set up Cloudflare Pages staging branch
- Create staging Supabase project (user does in dashboard)

## Key files
- `/home/korm85/projects/work/gavanmanage/supabase/seed.sql` — test user seed
- `/home/korm85/projects/work/gavan-qa/CLAUDE.md` — full QA project context
- `/home/korm85/projects/work/gavan-qa/scripts/` — exploratory CDP scripts
