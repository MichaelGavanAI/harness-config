---
name: feedback_todo_impact_wording
description: "Todo items should read as product impact, not implementation steps; Coding category splits Product vs Infra & Routine"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e6ef3db3-1d8b-4431-9a7a-bcdf3fa1997f
---

Write todo item text (in `MichaelGavanAI/todos` issue #1, and by extension any task list Michael reads) as what breaks or improves for the user/technician, not as a list of code changes to make.

**Why:** Michael pushed back twice on the same batch of items. First: "coding is not meaningful name — text should reflect what impact the effort actually does" — items like "add Layering field, fix Architecture binary, auto-decide gradient" got rewritten to lead with "Stop recommending materials technicians cannot actually select or use..." Second: "in coding I don't want a single block like this — there are product improvements and there are just routine PRs to be handled, they are not on the same level, think of a product todolist, not developer flat tasks" — this led to splitting `## Coding` into `### Product` and `### Infra & Routine` subheadings, encoded in the repo's `AGENTS.md` so it persists for other agents (Hermes, OpenClaw) too.

**How to apply:**
- When adding a Coding item, ask first: does this change what the product does for a user/technician (Product), or does it just keep the engine running (Infra & Routine)? File under the matching `###` subheading, blocked-first within each.
- Phrase the item as the failure mode or improvement ("Stop X from happening" / "Users can now Y"), not the mechanism ("add field," "fix function," "refactor Z"). The mechanism can live in the linked doc/PR, not the todo line.
- This preference likely generalizes beyond the todos repo — default to impact-first wording in any list Michael will read directly (PR summaries, status updates), not just this specific issue.
