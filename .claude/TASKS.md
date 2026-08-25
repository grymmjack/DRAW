# v2.0.0 DEEP BUG HUNT (exhaustive)

Round 2: fix the remaining deferred bugs, then hunt EXHAUSTIVELY across every state-interaction
area the seam pass didn't drill into. Each hunt box: fan out finder agents → I adversarially
verify each finding against source → append CONFIRMED bugs to `BUGS-v2.0.0.md` (BUG-9+). Then fix
all confirmed HIGH/MED bugs, rebuild, QA, commit, update the artifact. Branch `v2.0.0-input-hardening`.
Artifact: https://claude.ai/code/artifact/5861a9f8-234d-4065-84cc-6ef49359aa9a

## 🔨 NOW — doing right now

➡️ Fixed 15 bugs (BUG-9/14/15/16/17/18/23/25/26/27/28/32 + BUG-4/6/7). Rebuilding apron/recolor/grayscale batch → then run apron QA test. Remaining: BUG-10/11/12 (transform mask/apron/clip), BUG-13/24/29 (contained), BUG-19/22 (complex — likely defer with docs).

## Phase F — Fix the deferred bugs

- [x] F1. BUG-4 fixed — added `CUSTOM_BRUSH_reset` to Open (DRW.BM after IMAGE_IMPORT_reset) + `ZOOM_drag_reset` to New/New-from-clip. Three reset lists now aligned. (compile-verify in I1)
- [x] F2. BUG-6 fixed — `TOOLS_reset_all` now calls `POLY_LINE_cancel_restore` (guarded, rolls partial polygon back on switch), matching `BEZIER_cancel_restore`. (compile-verify in I1)

## Phase G — Deep hunt (fan out finders → adversarially verify → log confirmed bugs)

- [x] G1. HISTORY / undo-redo (the #1 bug source): multi-layer undo, group undo, transform undo, text undo, selection-mask snapshot/restore, the double-save guard (`HISTORY_saved_this_frame%`), redo-after-branch, undo across doc-creation. Verify + log.
- [x] G2. APRON + coordinates (gotcha #14): promoted-layer coord offset, move/transform/paint past the canvas edge, crop with apron, apron cull-on-save, demote-on-first-press, wheel-zoom into apron. Verify + log.
- [x] G3. LAYER groups/symbols + multi-select ops: group move (GROUP_ORIGIN), merge group/selected/visible, delete group, symbol child sync (symbolParentId), align/distribute (to-selection vs canvas), arrange reorder, solo/visibility. Verify + log.
- [x] G4. TRANSFORM overlay modes: scale/rotate/shear/distort/perspective commit vs cancel, identity commit, apron interaction, multi-layer transform, SRC_IMG handle lifecycle, PREV_TOOL restore, re-activate while active. Verify + log.
- [x] G5. SELECTION mask ops: flip/rotate/scale a selection (auto-float), fill selection FG/BG, crop-to-selection, stroke selection, clear selection, wand-mask vs rect-mask, deselect, mask + move/paste/clone interactions, mask persistence across ops. Verify + log.
- [x] G6. RENDERING / cache + EFFECTS + SAVE-LOAD: scene/composite cache invalidation (missed INVALIDATE_scene, per-frame animation defeating cache), contentDirty discipline, effects clip-to-selection / selection-as-shape / multi-layer / undo, `.draw` round-trip fidelity (layer types, groups, text layers, apron, blend modes), opacity-lock + selection-clip interactions. Verify + log.
- [x] G7. TOOL internals: text state machine (edit/commit/rasterize/re-edit/empty-layer/font-switch), bezier state + undo snapshot, smart shapes commit/AA, custom brush lifecycle (stash/recolor/scale/flip), fill variants (flood/merged/global), color mode/palette ops, grid snap/offset/cell-fill, spray, reference image, drag-drop routing. Verify + log.

## Phase H — Fix confirmed bugs found by the hunt

- [x] H1. Triaged — 25 bugs (BUG-9..33) logged with severity + root cause in BUGS-v2.0.0.md. Systemic sparse-array class (BUG-25/26) audited across all sites.
- [ ] H2. Fix all confirmed HIGH-severity bugs. Compile clean after each.
- [ ] H3. Fix all confirmed MED-severity bugs (or log LOW/needs-decision, not blocking). Compile clean.
- [ ] H4. Add QA tests for the new fixes where deterministically testable.

## Phase I — Verify & wrap

- [ ] I1. Full clean compile (`make`) — 0 new warnings.
- [ ] I2. Run new + affected QA tests offscreen (force `--rerun-passed` single-file); iterate to green (document proven-flaky).
- [ ] I3. Regression: input/tool/history/layer QA subset — confirm no new failures vs baseline.
- [ ] I4. Final BUGS-v2.0.0.md consolidation; commit all on branch; UPDATE the bug artifact with the full list; write a round-2 run summary.

loop:on
