---
name: agy-worker
description: Offloads heavy repository exploration, multi-file code searches, architecture audits, and large codebase scans to local Antigravity (Gemini 1M context) to burn ZERO Anthropic quota tokens. Use whenever searching across >3 files, finding implementations across a whole repo, or performing broad codebase audits.
---

Delegate heavy repository exploration, multi-file searches, and architecture audits to local Antigravity (`agy`).

## Why use this skill?
- **Zero Anthropic Quota Cost**: Antigravity runs on local Google Gemini infrastructure. Scanning 50 files costs 0 Anthropic tokens, saving your $20 Claude Code 5-hour rolling pool for pure coding logic.
- **1,000,000+ Context Window**: Antigravity reads entire repositories without token context anxiety.
- **Compressed Output**: Antigravity returns concise, high-signal caveman summaries directly to your context.

## When to Trigger:
- Scanning or grepping across multiple directories or >3 files.
- "Where is [feature/class/function] implemented in this project?"
- "Analyze the architecture of [module] and list all call sites."
- Broad codebase audits or locating unreferenced dead code.
- Pre-refactor discovery across unfamiliar codebases.

## How to Execute:

Run the scan helper script via the `Bash` tool:

```bash
python3 ~/.claude/skills/agy-worker/scripts/scan.py "<your specific question or search request>"
```

### Examples:

1. **Locate implementations**:
   ```bash
   python3 ~/.claude/skills/agy-worker/scripts/scan.py "Find all database migration files and list table definitions"
   ```

2. **Architecture review**:
   ```bash
   python3 ~/.claude/skills/agy-worker/scripts/scan.py "Trace how authentication tokens flow from API routes to Supabase client"
   ```

3. **Multi-file grep & audit**:
   ```bash
   python3 ~/.claude/skills/agy-worker/scripts/scan.py "Find all files importing 'relay_router' and describe how each uses it"
   ```

## Rules:
- Read the output returned from `scan.py` and proceed with your reasoning.
- Do not repeat the full file reading with native `View` if `scan.py` already answered the question.
