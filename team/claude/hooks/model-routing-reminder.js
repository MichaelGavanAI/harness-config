#!/usr/bin/env node
// model-routing-reminder.js — UserPromptSubmit hook
// Re-injects subagent model routing table every turn to prevent drift.

let input = '';
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: "SUBAGENT MODEL ROUTING (enforce always when spawning Agent tool): " +
          "Search/read/grep/glob → claude-haiku-4-5-20251001. " +
          "Code writing/editing (default) → claude-sonnet-4-6. " +
          "Architecture/planning/design → claude-opus-4-8. " +
          "Always pass explicit model ID. Never use wrong tier."
      }
    }));
  } catch (e) {
    // Silent fail
  }
});
