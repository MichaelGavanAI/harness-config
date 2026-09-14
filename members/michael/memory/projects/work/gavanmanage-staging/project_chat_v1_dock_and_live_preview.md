---
name: project_chat_v1_dock_and_live_preview
description: Chat dock UI fixes + live 3D restoration-preview-in-chat feature, pushed as fix/chat-dock-ui
metadata:
  type: project
---

Branch `fix/chat-dock-ui` (based on origin/staging) pushed to GitHub at commit 922c1eb, not yet PR'd. PR link: https://github.com/Gavan-AI-Labs-LTD/gavanmanage/pull/new/fix/chat-dock-ui

**What shipped:**
- Fixed docked chat panel (crushed input line, missing header info) and added `useDockedCaseHeader` hook (patient name + counterparty, dropped case number from docked view).
- Desktop chat entry point added to clinic `CaseDetailsModal` for feature parity with lab; unread-count badges added across sidebars (clinic+lab), mobile bottom nav, and messages hub.
- Restoration preview in chat: replaced any AI-generated image approach with a **live, read-only 3D viewer embed** — `SimulationShareCard` now renders `ZoneProjectionPanel` with `presentation="mobile-clinic"`, reusing the same viewer already used in the mobile PWA (`mobileCaseViewerUnit` builds its props from live `case_tooth_progress`). Auto-invalidates via existing `isSimulationShareExpired(capturedDataVersion, liveUpdatedAt)` when the lab changes shape/shade/stain; manual "Stop sharing" sets `revoked_at`.
- Migrations: `case_message_simulation_refs` gained `revoked_at` + UPDATE RLS (scoped `shared_by = auth.uid()`) + a trigger blocking any other column from changing; widened the `stage` CHECK constraint (was silently rejecting most workflow stages — this was the root cause of restoration preview "never working").
- Real infra fix (not scoped to this feature): `scripts/lib/schema-replay.mjs` search_path was missing `extensions`, breaking every pgcrypto-dependent migration for all per-developer schemas.

**Abandoned approach:** a headless static-image capture (`src/lib/shape-mesh/frontViewCapture.tsx`) — built, then deleted — because the live viewer hung forever at `loadState: "loading"` when mounted off-screen via `createRoot`, root cause never found. Pivoted to embedding the live viewer directly instead, which needed almost no new code since [[feedback_ma_copy_and_signal_conventions]]-adjacent infra (`isSimulationShareExpired`, `presentation="mobile-clinic"`, `mobileCaseViewerUnit`) already existed.

**Why:** user explicitly rejected AI-generated preview images ("no sense to have them") and required an auto-invalidating mechanism since shape/shade/stain can all change after a share.

**Known follow-up gaps (not yet fixed):**
- No DELETE RLS policy on `case_messages` — failed/aborted shares leave orphaned empty message bubbles. Cleaned up manually for case `a157851d-03cd-4a9a-81f2-d3b4c4734051` this session (11 orphaned rows + refs deleted, and the fake test `viewer_front_rotation`/`silhouette` patched into that case's tooth 22 during dev testing was reverted to its real unconfirmed-front-view state) — but the underlying missing-DELETE-policy gap itself is still open.
- Code review (Opus, pre-push) flagged: a counterparty with the chat thread already open won't see a "Stop sharing" revocation until they refetch (`case_message_simulation_refs` subscription only listens for INSERT, not UPDATE) — presentation-only staleness, not a data-exposure issue since both parties already have SELECT on the underlying `case_tooth_progress` row. Also two low-severity polish items: unhandled `Notification.requestPermission()` rejection in `ChatNotificationProvider.tsx`, and `useHelpButtonVisibility.ts` writes to `localStorage` without the guard/try-catch the read path has.

**How to apply:** if asked to open a PR for this branch, or to fix the revocation-staleness/DELETE-policy gaps, this is the context. Don't re-attempt the headless capture approach — it's a known dead end pending a real root-cause investigation into off-screen `createRoot` + Three.js mount hangs.
