#!/usr/bin/env node
// agent-model-verifier.js — PreToolUse hook on Agent
// Blocks Agent calls that omit model param or use an unrecognized model ID.

const VALID_MODELS = new Set([
  // Aliases are the supported Agent-tool values; they track the current generation.
  'haiku',
  'sonnet',
  'opus',
  'fable',
  // Full IDs accepted for compatibility.
  'claude-haiku-4-5-20251001',
  'claude-haiku-4-5',
  'claude-sonnet-5',
  'claude-opus-5',
  'claude-fable-5',
  'claude-sonnet-4-6',
  'claude-opus-4-8',
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
            "Use an alias: haiku, sonnet, opus, or fable."
        }
      }));
      return;
    }

    // Valid — allow
  } catch (e) {
    // Silent fail — never block on parse error
  }
});
