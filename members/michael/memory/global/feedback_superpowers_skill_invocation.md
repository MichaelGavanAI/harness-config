---
name: feedback_superpowers_skill_invocation
description: "When and how to invoke superpowers skills — using-superpowers already loaded via hook, don't re-invoke it"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: e44ca9c3-8f33-4b36-a449-165981f91150
---

Do NOT invoke `using-superpowers` via Skill tool before every response.

**Why:** The SessionStart hook already injects `using-superpowers` content into context. Re-invoking it is redundant and wastes tokens. The skill description says "use when starting any conversation" — once per session, not per response.

**How to apply:** Before each response, ask "does a task-specific skill apply?" (brainstorming, debugging, TDD, etc.) and invoke only those. Trivial tasks (auth, config, short Q&A) need no skill invocation. `using-superpowers` itself is never the answer to "which skill applies here."
