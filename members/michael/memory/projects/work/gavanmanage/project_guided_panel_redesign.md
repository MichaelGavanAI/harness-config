---
name: project_guided_panel_redesign
description: GuidedCasePanel UX redesign — immersive rich-content guide, pending Stitch MCP design generation
metadata:
  node_type: memory
  type: project
---

Approved plan to redesign GuidedCasePanel from plain text box into immersive contextual guide.

**Why:** Current panel too small, strains eyes, feels like bystander. Goal: coach-like, icon-per-step, rich text (bold/bullets), multiple visual zones, generous sizing.

**How to apply:** On session resume, check Stitch MCP tools available, generate design, then implement.

## Current state (2026-06-17)
- Branch: `feat/guided-tour-event-driven` at `0ef1de4`
- Plan file: `/home/korm85/.claude/plans/serene-shimmying-orbit.md`
- Stitch MCP: added to `/home/korm85/.claude.json` (GuidedTour project scope), needs session restart from `~/projects/work/gavanmanage` to load tools

## What to do on resume
1. Check Stitch tools loaded (`ToolSearch "stitch"`)
2. If yes: use Stitch with the prompt below to generate panel design
3. Implement from Stitch output into `src/components/GuidedCasePanel.tsx`
4. Also update `src/lib/wizardGuidance.ts` (add `icon` field, enrich body with bold/bullets)
5. Update `src/components/HelpButton.tsx` subtitles

## Stitch prompt (ready to use)
```
Design an immersive step-by-step guided panel for a dental lab SaaS app.
The guide should feel like a contextual coach, not a bystander info box.

Brand: Clinical Turquoise #2DD4BF, white card bg (#FFFFFF), Inter font.
Panel: fixed bottom-left corner, ~448px wide, floats above app content.

Design system:
- Primary: #2DD4BF (turquoise)
- Background: #FAFAFA
- Foreground text: #1E293B
- Muted text: hsl(215 16% 47%)
- Accent bg: hsl(168 76% 95%) (light turquoise)
- Border: hsl(214 32% 91%)
- Border radius: 0.75rem
- Shadow: 0 16px 40px rgba(0,0,0,0.22)

Requirements:
- Each step has a large step-specific illustration or icon (dentistry/workflow themed)
- Step heading large and bold (18px+)
- Body text uses bold for key terms, bullet points for multi-step actions
- Tip section: accent bg with lightbulb icon, distinct visual treatment
- Progress: visual stepper dots showing position in 6 steps
- Footer: waiting hint italic text left + End button right
- Step 1 special: Got it / Skip CTA pair
- Completion state: celebratory — large check with glow, "All done!" message
- Multiple visual zones: illustration area (top), content area (middle), action area (bottom)
- NOT a single flat text box — layered, visual hierarchy
- min 16px body text, high contrast, generous padding
```

## Files to change
- `src/components/GuidedCasePanel.tsx` — full redesign
- `src/lib/wizardGuidance.ts` — add `icon` field, enrich body text (bold markers, bullets)
- `src/components/HelpButton.tsx` — subtitle: "Quick overview of this screen" for Tour; "Step-by-step: process a work order" for lab Setup; "Step-by-step: submit your first case" for clinic Setup

## Note on HelpButton Guided Tour / Guided Setup issue
Both buttons call startGuidedMode → both open same panel. User confirmed keeping both — do NOT remove either. Fix needed: Guided Tour for lab should show isTourActive indicator (currently always false). Deferred — user wants design fix first.
