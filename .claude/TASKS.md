# DRAW effects backlog (from grymmjack, 2026-08-15)

Ordered so shared machinery is built once, then reused across the effects it unlocks.
Each box is independently buildable + verifiable. Build with `~/git/qb64pe-450/qb64pe`
(v4.5.0, the Makefile default). Commit after each grouped box lands green.

## 🔨 NOW — doing right now
- [ ] ➡️ Shared widget: Cell-SHAPE picker (square/triangle/rect/hex/voronoi/random) for Mosaic + Extrude

## 🐞 Bugs / regressions
- [x] Cursor is a move/cross over EFFECTS flyout items — POINTER.BM now sets CURSOR_NULL over the category flyout region (genOpen%/genX/genY/genW/genH), matching the submenu-arrow logic. Built 17:31.
- [x] Inner Glow slow at high radius — now O(pixels) via shared IMGADJ_dist_transform (Chebyshev, two-pass). QA effect-innerglow green. Built 17:40.
- [x] Corona slow at high radius — now O(pixels) via shared IMGADJ_dist_transform (seedMode 1, Chebyshev). Ring is a touch squarer than the old Euclidean scan; QA effect-corona 6/6 green. Built 17:51.
- [x] Bevel slow at high radius — heightfield now O(pixels) via IMGADJ_dist_transform (seedMode 0, border-as-seed); shading phase untouched. QA effect-bevel 6/6 green. Built 17:57.
- [x] Shape/generative effects don't work with selection — 7 radiating Shape effects (Fire, Smoke, Snow, Drip, Icicles, Electrify, Motion Trail) now route through the sel-as-shape choke point (IMGADJ_edge_shape_source + apply_spatial_edge) for BOTH apply and preview, exactly like the alpha-edge effects. Interior effects (Water Drops, Glass, Rust) already clip correctly via apply_to_layer. New QA effect-fire-selection 6/6 + all 7 no-selection tests 42/42 green. Built 18:08.

## 🧩 Shared widgets (build once → reuse)
- [x] DROPDOWN control in the dialog framework — DIALOG_dropdown% + _input/_draw/_overlay in GUI/DIALOG.{BI,BM}. Immediate-mode, single-open, on-top popup with an input-gate that owns the frame's click/wheel/keys (Up/Down/Enter/Esc) so nothing underneath reacts; scrolls past DIALOG_DD_MAXVIS (8). Proven by converting Posterize dither (23 options). QA posterize-dither-color 6/6 green. Built 18:31.
- [x] Angle DIAL widget wired into degrees controls — new combined IMGDLG_angle_handle%/IMGDLG_angle_draw (shortened 0..359 slider + compact drag-dial + live degree readout in the label). Wired into all 7 compass-angle controls (Motion Trail, Kaleidoscope rotation, Bevel light, Chrome cast, Backlight/Long-shadow angles, bevel-motion). Twirl's ANGLE (10..360 swirl magnitude) deliberately left as a plain slider. QA motiontrail/bevel/chrome/kaleidoscope 24/24 green. Built 18:44.
- [x] Click-on-canvas to set a CENTER point — IMGADJ_center_pick_pane% + marker + preview/apply coord mappers (canvas-space store, apron-aware). Click the loupe pane to place the centre. Wired into Pinch/Bulge (engine takes a centre param, -1 = image centre; radius = nearest-edge so centred look is unchanged). Kaleidoscope + Lens Flare adopt it in their own boxes. QA effect-pinch-center 6/6 + effect-pinch (default) 6/6. Built 19:00.
- [ ] Cell-SHAPE picker (square / triangle / rectangle / hex / voronoi / random-per-cell) — reusable for Mosaic + Extrude
- [ ] Angle + random SEED pattern applied to ALL texture effects at once (Wood, Marble, Brick, Brushed Metal, Weave, Stone, Reptile, Diamond Plate, Ripples, Fur, Texture Noise, Glass, Water Drops, Lightning, Rust)

## ✨ Per-effect (use the shared pieces above)
- [ ] Blend Last Effect: expose ALL layer blend modes (incl. Color Dodge, etc.) as a DROPDOWN (not the cycle button)
- [x] Posterize dither: cycle-button → dropdown (23 options, keyboard-navigable). First consumer of the shared DIALOG_dropdown widget. QA posterize-dither-color updated + 6/6 green. Built 18:31.
- [ ] Chromatic Aberration: add an ANGLE (with dial)
- [ ] Add Noise: add ANGLE + SEED (current result reads as a flat patch)
- [ ] Pinch / Bulge: much more extreme range (click-to-set center DONE via the shared widget; remaining: widen the amount range)
- [ ] Kaleidoscope: click-to-set center
- [ ] Mosaic / Tessellate: cell-shape options (triangle, rectangle, hex, voronoi, random-per-cell)
- [ ] Extrude: option to fill the 3D faces with the extruded pixels; extrude ANGLE; JITTER 0–100 (random placement); extrusion shapes (from the cell-shape picker)
- [ ] Chrome / Metallic: rework to actually look metallic — gradient picker + amount + reflectivity / light reflections
- [ ] Sharpen: add an Unsharp Mask option (dropdown/toggle) like Photoshop
- [ ] Diamond Plate: space-between, space-inside, sharpness, roundness, bumpiness + a LIGHT-direction angle in addition to the pattern angle
- [ ] Stone Wall: stone TYPES — rock, rounded boulders, cracked, stacked, toothed, etc. (dropdown)
- [ ] Lightning: forks, fork randomness, fork diminish (thicker→thinner), spikiness, etc.
- [ ] Glass (Shape): number-of-repeats, zoom/thickness of glints, angle
- [ ] Render Grid: endless 1980s-style perspective (lines continue off every side, don't collapse into a rect) + an angle option
- [ ] Clouds + Difference Clouds: realistic fBm clouds — they don't look like clouds
- [ ] Render Sky: deeper day / night / space rendering (gradient≠sky; night is dotted; space is dots+circles)
- [ ] Terrain: land/sea/height color chips (pick from palette), seed, rotation, variation
- [ ] Lens Flare: click-to-position + a real flare render (halo/streaks/rings) + lens-type presets

## ✅ Done earlier this session (for reference — not tasks)
sel-as-shape for edge effects + preview parity; loupe follows dialog + padded capture;
Redo/Recall/Blend Last Effect; Blur type selector + O(1) separable blur; progress overlay
(56 engines); raised slider maxes; Wind DIRECTION; Add Noise PIXEL SIZE+MIX; Mosaic GROUT;
Long Shadow distance falloff; Lens Flare/Diff Clouds render on blank layer; Outline INSIDE
all-borders; Blend flicker fix; angle wheel-step (15°/Shift 1°).
