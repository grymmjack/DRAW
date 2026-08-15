# DRAW effects backlog (from grymmjack, 2026-08-15)

Ordered so shared machinery is built once, then reused across the effects it unlocks.
Each box is independently buildable + verifiable. Build with `~/git/qb64pe-450/qb64pe`
(v4.5.0, the Makefile default). Commit after each grouped box lands green.

## 🔨 NOW — doing right now
- [ ] ➡️ Shape/generative effects (Fire, and others) don't work with a selection — extend sel-as-shape/clip

## 🐞 Bugs / regressions
- [x] Cursor is a move/cross over EFFECTS flyout items — POINTER.BM now sets CURSOR_NULL over the category flyout region (genOpen%/genX/genY/genW/genH), matching the submenu-arrow logic. Built 17:31.
- [x] Inner Glow slow at high radius — now O(pixels) via shared IMGADJ_dist_transform (Chebyshev, two-pass). QA effect-innerglow green. Built 17:40.
- [x] Corona slow at high radius — now O(pixels) via shared IMGADJ_dist_transform (seedMode 1, Chebyshev). Ring is a touch squarer than the old Euclidean scan; QA effect-corona 6/6 green. Built 17:51.
- [x] Bevel slow at high radius — heightfield now O(pixels) via IMGADJ_dist_transform (seedMode 0, border-as-seed); shading phase untouched. QA effect-bevel 6/6 green. Built 17:57.

## 🧩 Shared widgets (build once → reuse)
- [ ] DROPDOWN control in the dialog framework (popup list, keyboard + wheel) — replaces cycle-buttons that have >4 options
- [ ] Angle DIAL widget wired into all degrees controls (helper IMGDLG_draw_dial/IMGDLG_dial_drag already written) — visual sphere/dial showing degrees, drag to set. (Wheel 15° / Shift+wheel 1° already done via IMGDLG_angle_wheel.)
- [ ] Click-on-canvas to set a CENTER point (when no selection) — reusable for Pinch/Bulge, Kaleidoscope, Lens Flare
- [ ] Cell-SHAPE picker (square / triangle / rectangle / hex / voronoi / random-per-cell) — reusable for Mosaic + Extrude
- [ ] Angle + random SEED pattern applied to ALL texture effects at once (Wood, Marble, Brick, Brushed Metal, Weave, Stone, Reptile, Diamond Plate, Ripples, Fur, Texture Noise, Glass, Water Drops, Lightning, Rust)

## ✨ Per-effect (use the shared pieces above)
- [ ] Blend Last Effect: expose ALL layer blend modes (incl. Color Dodge, etc.) as a DROPDOWN (not the cycle button)
- [ ] Posterize dither: cycle-button → dropdown
- [ ] Chromatic Aberration: add an ANGLE (with dial)
- [ ] Add Noise: add ANGLE + SEED (current result reads as a flat patch)
- [ ] Pinch / Bulge: much more extreme range + click-to-set center
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
