---
name: feedback_ci_badge_design
description: "Rules for adding state badges to the CI/CD Manager dashboard - actionable, honest, no auto-fix"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 56062749-8002-4414-9aa2-d54577a6c43e
---

When adding status badges/indicators to `gavan-cicd/cicd-manager` (or any dashboard), Michael pushed back on several drafts before landing on the right shape:

1. **No auto-resolve actions.** A "rebase and promote" button was rejected — real conflicts (overlapping logic changes) need a human to pick the correct code, not a tool guessing. Only show state, let the human decide the fix. [[project_pr115_conflict_and_cicd_badges]]
2. **No embedded fix commands in tooltips.** Even "run `git merge origin/staging`" was rejected as a tooltip suggestion — rebase vs merge is a judgment call depending on context, a canned command invites blind copy-paste. Point to the docs (`WORKFLOW.md`) instead, or state the action category ("sync your branch") without the literal command.
3. **Only badge non-standard/anomalous states**, not routine pipeline steps. Same principle as the existing `⚠ CI bypassed` badge (main force-merged despite failing CI) — badges exist for deviations from the expected path, not to narrate every normal step.
4. **Don't mislabel as "policy override" unless it actually is one.** Checked the GitHub ruleset before labeling anything a bypass — `staging` requires the `e2e` status check server-side, so enabling auto-merge early isn't a violation, just premature. Reserve "policy overruled" language for cases with no server-side enforcement (e.g. `main` has no branch protection at all).
5. **Drop badges that are informative but not actionable.** A standalone "N commits behind staging" badge was proposed then killed — if there's no conflict yet, the number alone gives the developer nothing to act on. Folded into the conflict badge as context instead of a standalone signal.

**Why:** Michael wants the dashboard to build trust by being precise — badges that cry wolf (false "policy violation" labels) or invite unsafe blind actions (canned fix commands, auto-resolve buttons) erode that trust fast.

**How to apply:** Before proposing any new dashboard indicator, check: (a) is this state actually reachable via the documented CI/CD flow, or a genuine deviation? (b) does surfacing it give the developer something to *decide*, not just know? (c) am I confident enough in the label (e.g. "conflict", "override") to have verified it against actual GitHub API / ruleset data, not assumed?
