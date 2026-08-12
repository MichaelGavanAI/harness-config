---
name: project-haim-feedback-tracker
description: "docs/haim-feedback-tracker.md is a living doc, not scoped to any feature branch"
metadata: 
  node_type: memory
  type: project
  originSessionId: f037891a-5792-4a35-8919-be4231422fd1
  modified: 2026-07-20T09:00:32.289Z
---

`docs/haim-feedback-tracker.md` is a living document tracking Haim's (dental technician) hands-on feedback across sessions — not tied to any specific feature branch or PR.

**Why:** Michael updates it whenever new feedback comes in from Haim, independent of what code branch is currently checked out. It stays untracked/uncommitted in working dir across branch switches (git checkout doesn't touch untracked files, so no special handling needed).

**How to apply:** Don't treat this file as scoped to the branch it happens to be sitting on. When Michael gives feedback, update the relevant row/section directly regardless of current branch context. See [[project_shade_material_ux_findings]] for related UX findings.
