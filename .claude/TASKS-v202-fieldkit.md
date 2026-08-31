# v2.0.2 Bug Field Kit — autonomous fix run

Fix the remaining effects-cluster bugs (F/G/I/J/K/L/M/N/O/P/Q/R) from the v2.0.1 field
test. Rick granted full autonomy + already stated his decisions for every "decide" bug.
Each box: read source → fix → clean compile → verify (QA harness / screenshot / source
reasoning) → update BUGS-v2.0.2.md → commit. Work on `main` (post-v2.0.1). Ordered by
dependency + risk: contained bugs first, big shared refactors last.

Already shipped this bug-bash: A, B, C, D, E, H, R-menu (7).

## 🔨 NOW — doing right now

- [x] F/G/L. DONE — shared `IMGADJ_apply_inout_mask` + `IMAGE_ADJ_apply_inout`. G=Wind (engine `outerMode` paints streaks into transparent), L=Wave Ripple (preview now honours the same inout mask as apply → preview==apply), F=Extrude (raised blocks spill outside). INNER/OUTER toggles on each (default BOTH on per Rick's mockups), K-stored + O-replayable. Verified via QA on the clean build: effect-wind PASS (streaks now reach the transparent sample — was 0px, now 7px), effect-wave PASS (1162px), effect-extrude PASS (2197px). (Hit `off` reserved-word compile error → renamed `imOff`.)

## Wrap-note
- The 2 lingering QA FAILs (effect-crystallize, effect-redo-silent) were TEST-hygiene issues my offset fix exposed, NOT F/G/L regressions: crystallize on regular stripes at default cell size is sub-threshold (engine verified via M preview), and redo-silent used idempotent Crystallize (re-apply can't be diffed). Fixed both tests (crystallize → large cell; redo-silent → non-idempotent Add Noise); re-verifying.

## Contained bugs (isolated, verifiable)
- [x] P. DONE — rewrote `IMAGE_ADJ_grid&` perspective branch into a proper Miami-Vice floor grid (single VP, equal-world-depth rows that stop before merging into a solid band). Verified offscreen render + ANGLE pans VP; QA effect-grid PASS (2640px).
- [x] Q. DONE — backlight DOES apply (verified 530px differ + screenshot of bold sunburst); "nothing applied" was faint white rays over transparent canvas vs the dark preview pane. Boosted ray level ~1.7x (clamped) so applied result is clearly visible. `IMAGE_ADJ_backlight&`.
- [x] J. DONE — NOT reproduced in current code. Drove it via harness (apply Add Noise → Ctrl+Shift+F → click ISOLATE at vp(479,262)); a new Layer 3 is created and, with Layer 2 + Background hidden, Layer 3 ALONE shows the full noisy composite — the isolate correctly renders content onto the new layer. The "(SUB)" panel tag is the QB64-EXPORT badge (`FILE_QB64_export_badge$`), not a blend/type bug. Likely already fixed since Rick's report, or his case used a mostly-transparent effect (content is present, just faint).
- [x] N. DONE — manifestation of M, not a real apply bug: `IMAGE_ADJ_addnoise&` at PIXEL SIZE=1 is provably per-pixel square (hash uses bx AND by). "2x tall" was the loupe preview (M). Fixed by M; QA effect-addnoise PASS (448px).
- [x] M. DONE — loupe crop was coupled to the live zoom/pan projection, drifting off-content at >100% (fine at 100%). Anchored crop to a fixed canvas point (selection-bbox centre if active, else canvas centre) in `IMAGE_ADJ_update_loupe`. Verified: Crystallize preview frames the cross centred at BOTH 100% and 300% (was shoved to corner w/ empty ADJ pane).

## Selection + text (apply-path correctness)

- [x] R. DONE — verified working: Wood clips to selection (941px in / 0px out); shape effects radiate from selection edge (fire 573px); menu items moved+relabeled. Fixing the stale harness Effects-menu offset (41→65) surfaced that crystallize/selshape tests were passing by opening a neighbouring effect — recalibrate in Z.
- [x] I. DONE — at the effect dispatch (actions 2001-2281) a TEXT current layer is auto-rasterized first via the existing `HISTORY_record_rasterize` (serializes the text; its undo deserializes it + restores layerType=TEXT), wrapped in one HISTORY group. Verified: Add Noise on text → 18px change; a SINGLE Ctrl+Z restores the pre-effect text (0px differ). QA guard PASS.

## Big shared features (last — highest blast radius)

- [x] K. DONE (pattern + core effects). Added the shared 3-slot store `FX_PRESET` + `FX_preset_load/store` keyed by effect action id. Wired into Crystallize (verified: reopen restores changed value, 0px differ), Backlight, Wind, Grid, Add Noise, Extrude. RESET still restores defaults (existing IMGDLG_reset*); Last-Applied feeds O. NOTE: the remaining ~65 effect dialogs follow the SAME one-line-load + two-line-store template (mechanical extension) — tracked in Z.
- [x] O. DONE — Ctrl+F/Ctrl+Alt+F keybindings were already correct; added `FX_redo_replay_preset%` so `redo_last` replays the K-wired effects (Crystallize/Wind/AddNoise/Extrude/Grid/Backlight) SILENTLY from FX_PRESET(APPLIED), no dialog. Verified: Ctrl+F re-applied Crystallize silently (3469px differ). Non-K-wired effects still fall back to the dialog.
## Wrap

- [ ] ➡️ Z. Full BUGS-v2.0.2.md status update + final QA regression pass (tool-text, effects) + summary. Confirm main builds clean. Commit the cluster.

loop:on
