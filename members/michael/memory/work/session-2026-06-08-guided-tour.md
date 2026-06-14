---
name: session-2026-06-08-guided-tour
description: Guided tour + interactive guided case mode implementation session summary — pick-up point
metadata: 
  node_type: memory
  type: project
  originSessionId: 3d7089df-c852-4255-b665-23e83a3445c2
---

# Session 2026-06-08 — Guided Tour & Interactive Guided Setup

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
  - `startGuidedMode()`: sets state + navigates to `/clinic-dashboard?view=new`
  - `handleStartTour()` — clinic → `startGuidedMode()`; lab → `startTour("lab")`
  - `handleToggleGuidedMode()` — toggle guided mode on/off
  - Renders `<GuidedCasePanel>` when `isGuidedMode && role === "clinic"`
  - Passes `role`, `isGuidedMode`, `onToggleGuidedMode` to HelpButton
- `src/components/HelpButton.tsx` — new props: `role`, `isGuidedMode`, `onToggleGuidedMode`; added `Compass` icon; clinic users see BOTH "Guided Tour" (passive) and "Guided Setup" (interactive); lab sees only "Guided Tour"
- `src/components/WelcomeModal.tsx` — CTA text: clinic → "Start Guided Setup", lab → "Start Tour"

## Pending / Next session
- **GuidedCasePanel visual fix**: panel is `w-72 bottom-6 left-6` — wizard content is centered leaving dead space left of panel; should be wider + positioned further left to fill that gutter
- **Lab/Production guided mode**: lab role currently only has passive driver.js tour; needs interactive guided mode for lab workbench workflow (case queue → open case → accept/decline → colour instructions → stages → ship)
- **Production view** (staining clinic tab): same lab guidance should apply when clinic uses "Production View" tab
- All changes uncommitted (user preference: no git push at this stage)

## Key technical details
- Dev server: `http://localhost:8081/` (Vite)
- CDP testing: Windows Chrome headless `--remote-debugging-port=9222`, accessed via Windows Node.js `/mnt/c/Program Files/nodejs/node.exe` + `C:\Users\korm8\AppData\Roaming\npm\node_modules\playwright`
- Login: `michael@gavan.ai / 123456`, role = clinic, org_type = clinic
- `gavan_tour_completed` localStorage key controls WelcomeModal visibility (null = show modal)
- `clinical-card` is a Tailwind utility class defined in the app's CSS
- No git push at any point — user working locally only

## Why: motivation
The passive driver.js tour only showed popovers without helping users do real work. Goal: support-engineer-style handholding where system guides, user enters real data. Both modes kept per user request (passive for overview, interactive for real first case).
