---
name: session-2026-06-08-guided-tour
description: Guided tour + interactive guided case mode — implementation complete; navigation fix applied 2026-06-09
metadata: 
  node_type: memory
  type: project
  originSessionId: 3d7089df-c852-4255-b665-23e83a3445c2
---

# Sessions 2026-06-08/09 — Guided Tour & Interactive Guided Setup

## What was built

### Passive Tour (driver.js) — refactored and working
- `src/lib/tourConfig.ts` — completely rewritten
  - Module-level `_driver` ref + `setTourDriverInstance()` export
  - Clinic tour: 8 steps — step 1 highlights `[data-tour='new-case-button']`, `onNextClick` auto-clicks button and polls for wizard to open, steps 2–8 highlight each `[data-tour='wizard-step-{n}']` circle in StepIndicator with rich HTML descriptions
  - Lab tour: 5 floating popovers (rich HTML)
- `src/components/clinic/StepIndicator.tsx` — added `data-tour="wizard-step-{n}"` to each step div
- `src/components/clinic/OrderWizard.tsx` — added `data-tour="wizard-step-indicator"` to container; removed broken `useBlocker`/AlertDialog (requires data router, app uses BrowserRouter); kept `beforeunload` handler
- `src/App.tsx` — `setTourDriverInstance(d)` called after driver creation; `null` on destroy

### Interactive Guided Setup (NEW) — working
- `src/lib/wizardGuidance.ts` — `WizardStepGuidance` interface, `WIZARD_GUIDANCE` record (6 steps), `getWizardGuidance(step)` helper
- `src/components/GuidedCasePanel.tsx` — fixed bottom-left floating panel (`fixed bottom-6 left-6 z-50 w-72`), gradient header with Compass icon + "N/6" badge, progress bar, heading/body/tip, "End guidance" link. Uses `clinical-card` class. Imports: `Compass`, `Lightbulb` from lucide-react
- `src/components/clinic/OrderWizard.tsx` — two new useEffects: dispatches `gavan:wizard-step` (CustomEvent<number>) on step change; dispatches `gavan:wizard-closed` on unmount
- `src/App.tsx` changes:
  - `useNavigate` imported from react-router-dom
  - `GuidedCasePanel` imported
  - New state: `isGuidedMode`, `guidedStep`
  - useEffect listening to `gavan:wizard-step` → updates `guidedStep`; `gavan:wizard-closed` → clears guided mode
  - `startGuidedMode()`: sets state only — NO navigation (panel shows in-place on current screen; `useNavigate` import removed)
  - `handleStartTour()` — clinic → `startGuidedMode()`; lab → `startTour("lab")`
  - `handleToggleGuidedMode()` — toggle guided mode on/off
  - Renders `<GuidedCasePanel>` when `isGuidedMode && (role === "clinic" || role === "lab")`
  - Passes `role`, `isGuidedMode`, `onToggleGuidedMode` to HelpButton
- `src/components/HelpButton.tsx` — new props: `role`, `isGuidedMode`, `onToggleGuidedMode`; added `Compass` icon; clinic users see BOTH "Guided Tour" (passive) and "Guided Setup" (interactive); lab sees only "Guided Tour"
- `src/components/WelcomeModal.tsx` — CTA text: clinic → "Start Guided Setup", lab → "Start Tour"

## Update: 2026-06-17 — Event-Driven Lab Guide (v2) COMPLETE

Branch: `feat/guided-tour-event-driven` at `e83aaf5`

**What changed from v1:**
- `src/lib/labGuideContext.ts` (NEW) — module-level singleton tracking `hasCaseOpen`, `caseStatus`, `activeStage`
- `src/lib/detectGuidedStep.ts` (NEW) — `detectLabStep()` maps context → step 1-6; `detectClinicStep(wizardStep)` passthrough
- `src/components/GuidedCasePanel.tsx` — `mode="event-driven"` replaces `mode="manual"`. Auto-advances on real user actions. Step 1 has "Skip guide"/"Got it" CTA. Steps 2+ show `waitingHint`. Completion state shows CheckCircle2, auto-closes after 2200ms.
- `src/components/lab/LabWorkbench.tsx` — dispatches `gavan:lab-step` (detail 1-6) at each workflow milestone; dispatches `gavan:lab-case-closed` when case deselected; calls `setLabGuideContext()` to keep singleton in sync
- `src/App.tsx` — `startGuidedMode` now context-aware: uses `detectLabStep()` for initial step; nav guard sets `guidePendingRole` if user is on wrong page; pathname-watch effect closes guide on nav; AlertDialog confirms navigate-and-start
- `src/lib/wizardGuidance.ts` — `waitingHint` field added to all 6 clinic + 6 lab steps; copy refreshed

**Event dispatch sequence (lab):**
- Open case → `gavan:lab-step` detail 2
- Accept → detail 3 then 4
- Decline → detail 3
- Stage commit (past shape) → detail 5
- Ship case → detail 6 (BEFORE setSelectedCase null to avoid race with lab-case-closed)
- Close/deselect case → `gavan:lab-case-closed`

**Tests:** 82/83 unit pass (1 pre-existing WelcomeModal failure), 5/5 Playwright pass

**Pending / Next session:**
- Roy's 5 remaining guided-tour bugs (from PR #28) — need list from Roy to assess if any overlap with new event-driven flow
- Dead code to clean up: `handleGuidedNext`, `handleGuidedPrev`, `guidedTotal`, `startTour("lab")` path in App.tsx — now unused after event-driven switch

## Key technical details
- Dev server: `http://localhost:8081/` (Vite)
- CDP testing: Windows Chrome headless `--remote-debugging-port=9222`, accessed via Windows Node.js `/mnt/c/Program Files/nodejs/node.exe` + `C:\Users\korm8\AppData\Roaming\npm\node_modules\playwright`
- Login: `michael@gavan.ai / 123456`, role = clinic, org_type = clinic
- `gavan_tour_completed` localStorage key controls WelcomeModal visibility (null = show modal)
- `clinical-card` is a Tailwind utility class defined in the app's CSS
- No git push at any point — user working locally only

## Why: motivation
The passive driver.js tour only showed popovers without helping users do real work. Goal: support-engineer-style handholding where system guides, user enters real data. Both modes kept per user request (passive for overview, interactive for real first case).
