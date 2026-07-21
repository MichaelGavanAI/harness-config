---
name: reference_supabase_dev_env
description: "gavanmanage's .env.local is pre-wired to Michael's per-dev Supabase schema — tell every dispatched agent this directly, don't let them hunt for it"
metadata: 
  node_type: memory
  type: reference
  originSessionId: e6ef3db3-1d8b-4431-9a7a-bcdf3fa1997f
---

`gavanmanage`'s `.env.local` already points at the real Supabase project and Michael's per-developer schema:

- `VITE_SUPABASE_URL=https://rmgkldfqlnaenanzjhnn.supabase.co`
- `VITE_SUPABASE_SCHEMA=michael`

**Why:** subagents kept spending real time (and turns) trying to discover or guess which database/schema to connect to, or inventing throwaway test accounts, when the answer was already sitting in a file one `cat` away.

**How to apply:** when dispatching any agent that needs to run the app (`npm run dev`, a build, an authenticated repro), state directly in the prompt: "`.env.local` is already configured for the `michael` dev schema — just run `npm run dev`, don't hunt for connection info." If a login is needed, don't have the agent invent a random throwaway email — check first whether a stable synthetic lab-role test account already exists (one referenced earlier in this session was `lab-test@gavan.ai`, but its password isn't persisted anywhere durable — if unknown, create ONE new synthetic account via the app's own signup with a clearly fake email, never real/patient data, and only as a last resort).
