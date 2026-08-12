---
name: feedback_agy_only_parity_plan
description: Parity POC plan work runs on agy only — no Claude subagents until Michael revokes
metadata:
  type: feedback
---

For the full-parity headless POC plan (GLS repo, feat/headless-calibration-poc): all implementation AND review work goes to agy (Antigravity/Gemini), not Claude subagents. Main thread acts only as thin dispatcher (direct `agy -p` Bash calls) and bookkeeper.

**Why:** Michael hit the Claude monthly spend limit mid-plan (2026-07-13); explicit directive "delegate all work to agy, don't use claude for this plan until i say otherwise".

**How to apply:** Dispatch tasks via `agy -p` with the task brief file paths. Verify agy's work with cheap Bash commands (dotnet test/build) from main thread, not Claude reviewer subagents. Revoked only by Michael's explicit say-so.
