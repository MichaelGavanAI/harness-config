---
name: feedback-defined-gates-not-adhoc
description: "Use the repo's defined CI/test/review gates, not whatever verification feels reasonable in the moment"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0c01fe9e-894c-4344-a5f3-7a3dd485962d
  modified: 2026-07-20T15:30:22.037Z
---

Run verification against the repo's actual defined pipeline (CI workflow steps, `/code-review` stamp gate, scoped test files tied to the diff) — not an ad hoc full `npx vitest run` sweep picked because it "seemed reasonable."

**Why:** Michael pushed back hard (2026-07-20) after I ran the full unit-test suite unscoped, hit unrelated pre-existing timeout failures in Roy's color-science tests (kubelkaMunkStumpPrep etc.), and initially mischaracterized them (wrongly attributed to Yael without checking git blame, called them "standard" without verifying against baseline). His core complaint: he wants predictable, repo-defined verification (CI pipeline, code review gate), not me improvising scope on my own judgment.

**How to apply:** Before claiming work done on this repo:
1. Check `.github/workflows/*.yml` for what CI actually runs — this project's CI ([e2e.yml](/home/korm85/projects/work/gavanmanage/.github/workflows/e2e.yml)) runs `tsc --noEmit` + Playwright e2e, NOT `vitest`/unit tests at all.
2. Scope any test run to files touching the actual diff, not a full-suite sweep — full-suite runs sweep in unrelated flaky/slow tests (e.g. Roy's Kubelka-Munk color-science tests time out under parallel load) that have nothing to do with the change and just create noise/confusion.
3. Before `git push`, run the `/code-review` skill per [CLAUDE.md](/home/korm85/projects/work/gavanmanage/CLAUDE.md) — that's the actual defined, SHA-stamped gate this repo requires, not a self-invented "run everything and eyeball it" check.
4. If a test fails, verify root cause before asserting anything about it (stash+baseline-compare, git blame) — don't guess ownership or call something "standard behavior" without checking.

See also [Verify before reporting](feedback_verify_before_reporting.md).
