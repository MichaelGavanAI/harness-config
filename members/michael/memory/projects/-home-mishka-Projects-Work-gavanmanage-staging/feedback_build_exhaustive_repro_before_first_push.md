---
name: feedback_build_exhaustive_repro_before_first_push
description: "For multi-step completion/validation flows, build the exhaustive walk-every-path local test BEFORE the first push, not after a second CI failure confirms it's a bug class"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 924fd0af-d91a-4eed-8b74-6793d0fa134b
  modified: 2026-08-19T12:32:02.170Z
---

PR #307 (Material Advisor wizard) took 5 CI cycles (~15-20 min each) to go green, across 4 distinct root causes. Retrospective (2026-08-19, requested by user specifically to reduce future CI cycles):

- Cycle 1→2: justified, first bug needed discovery.
- **Cycle 2→3: avoidable.** A first targeted fix (5bef546) didn't resolve CI. That alone is a strong signal of a systemic bug class (same failure mechanism, same symptom), not a one-off - but a second narrow fix (4dd0f6e) was tried before escalating to a full audit, costing a whole extra CI cycle to learn what was already knowable.
- Cycle 3→4: cost ZERO CI cycles, because an independent adversarial review caught a real P0 safety regression in the round-3 fix BEFORE it was pushed (see [[feedback_adversarial_review_before_large_clinical_diffs]]). This is the pattern that actually worked - it just arrived one round later than necessary.
- Cycle 4→5: a genuinely separate, hard-to-predict feature gap (an unrelated dialog the test helper didn't know about) - not much to improve here short of a live end-to-end run before ever touching CI.

**The actual root inefficiency:** the test that eventually caught every instance of the bug class - an exhaustive "walk all steps via their own defaults, assert the completed state never silently reverts" Vitest test - was only built as a byproduct of the round-3 audit. It runs in ~10-20 seconds locally. Had it existed before the FIRST push, cycles 2 and 3 would likely have collapsed into one fast local iteration loop instead of two 15-20 minute CI round-trips.

**Why:** CI cycles for E2E/Playwright suites are 50-100x slower than a local Vitest run. When a bug's symptom is "the whole flow silently discards state" (a validator disagreeing with the thing it's validating, a revert, a snap-back), that's exactly the shape of bug an exhaustive local walk-through test catches cheaply and a live E2E run catches expensively and vaguely (log archaeology, screenshots, guessing which step failed).

**How to apply:** when a fix touches a multi-step wizard/form's completion or cross-step validation logic, and especially once a first CI failure's root cause turns out to be "step X's value doesn't satisfy step X's own independent re-validator" - build the exhaustive walk-every-realistic-path local test immediately, covering multiple case shapes (not just the one CI fixture that failed), BEFORE pushing the fix for that first instance. Don't wait for a second CI failure to justify going exhaustive - the first failure's root cause pattern is usually enough of a signal on its own. Local test iteration is nearly free; CI cycles are not.
