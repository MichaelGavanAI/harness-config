---
name: feedback_cost_conscious_subagent_model_choice
description: "User pushed back on opus spec+plan agents burning 130k+ tokens for small, well-precedented fixes - default to sonnet once a pattern is established"
metadata:
  type: feedback
  originSessionId: f35a90e9-baf0-4dbd-9a3f-baa184002ab8
  modified: 2026-08-17T10:15:33.774Z
---

Do not default to opus for spec+plan subagents on every gap-fix task, even when project CLAUDE.md's Scope Gate nominally calls for it. After the first 1-2 gaps in a series establish a clear, repeatable pattern (same files, same mechanism, same test conventions), drop to sonnet for the remaining ones.

**Why:** User saw a screenshot showing a single opus spec+plan agent for gap #33 spending 132k tokens, and asked "is this the best approach?" This was for the third gap-fix in an already-established pattern (gap #36 had just built the exact same shape: type additions, a `resolveX`/`isXFragile`-style helper, wizard wiring, AC-numbered tests) — opus's deeper reasoning was mostly redundant by that point. User's explicit instruction: "drop opus, use sonnet for #33/#35." Killed the running opus agent mid-task (`TaskStop`) and relaunched the identical prompt on sonnet with no quality loss — sonnet's plan for #33 was tighter and actually caught a real error opus's approach direction hadn't surfaced yet (that bridge_units_fit was never actually stale).

**How to apply:** For a multi-item task where each item follows the same fix shape (gap-fix series, repeated migration pattern, etc.): use the stronger model (opus) for the FIRST 1-2 items to establish the pattern and citation-verification discipline, then downgrade to sonnet for subsequent items once the shape is proven. Don't wait for the user to notice and ask — proactively suggest the downgrade once repetition is evident. Also: for very well-precedented fixes (e.g., a fix that's structurally near-identical to one already shipped in the same file), it's reasonable to skip the separate spec+plan subagent step entirely and implement directly with a short inline plan, as was done for gap #35 after #33 and #36 had already established the exact pattern.
