---
name: effect-dialog-shared-widgets
description: Reusable widgets/engines added to the effect-dialog framework (dropdown, angle dial, click-to-center, cell-ID mosaic, blend helpers, distance transform) and the menu-click-bleed fix
metadata:
  type: project
---

[Linux] Added 2026-08-15 (branch more-image-effects, big effects overhaul). Prefer
these over rolling your own when building/extending an effect dialog or engine.

**DIALOG dropdown** (`GUI/DIALOG.{BI,BM}`) — immediate-mode popup select for any
control with >4 options. FOUR call sites per dropdown: `DIALOG_dropdown_input ctx`
(right after `DIALOG_poll_mouse` — the input gate that OWNS the frame's
click/wheel/keys while open so nothing underneath reacts), `v% =
DIALOG_dropdown%(ctx, id, x, y, w, v%, labels$(), n)` (input phase),
`DIALOG_dropdown_draw ...` (draw phase, closed box), `DIALOG_dropdown_overlay ctx`
(LAST, before `DIALOG_blit` — the open list on top). Keyboard Up/Down/Enter/Esc;
scrolls past `DIALOG_DD_MAXVIS`=8. Labels 0-based; `id` unique-per-dialog small int.
First consumers: Posterize dither, Mosaic shape, Stone type, Lens Flare lens, Blend
Last Effect modes.

**Angle dial** (`IMGDLG_angle_handle%` input + `IMGDLG_angle_draw` draw, same rowN)
— a shortened 0..359 slider + compact drag-dial + live "LABEL: NNN°" readout in one
row. Use for every compass-direction control (NOT rotation-magnitude sliders like
Twirl's 10..360). Wheel 15° / Shift-wheel 1° via `IMGDLG_angle_wheel%`.

**Click-to-set-CENTER** (`IMGADJ_center_pick_pane%` + `IMGADJ_center_draw_marker` +
`IMGADJ_center_preview_x/y&` / `IMGADJ_center_apply_x/y&`) — clicking the LOUPE
PREVIEW PANE places a canvas-space centre point (the modal covers the real canvas,
so the pane IS the clickable canvas). Reset `IMGADJ_CENTER_SET%=FALSE` at dialog
open; engines take a centre param where `<0` = default. Wired: Pinch, Kaleidoscope,
Lens Flare.

**Mosaic cell shapes** — `MOSAIC_SHAPE_*` consts + a per-pixel cell-ID engine:
direct formulas for square/rect/triangle, nearest-seed lattice for
hex/voronoi/random (`IMGADJ_cell_jitter!(cx,cy,seed,salt)`), shape-agnostic grout
(neighbour cell-ID differs). Reusable for any tessellation.

**All 19 blend modes** — `BLEND_ch%(mode,d,s)` (per-channel 0..16) and
`BLEND_mix_channels(mode, dR..sB, bR..bB)` (delegates + Rec.601 for
COLOR/LUMINOSITY) in `GUI/LAYERS.BM`. Mirrors the layer compositor's INLINED math
(kept separate so the perf-critical compositor stays inlined — one-shot callers use
the SUB).

**O(pixels) shape distance** — `IMGADJ_dist_transform(srcImg, seedMode, distA())`:
two-pass Chebyshev DT. seedMode 0 = transparent+border seeds (Inner Glow, Bevel
heightfield), 1 = opaque seeds (Corona). Replaces O(r²)-per-pixel edge scans that
froze at large radius. See [[effects-selection-as-shape]].

**Menu-click bleed fix** — `DIALOG_CTX.inputArmed`: `DIALOG_poll_mouse` treats mb1
as up until it's seen released once, so a menu click that OPENED a dialog can't
drag/toggle a control the dialog drew under the cursor. Fixed Rust's SCALE jumping
to 168 when its dialog grew so the slider landed under the menu-child click point.
Any dialog that grows tall enough to sit under `open_effect`'s click benefits.

⚠️ **QA batch flake**: running ~60+ effect tests back-to-back offscreen (Xvfb) can
make DRAW die mid-run on one test (seen on `effect-crystallize`: "app process has
died" cascading its follow-on asserts), while that test passes cleanly in
isolation. Re-run the single failing test alone before assuming a regression.
