---
name: project_michael_schema_phase1
description: "Phase 1 per-developer schema (michael) rollout — implementation done, blocked on Roy for Exposed Schemas API setting"
metadata: 
  node_type: memory
  type: project
  originSessionId: f4081777-3b76-42f6-a459-d5c429ee019a
---

Phase 1 of the per-developer Postgres schema design (see [[project_state]] and the approved plan at `~/.claude/plans/production-is-dentflow-prod-sparkling-oasis.md`, copied into `gavanmanage/docs/superpowers/plans/2026-07-02-per-developer-schema-phase1-plan.md`) is code-complete, live database bootstrap succeeded, and the Roy blocker is now cleared — `michael` confirmed added to Data API "Exposed schemas" on `rmgkldfqlnaenanzjhnn` as of 2026-07-07. End-to-end verification is unblocked, in progress.

**Why:** Michael wanted to stop using local Docker Supabase and develop against a real `michael` schema in the shared dev project (`rmgkldfqlnaenanzjhnn`, "GavanManage"), isolated from Roy's `public` schema. The plan went through 7 audit rounds (2 Gemini/agy, 5 Opus) before implementation — see the plan file's "Audit checklist" section for the full trail of real bugs caught (search_path leakage, shared-resource migrations, a wholesale-skip mistake that would have deleted core tables, a SQL-generator quoting bug, an unqualified pg_type guard, a missing-BEGIN/COMMIT bug).

**Current state as of 2026-07-05:**
- Code done: `gavanmanage/scripts/lib/schema-replay.mjs`, `scripts/db-bootstrap.mjs`, `scripts/db-sync.mjs`, `scripts/db-generate-sql.mjs` (SQL-Editor-paste fallback, used because neither Michael nor a custom Postgres role could get the real `postgres` password/privileges), `supabase/seed-auth.sql`, `supabase/seed-schema-template.sql`, `src/integrations/supabase/client.ts` (added `db.schema` wiring), `package.json` (added `pg` dep + `db:bootstrap`/`db:sync` scripts), `supabase/config.toml` (fixed stale project_id), `.env.example`. None of this is committed to git yet (per Michael's standing preference to confirm before any commit/push).
- Database done: `michael` schema fully bootstrapped on `rmgkldfqlnaenanzjhnn` via a generated SQL script pasted into Supabase SQL Editor (run as the real `postgres` role, since no custom role could get `REFERENCES` on `auth.users` — Supabase's platform silently resets any manual grant on the `auth` schema beyond its own baked-in role baseline, confirmed empirically, not documented anywhere). 145 rows in `michael._migrations` (137 applied + 7 skipped + 1 seed), 47 tables, 22 enums, 3 correctly-seeded test cases verified by direct query.
- `.env.local` on Michael's machine updated: `VITE_SUPABASE_URL=https://rmgkldfqlnaenanzjhnn.supabase.co`, `VITE_SUPABASE_SCHEMA=michael`, publishable key set. Dev server confirmed running at `localhost:8081`.
- **Unblocked 2026-07-07**: Roy added `michael` to Data API "Exposed schemas" — confirmed. PostgREST now serves `michael` schema to browser clients.
- **Verified end-to-end 2026-07-07 11:12-11:17**: Clinic flow — created case COL-20260707-9701 via UI, confirmed row landed in `michael.cases` (clinic_user_id/assigned_lab_id resolved to seeded test users), `public.cases` untouched (Roy's data safe). Lab flow — logged in as `lab-test@gavan.ai`, case progressed through 2 stages in workbench, read+write both confirmed hitting `michael.cases` not `public`. User judged this sufficient — skipped remaining stages 3-6 (repeating pattern, no new pipeline risk). **Phase 1 core goal (replace local Docker with real `michael` schema) is done.**
- Branch had drifted back to `feat/lab-navigation-redesign` mid-session, losing the schema wiring (client.ts/config.toml/package.json) — had to reset to main and re-apply. Watch for this recurring if switching branches during this work.
- Remaining optional, not urgent: file-upload same-uploader test; `db:sync` idempotency check (deferred — couldn't locate `SUPABASE_DB_URL` connection string in dashboard UI, not blocking).
- Second terminal session hit lab-login trouble while pointed at `michael` schema after the above was already verified working — likely a local env/branch issue on that session specifically (missing `.env.local` schema wiring, or branch drift like above), not a schema/Roy problem. Check its `.env.local` matches `VITE_SUPABASE_URL=https://rmgkldfqlnaenanzjhnn.supabase.co`, `VITE_SUPABASE_SCHEMA=michael`, and that it's not sitting on a branch missing the schema-wiring commits.

**How to apply:** When resuming, check whether Roy has responded — if `michael` is now exposed, resume verification: refresh the dev server, log in as `clinic-test@gavan.ai` / `testpass123`, run the clinic new-case flow (confirm the new case lands in `michael.cases`, watching for the known Edge-Functions caveat that some writes go to `public` regardless of client schema), log in as `lab-test@gavan.ai` for the lab production-view flow, test a file upload, then `npm run db:sync -- --schema=michael` to confirm idempotency ("Already up to date"). If Roy hasn't responded, no need to re-derive any of this — just wait, nothing else to do.

**Cleanup, optional, not urgent:** a `michael_tooling` Postgres role and its `service_role` membership grant, and possibly a leftover `dev_tooling` schema/function, were created during troubleshooting and are no longer used by the final design (which runs entirely as `postgres` via the SQL Editor). Safe to drop later: `DROP SCHEMA IF EXISTS dev_tooling CASCADE; DROP ROLE IF EXISTS michael_tooling;` — check nothing depends on them first.

**Secrets exposed in plaintext during this session — rotation worth considering:**
- `michael_tooling` role's Postgres password (low stakes — role itself is disposable, see cleanup above).
- A Supabase Management API personal access token (`sbp_...`).
- The `rmgkldfqlnaenanzjhnn` project's **JWT secret** (signs/validates every user session — rotating it would instantly log out all active users app-wide; only rotate deliberately, not casually).
- The project's legacy `service_role` API key (bypasses all RLS — high value if leaked further).
None of these were used maliciously or shared outside this conversation, but the transcript itself now contains them. Flagging so a future session doesn't need to rediscover this.
