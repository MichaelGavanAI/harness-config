# Getting your Claude Code setup back

## When to use this

- You got a new laptop.
- Your old laptop was wiped, lost, or died.
- You're setting up a second computer and want it to work the same way.

## Before you start

Claude Code itself needs to be installed first — that's the one manual step this guide doesn't cover. If it's not already installed, go to Anthropic's own Claude Code page and follow their install steps. Once you can open a Claude Code session, come back here.

## The one thing to say

Open a fresh Claude Code session anywhere on your computer, and say exactly this:

> Restore my Claude Code setup from github.com/MichaelGavanAI/gavan-agent-config

Claude will read this repository and start putting your setup back together — your saved notes about past projects, your custom shortcuts and automations, and your installed add-ons.

## What you'll be asked for

At some point, Claude will likely ask you to paste in an API key or similar secret (for example, a Figma key). This is expected — those are never saved in this repository on purpose, so nothing sensitive sits on GitHub. Just paste the value in when asked.

## How you'll know it worked

- **Ask Claude about an old project** ("what were we working on in gavanmanage last week?"). If it remembers real details, your notes came back correctly.
- **Try a shortcut you used before** (a slash command or a phrase you'd normally use, like caveman mode). If it responds the way it used to, your automations came back correctly.
- **Check your add-ons are there.** If you had specific plugins installed before (ask Claude "what plugins do I have installed?"), they should be reinstalled and listed.

## If something looks wrong

- **Claude doesn't remember anything about your past work** — tell Claude directly: "my memory doesn't seem to have come back, can you check?" It can run a diagnostic (`tools/harness-sync.sh check`) to see what's missing.
- **A shortcut or automation you used before seems to not exist anymore** — same thing: describe what you expected to Claude, and it can look for the gap.
- **You're not sure if something is missing at all** — just ask Claude to double check your setup against this repository. That's exactly what it's built to do.
