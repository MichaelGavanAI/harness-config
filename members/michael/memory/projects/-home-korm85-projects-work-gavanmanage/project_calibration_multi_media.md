---
name: project_calibration_multi_media
description: "Multi-media calibration upload feature (video + up to 5 images) — status, branch, open decisions"
metadata: 
  node_type: memory
  type: project
  originSessionId: 55a5e091-322b-43e2-830d-83cf06c2279d
---

**Superseded branch:** `feat/calibration-multi-media` (22 commits, based on `abd390a`) was discovered 2026-07-15 to be unintentionally built on top of the entire unmerged, unreviewed `feat/lab-navigation-redesign` branch (no PR ever existed for it) — rebasing it onto staging replayed ~100 commits, bundling two unrelated features into one PR and causing real e2e failures (sidebar nav replaced the old "Stage 1" button UI the e2e suite still expected). Per Michael: the sidebar nav + 2-column Shade Analysis are the real future direction but are NOT complete yet; calibration-media is decoupled and can ship independently.

**Replacement branch:** `feat/calibration-multi-media-v2`, built by cherry-picking exactly the 24 calibration-media commits (`e16cd94^..1c0605c` from the old branch — starts one commit earlier than first assumed, see below) cleanly onto `origin/staging`. PR #152 → staging, pushed 2026-07-15. Zero schema changes. Storage moves from single `calibration_video_url` file to a folder convention (`calibration/video.{ext}` + `calibration/image_1..5.{ext}`) with filename-encoded kind/order, discovered via `storage.list`, legacy single-file cases fall back through `mediaSetFromLegacy`. New Case wizard shows dedicated Video and Images upload boxes (Stump Shade Video box removed; legacy stump files stay read-only elsewhere).

**Why:** Michael's goal — doctors/lab techs upload whatever media they have (video, up to 5 images, or both) with no mode decision up front. Media is dual-purpose downstream (Roy's calibration-bar detection AND mirrored-tooth/9-point color sampling for material recommendation), so all files must reach the MA export folder, not just the primary. See [[project_lab_nav_redesign]] for the nav-redesign branch calibration-media was mistakenly built on top of (still unmerged, no PR, not ready), and Roy coordination history.

**How to apply:** Before doing more work on this feature, use `feat/calibration-multi-media-v2` (not the old `feat/calibration-multi-media`, which is now superseded/stale — do not rebuild from it). Check `git log --oneline origin/staging..HEAD` on the v2 branch. `.superpowers/sdd/progress.md` still has full task-by-task history from the original implementation (logic unchanged, only the branch base and a couple of bugfixes found during the rebuild differ — see below).

## Commit-boundary gotcha for future rebuilds
The calibration-media work's true first commit is `e16cd94` ("calibration slot accepts a single image or a video") plus its review-fix `0116e31`, NOT the `docs(calibration): spec + plan` commit that was first assumed — those two commits create `src/lib/calibrationMedia.ts`, a real dependency the rest of the feature imports from, not nav-redesign UI work. `0116e31` also carries two small unrelated bundled fixes (`DueDateAlertsCard.tsx`, `CaseQueueCard.test.tsx`) that had already been superseded/deleted on staging by the time of the rebuild — those two files were dropped during cherry-pick, everything else kept.

## Bugs found and fixed during the v2 rebuild (not present in original session's review)
1. `clearCaseFileAsset`'s owner-lookup fallback queried a nonexistent `owner_user_id` column (should be `clinic_user_id`) — silently skipped folder cleanup for orphaned calibration images when no existing legacy URL was available to derive the owner from. Caught by `tsc`, not by review. Fixed.
2. `uploadCalibrationMediaSet` removed the existing same-slot object *before* attempting the new upload — if remove succeeded but upload then failed, the old file was already gone and never restored: a failed replace silently destroyed a working file. Fixed by flipping the order (upload with `upsert` first, remove stale differently-extensioned object only after success); 2 unit tests updated to match. Found by independent Sonnet review during the rebuild's code-review gate.

## Open decision, not yet Michael's call made
Lab-side calibration attach (`AcceptCaseOrderReview.tsx`) writes new files under the lab reviewer's own storage folder (`user.id`), but every read path lists from the clinic's folder (`clinic_user_id`) — forced by storage RLS (INSERT/UPDATE requires the first path segment to equal `auth.uid()`, a lab account cannot write into a clinic user's folder). Degrades gracefully for a single attached file via the legacy-URL fallback; breaks (file becomes invisible on every surface) when a lab attaches a 2nd+ image, or attaches alongside existing clinic-side media. Real fix needs either an RLS policy change or an owner-convention redesign for lab-side attach — both out of UI/UX scope. Pre-existing pattern (scan/stump attach had the same shape before this feature), not introduced by this branch, just newly exposed by folder-based reads.

## Deferred, lower severity, not fixed this session
Phone-calibration-draft video, when promoted on an update-mode submit where the case already has folder-based images, lands at the OLD legacy flat path (`calibration_video.<ext>`) instead of the new `calibration/` folder — `uploadCalibrationMediaSet`'s legacy-migration trigger only fires when the existing set has exactly 1 legacy item. Once the folder has real images, folder-wins semantics make the phone-draft video invisible everywhere. Needs a careful edit to the storage lib's migration condition (`src/lib/caseFileUpload.ts` ~line 465) — not rushed.

## Roy status (external, non-blocking)
Slack message + dataflow artifact sent 2026-07-14. Awaiting his Option A/B pick for the MA export payload (default shipped: Option B, folder-scan by filename, zero payload change), confirmation of video-wins-primary, confirmation of `_calibration_image_1..5.<ext>` naming. Nothing here blocks this branch.

## agy advisory flag on push (informational, not from this branch's diff)
Push-time agy review on `v2` re-flagged the plan doc's already-known deferred items (EXIF/GPS scrubbing not implemented, storage RLS org-scope broader than DB RLS) — these are documented, out-of-scope-for-this-branch items already in this memory file, not new findings.

## CF preview
`feat/calibration-multi-media-v2` → PR #152 → branch preview `https://feat-calibration-multi-media-t5jc.gavanmanage.pages.dev`.
