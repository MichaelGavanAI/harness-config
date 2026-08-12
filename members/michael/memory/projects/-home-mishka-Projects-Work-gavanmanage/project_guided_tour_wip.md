---
name: project_guided_tour_wip
description: "Lab guided tour — feat/guided-tour-lab-onboarding branch state, ready for merge + push"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5f73a7e3-e2e2-41b7-a8a1-bd033713f897
---

Branch: `feat/guided-tour-lab-onboarding`
Status: **PUSHED to remote** — 5 commits ahead of main, 0 behind. PR to staging next.

## What's complete and pushed (2026-06-23)

### GuidedCasePanel.tsx
- Inline icon+heading row (removed standalone icon zone)
- Tighter dot stepper (py-1.5)
- CommandToken chip component + parseRich parser (backtick = chip, ** = bold)
- Sparkles + MonitorPlay added to ICON_MAP

### wizardGuidance.ts — LAB_GUIDANCE (10 steps)
- Steps 1-2: setup (catalog, color calibration) — manualNext=true
- Step 3: waitingHint added (no longer shows Got it button prematurely)
- Step 5: stage number jargon removed
- Steps 7-10: backtick chips on all UI button names
- LAB_PRODUCTION_GUIDANCE step 1: stage names instead of "Stages 2-5"

### Tooltips (Radix, dark bg-foreground/text-background styling)
- ShadeAnalysisPanel: Open Shade Analysis, Read Shade Data (span wrapper fix), Confirm Shade Analysis
- ColorInstructionsPanel: Generate Staining Instructions, Confirm & Continue
- LabWorkbench: locked Simulation + Production padlocks

### LabDashboard.tsx — New Internal Case tooltip: hidden when case open or not at workbench

### WelcomeModal.tsx — 4 LAB_STEPS, vertical list, no em dashes

### FileUploadStep.tsx — Calibration Video first, 3D Scan optional for both roles

### tooltip.tsx — Global dark bg (bg-foreground text-background border-0 shadow-xl)

### App.tsx — 3 bugs fixed (2026-06-23)
- onStep/onClosed guard role=clinic (lab wizard cancel no longer kills guide)
- onLabWizardStep guards role=lab (clinic events no longer corrupt labWizardStep)
- onLabStep guards setup steps 1-2 (LabWorkbench mount can't jump guide to step 5)

## Status: SHIPPED to main (2026-06-23)
- PR #60: feat/guided-tour-lab-onboarding → staging — merged, all CI green
- PR #61: staging → main — merged, all CI green
