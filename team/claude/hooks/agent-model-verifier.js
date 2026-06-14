#!/usr/bin/env node
// agent-model-verifier.js — PreToolUse hook on Agent
// Blocks Agent calls that omit model param or use an unrecognized model ID.

const VALID_MODELS = new Set([
  'claude-haiku-4-5-20251001',
  'claude-sonnet-4-6',
  'claude-opus-4-8',
  'haiku',
  'sonnet',
  'opus',
]);

let input = '';
process.stdin.on('data', chunk => { input += chunk; });
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const model = (data.tool_input || {}).model;

    if (!model) {
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason:
            "Agent called without explicit model param. " +
            "Required: haiku=search/read/grep, sonnet=code (default), opus=architecture. " +
            "Add model: '<id>' to Agent call."
        }
      }));
      return;
    }

    if (!VALID_MODELS.has(model)) {
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PreToolUse",
          permissionDecision: "deny",
          permissionDecisionReason:
            "Agent model '" + model + "' not in approved list. " +
            "Use: claude-haiku-4-5-20251001, claude-sonnet-4-6, or claude-opus-4-8."
        }
      }));
      return;
    }

    // Valid — allow
  } catch (e) {
    // Silent fail — never block on parse error
  }
});
