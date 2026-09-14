---
name: feedback_code_review_effort
description: "Scale code review model/effort to diff size and risk — don't default to Opus for every final review"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3c66c123-663b-4e59-b385-41d68a80db58
---

Final whole-branch code review model must match effort to risk, not always use Opus.

**Why:** Michael flagged that SDD skill's "use most capable model for final review" is wasteful when the branch has minimal logic risk (e.g. mostly HTML scenes + one small React component, each already reviewed per-task).

**How to apply:**
- Small branch (1-2 logic files, all tasks already reviewed): skip final review OR use Haiku/Sonnet
- Medium branch (3-5 logic files, some integration): Sonnet
- Large branch (6+ files, auth/Supabase/patient-data touched, >400 lines logic): Opus
- The per-task reviews are the real gate; final review is a catch-all, not a repeat of everything

**Confirmed 2026-07-15** (calibration-multi-media branch, 9 files, storage/case-data touched, ~3000 lines): Opus whole-branch review found 3 real cross-task bugs — including one destructive (removing a case's video wiped all its images) — that 8 clean, individually-approved Sonnet per-task reviews had missed entirely. Cross-task integration bugs are structurally invisible to task-scoped reviewers; the "Large branch → Opus" tier is not optional for this class of risk. A subsequent 3-angle Sonnet code-review gate on top of the Opus review found 3 more real bugs the Opus review's targeted risk list hadn't covered — running multiple independent review passes at this size found genuinely new things each time, not diminishing returns.

Relates to: [[feedback_autonomous_decisions]]
