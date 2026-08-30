---
name: feedback_adversarial_review_before_large_clinical_diffs
description: "Before committing a large, unsupervised subagent diff in clinical-logic code, get an independent adversarial review even if all tests pass - it caught a real safety regression the tests missed"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 924fd0af-d91a-4eed-8b74-6793d0fa134b
  modified: 2026-08-19T12:00:47.579Z
---

During PR #307's third debugging round (2026-08-19, Material Advisor wizard), a subagent doing an "exhaustive audit" fix came back much larger than the two prior minimal fixes - new UI states, card reordering, a translucency-blocking logic change - with 110/110 tests passing and tsc clean. Rather than trusting that and committing, a SEPARATE Opus agent was dispatched specifically to adversarially review the uncommitted diff before push. It found a real P0: a new "escape hatch" the implementer added was partly self-referential (it counted the very safety gate it then disabled as a trigger condition), silently letting a blocked clinical option (High translucency on a masking-compromised case) through as selectable - confirmed with runtime instrumentation, firing twice inside the existing passing test suite with zero test catching it. Also found two P1s (a reintroduced dead-button bug, a fabricated "Best match" label with no real scoring behind it) and a P2, all real, all missed by 110 passing tests.

**Why:** passing tests only prove the tests' own coverage is met - they say nothing about whether a large diff quietly weakens a safety gate the tests never thought to check. An implementer agent working unsupervised (especially across a "was killed and resumed mid-task" session) has no adversarial incentive to look for what it might have broken while fixing what it was asked to fix. A second agent with instructions to specifically hunt for weakened safety checks, fabricated labels, and reintroduced failure modes - not just "does it still pass" - caught what the first agent's own re-run of the same tests could not.

**How to apply:** when a subagent fix in clinical/safety-relevant code comes back significantly larger in scope than the bug it was sent to fix (new states, reordering, logic branches beyond the reported mismatch), don't commit on "tests pass" alone. Dispatch an independent review agent (different agent instance, ideally same reasoning tier or higher) with an explicit adversarial framing: name the specific safety gates/invariants that exist in the surrounding code and ask it to trace whether the new diff can defeat them, not just "review this diff." Small, narrowly-scoped fixes (single value-matching guard, single normalization) don't need this - it's specifically warranted when scope creep happens organically inside an "exhaustive audit" task. See [[project_material_advisor_wizard_gaps]] for the fuller incident history.
