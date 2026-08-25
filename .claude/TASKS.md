# v2.0.0 DEEP BUG HUNT (exhaustive)

Round 2: fix the remaining deferred bugs, then hunt EXHAUSTIVELY across every state-interaction
area the seam pass didn't drill into. Each hunt box: fan out finder agents → I adversarially
verify each finding against source → append CONFIRMED bugs to `BUGS-v2.0.0.md` (BUG-9+). Then fix
all confirmed HIGH/MED bugs, rebuild, QA, commit, update the artifact. Branch `v2.0.0-input-hardening`.
Artifact: https://claude.ai/code/artifact/5861a9f8-234d-4065-84cc-6ef49359aa9a

## 🔨 NOW — doing right now

✅ ALL PHASES COMPLETE. 3 deep-hunt waves (16 agents): **77 bugs found, 40 fixed & verified, 2 closed, 35 deferred (documented)**. 10 commits on `v2.0.0-input-hardening`, all built clean + QA-verified, no regressions. Artifact live. Loop done.

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
- [x] H2. Fixed all CLEAN HIGH bugs: BUG-9/14/15/16/17/25/26. Deferred as complex (need visual verification, documented in BUGS): BUG-10/11/12 (transform pipeline), BUG-19 (merge redo), BUG-22 (float-transform mask).
- [x] H3. Fixed clean MED/LOW: BUG-18/23/24/27/28/32. Deferred LOW/UNVERIFIED (documented): BUG-13/20/21/29/30/31/33.
- [x] H4. Added `apron-paint-after-move.sh` (BUG-14, GREEN). Verified BUG-14 fix + no paint regression; tool-eraser flakiness confirmed pre-existing harness noise.

## Phase J — SECOND-WAVE HUNT (exhaustive continued)

- [x] J1. MOUSE pipeline + INPUT dispatch hunt (UI_CHROME_CLICKED lifecycle, z-order precedence, drag/dblclick state machines, wheel/hover, deferred actions). Verify + log + fix.
- [x] J2. KEYBOARD + modifiers + chords + DIALOGS/widgets/text-input hunt (bitwise-NOT sites, STATIC guards, hotkey conflicts, modal loops, TI-input). Verify + log + fix.
- [x] J3. MULTI-INSTANCE + cross-instance clipboard + DRAG-DROP hunt (LAYERXFER, INSTANCE registry, DROP routing, IPC). Verify + log + fix.
- [x] J4. CONFIG + STARTUP + PATHS + CLI + THEME hunt (include-order, color-field types, round-trip, --option, migration). Verify + log + fix.
- [x] J5. GUI-chrome panels hunt (preview/organizer/drawer/menubar/statusbar/palette/layer-panel — auto-hide, drag-reorder, flyouts, _DEST restore). Verify + log + fix.
- [x] J6. (duplicate — see the checked J6 below; done: fixed + built + QA + committed 5693fbf0 + artifact updated.)

## Phase I — Verify & wrap

- [x] I1. Full clean compile — all fix batches built clean (exit 0), `DRAW 2.0.0` runs.
- [x] I2. New QA tests GREEN (10 seam + apron-paint-after-move); CLI `--option` smoke GREEN.
- [x] I3. Input-pipeline regression: 9/10 GREEN incl. gui-command-palette (BUG-40 area), tool-switch-matrix, tool-move, edit-undo-redo; the 1 flaky (seam-selection-to-draw) confirmed 8/8 on re-run → NO regressions from INPUT.BM/MOUSE.BM/BRUSH.BM changes.
- [x] J6. Second-wave findings consolidated + HIGH/MED fixed (BUG-34/35/40/44/48/50/51/53/55); built, QA-verified, committed (5693fbf0); artifact updated.
- [x] I4. (see K5 line — done: run summary + commit + artifact.)

## Phase K — THIRD WAVE (peripheral subsystems)

- [x] K1. FILE EXPORTERS hunt (BAS/QB64-source, PNG/BMP/GIF/JPG/TGA/HDR/ICO/QOI, ANSI export): flatten fidelity, blend/opacity, selection region, palette, handle leaks, format edge cases. Verify + log + fix.
- [x] K2. FILE IMPORTERS hunt (PSD, ASE/Aseprite, ANSI/XBIN, Lospec, generic image): layer/blend mapping, malformed input, handle leaks, coordinate/size. Verify + log + fix.
- [x] K3. EFFECTS ENGINE MATH hunt (the actual effect algorithms + -O3 kernels: blur/median/edge/emboss/sharpen/pixelate/mosaic/render/shape/texture): bounds, seed determinism, alpha handling, clip-to-selection, multi-layer. Verify + log + fix.
- [x] K4. FONTS/TDF + PIXEL-COACH + SOUND hunt (TDF binary rasteriser + .TDX, bitmap/CBF fonts, pixel-art analyzer, sound slots/music/SF2). Verify + log + fix.
- [x] K5. Third-wave findings consolidated (BUG-59..77); fixed BUG-62/65/66/67/68/70/72/74 (+52/57); built clean; smoke GREEN; committed; artifact updated to 77/40.
- [x] I4. Final BUGS-v2.0.0.md run summary written; all 10 commits on branch; artifact live. Deferred list documented with root causes. **Session complete.**

loop:on
