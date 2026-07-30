#!/usr/bin/env node
// DEPRECATED — no-op, kept so existing settings.json registrations don't error.
//
// This hook re-injected the subagent routing table on every UserPromptSubmit.
// agent-model-verifier.js already enforces routing by DENYING an Agent call
// with a bad model, which is deterministic; restating the rule each turn added
// tokens without adding enforcement. The routing table lives in CLAUDE.md.
// Remove this from settings.json when convenient.
process.stdin.resume();
process.stdin.on('data', () => {});
process.stdin.on('end', () => process.exit(0));
