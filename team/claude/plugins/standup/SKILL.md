---
name: standup
description: >
  Daily task briefing — scans all Slack channels and DMs for new tasks, cross-references
  git history to mark done vs pending, outputs prioritized task list. Updates
  project_open_items.md memory with current status. Use at session start or any time
  you want a task refresh. Triggers on /standup.
---

# Standup — Daily Task Briefing

## Purpose

Pull together everything Michael needs to know at the start of a work session:
what's new in Slack, what got done in git, and what's still open.

## Steps

### 1. Refresh Slack digest

Run the fetch script to get latest messages (skip if digest is less than 30 min old):

```bash
bash ~/projects/work/slack-fetch.sh
```

### 2. Read the digest

Read `~/projects/work/slack-digest.md` in full. Extract:
- Any new tasks or action items assigned to Michael (from Roy, Matan, or others)
- Any decisions made that affect open work
- Any blockers or questions waiting for Michael's response

Focus channels: DM Roy, Group DM (Roy+Matan+Michael), #cicd, #gavan-all-tech.
Other channels: scan briefly for anything mentioning Michael or his work areas.

### 3. Cross-reference git

Run in both repos to see what shipped since last standup:

```bash
cd ~/projects/work/gavanmanage && git log --oneline --since="2 days ago"
cd ~/projects/work/gavan-cicd && git log --oneline --since="2 days ago"
```

Match commit messages against known open items → mark as done if shipped.

### 4. Read current open items

Read `~/.claude/projects/-home-korm85-projects-work-gavanmanage/memory/project_open_items.md`
for the current task list.

### 5. Output briefing

Produce a concise briefing in this format:

```
## Standup — [DATE]

### New from Slack
- [person, channel, date]: task or decision

### Done since last standup
- ✅ [task] — [commit or evidence]

### Still open
- ❌ [task] — [owner / blocker]

### Needs decision
- ❓ [item] — [what's needed]
```

Keep it tight — no summaries of conversations, just action items and status.

### 6. Update memory

After outputting the briefing, update `project_open_items.md`:
- Mark shipped items as done with date
- Add any new items discovered in Slack
- Remove items that are clearly obsolete

## Notes

- Slack digest auto-refreshes if >30 min old — no need to force-refresh manually
- If `slack-fetch.sh` fails (token expired, network), fall back to the cloud Slack MCP plugin
- git log window is 2 days by default — extend to 7 days if coming back from a break
