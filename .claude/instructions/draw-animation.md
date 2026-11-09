# DRAW — Animation (phase 1: frames on the sheet)

Plan, decisions and the phases still to come: `PLANS/ANIMATION.md` (round 1 Q-01..Q-31,
round 2 R-01..R-12). Checklist: `.claude/TASKS-ANIMATION.md`. Branch: `animation`.

---

## The model: the canvas is the sprite sheet

- A **frame** is a `frameW x frameH` cell of the canvas. Frame N is the Nth cell in reading
  order (left to right, then down). `margin` px from the canvas edges, `gutter` px between
  cells (both default 0, R-02). Columns fit the canvas width (`ANIM_fit%`).
- **Layers span the sheet.** Each layer's cell is its drawing for that frame. Every tool,
  zoom, selection and effect works unchanged, so there is no frame store and no layer-buffer
  swapping. The ~300 `LAYERS(CURRENT_LAYER%)` call sites are untouched.
- `ANIM.count` frames (<= cells; the rest are **spare** cells, drawn dotted).
  `ANIM.wanted` is the count asked for (load, frame ops). A layout with fewer cells shows
  fewer frames, and they come back when a later layout fits them, so stepping the frame
  size through a smaller layout loses nothing.
- `ANIM.current` (1-based) is outlined on the frame grid. Holds are `ANIM_HOLDS(n)`, ticks at
  `ANIM.fps` (0 = 1). `ANIM.loopMode` is `ANIM_LOOP_FWD/REV/PING/ONCE`.
- A plain picture has `ANIM.active = FALSE`. Everything is additive: nothing changes for a
  document without frames.

**Starting one:** a plain picture has no frames, so the ANIM menu greys out the frame commands until `Num +` / ANIM > Add Frame. Lightbox / Panes / X-Sheet / Onion Skin are views of the frames: greyed **and shown unchecked** on a plain picture (`MENUBAR_update_checkboxes`; their DRAW.cfg settings are kept and apply once there are frames - field kit T-3, the X-Sheet could not be unchecked there). A refused frame command says `ANIM_NO_FRAMES$` (how to start). QA dump `ANIMMENU id:checked:enabled`, `anim-menu-plain.sh`. `ASSETS/TEMPLATES/ANIMATION/*.png` (16 / 32 / 64 / 128 square x 8 frames, 320x200 x 4, 15 fps) are blank sheets with a `drAn` chunk, made by DRAW itself (`DRAW.run sheet.png --export out.draw` from a transparent PNG carrying a v1 drAn), so File > New from Template opens them with frames.

## Files

| File | Role |
|---|---|
| `TOOLS/ANIM.BI/BM` | State + pure math: layout (`ANIM_set_layout%`, `ANIM_cols/rows/cells%`, `ANIM_cell_rect%`, `ANIM_rect_at`, `ANIM_span&`, `ANIM_frame_at%`), holds, stepping, `ANIM_serialize$ / ANIM_deserialize%`, frame-op planner (`ANIM_plan%`, `ANIM_op_refusal$`, `ANIM_sheet_h&`, `ANIM_apply_plan`), playback (`ANIM_play_start% / _next% / _advance% / _stop`). Touches only `ANIM*` and `SCRN.canvasW/H`, so **`QA/unit/anim-unit.bas` tests it headless** (110 checks) |
| `TOOLS/ANIM-VIEW.BI/BM` | Frame grid overlay (`ANIM_VIEW_render_grid`, View > Frame Grid 2500), frame keys (numpad + Alt), `ANIM_VIEW_goto`, play toggle + tick, the Preview window's frame view, the `ANIM` QA dump line |
| `TOOLS/ANIM-OPS.BI/BM` | Frame operations, layout changes (re-slice / resize), timing changes, whole-sheet snapshots, the undo record, `ANIMC` dump line |
| `GUI/ANIM-PANEL.BI/BM` | The Animation panel (2505): FPANEL window like `GUI/PEN-PANEL` (dock slot `DP_ANIM`, `REGION_ANIM_PANEL`, `WZ_*`, auto-hide, F11, workspace element `ANIM_PANEL`, `ANIM_PANEL_VISIBLE/X/Y`) |
| `TOOLS/ANIM-CANVAS.BI/BM` | In the lightbox the current frame is the canvas: `ANIM_CV_rect%` (the cell, else the whole canvas), `ANIM_CV_bounds%` (opaque bounds of a layer inside a rect, apron-aware), `ANIM_CV_shift` (shift one cell, cut off at its edge), `ANIM_CV_align` (1901-1908), `ANIM_CV_scale` (317 318 331 333), pane Move guides (`ANIM_CV_move_begin` / `_move_guides`), `ANIM_CV_TF_F` (the transform's frame), the `ANIMCV` dump line |
| `TOOLS/ANIM-LB.BI/BM` | The lightbox view (2.1): layout (`ANIM_LB_layout`, bands strip / transport bar / editor, `ANIM_LB_area` + `ANIM_LB_clear_floats`), `ANIM_LB_render` (cut from the composite), transport bar controls `LB_CTL_*`, `ANIM_LB_mouse`, the `ANIMLB` / `ANIMLBC` / `ANIMLBP` dump lines; drawing in the panes (2.2): the pane view (`ANIM_LB_view_push / _pick / _pop`, `ANIM_LB_pane_view%`), overlays (`ANIM_LB_overlay_begin% / _end`), strokes clipped to a frame (`ANIM_LB_clip_*`) |
| `TOOLS/ANIM-IMPORT.BI/BM` | Bringing frames in (phase 5): `ANIM_GIF_import%` (5.1, from `DRW_load` after `GIF_load_cycling%`), `ANIM_ASE_apply` (5.2, from `FILE_ASE_load`), shared `ANIM_IMP_grid%` / `ANIM_IMP_fps%` |
| `INPUT/NUMPAD.BI/BM` | Numpad keys from bu1ld0r: `NUMPAD_poll` (`_KEYDOWN` edges), `NUMPAD_dev` ([Linux] device ids = X11 key code + 1, catches taps quicker than a frame), `NUMPAD_of%` (which numpad key a plain code could be), `NUMPAD_sent%` |

## Action ids (2500-2599)

| Id | Action |
|---|---|
| 2500 | Frame Grid (View + ANIM menu, `CFG.FRAME_GRID`) |
| 2501-2504 | First / previous / next / last frame (`ANIM_VIEW_goto`; previous / next wrap) |
| 2505 | Animation panel (View + ANIM menu) |
| 2506 | Play / stop (`ANIM_VIEW_play_toggle`) |
| 2507 | Preview Shows Frame (`CFG.PREVIEW_SHOWS_FRAME`) |
| 2519 | Lightbox on / off (`CFG.LIGHTBOX`, Num 0) |
| 2520 | Lightbox panes 3 → 5 → 7 (`CFG.LIGHTBOX_PANES`, Num *) |
| 2521 | Clip strokes to the frame in the lightbox (`CFG.CLIP_FRAME_LIGHTBOX`, on by default) |
| 2522 | Clip strokes to the frame in sheet view (`CFG.CLIP_FRAME_SHEET`, off by default) |
| 2523-2526 | Copy / Cut / Paste Frames as New / Paste Frames Over (`ANIM_OPS_clip_action`, 2.5) |
| 2527 | Onion skin on / off (`CFG.ONION_SKIN`, Num /; lightbox only) |
| 2528 | Onion skin red / blue tint (`CFG.ONION_TINT`) |
| 2529 | Replace FG color with BG in the selected frames (`ANIM_OPS_swap_fg_bg`; sheet view too) |
| 2530 | Reference Layer - the current layer (`ANIM_LF_toggle ANIM_LF_REF`) |
| 2531 | Layer Same on Every Frame - the current layer (`ANIM_LF_toggle ANIM_LF_SAME`) |
| 2532 | Export Animated GIF... (`ANIM_EXPORT_action`, `TOOLS/ANIM-EXPORT`) |
| 2533 | Export Scale 1x / 2x / 4x (cycles `CFG.ANIM_EXPORT_SCALE`; the menu label shows the scale - `MENUBAR` per-item block, F4) |
| 2534 | Export PNG Sequence... (`ANIM_PNGSEQ_export%`) |
| 2535 | Export Sprite Sheet + Frame Data... (`ANIM_SHEET_export%`: .png + .json + .bi) |
| 2536 | Export Animated PNG (APNG)... (`ANIM_APNG_export%`) |
| 2537 | Export BAS Player (DATA)... (`ANIM_BAS_export%`) |
| 2538 | Export BAS Player + Sheet PNG... (`ANIM_BAS_sheet_export%`) |
| 2539 | Full-Screen Preview (`ANIM_FS_show`, `TOOLS/ANIM-FS`, Num .) |
| 2541 / 2542 | Link Cells / Unlink Cells (`ANIM_LK_action`, `TOOLS/ANIM-OPS`, the current layer, the selected frames) |
| 2543 / 2544 | Tag Frames... / Delete Tag (`ANIM_TG_action`, `TOOLS/ANIM-OPS`, 4.4) |
| 2545 / 2546 | Frame Note... / Clear Frame Note (`ANIM_NT_action`, `TOOLS/ANIM-OPS`, 4.5) |
| 2547 | Detect Frames (`ANIM_DT_action`, `TOOLS/ANIM-IMPORT`, 5.3: the sheet's grid from its gaps) |
| 2548 | Import PNG Sequence... (`ANIM_SEQ_action`, `TOOLS/ANIM-IMPORT`, 5.4; CLI `--sequence FILE`) |
| 2549 / 2550 | Soundtrack... / Remove Soundtrack (`ANIM_SND_action`, `TOOLS/ANIM-SOUND`, L.1) |
| 2552-2559 | the SOUND rows (F6): Add Sound Here... / on a New Track... / Copy / Cut / Paste / Delete / Split / Remove Clip (`ANIM_SND_action`) |
| 2560 / 2561 | Add Empty Track / Remove Track (the SOUND rows; `ANIM_SC_XTRA`, `ANIM_SC_drop_trk%`) |
| 2551 | Create Frames from Grid (`ANIM_GRID_frames_action`, `TOOLS/ANIM-IMPORT`, F8: frame = `GRID.gridWidth` x `gridHeight`, no gutter / margin, frames up to the last drawn cell; one undo step; `anim-frames-from-grid.sh`) |
| 2540 | X-Sheet in the lightbox's top band (`ANIM_XS_toggle`, `TOOLS/ANIM-XS`, `CFG.XSHEET`, Num 8, chip `LB_CTL_XS`) |
| 2510-2518 | Frame ops: op = id - `ANIM_ACT_OP0` (2509) = `ANIM_OP_APPEND` .. `ANIM_OP_REVERSE` (`ANIM_OPS_action`; Shift on Add = blank) |

Grep before adding one (CLAUDE.md gotcha 17).

## Keys

- **Numpad:** 1 / 4 / 5 / 9 first / prev / next / last, `+` add (Shift: blank), Enter play, 0 lightbox, `*` lightbox panes, `/` onion skin, `.` full-screen Preview.
  Frame keys whatever the Num Lock state, only while the sheet has frames (Num + on a plain
  picture too: `ANIM_key_ok%`). Not while typing, dragging, in a menu / palette / dialog,
  with Ctrl / Alt (`ANIM_keys_free%`).
- **Why not `_KEYHIT`:** DRAW drains `_KEYHIT` after render (`KEYBOARD_input_handler_loop`
  and the Ctrl / Alt branch), so the main loop's `k&` rarely sees a key (memory
  `keyhit-drained-after-render.md`). Presses come from `_KEYDOWN(100256+n)` (Num Lock on) /
  `_KEYDOWN(200000+n)` (off) edges and the device queue. `ANIM_numpad_tick` (DRAW.BAS, after
  `NUMPAD_poll`) fires them, and the plain-code **twins** (`_KEYHIT` 1, INKEY$ 2) are then
  dropped by `ANIM_numpad_code%` / `ANIM_numpad_inkey%`, so a numpad 4 does not also set
  opacity 40%.
- **Num Lock off** sends arrows / Home / End / PgUp. `ANIM_keydown%(kc)` masks those
  `_KEYDOWN` reads (22 sites in `INPUT/KEYBOARD.BM`) while that numpad key is held on a
  sheet, so they don't also nudge / page.
- **Laptop keys** go through the dispatcher (`INPUTS_register_all`): `Alt+,` / `Alt+.` /
  `Alt+Home` / `Alt+End` / `Alt+/`. They appear in SHORTCUTS.md's generated index.
- QA: send Alt chords with the harness `key` (it holds the modifier for `_KEYDOWN`); raw
  `xdotool key` is too quick.

## Frame operations (`TOOLS/ANIM-OPS`)

The sheet is always in play order (R-04), so an op moves pixels:

1. `ANIM_op_refusal$` (no frames, only frame, first / last, sheet too big) and
   `ANIM_OPS_busy$` (live transform / floating move / import / text edit / stroke). A
   refusal flashes in the status bar.
2. `ANIM_plan%(op, newCount, newCur)` fills `ANIM_SRC(1..newCount)`: new frame n shows old
   frame `ANIM_SRC(n)`, 0 = blank. This is pure and unit-tested. **The outputs are BYREF
   INTEGERs**: passing LONGs gives QB64 a temp copy and the results never come back.
3. Growth: `ANIM_sheet_h&(newCount)` > canvas height -> `ANIM_OPS_resize_keep_view` (by
   whole rows, R-03). It keeps zoom / scroll and records no Resize Canvas step.
4. `ANIM_OPS_move_cells`: per layer, a copy, then each cell 1..max(old, new) is cleared and
   given its source cell (`_DONTBLEND`, apron offsets - gotcha 14). Margins, gutters and the
   space past the cells are left alone. **Text and symbol-child layers stay put** (text is
   redrawn from its words, a linked copy from its parent); groups have no pixels.
5. `ANIM_apply_plan`: the holds follow their frames (blank = 1), count = wanted = newCount.
6. One undo record (below), `INVALIDATE_canvas`, status "Add Frame: frame n of m".

**Plain picture + add (R-08):** `ANIM_OPS_first_frame` sets frame size = canvas and doubles
the canvas width, so frame 2 goes beside frame 1. After that, R-03's rows rule applies. One
undo step back to the plain picture.

## Changing the layout of a drawn sheet (R-07)

Panel W / H / gutter / margin go to `ANIM_OPS_relayout`:

- **Re-slice** (`ANIM_SIZE_RESLICE`): `ANIM_set_layout%`. The grid moves, the pixels stay,
  and frames are clamped to the canvas.
- **Resize** (`ANIM_SIZE_RESIZE`): `ANIM_OPS_resize_frames%`. The canvas refits the same
  columns x rows at the new size (`ANIM_span&`), and each old cell's drawing goes to its new
  cell, cropped or padded at its top left (`LAYERS_demote_all` first). Content outside the
  cells is dropped. This is undoable.
- **The ask:** on an active sheet with `ANIM_SIZE_MODE = ANIM_SIZE_ASK` and anything drawn
  (`ANIM_OPS_sheet_drawn%`, a row-vs-zero scan), the step waits in `ANIMP.pendRow / pendD`.
  The panel then shows "RE-SLICE OR RESIZE?" with both chips lit. Picking a chip sets the
  mode and runs the waiting step. Any other control, or closing the panel, drops it. The
  answer is per document: `ANIM_reset` clears it, and `ANIM_deserialize%` (undo / redo)
  keeps it. An empty sheet just re-slices. This is a non-blocking question (no modal: QA
  and held steppers).

## Undo (`HISTORY_KIND_ANIM_FRAMES` = 21)

`ANIM_OPS_snapshot$(withPixels)` is deflated: canvas W/H, `ANIM.wanted`, `ANIM_serialize$`,
then (withPixels) every non-group layer `slot, w, h, raw RGBA`. Re-slice and timing changes
take no pixels (cheap). `HISTORY_record_anim_frames` stores `MKL(len before) + before +
after`, with `payloadLength` set, so it is saved with the document. Undo / redo call
`ANIM_OPS_restore`: resize back if needed, reallocate a layer whose buffer size differs (as
`HISTORY_apply_layer_snapshot`), `_MEMPUT`, then frames via `ANIM_deserialize%` + wanted.
It stops playback first.

**Held stepper = one step:** `ANIM_OPS_record(..., pressKey)`. While the top record is this
press's (`ANIM_OPS_LAST_KEY / _REC`, no redo tail), the new "after" replaces the old one.
`ANIMP.pressKey` increments on every fresh panel press.

**Export rows (F4, field kit T-17):** under the onion rows, `ANIMP.yScale` = SCALE + chips
1X 2X 4X (`ANIMP_CTL_SCALE0` 36-38, the current one lit; sets `CFG.ANIM_EXPORT_SCALE` +
`CONFIG_save`) and `ANIMP.yExport` = EXPORT + GIF APNG BAS (`ANIMP_CTL_EXP0` 39-41 ->
`ANIM_ACT_EXPORT_GIF / _APNG / _BAS`; greyed without frames). Both rows are 4-chip rows with the
label in slot 0. `ANIMPL` ends `... yScale yExport exportScale`. QA: `anim-panel-export`.

**Number boxes (F1, field kit T-6):** every stepper row's number - the 6 layout / timing rows
and the 3 onion rows (box ids `ANIMP_ROWS + 1..3`) - also takes the wheel, a middle click, a
drag and a click (`ANIMP_value_at%(nx, ny, whole)`: `whole` = anywhere on the row, for the
wheel and middle click; else only the value between - and +). `ANIMP_box_step / _set /
_reset% / _type` route to `ANIMP_step` or the onion CFG. Wheel (`ANIMP_wheel%`, hooked in
`MOUSE_handle_gui_panels` after `ANIMP_mouse_input`; it eats the wheel anywhere over the
panel): up = more, Shift = 10; ticks on one row within 0.8 s share a `pressKey` (one undo
step). Middle click: gutter / margin 0, FPS `ANIM_FPS_DEFAULT`, hold 1, onion 1 / 1 / 40; W / H
have no default (status hint). A press on the number sets `ANIMP.vRow`: moving
`ANIMP_DRAG_PX` (3) viewport px a step, up = more, Shift x10, one undo step; a release without
moving opens `DRAW_input_box_ex$` (autoselect) to type it. A layout row on a drawn sheet still
waits for RE-SLICE / RESIZE (`pendRow`; a drag stops there).

## Playback

- `ANIM_PLAY` (`playing`, `dir`, `fromF..toF`, `nextT`). `ANIM_play_start%` (count >= 2;
  play once from the last frame starts over), `ANIM_play_next%` (per loop mode, 0 = once
  ended), `ANIM_play_advance%(t)`: at most 4 steps a call, resyncs after a stall (no
  burst), handles TIMER's midnight wrap.
- `DRAW.BAS`, beside the palette-cycling tick: `IF ANIM_play_tick% THEN FRAME_IDLE% = FALSE:
  SCENE_CHANGED% = TRUE: GUI_NEEDS_REDRAW% = TRUE`, and `IF ANIM_PLAY.playing THEN
  FRAME_IDLE% = FALSE`. The loop stays live only while playing, and the scene rebuilds only
  when the frame changes.
- **Drawing blocked** (Q-22): `MOUSE_should_skip_tool_actions%` turns a press during playback
  into a chrome click (`MOUSE.UI_CHROME_CLICKED%`, consumed until release, gotcha 5). Pan
  still works. Frame ops, layout changes and undo stop playback.
- The range is all frames for now. `fromF / toF` are ready for the strip selection (2.3) and
  tags (4.4).
- **Preview window:** with frames on and `CFG.PREVIEW_SHOWS_FRAME`, `PREVIEW_render`
  (non-float mode) calls `ANIM_VIEW_preview_blit`: the current cell fitted, at a
  whole-number zoom when it fits, centred, with no follow crosshair. So it plays along.

## Lightbox (`TOOLS/ANIM-LB`, 2.1)

The **Animate** built-in workspace (L.2, `ASSETS/WORKSPACES/animate.workspace`) is `[CHROME] ANIM_PANEL=SHOW` (+ layers, charmap / 3D / browser hidden) and `[OPTIONS] LIGHTBOX=1 ONION_SKIN=1 FRAME_GRID=1` - an overlay, so Default / leaving puts the user's view back and DRAW.cfg never sees it. QA: `workspace-animate.sh` (13, incl. a toggle inside the workspace sticking - the guard fix in draw-workspaces.md).

- **A view, not a mode:** `ANIM_LB_showing%` = `CFG.LIGHTBOX` and the sheet has frames. In
  `SCREEN_render` it replaces the whole canvas branch (normal and tile mode): `RENDER_layers`
  composites with its blit thrown off screen (`useComposite` is forced while showing, so
  `CANVAS_CONTENT_SRC&` is a canvas-size composite, the one the Preview reads), then
  `ANIM_LB_render` cuts every frame from it. Grids, the frame grid, symmetry, the border, the
  ref image, CRT, the text hover outline and the scrollbars are sheet-view things and are
  skipped; tool previews, marching ants, smart guides and the pointer are drawn through a pane
  (below). It is drawn before the scene cache, so it only
  re-renders when the scene does (a frame step, a playback tick, a canvas change).
- **Bands:** strip = a quarter of the area (cells are the band's height, the frame's shape,
  integer zoom, scrolled so the current frame stays in view), the transport bar (one
  `FPANEL.rowH` row; low-priority controls drop out when it is narrow so the seek bar keeps
  24 px), the editor (panes, current in the middle; a pane past either end is drawn empty).
  Checks: cut from `TRANSPARENCY.blueprint&` (`TRANSPARENCY_ensure_blueprint`, split out of
  `TRANSPARENCY_render`) for the same cell, so they scale with the art as in sheet view.
- **Area:** `ANIM_LB_area` = the canvas work area (between the docks, under the menu / text
  bar, over the status bar, beside the Browser band); `ANIM_LB_clear_floats` then moves an edge
  in past a floating window that touches it over the strip / bar (the user's Color Mixer sits
  top-left), never below half the width. `hx1 / hx2` keep the whole width for hit tests.
- **Input:** `ANIM_LB_mouse` at the top of `MOUSE_should_skip_tool_actions%`: any press in the
  work area while showing is a chrome click (gotcha 5 lifecycle); a left press on a transport
  control runs it. `POINTER_build` shows the arrow there - except over a pane's picture
  (`ANIM_LB_pane_at%`), where the press goes to the tool (`strokePane` = that pane until every
  button is up).
- **Drawing in a pane (2.2) - the pane view:** DRAW.BAS wraps `MOUSE_input_handler` in
  `ANIM_LB_view_push` / `ANIM_LB_view_pop`; `ANIM_LB_view_pick` (in `MOUSE_drain_update_state`,
  just before the canvas mapping) sets `SCRN.zoom / offsetX / offsetY` to the view that puts
  the pane's frame cell on its picture (`ANIM_LB_pane_view%`: the inverse of the mapping
  `dx = (SCRN.w - zw) \ 2 + offsetX + panelShiftX`) and tile mode off. So every tool maps,
  paints, previews and commits in that cell with no tool code changed. The pane is the stroke's
  pane, else the one under the pointer, else the middle one (`vPane`). Pop puts the real view
  back; a zoom or pan the handler made in the pane view is kept as the lightbox's own first
  (below).
- **The drawing pane (F2, field kit T-7):** every pane takes strokes, so the pane a stroke goes
  into - `strokePane` mid-stroke, else `ANIM_LB_pane_at%` under the pointer on `REGION_CANVAS`
  (none while playing) - is `ANIM_LB.drawPane`, tracked by `ANIM_LB_draw_pane_track` (end of
  `ANIM_LB_view_pop`, every frame; it dirties the scene only when the pane changes).
  `ANIM_LB_draw_pane_ring` draws 2 px of theme `ANIM_FRAME_DRAWING` (magenta, 255,70,200) plus a
  dashed (`&HF0F0` over black) outer px outside the outline already there (the current frame's
  2 px blue); its label turns that colour. A theme without the key falls back to magenta. Dump:
  `ANIMLB ... pad drawPane`. QA: `anim-lightbox-drawpane`.
- **Shift crosshair (field kit T-23):** `RENDER_crosshair_and_command_palette` draws it only
  when the pointer is over pane `ANIM_LB.vPane` (REGION_CANVAS), between
  `ANIM_LB_overlay_begin%` / `_end` - the pane's view, clipped to the pane; never over the strip
  or bar. Test: `anim-lightbox-crosshair.sh`.
- **Zoom (field kit T-9):** every pane shows its frame at `ANIM_LB.vz` (0 = fitted,
  `ANIM_LB_pane_fit!`), its corner at `vrx / vry` from the pane's; a picture bigger than its pane
  is built in a pane-sized scratch (`ANIM_LB_draw_zoomed`, `ANIM_box_begin& / _end`,
  `ANIM_put_view` - only the source pixels that land are put) so it stops at the pane's edge, and
  `ANIM_LB_vis` gives the part that shows (hit test, overlays, outline, label). Input is not
  special-cased: `ANIM_LB_view_pick` records the view it set (`pickZ / OX / OY / K`) and
  `ANIM_LB_view_absorb` (next pick, and pop) turns any change into `vz / vrx / vry`
  (`ANIM_clamp_pan`: inside the pane while it fits, no gap once bigger; at or below the fit =
  fitted). So Ctrl+wheel (`ANIM_LB_pane_wheel%`, next to the strip wheel), the Zoom tool,
  middle / Space drag and Shift+wheel all work. View > Zoom In / Out / Reset (406 / 407 / 405,
  Ctrl+= / - / 0) go to `ANIM_LB_zoom_cmd%` while it shows (about the middle pane; 405 = fit).
  The **plain wheel** over the panes steps frames (down = later, stops at the ends; Rick
  2026-11-08). A frame size change resets to fitted. Dump `ANIMLBZ zoom% rx ry`; `ANIMLBP` gives
  the whole picture rect (may exceed the pane). **The wheel anchor** (`WHEEL_zoom_at_cursor`,
  `ZOOM_adjust_offset`) now counts `SCRN.panelShiftX / Y` as the mouse mapping does - before, the
  pixel under the pointer drifted by the shift on every step, in sheet view too.
  The Preview's frame view has its own zoom (`ANIM_VIEW.pvZ / pvRX / pvRY`,
  `ANIM_VIEW_preview_fit! / _zoom%` from `PREVIEW_mouse_scroll`; dump `ANIMPV`). QA:
  `anim-lightbox-zoom.sh`.
- **Overlays:** `ANIM_LB_overlay_begin%` sets the same view for `vPane`, swaps `SCRN.CANVAS&`
  for a scratch image (pane picture cleared), and `_end` copies only the picture rect back, so
  an overlay never spills out of its pane. Wrapped: the import / crop / transform / fill-adj /
  `RENDER_tool_previews` block (with `dx / dy / zw / zh` recomputed for the view), the selection
  overlay + smart guides after `SkipToPointer:`, and `POINTER_draw` in `POINTER_render`.
  `ANIM_LB_skip_overlay%` is the guard inside those routines. The dirty-rect and status-only
  fast paths are off while showing (their rects are in sheet coords): a cursor frame copies the
  whole scene cache and redraws the overlays.
- **Clip to the frame (R-06):** a press in a pane (with `CLIP_FRAME_LIGHTBOX`) or on the canvas
  in sheet view (`ANIM_LB_sheet_press`, with `CLIP_FRAME_SHEET`) starts `ANIM_LB_clip_begin f`:
  a copy of the current layer. After every mouse frame (`view_pop`) everything outside the cell
  is put back from it (only inside this frame's `COMP_DIRTY_*` rect when set; apron offset,
  gotcha 14), and in full from `HISTORY_store_after_image` (`ANIM_LB_clip_finish`) so the undo
  step stores the clipped result. Skipped for marquee / picker / zoom / pan / text / move, an active
  transform, and text / group layers; it ends when the buttons are up. Known limit: tools that commit after
  the release (polyline, bezier) are not clipped.
- **Clip off: strokes follow the panes (B9):** with `CLIP_FRAME_LIGHTBOX` off, a freehand
  stroke (`ANIM_LB_freehand%`: brush, dot, spray, eraser) is still clipped to its pane's frame
  (`ANIM_LB.follow`), and `ANIM_LB_follow_step` (from `view_pop`) moves it on when the pointer
  is over another pane: `strokePane` / `vPane` switch, the last point (`MOUSE.X/OLD_X/UNSNAPPED/CON`,
  `DOT.LAST_*`, `BMIX.last*`) is shifted by `(oxK - oxN) / z` - the same screen spot seen
  through the new pane's view - so the next segment starts at the pane's edge, and the clip
  restarts on the new frame (its copy holds the stroke so far). One undo step. Before, the
  stroke ran past the cell into its sheet neighbour (the next cell in the row, or off the
  sheet). Shapes keep the start pane's view, unclipped. Test: `anim-lightbox-follow.sh`.
- **The strip (2.3):** `ANIM_LB_strip_at%` (cell + half the gap either side). A left press runs
  `ANIM_LB_strip_press` (R-12 via `ANIM_SEL_click`; a plain press on a frame already in a
  multi-selection only makes it current and collapses on release - it may be a drag), then
  `ANIM_LB_strip_hold` every frame until the release (chrome click throughout): 4 px of
  motion without Ctrl / Shift = a drag, `sDrop` = `ANIM_LB_strip_slot%` (before the frame whose
  left half the pointer is over), a marker between cells, past the strip's ends it scrolls a
  frame per 0.25 s; the release sets `ANIM_MOVE_TO` and runs `ANIM_OPS_run ANIM_OP_MOVE_SEL`
  (one undo step; refused = no step when dropped in place). The wheel over the strip
  (`ANIM_LB_strip_wheel%`, after the layer panel in the mouse chain) scrolls a quarter of it;
  `lastCur` makes the layout bring the current frame back only when it changes. Selected
  frames (2+) are tinted with `ANIM_FRAME_current` at alpha &H50 and outlined.
- **Transport bar sizes (F3, field kit T-11):** the number boxes (TIME, FPS, COUNT) print in the
  theme UI font at 2x (`ANIM_LB_big_ensure`: `GLOBAL_FONT_FILE` at `2 * GLOBAL_FONT_SIZE` =
  Tiny5 16; `ANIM_LB_big_w% / _big_text`, falls back to the panel font). Every control is
  `ANIM_LB.rowH` (= max(`FPANEL.rowH`, bigH + 6)) tall inside `LB_BAR_PAD` (4) px, so
  `barH = ANIM_LB_bar_h%` (30 at Tiny5 8; `ANIM_LB_clear_floats` uses it too). Chips are
  padded by 2 x fontW. `ANIM_LB_seek_draw`: a track rowH - 6 tall, an `LB_SEEK_THUMB` (8) px
  handle 2 px proud with its border outside. `ANIM_LB_ctl_at%` hit-tests the same band. QA:
  `anim-lightbox-transport`.
- **The transport bar (2.4):** LOOP opens a `POPUP_MENU` of the four modes
  (`ANIM_LB_menu_open / _mouse% / _render`; drawn after `SkipToPointer:` every frame so it sits
  over everything; a press outside closes it). FPS is a spinner: a click on its left / right
  third steps -1 / +1 (Shift 10), the wheel over it steps (`ANIM_LB_bar_wheel%`), each through
  `ANIM_OPS_timing` (one undo step). A press on the seek bar scrubs (`seekHeld` until the
  release). The count box takes typing (`ANIM_LB_EDIT` - a plain shared string: a fixed
  `STRING * n` in the TYPE is NUL-filled and turned the QA dump binary): `ANIM_LB_keys%` in
  `KEYBOARD_input_handler` right after `COLORMIXER_keys%` eats every key (INKEY$, as the hex
  box), `ANIM_LB_editing%` sets `CTX_TEXT_ACTIVE` and blocks the numpad frame keys (numpad
  digits type). "5" = go to 5, "5/9" = 9 frames and go to 5, "/9" = only the total
  (`ANIM_OP_SET_COUNT` + `ANIM_COUNT_TO`: blanks added at the end, or the last dropped). A
  smaller total that drops drawn frames (`ANIM_OPS_drawn_in%`) asks first in the status bar
  (Enter drops, Esc keeps; R-16); always undoable. COPY / PASTE / CUT run 2523 / 2525 / 2524
  (Shift+PASTE = 2526, over).
- **Copy / cut / paste frames (2.5, `TOOLS/ANIM-OPS`):** the selected frames (else the
  current) go to the OS clipboard as ONE picture: a column per frame, a row per pixel layer
  (`ANIM_OPS_moves%` slot order), with the line `DRAWFRAMES1|w|h|frames|layers|id|hold,...` in a
  header strip on top (`ANIM_OPS_clip_pack&` / `ANIM_OPS_clip_meta$`: opaque pixels, 3 bytes
  each, pixel 0 = "DF1", pixel 1 = length hi / lo / header rows). **[Linux] the X clipboard holds
  a picture OR text** - setting `_CLIPBOARD$` after `_CLIPBOARDIMAGE` drops the picture (probed
  2026-11-07; Copy Layer 715 has the same limit), so the line can't ride the text clipboard. The
  copy is also kept un-stripped in `ANIM_CLIP_IMG` / `ANIM_CLIP_META`: a paste whose header
  matches it uses the exact pixels; an empty OS clipboard falls back to it. Paste as new =
  `ANIM_OP_INSERT_N` (`ANIM_COUNT_TO` blank frames after the selection's last frame) then the
  pixels; over = from the first selected frame, growing the count (`ANIM_OP_SET_COUNT`) when they
  run past the end. Row r goes to the r-th pixel layer, extra rows onto the last one; another
  frame size pastes top-left, cropped. Holds ride along. One undo step (`ANIM_OPS_record`); the
  pasted frames end up selected. Cut = copy + `ANIM_OP_DELETE_SEL` named "Cut Frames"
  (`ANIM_OPS_STEP_NAME` overrides the op's label). **[Linux] QB64-PE's `_CLIPBOARDIMAGE` misreads
  a palette PNG with tRNS** (color type 3): pixels arrive shifted, as if RGBA were read as RGB;
  RGBA / RGB PNGs read fine - QA builds its "other window" picture as `PNG32:`.

## Onion skin (`TOOLS/ANIM-LB`, 2.6)

R-09: the lightbox only, on the **current pane** only (drawing in another pane doesn't make it
current). `ANIM_LB_onion` runs in the pane loop of `ANIM_LB_render` right after the picture:
for `CFG.ONION_BEFORE` / `ONION_AFTER` (0-5, `ANIM_ONION_MAX`) frames, farthest first so the
nearest lands on top, it builds the cell into `ANIM_LB.onionImg` from the composite with `_MEM`
and `_PUTIMAGE`s it scaled over the picture. Alpha = pixel alpha x `ONION_OPACITY`% x
(n - d + 1) / n. A pixel shows only where it **differs from the current frame** and **is not
that frame's background** (`ANIM_LB_cell_bg%`: the colour 3 or 4 corners share) - so a solid
background layer doesn't tint the whole pane, and a static scene stays clear. **Ghosts go behind
the current drawing:** only where the current frame is transparent or its own background
(`ANIM_LB_cell_bg%` of the current cell) - drawn over it, the current frame looked faded (field
kit T-13). Tint: 3/4 red
(255,48,48) before, 3/4 blue (48,112,255) after. No wrap at the ends; nothing while playing.
Settings are DRAW.cfg (`ONION_*`), not undo steps: ANIM menu (2527 / 2528), Num / (numpad slot
15), and the Animation panel's ONION / TINT chips + BEFORE / AFTER / OPACITY steppers
(`ANIMP_CTL_ON0`.. ids 28-35, `ANIMP_onY`; a held stepper saves the cfg on its release). Cost is
per real render (not cursor-only frames): fine for pixel-art cells; a 512x512 frame with 5 + 5
neighbours would be the case to cache. QA dump `ANIMLBO on before after opacity tint prevPx
nextPx`; `ANIMPL` gained `yOnion onY1..3` at the end (read it with a trailing `_`).

## The current frame is the canvas (2026-11-09, `TOOLS/ANIM-CANVAS`)

Rick: "anything that uses the canvas needs to consider lightbox mode, not just the drawing tools".
The one question is `ANIM_CV_rect%(x, y, w, h)`: in the lightbox (`ANIM_LB_showing%`) the current
frame's cell (TRUE), else `0, 0, canvasW, canvasH`. Done so far:

- **Align / Distribute** (1901-1908): `CMD_execute_action` sends them to `ANIM_CV_align` while the
  lightbox shows. Per selected frame (`ANIM_SEL_is%`), on the layers the canvas version takes
  (multi-select or current, group expanded; `ANIM_OPS_moves%` only): bounds inside the cell
  (`ANIM_CV_bounds%`), one layer -> the cell, several -> the same anchor / union rules as the
  canvas version, shifted with `ANIM_CV_shift` (what leaves the cell is cut off). One
  `ANIM_OPS_record` (sheet snapshot with pixels). Distribute needs 3+ layers.
- **Smart guides:** `SMART_GUIDES_update` uses the cell's edges / centre, and
  `SMART_GUIDES_compute_bbox` the layer's bounds inside the cell; the cache is keyed by frame
  (`SG_FRAME_KEY`, 0 = sheet). The pane Move tool (`ANIM_LB_move_*`, no `MOVE.*`) gets guides too:
  `ANIM_CV_move_begin` (press: the current layer's bounds in the current cell),
  `ANIM_CV_move_guides ox, oy` (feeds `SMART_GUIDES_update` with `moveBBox*` set; snap adjusts the
  offset); the render condition in `SCREEN.BM` takes `ANIM_LB.mvOn` beside `MOVE.TRANSFORMING`.
- **Transform tool:** `TRANSFORM_activate` sets `ANIM_CV_TF_F` (the current frame) and, with no
  selection, takes the layer's bounds inside the cell (nothing there = a status message, no
  transform); `TRANSFORM_commit` puts only the part of the result inside that cell (no apron
  promotion), so it never spills into a neighbour. Cleared on commit / cancel.
- **Select All / Invert** (`MARQUEE.BM`): Select All selects the cell; Invert ends with
  `ANIM_CV_clip_selection` (a mask selection cleared outside the cell and its bounds rescanned -
  empty = cleared; a box selection intersected with the cell).
- **Copy / Cut / Copy Merged / Paste** (`SELECTION.BM`): with no selection the source is the cell
  (Cut clears only the cell, apron-aware); Paste centres and clamps to the cell.
- **Symmetry** (`SYMMETRY_get_mirrored_points`): `ANIM_CV_sym_center x, y, cx, cy` - the frame
  under the point (`ANIM_frame_at%`), the centre = that cell's centre, or a user-set centre kept at
  the same offset inside its own cell. The guides draw per pane (`ANIM_CV_sym_guides`, inside the
  lightbox overlay in `SCREEN.BM`).
- **Image drop / Import Image** (`DROP.BM`, `IMAGE-IMPORT.BM`): "larger than" compares against the
  cell, `ANIM_CV_place` centres / places in it, and `ANIM_CV_keep_cell` clears what the stamp put
  outside it.
- **Scale -50% / 2x / 2x H / 2x V** (317 318 331 333): `ANIM_CV_scale_wants%` (lightbox, no
  selection / floating move / custom brush / symbol child) sends them to `ANIM_CV_scale`: each
  selected frame's cell scaled about its centre (`ANIM_CV_scale_cell`, nearest neighbour, cut off
  at the cell), on `ANIM_CV_layers%` (multi-select or current, drawing layers only - shared with
  align). One `ANIM_OPS_record`. Unlike the canvas version there is no kept original, so -50%
  then 2x loses the detail. Test `anim-lightbox-scale.sh`.
- **Floods** (`FILL_generate_mask&`, `FILL_flood`, `FILL_flood_merged`, `FILL_flood_global`;
  `MAGIC_WAND_select_with_mode`, `_select_merged`, `_select_all_color_merged`, `_erase_flood`,
  `_fill_flood`): each scans inside `bL bT bR bB`, the canvas unless `ANIM_CV_fill_box` narrows
  it to the cell of the frame clicked in (`ANIM_frame_at%` of the seed). The erase / fill floods
  work in buffer pixels, so their box carries the apron offset. Without it the region could run
  out through a neighbouring frame and back in (clip-to-frame only put the paint back). Test
  `anim-lightbox-fill.sh`.
- **Selection from layer** (728 / 1401 / 1414): `LAYER_select_non_transparent` and 1414 end
  with `ANIM_CV_clip_selection`.
- **Marquee:** `MARQUEE_update_drag` ends with `ANIM_CV_marquee_drag` (both corners inside the
  cell of the frame the drag began in, `MARQUEE_UNSNAPPED_START_*`; the grid-snap end is
  exclusive), and `MARQUEE_finish_drag` clamps the final box (`ANIM_CV_clamp_box`).
- **Move / paste commit** (`MOVE_apply_transform`): `ANIM_CV_keep_begin&` copies the target
  buffer when the lightbox clips to the frame (`CFG.CLIP_FRAME_LIGHTBOX`), `ANIM_CV_keep_end`
  puts back everything outside the current cell after the stamp. The multi-layer sibling path
  is not clipped yet. Test `anim-lightbox-select.sh`.
- **Text:** New Text Layer (712) starts at the cell's centre; `TEXT_add_char`'s auto-wrap and
  `TEXT_char_mode_set_cursor`'s column limit use the right edge of the cell the text starts in
  (`ANIM_CV_fill_box` on `startX / startY`). Lines still run on below the cell's bottom. Dump
  `ANIMTX startX startY x y w h` (the current text layer; its pixels' bounds). Test
  `anim-lightbox-text.sh`.
- **Centred effects** (`IMAGE_ADJ_twirl& pinch& kaleidoscope& lensflare& backlight& ripples&
  grid& lightning& blur_typed&`): a prologue - when `ANIM_CV_fx_split%` sees a layer buffer in
  the lightbox, the effect calls itself on each selected frame's cell (`ANIM_CV_fx_begin& /
  _fx_cell& / _fx_put / _fx_end`; `ANIM_CV_FX_L` is the re-entry guard) and stitches the
  results, so centre and radius are the frame's (and a blur does not bleed across frames). A
  picked centre keeps its offset inside each frame (`ANIM_CV_fx_cen&`). The loupe preview
  centres on the current frame (`IMAGE_ADJ_update_loupe`). Texture-like effects (weave, stone,
  rust, noise ...) are not split. Test `anim-lightbox-effect-centre.sh` (frames 1 and 3 hold the
  same picture; Twirl / Pinch on each must match).
- **Gradient / image paint:** the flood fill's `GRAD_CTX_set` (`MOUSE.BM`) and
  `DRAWER_resolve_paint_color~&`'s stretched / tiled image span the cell of the frame painted in
  (`ANIM_CV_fill_box`). The grid stays on the sheet (its snap matches the drawn grid).
- **Paste in Place** (312, now also in the command palette): `ANIM_CV_same_spot` moves the copied
  spot from its frame to the current frame; `CLIPBOARD_IN_PLACE` makes `CLIPBOARD_paste` keep the
  point instead of centring (it had centred every paste since BUG-A, so Paste in Place never
  pasted in place, lightbox or not). Copy / Paste Layer between instances stay whole-sheet (a layer
  is every frame). Test `anim-lightbox-paint.sh` (`DEFAULT_DRAW_MODE=2`; DRAWERL now ends with the
  first bin x y, bin w h, gaps, paint mode, gradient picked).
- Dump `ANIMCV guidesOn snapOn moveX moveY moveW moveH` + the last pane-move guide step (offset
  in, guides v / h, snap dx / dy, offset out). Test `anim-lightbox-canvas.sh` (fixture frames 2-5
  are frame 1 aligned right / centred / bottom / snapped right + top).
  Test `anim-lightbox-canvas-edit.sh` (Select All + Delete, Cut with no selection, Paste back,
  a symmetric dot in frame 3 = fixture frame 4).
- Still to do (the audit, TASKS-ANIMATION-2 F11 o): crop / analyzer / AI size / ref image.

## Apply to the selected frames (2.7)

In the lightbox, commands act on the strip's selected frames (`ANIM_SEL_is%`: the current frame
when none is), each one undo step. A user marquee selection keeps the commands' own behaviour.

- **Effects** (`ANIM_FM_wants%`: 2001-2011, 2101-2289, 2350-2352, Remap to Palette 1516, and
  Delete / Edit > Clear 306 / 308 + Fill with FG / BG 313 / 314 - Backspace): the top
  of `CMD_execute_action` runs the command nested between `ANIM_FM_begin` (a copy of every pixel
  layer in `ANIM_FM_IMG()`) and `ANIM_FM_end`; `ANIM_FM_mask` puts back everything outside the
  selected cells. It also runs from `HISTORY_store_after_image` (`ANIM_FM_finish`, next to 2.2's
  `ANIM_LB_clip_finish`), so the effect's own undo record stores the masked after-image - redo is
  masked too. The effect still samples across cell edges (a blur pulls in the neighbour frame).
- **Flip / rotate** (`ANIM_OPS_frames_geom%`: 315 / 316 / 319 / 320 on the current or selected
  layers, Image > Flip Canvas 1803 / 1804 on every layer) are done per cell
  (`ANIM_OPS_cell_geom`), since a whole-layer flip would move frames into each other's cells.
  Rotate needs square frames. Undo = `ANIM_OPS_record` sheet snapshots. Symbol children keep
  their own flip.
- **Move tool** in a pane (`ANIM_LB_move_begin%` / `_hold` / `_apply`): the press is swallowed
  like a chrome click; the drag shifts each selected cell of the current layer from a press copy
  (what leaves a cell is cut off); released = one `ANIM_OPS_record`. Pressing V lifts the whole
  layer at once (`MOVE_capture_selection`) - an untouched lift is dropped with `MOVE_reset`
  first, which records nothing.
- **Arrow keys** (B4, `ANIM_LB_nudge_wants%` / `ANIM_LB_nudge`, hooked at the top of
  `KEYBOARD_handle_move_keys`): Ctrl+arrow with any tool, or a bare arrow with the Move tool,
  shifts the selected cells the same way (`ANIM_LB_move_apply`), Shift = `CFG.NUDGE_N%`, one
  `ANIM_OPS_record` per press. Not with Alt (clone), a marquee, a transform, or a floating
  selection that has moved; an untouched whole-layer lift is dropped first. Test:
  `anim-lightbox-nudge.sh`.
- **Palette swap**: ANIM > Replace FG Color with BG in Frames (2529) - exact RGBA matches on the
  current / selected layers, sheet view or lightbox.

QA: `anim-lightbox-apply.sh` - its fixture's frames 2 / 3 / 4 are frame 1 moved / turned /
mirrored, so a correct per-cell op on frame 1 produces another frame's exact CRC.

## Layer flags: reference layers, same on every frame (2.8)

Flags live beside the layers, not in `DRAW_LAYER`: `ANIM_LF_ID() / ANIM_LF_FL()` keyed by
**historyId** (stable through reorder, delete + undo, save / load), bits `ANIM_LF_REF` /
`ANIM_LF_SAME`; `ANIM_LF_get% / _set` (pure, unit-tested), `ANIM_LF_of% / is_ref% / is_same%`
(by slot, `TOOLS/ANIM-OPS`). Saved in `drAn` v2 after the holds (`n` + `id, flags` each) - also
for a picture without frames, which then writes a frame-less drAn (count 0); the loader reads
the flags before checking the layout, and `DRW_load_from_png` runs `ANIM_LF_prune` (a dropped
layer's id could be given to a later layer). They ride in every `ANIM_OPS_snapshot$`, and each
toggle is an `ANIM_OPS_record` step, so an undo never lands on flags from another time.

- **Reference** (Q-19): `LAYERS_flatten&` skips it, and with it every export (PNG / GIF / ANS /
  .draw composite / Flatten & Save / AI dimg / extract / analyzer) and the BAS code export
  (`FILE-QB64`). On screen and in the lightbox it is drawn as usual. Layer panel: `[R] ` name prefix.
- **Same on every frame** (R-05 phase 1; pixel layers only, needs frames): `ANIM_SB_*` holds the
  picture every cell shows (by historyId; `ANIM_deserialize%` keeps it - undo / redo is the same
  document). `ANIM_SAME_tick%` runs in the main loop before the render when `ANIM_SAME_CHECK`
  is set (`HISTORY_commit_record`, `HISTORY_undo`, `HISTORY_redo`) and no button is held / no
  float or transform is up: every pixel of any cell that differs from the picture goes into it,
  then into every cell (spare ones too). So a stroke in one frame lands on all, and so do its
  undo and redo (the restored cell differs, and spreads) - nothing else hooks the tools.
  Frame ops (`ANIM_OPS_run`, paste, resize frames, re-slice) call `ANIM_SAME_stamp_all` before
  their after-snapshot: a blank frame would otherwise erase it everywhere. Content ops (flip,
  swap, Move, masked effects) need nothing - the tick spreads them. A missing / wrong-sized
  picture is rebuilt from the current frame's cell. Layer panel: `[=] `.

QA: `anim-layer-flags.sh` (`ANIMLF curRef curSame nFlags flatCrc`, flatCrc = CRC32 of
`LAYERS_flatten&`, only for a document with frames or flags, `-` past 512x512).

## Exports (`TOOLS/ANIM-EXPORT`, phase 3)

**Animated GIF** (3.1, `ANIM_GIF_export% path`; ANIM > Export Animated GIF..., batch
`--export-anim out.gif` on a document with frames - without frames it is still the colour
cycle GIF): pixels from `LAYERS_flatten&` (hidden / reference layers out), the frames in
`ANIM_play_order%` (pure, unit-tested: ping-pong written out 1..n..2; play once = no NETSCAPE
block). Delays: cumulative rounding of `hold * 100 / fps` cs, at least 2 (flagged "faster than
50 fps"). Colours exact (`ANIM_GH_*` hash of the cells' RGB) when they fit 256 with the
transparent entry, else `IDX_index_image$` against the palette. Transparency: index after the
colours, disposal 2. `CFG.ANIM_EXPORT_SCALE` 1 / 2 / 4 (nearest; `ANIM_GIF_cell$`). LZW is
encoded once per frame. **Colour cycling** with active ranges: a 2-cs tick timeline
(`GIF_cycle_ticks&`, factored out of `GIF_anim_stream$`, + `GIF_display_map`); a GIF frame
whenever the frame or the colours change, each with a local colour table (entry -> its
palette chip in a range -> `PAL(dispOf(chip))`); length = LCM(frames loop, cycle loop), cut
at 120 s / 2000 GIF frames. `ANIM_EXPORT_INFO` sums it up (status bar, log).
QA: `file-anim-gif.sh` (batch CLI, ImageMagick: counts, delays, sizes, disposal, pixels per
cell); `DEV/tools/test-cycle-exports.sh` covers the cycle GIF.

**PNG sequence** (3.2, `ANIM_PNGSEQ_export% path`; batch `--export-anim out.png`): for
out.png, `out_0001.png ...` (4+ digits) - one PNG per tick at the FPS in `ANIM_play_order%`
(a frame held 3 = 3 files, ping-pong written out; the video stand-in of Q-24: `ffmpeg
-framerate FPS -i out_%04d.png`). out.png itself is not written. Numbered files straight
after the new last one (a longer earlier export) are removed. No colour cycling (the cells as
drawn). Capped at `ANIM_PNGSEQ_MAX` files.
**Sprite sheet** (3.2, `ANIM_SHEET_export% path`; batch `--export-anim out.json`): for any
out.ext, `out.png` = the flattened sheet (gutter / margin kept), `out.json` = Aseprite's
"array" layout (`frames[]`: filename, frame {x,y,w,h}, spriteSourceSize, sourceSize,
duration ms = hold * 1000 / fps; `meta`: app, version, image, RGBA8888, size, scale, fps,
loop, `frameTags[0]` "all" with direction forward / reverse / pingpong, `repeat "1"` for play
once), `out.bi` = QB64 `CONST <NAME>_FRAMES / _FRAME_W / _FRAME_H / _FPS / _LOOP` + label
`<NAME>_FRAME_DATA:` + `DATA x, y, w, h, ms` per frame (`ANIM_bas_name$`: upper case,
A-Z 0-9 _). Refuses when out.png is the open document (`ANIM_is_document%`, `_FULLPATH$`).
Both scale by `CFG.ANIM_EXPORT_SCALE` (`ANIM_block_image&`, an exact `_MEM` pixel copy).
In the batch CLI the .png / .json cases run before `BATCH_export%`'s `KILL path`.
QA: `file-anim-sheet.sh` (batch CLI: files per tick, exact pixels per cell, stale files,
2x, JSON via python, the .bi compiled and run with qb64pe, gutter / margin rects, the
document guard).
**APNG** (3.3, `ANIM_APNG_export% path`; ANIM > Export Animated PNG (APNG)..., batch
`--export-anim out.apng`): written by hand - IHDR (RGBA 8-bit), acTL (frames, num_plays 0 or
1 for play once), then per frame in `ANIM_play_order%` a full-frame fcTL (delay_num = hold,
delay_den = fps: exact; dispose none, blend source) + IDAT for frame 1 (the default image a
plain PNG reader shows) / fdAT after; one sequence number across fcTL + fdAT. Pixel rows:
`ANIM_png_zdata$` (BGRA memory -> RGBA, filter 0, `_DEFLATE$` = a zlib stream), once per
frame; chunks via `PNG_make_chunk$` (DRW.BM). No colour cycling (flagged in
`ANIM_EXPORT_INFO`; the GIF runs it). Refuses the open document's own path (the dialog
suggests name.png). QA: `file-anim-apng.sh` (a python stdlib reader: CRCs, zlib + adler,
sequence, delays, RGBA per cell; ffprobe frame count; ImageMagick default image).
**BAS player** (3.4, `ANIM_BAS_export% path`; ANIM > Export BAS Player (DATA)..., batch
`--export-anim out.bas` on a document with frames - without, `.bas` is still the colour
cycling program): one self-contained .bas. `ANIM_BAS_blob$(pixels, nCyc)` = "DANM" v1:
MKI frameW, frameH, count, fps, loopMode, nOrder, the play order, the holds, the palette,
the cycle ranges (as DCYC: lo, hi, overlay base, rate, mode, active, heldStep), then per
frame its cell (BGRA, `pixels = FALSE` leaves them out for 3.5) + with ranges its overlay
(index into the packed range colours, 0 = not cycling). Deflate + base64 in `DATA` after the
label `anim_data:` (the player `RESTORE`s it - 3.5 puts its rect DATA first).
`ANIM_BAS_player nm, b64, sheetPng` writes the program through `CYCX_L` (backtick = quote):
`$SCREENHIDE` until the window opens; per frame a 32-bit image + 256-colour overlay with
`_CLEARCOLOR 0`; `compose f` copies the cell `_DONTBLEND` and puts the overlay with its
palette rotated (`shifts_at%(t)`, the cycle player's formulas); the loop advances by
`acc += dt * speed * fps` against the hold, play once stays on the last frame. Keys SPACE /
LEFT / RIGHT / + - / R / ESC. `--frames DIR` writes one loop - `frame_0001.png ...` with
the cycle at each step's start time, and `frames.txt` "step frame ms" (CRLF) - then exits.
QA: `file-anim-bas.sh` (compiles the players with qb64pe; `--frames` exact per cell for
ping-pong / reverse, the cycle one step on at 0.1 s; live under `QA_IN_XVFB` only: the
player window's xwd changes, Esc exits 0).
**BAS player + sheet PNG** (3.5, `ANIM_BAS_sheet_export% path`; batch `--export-anim
out.sheet.bas`, like `.pbm.lbm`): the same player, `ANIM_BAS_blob$(FALSE, ..)` (no cells),
plus `name.png` = `LAYERS_flatten&` at 1x (`name-sheet.png` when name.png is the open
document). The program `_LOADIMAGE`s it from the current folder, else beside the program
(the folder of `COMMAND$(0)`), and cuts each frame `_DONTBLEND` at its rect from
`frame_rects:` DATA (x, y; before `anim_data:`). QA: in `file-anim-bas.sh` (exact PNG, the
blob = the DATA player's minus the cells, `--frames` started from `/`, gutter / margin
rects, the document clash).
**Batch CLI** (3.7, `OUTPUT/BATCH`): `--export` / `--export-anim` collect CHR$(0) lists and
run in order (repeatable). `BATCH_export%`: `.apng` / `.json` / `.sheet.bas` go to the frame
exporters from either flag (before the `KILL path` - out.png is never written there, and may be
the document); `--export-anim` `.png` = PNG sequence, `.gif` / `.bas` = the frames when there
are any; `--export` `.png` = `LAYERS_flatten&` saved, `.gif` / `.bas` = the colour cycle.
`BATCH_say` prints one console line per export (`CLI_begin`, `_DEST` saved and put back):
`wrote PATH  (ANIM_EXPORT_INFO)` / `FAILED PATH: why` (colours only on a terminal). Exit 1 if
any failed. Needs a display (it runs on the first frame of DRAW's window). QA:
`file-anim-batch.sh`.
**Known (pre-existing):** `LAYERS_flatten&` composites with `_BLEND` onto a transparent
image, which darkens the colour of a partly transparent pixel (rgb x alpha); every export
inherits it. The APNG keeps the alpha level itself.

## Full-screen Preview (`TOOLS/ANIM-FS`, 3.6)

`ANIM_FS_show` (action 2539, Num ., ANIM menu, command palette) is a modal loop of its own,
like the Pixel Analyzer: `_COPYIMAGE(0)` saved and put back, `POINTER_hide_for_dialog` /
`MOUSE_cleanup_after_dialog`. It plays `LAYERS_flatten&` (what exports) in
`ANIM_play_order%` with the holds at the FPS, from the current frame, playing; colour cycling
through `PCYC_present&` each frame. Drawn in physical px (`_WIDTH(0)`), laid out in logical
(`SCRN.displayScale%`): the frame at a fit zoom (whole numbers when it fits) over a checker
(`ANIM_FS_checker&`, one pixel a square, scaled x8), a 30 px status bar image (seek bar + one
line, `_FONT 8`) scaled up. Wheel zooms about the pointer; middle press twice < .4 s = 100%;
middle drag pans; a left press on the bar scrubs (pauses). Keys from `_KEYHIT` (the main loop
is not running, so it is not drained): ESC, SPACE / Enter, LEFT / RIGHT / HOME / END and the
Num Lock-on digits 4 5 1 9; Num . closes by `NUMPAD_held%(11)` on a fresh press (its
`_KEYHIT` code is 46 or 21248 by Num Lock). **On close** the closing key must not reach DRAW:
`_KEYHIT` and `INKEY$` drained, `NUMPAD_resync` (NP_HELD = now, NP_T cleared, device queue
dropped) - else a Num . still down is a new press to `NUMPAD_poll` and reopens it - and for a
Num . close its late twins marked dropped (`ANIM_SW_*`), then `KEYBOARD_SUPPRESS_FRAMES% = 3`.
It goes to the frame shown (`ANIM_go%`). QA dump: `ANIM_FS_dump_write` appends `ANIMFS open
step frame playing zoom% x y w h barX barY barW barH steps` (logical px) to `DOCK_DUMP_LAST`
while open; on close `DOCK_DUMP_LAST = ""` makes the main loop rewrite it without.
QA: `anim-fullscreen.sh` (open / play / pause / steps / seek click + drag / wheel / double
middle 100% / middle-drag pan / ESC on the frame shown, each checked by the colour on
screen at the frame's middle; ESC does not deselect; Num . open + close).

## X-sheet (`TOOLS/ANIM-XS`, 4.1)

**Layer controls (F5, field kit T-22):** the name column starts with an eye (`XS_EYE_X`) and
a lock (`XS_LOCK_X`, the alpha lock `opacityLock`; none on a group), the name at
`XS_ICONS_W`, and ends with an opacity box (`ANIM_XS_op_x%`, 0 when the column is too narrow;
`nameW` makes room). The layers panel's icons (`LAYER_PANEL.iconVis* / iconLock*`) and
routines (`LAYERS_toggle_visibility` / `_toggle_group_visibility` / `_toggle_opacity_lock` /
`_set_opacity` - not undo steps there either). `ANIM_XS_ctl_press%` runs first in
`ANIM_XS_press%`; the opacity box: wheel +/- 5 % (Shift 1 %, in `ANIM_XS_wheel%`), a press
sets `oSlot` and `ANIM_XS_op_hold` (from `ANIM_LB_mouse`) drags 1 % a px (up = more) or, on a
release without moving, asks the number (`DRAW_input_box_ex$`). A right press on a layer row
sets `rSlot`; on the release over the same row `LAYER_PANEL_ctx_menu_show` opens the layers
panel's menu - on the release, because `MOUSE_handle_layer_panel` checks presses for an open
menu later in the same frame. Dump `ANIMXSL eyeX lockX opX opW` + per row `slot visible lock
opacity%`. QA: `anim-xsheet-layer-controls`.

A mode of the lightbox's top band (`CFG.XSHEET`, DRAW.cfg `XSHEET`): `ANIM_LB_layout` gives the
band `ANIM_XS_band_h%` (header + every layer row + holds row, `FPANEL.rowH + 6` each, at most half
of what the bar leaves) and calls `ANIM_XS_layout`; `ANIM_LB_render` draws `ANIM_XS_render`
in place of the strip (`GOTO LbBar`); `ANIM_LB_strip_at%` returns 0 and the strip wheel goes to
`ANIM_XS_wheel%`; a left press goes to `ANIM_XS_press%` before the strip. Toggle 2540 from sheet
view turns the lightbox on first (`ANIM_LB_toggle`, its busy refusals). Columns are ticks:
`ANIM_XS_frame_x%(f)` = gx + the holds from `firstF`; a frame spans hold x `tickW` (`tickW` =
the thumbnail of the frame's shape at `rowH - 2`, + 3). Rows = the layers panel's order
(zIndex high first, `LAYER_PANEL_row_hidden%` skipped, groups as label rows, depth indent),
`ANIM_XS_rows_build`. A cell is drawn when the layer has a pixel with alpha > 0 in it
(`ANIM_XS_scan%`, `_MEM`, apron offset); cached per slot in `ANIM_XS_FILL()` and dropped when
`HISTORY.current / count`, `UNDO_SEQ`, `ANIM_serialize$`, the canvas size or `LAYER_COUNT`
change (`ANIM_XS_cache_check`, once a render / dump); the current layer's current cell is
rescanned every render (live strokes). Thumbnail = the transparency blueprint + the layer's
cell `_PUTIMAGE`d at the span's start, a hold line to the end. Click: cell = `ANIM_SEL_click`
+ `LAYERS_select` (`LAYERS_select_group` for a group); name = the layer; header / holds = the
frame. Wheel: frames by a quarter of those shown; Shift / over the names: rows. Current frame
/ layer scroll into view when they change.
**Editing (4.2):** a plain press sets `ANIM_XS.dMode` (`XS_DRAG_HOLD` holds row / `XS_DRAG_CELL`
a drawn pixel-layer cell / `XS_DRAG_FRAMES` header); `ANIM_LB_mouse` then routes every frame to
`ANIM_XS_hold` until the release (4 px = a drag; else the click it already was). Hold: live
`ANIM_set_hold` = hold at press + ticks dragged, `ANIM_XS_BEFORE` snapshot (no pixels) at drag
start, one `ANIM_OPS_record` "Frame Hold" at release. Cell: target frame + row slot, outlined
(`+` with Ctrl); release = `ANIM_XS_drop`: refuses text / symbol copies / groups, same-on-every-
frame layers and `ANIM_OPS_busy$`; whole-sheet snapshot before/after, cell copied through a
`_DONTBLEND` scratch, source cleared unless Ctrl at the drop, target cleared then put,
`ANIM_XS_touched` (contentDirty, apron cache, symbol parent), "Move / Copy Drawing", target
current. Frames: `ANIM_XS_drop_slot%` (left half of a span) -> `ANIM_MOVE_TO` +
`ANIM_OP_MOVE_SEL` (holds travel with their frames); a plain press on a multi-selection
collapses on a click release. Past the grid's ends a cell / frame drag scrolls a frame / 0.25 s.
Dump `ANIMXSD mode on frame slot to toSlot`. QA: `anim-xsheet-edit.sh`.
QA dump: `ANIMXS on shown x1 y1 x2 y2 nameW rowH tickW gx firstF lastF nRows firstRow
rowsShown currentLayer`, `ANIMXSF f x w ...` (spans), `ANIMXSR r slot y fill` (fill = 1 / 0 per
frame, `-` a group; y -1 scrolled out). The chip is `ANIMLBC` pair 15. QA: `anim-xsheet.sh`.

## Linked cells (4.3, Q-03 / R-05)

Table in `TOOLS/ANIM.BI`: `ANIM_LK_ID / F / G (1..ANIM_LK_N)` = layer historyId's cell in frame F
is in group G (a number per layer); the lowest frame of a group is its source, the rest are
links (`ANIM_LK_is_link%`). Helpers in `ANIM.BM`: `_group% _source% _remove _put _new_group%`,
`ANIM_LK_tidy` (drops groups left with < 2 cells / frames past count), `ANIM_LK_remap` (called
from `ANIM_apply_plan`: each entry moves to the first new frame whose `ANIM_SRC` is its old
frame - a duplicate copy is not linked; deleted frames drop out). Serialized in
`ANIM_serialize$` as drAn **v3** only when links exist (so every frame-op snapshot carries
them: undo / redo restore links with the pixels); `ANIM_reset` clears them, `ANIM_LK_prune`
on load (DRW.BM, beside `ANIM_LF_prune`).
**Sync** (`ANIM-OPS.BM`): `ANIM_LK_tick%` runs inside `ANIM_SAME_tick%` (once a frame, waits
for buttons / a float / transform) when `ANIM_SAME_CHECK` (an undo step added / undone /
redone): each group's cells are merged against its picture (`ANIM_px_merge%`: differing pixels
win) and written to every cell - a stroke on any linked cell lands on all of them, its undo /
redo too. Pictures (`ANIM_LKP_*`) are rebuilt from the source cells when `ANIM_LK_SIG`
(layout + table) changes, without writing cells. SAME layers are skipped.
**Making links:** `ANIM_LK_action` 2541: selected frames (>= 2) join the first selected one's
group, else the current frame joins the frame before (`ANIM_LK_join`: pixels = the source
cell's); 2542 removes the selected / current cells (pixels kept, snapshot without pixels).
`ANIM_LK_refusal$`: frames, a pixel layer, not SAME, not busy. X-sheet: Shift at a cell drop
(same row) = `ANIM_XS_drop_link`; a plain / Ctrl drop first unlinks the cell landed on (and a
moved cell), so only it changes. **Hatching:** `ANIM_LK_hatch` (45-degree lines, fixed phase)
over the current layer's links in `ANIM_VIEW_render_grid` (sheet view, with the frame grid)
and over a link's first tick in the X-sheet. QA dump `ANIMLK entries map` (current layer: "."
/ a letter per group, upper case = source). QA: `anim-links.sh`.

## Tags (4.4, Q-20)

Named frame ranges in `TOOLS/ANIM.BI`: `ANIM_TG_NAME / A / B (1..ANIM_TG_N)`, at most
`ANIM_TG_MAX` 64, names trimmed to 32 and unique ignoring case; ranges may overlap. Pure helpers
in `ANIM.BM` (unit-tested): `ANIM_TG_find%`, `ANIM_TG_put%` (a name that exists moves that tag;
`ANIM_TG_set` = the SUB form - QB64 rejects a SUB and FUNCTION of one name), `_remove`,
`ANIM_TG_at%` (the shortest tag holding a frame), `ANIM_TG_selected%` (the tag whose range IS the
selection, nothing selected = the current frame), `ANIM_TG_select` (its frames, the first
current), `ANIM_TG_remap` (from `ANIM_apply_plan`: a tag spans the new frames showing its old
ones - frames put inside join it; none left = it goes). Saved as drAn **v4** only when tags exist
(so frame-op snapshots / undo carry them); `ANIM_reset` clears them.
**Actions** (`ANIM-OPS.BM` `ANIM_TG_action`): Tag Frames 2543 asks a name in
`DRAW_input_box_ex$` (Enter in its field submits) for the selected span (or the current frame);
the box starts with the selected tag's name (a new name renames it - another tag of that name
goes) or the first free `tagN`. Delete Tag 2544: the selected tag, else `ANIM_TG_at%(current)`.
One undo step each (`ANIM_OPS_snapshot$(FALSE)`).
**X-sheet:** a TAGS row under HOLD only while tags exist (`ANIM_XS_tag_rows%`: band height and
`rowsShown` make room; band row `rowsShown + 2`): a bar per tag (`ANIM_XS_tag_span%`), the
selected one bright; a press on it selects the tag (`ANIM_TG_select`), so Play (which plays a
selected span) plays the tag.
**Exports:** `ANIM_play_order%` covers `ANIM_EXP_A..ANIM_EXP_B` when set (0 = all). The GUI
wrapper `ANIM_EXPORT_action` sets it from `ANIM_TG_selected%` when that tag has 2+ frames (not
the sprite sheet), calls `ANIM_EXPORT_run`, then clears it; the report adds `- tag NAME`
(`ANIM_EXPORT_note$`). GIF / APNG / PNG sequence write only those frames; the BAS players keep
every frame's pixels and play the tag's order. The sprite sheet always has all frames: its JSON
`frameTags` lists the tags (from 0, Aseprite style; none = one "all") and its .bi
`CONST <SHEET>_TAG_<NAME>_FROM / _TO` (from 1). Full-screen Preview plays the selected span (2+
frames) like Play. Batch `--tag NAME` (OUTPUT/BATCH, a 2-token flag skipped in `DRAW.BAS`'s
file-argument scan) sets the range for every export of the run; an unknown name prints
`FAILED --tag NAME: no such tag (the document has: ...)` and exits 1 before writing anything.
QA dump `ANIMTG n selected [name from to]... _` (spaces in names as `_`), and `ANIMXST rowY
[k xa xb]...` from the X-sheet. QA: `anim-tags.sh` (24), unit checks in `anim-unit.bas`.
Palette matching is a plain subsequence test in registration order (no ranking): keep command
descriptions from swallowing other names' letters ("name the selected frames" matched "frame
note" and won).

## Frame notes (4.5, Q-31)

`ANIM_NOTE(1..ANIM_MAX_FRAMES)` in `ANIM.BI`, a line of text per frame (`ANIM_NT_set`: control
characters dropped, trimmed, at most `ANIM_NOTE_MAX` 80; "" clears). `ANIM_NT_count%`,
`ANIM_NT_remap` (from `ANIM_apply_plan`: a note goes to the first new frame showing its old one -
a duplicate has none, deleted frames' go). drAn **v5** only when a frame has one (every earlier
block written, counts may be 0); `ANIM_reset` clears them. **Actions** (`ANIM_NT_action act,
frame`): Frame Note... 2545 = `DRAW_input_box_ex$` with the frame's note (an empty answer or
Cancel changes nothing); Clear Frame Note 2546 = the selected frames' notes (`ANIM_SEL_is%`).
One undo step each. **X-sheet:** a NOTES row (after TAGS) while any frame has a note
(`ANIM_XS_note_rows%`, `ANIM_XS_extra%` = the rows under HOLD, `ANIM_XS_tags_k%` /
`ANIM_XS_notes_k%`): each note from its frame's start until the next noted frame, a mark where it
starts. A click = the frame (Ctrl / Shift as the strip) + the note on the status bar; a
double-click = Frame Note... for that frame - two presses on one frame within 0.45 s, or two
main-loop passes apart (`ANIM_LOOP_TICK`, counted in `DRAW.BAS`) when frames are slow. QA dump
`ANIMNT n [frame note]... _`, `ANIMXSN y`. QA: `anim-notes.sh` (18; on the 3x user profile the box
takes over a second to come up after a double-click - the test waits 2 s before typing).
**Tooltips (F7):** hovering a tag bar or a note shows its whole text (the rows cut them to fit):
`ANIM_XS_tip%` (id 1000 + tag, 2000 + frame) feeds `TOOLTIP_update` as `TOOLTIP_SRC_ANIM_XS`
(13), checked first while the pointer is on the band; the text rides `TOOLTIP.DYNAMIC_TEXT$` (two
lines). QA: `anim-xsheet-tips.sh` (dump `TIP active source idx`).

## Imports (`TOOLS/ANIM-IMPORT`, phase 5)

**Animated GIF (5.1):** `DRW_load` tries `GIF_load_cycling%` first (only GIFs with CRNG /
DRAWCYCL ranges: indexed, first image), then `ANIM_GIF_import%`: `ANIM_GIF_count%` walks the
blocks; 2+ images = a sheet. Grid: `cols = INT(SQR(n - 1)) + 1` (inside `ANIM_SHEET_MAX`), refused
(plain first-frame load) past `ANIM_IMP_MAX_PIXELS`. Canvas + palette via `CYCX_adopt_begin` (the
GCT, else the first LCT; neither = `DRW_create_canvas_at_size`), so all three document paths'
resets apply. Decode: an RGBA "logical screen" string, each image drawn over it (its GCE's
transparent index leaves pixels), the screen copied into cell k (`_MEMPUT` per row), then the
disposal: 2 = its rect back to transparent (browsers, not the background colour), 3 = the screen
from before it. Interlace via `ANIM_GIF_deinterlace$`; LZW = `GIF_lzw_decode$` (FILE-GIF).
Timing: `ANIM_GIF_fps%` - delays < 2 cs count as 10, FPS = 100 / their gcd (max 50, lower while a
hold would pass `ANIM_HOLD_MAX`), hold = delay at that FPS. NETSCAPE / ANIMEXTS block = FWD, none
= ONCE. **Saving back:** `SAVE_flat_write%` (Ctrl+S with `SAVE_DRAW_SIDECAR` off, Flatten & Save)
writes a .gif of a document with frames as an animated GIF at 1x (`ANIM_GIF_export%`, export scale
forced to 1 for the call). QA: `file-anim-gif-import.sh` (13): plain / optimised (sub-rects) /
disposal previous + background over transparency, each frame vs `magick -coalesce` (fully
transparent pixels normalised with `-alpha background` - ImageMagick keeps their RGB), no loop
block = once, a single image = a picture, Ctrl+S round trip. Note ImageMagick's `-layers
Optimize` of a transparent GIF drops the transparency and its coalesce then starts from the
background colour, which browsers don't - use opaque frames for optimised fixtures.

**Aseprite (5.2):** `FILE_ASE_load` (INPUT/FILE-ASE) asks `ANIM_IMP_grid%` (the GIF grid, shared)
for a sheet when the header has 2+ frames; the canvas is then cols x rows sprite-size cells and each
image layer gets `load_layer_frame_image&(base, layer, f)` (QB64_GJ_LIB, frame f only, linked cels
load the frame they link to) `_PUTIMAGE`d into cell f with `_DONTBLEND` (pixels as they are).
`aseLayerOf$` = MKI$ per Aseprite layer: the DRAW layer it became (groups / tilemaps 0). After
`ANIM_reset`: `ANIM_set_layout%(spriteW, spriteH, 0, 0)`, count = frames, then `ANIM_ASE_apply`
reads the file itself (the library uses the header speed for every frame): frame durations (ms) ->
`ANIM_IMP_fps%(d(), n, 1000)` (the GIF timing rule with perSec 1000; 0 ms = 100) + holds; the Tags
chunk 0x2018 -> `ANIM_TG_put%` (0-based from/to + 1), a tag over every frame sets the loop
(direction 1 = REV, 2/3 = PING; else FWD); cel type 1 (linked) -> `ANIM_LK_put` on that layer's
historyId, grouped with the frame it links to. Cel opacity / z-index are not applied. QA:
`file-anim-ase-import.sh` (11; fixtures written by the test): frames / FPS / tags / links in the
dump, the PNG sequence vs the expected frames (offset sub-rect cel, linked cels, holds), a
ping-pong tag over all = loop 2, one frame = a picture. `file-aseprite-frames.sh` now reads frame
1 from the top-left cell of the 32x16 sheet.

**Sprite sheets (5.3).** *Frame data on open:* `DRW_load_from_png` (flat image, no drAn) calls
`ANIM_SHEET_import%`: `name.json` beside it (Aseprite Export Sprite Sheet array or hash,
TexturePacker hash, DRAW's own `ANIM_SHEET_export%`), read with the small `ANIM_JS_*` walker
(`_ws& / _end& / _next% / _get$ / _str$ / _num&` - no full parser; just values by key). Refused
when meta.image names another file or a frame lies outside the image. All frames untrimmed, one
size, unrotated, and exactly where `ANIM_set_layout%(w, h, gutter, margin)` puts them (margin =
frame 1's x = y, gutter from the next frame on its row, else the next row) = sliced in place;
otherwise laid out again (`ANIM_IMP_grid%` of the largest sourceSize, `ANIM_OPS_resize_keep_view`,
each rect `_PUTIMAGE`d at its spriteSourceSize offset; rotated = TexturePacker's quarter turn
clockwise, undone per pixel: sprite (x, y) = atlas (fx + h - 1 - y, fy + x)). durations ->
`ANIM_IMP_fps%(.., 1000)` + holds (else meta.fps); frameTags -> tags (a full-range tag sets the
loop; `repeat "1"` = ONCE); DRAW's own "all" tag (written when there are none) is dropped and its
meta.loop applies. *Detect Frames (2547):* `ANIM_DT_action` flattens, marks drawn pixels (alpha >
0, or <> the top-left colour on an opaque sheet), fills each 8-connected blob's extent into the
column / row masks (blobs only up to 4 M pixels, else raw columns), then the pure
`ANIM_DT_solve%` (ANIM.BM, unit-tested): first `ANIM_DT_tight%` - runs of equal size with equal
gaps and equal ends, gaps and ends <= a quarter of the cell, both axes sharing them = that grid;
else search margin / gutter 0..16 and cells per axis (<= runs, cells filling the span exactly,
`ANIM_DT_axis%`: every run inside one cell, `ANIM_fit%` gives that many) for the most cells,
then the smallest margin + gutter. An axis of one cell takes the other's gutter. Frames = up to
the last cell drawn in. One undo step (`ANIM_OPS_record`, no pixels). Emptiness alone can't tell
a gutter from a sprite's padding, so a padded sheet with gutters comes out as bigger cells
holding the same sprites in the same order. QA: `file-anim-sheet-import.sh` (17) + the unit test.

**PNG sequence (5.4).** `ANIM_SEQ_files%`: the number is the last digit run before the extension;
siblings (one `_FILES$` sweep of the folder) with the same prefix and suffix (case-insensitive)
and 1-12 digits there, sorted by value (so walk10 follows walk9). `ANIM_SEQ_import%` loads every
file twice - pass 1 for the largest size and repeats (a file whose pixels equal the previous
one's adds a tick to that frame, up to `ANIM_HOLD_MAX`), pass 2 `_PUTIMAGE`s each kept file
`_DONTBLEND` into its cell (top left) - on a `DRW_create_canvas_at_size` document (untitled: Ctrl+S
asks a name, never overwrites frame 1). FPS stays the default (files carry no timing). Entry
points: ANIM > Import PNG Sequence... 2548 (`DRAW_open_file$`, pick any file) and `--sequence`
(`ANIM_SEQ_CLI`, scanned at include time in ANIM-IMPORT.BI; the deferred command-line load tries
it first and falls back to a plain open). QA: `file-anim-seq-import.sh` (9): padded with a
repeat + non-frames beside it, unpadded 1-10 with a smaller file, round trip through
`--export-anim` PNGs, no number / alone = a picture.

**Soundtrack (L.1, R-12 B).** `TOOLS/ANIM-SOUND`. One sound per document: `ANIM_SND_PATH` (as
picked) + `ANIM_SND_OFS` (ms into the sound where frame 1 starts; no UI yet, always 0), both in
drAn v6 and in the undo snapshot (`ANIM_OPS_snapshot$` -> `ANIM_serialize$`), cleared by
`ANIM_reset`. Frame f starts at `ANIM_SND_time#(f)` = the earlier frames' holds / FPS + offset
(sheet order). *Opening:* `ANIM_SND_sync` (from the tick) opens lazily whenever the path differs
from what is loaded (`ANIM_SND_resolve$`: the path, else the same file name beside the document)
with `_SNDOPEN(f, "noasync")` - QB64-PE decodes in the background by default, and `_MEMSOUND`
then reads a half-filled buffer (a flat waveform, on some runs only). MIDI gets
`_MIDISOUNDBANK CFG.MIDI_SF2_FILE$` first when one is set. `ANIM_SND_peaks`: the loudest sample
per 1/100 s from `_MEMSOUND(h, 0)` (INTEGER / LONG / SINGLE / unsigned byte; every `stride`-th
sample on a long sound), scaled so the loudest is 255. *Playing:* `ANIM_SND_tick` (DRAW.BAS,
after `ANIM_play_tick%`) applies `CFG.ANIM_SOUND_VOLUME` (0-100, cfg only; QA pins 0) and calls
`ANIM_SND_follow cur, playing`, which the full-screen preview's modal loop calls too: playing,
the next frame runs on (re-seeked only when `_SNDGETPOS` drifts more than 0.1 s + a frame), any
other frame - a loop back to 1, a jump, ping-pong's way back - `ANIM_SND_play_at` its time;
stopped, a frame change plays just that frame's slice (hold / FPS, at least 0.06 s; `STOP_AT`),
and playback stopping stops it. *X-sheet:* a SOUND row under the notes (`ANIM_XS_sound_rows%`,
`ANIM_XS_sound_k%`), one waveform line per pixel over each frame's span (the bins it covers; the
current frame brighter); no peaks = the file name, "(not found)" when it did not open. Clicking
the row picks that frame (= a scrub). *BAS player:* `ANIM_BAS_sound$` copies the file beside the
.bas as `NAME-sound.EXT` (never a user file of the sound's own name; not found = left out, said in
the export line); the player opens it there or beside the program, `snd_follow` mirrors
`ANIM_SND_follow` (and is quiet at any speed but 1x), `--frames` adds `sound.txt` (file, found,
length ms, then per step: step, frame, its time ms). Dump: `ANIMSND open on starts lastStartMs
lenMs peaks name` (name "-" = none), `ANIMXSS rowY`, and `ANIMFS ... sndStarts sndLastMs sndOn`.
QA: `anim-soundtrack.sh` (28; a -60 dB WAV, volume 0), the unit test (v6 round trip).

**Sound files dropped, empty tracks (2026-11-09).** The X-sheet always has a SOUND row:
`ANIM_XS_sound_rows%` = `ANIM_SC_rows%` = max(1, `ANIM_SC_track_n%`, `ANIM_SC_XTRA`) capped at 4.
`ANIM_SC_XTRA` (ANIM.BI, never saved; reset in `ANIM_reset` only when not `ANIM_SB_KEEP`, so undo
keeps it; Remove Soundtrack zeroes it) is the empty rows asked for by Add Empty Track (2560). An
empty track draws the hint "drop a sound file here, or right-click" (`CP_text_dim`). Remove
Track (2561, `ANIM_SC_drop_trk%`) takes a track's clips away and moves higher tracks up; undo is
recorded when the snapshot changed (an empty track between clips moves them). New tracks
(Soundtrack... with sound, Add Sound on a New Track, a drop off a SOUND row) use
`ANIM_SC_free_trk%` = the first track with no clips. *Drops:* `DROP_handle_dropped_file` sends a
sound file (`ANIM_SND_is_sound%`, the Soundtrack... extensions) to `ANIM_SND_drop_file` before
any other route (never an image import or a new window): on a SOUND row that track from the
start of the frame under the pointer; elsewhere on the X-sheet a new track from that frame; off
it a new track from the current frame; a plain picture says to make frames first. Both the
dialog and the drop go through `ANIM_SND_add_list%` (one undo step). *QA:* with `DOCK_DUMP` set,
`DROP_qa_poll` (main loop, every 0.2 s) reads a path from `<DOCK_DUMP>.drop`, deletes it and
queues it like an OS drop - `anim-sound-drop.sh`. The sound palette entries are registered after
the frame ones and say "span", not "frames", so "delete frame" / "copy frame" find the frame
commands (F6 shipped "Delete Sound (... the selected frames' sound ...)" first, which caught
"delete frame").

**Sound clips and tracks (F6, field kit T-28).** Since F6 `ANIM_SND_PATH` / `_OFS` are gone: the
soundtrack is `ANIM_SC_*` in `TOOLS/ANIM.BI` (so the unit test sees it) - up to `ANIM_SC_MAX` (32)
clips, each PATH, TRK (1..`ANIM_SC_TRACKS` = 4), AT (timeline ms; 0 = frame 1's start), IN (ms
into the file), LEN (ms; 0 = to the file's end), plus FMS (the file's length as ANIM-SOUND found
it; not saved; 0 = unknown, then a to-the-end clip ends at `ANIM_SC_FOREVER`). Pure ops in
ANIM.BM: `ANIM_SC_add% / _remove / _clear / _end& / _split% / _cut% (trk, a, b) / _copy% /
_copy_clip / _paste% / _track_n% / _text$`; the sound clipboard is `ANIM_SCB_*` (pieces at ms
from the span's start + SPAN). A cut never ripples later sound; a paste first cuts its span.
*Saving:* the v6 block is clip 1 (ofs = IN - AT, so an older DRAW plays it); a v7 block (n, then
trk at in len pathLen path per clip) follows only when the clips are not "one clip on track 1 from
0 to the end" - so the simple case stays v6 (`anim-soundtrack.sh` checks `0600`). v7 replaces
v6's clip on load. *Playing (ANIM-SOUND):* `ANIM_SS_*` caches each file once (opened noasync, ms,
peaks at `ANIM_SND_PK(PK0..)`), reopened when `ANIM_SS_want$` (document folder + the sorted
paths) changes. `ANIM_SND_build` (when the clip signature changes, not while `ANIM_SC_DRAG`):
one clip with LEN 0 plays its file's own handle with `ANIM_SND_BASE = (IN - AT) / 1000` (MIDI /
trackers keep working); anything else is `ANIM_SND_mix` - a `_SNDNEW(frames, 2, 32)` at
`_SNDRATE` from frame 1's start, each readable clip's `_MEMSOUND` samples added in (mono spread
to both), clamped to +-1 when more than one; unreadable clips are skipped
(`ANIM_SND_SKIPPED`). A mix is ours to close (`ANIM_SND_MIXED`); `ANIM_SND_drop` never closes a
file's handle. `ANIM_SND_time#(f) = ANIM_SND_frame_ms#(f) / 1000 + BASE`. Up to 10 minutes are
mixed (`ANIM_SND_MIX_MAX_S`). *X-sheet:* a SOUND row per track (`ANIM_XS_sound_rows%` =
`ANIM_SC_track_n%`, `ANIM_XS_sound_trk%(k)`); timeline ms <-> x is linear (`ANIM_XS_ms_x%` /
`ANIM_XS_x_ms#`, ticks before `firstF` = `ANIM_XS_t0%`); a clip is a tinted block to the grid's
end with its waveform (`ANIM_SC_peak%`) or its file name, the picked one outlined in
`ANIM_FRAME_drawing`. A left / right press on a row (`ANIM_XS_sound_press%`) picks the clip,
sets `ANIM_SC_TRACK`, `ANIM_SC_FOCUS` and `ANIM_SC_MENU_T` (the pressed frame's start); a plain
left press on a clip starts `XS_DRAG_SOUND` (`ANIM_XS_sound_drag`: + ms dragged, `ANIM_SC_snap&`
to a frame start unless Shift, the row under the pointer = the track; one "Move Sound" undo on
release). A right release opens the lightbox popup as `menuKind = 1` (`ANIM_SC_menu_build`, item
values = action ids; `ANIM_SC_FROM_MENU` makes Paste / Split act at MENU_T). *Keys:*
`INPUT_dispatch_frame` asks `ANIM_SC_key%` first while focused (Ctrl+C / X / V, Delete,
Backspace -> 2554-2557, so the canvas never sees them); `ANIM_SND_tick` drops the focus on Esc
(`_KEYDOWN` edge - Esc is not a dispatcher event) or on a press anywhere but the rows (unless the
rows' menu took it: `ANIM_SC_KEEP`). The keys act on `ANIM_SC_span%` (more than one frame
selected: their span of the focused track) else the picked clip. Adding (`ANIM_SND_add_files%`)
uses the multi-select dialog: files laid one after another. *BAS:* a single to-the-end clip is
copied as before (`ANIM_BAS_SND_OFS`); otherwise `ANIM_SND_write_wav%` writes the mix as
`NAME-sound.wav` (16-bit stereo) with SND_OFS 0. Dump: `ANIMSC n sel track focus mixed skipped
clipN clipSpan dragging` + per clip `trk at in len end`; `ANIMXSS` = every SOUND row's y;
`ANIMXSC clip xa xb`; `ANIMSCM x y w` + `action y` per pickable item while the menu is open;
tooltip id 3000 + clip. QA: `anim-sound-edit.sh`, the unit test (clip ops, v6 / v7 rules).

## A selection stays put in its cell (2.9, Q-18)

`ANIM_SELBOX_watch` (main loop, before `ANIM_SAME_tick%`): when `ANIM.current` changed since
the last frame - keys, strip, playback, a frame op or its undo - and the selection's bbox
(`MARQUEE.BOX`, or `WAND_MIN/MAX` for a mask) lies inside the cell of the frame it was on, it
moves by the cell offset (`ANIM_SELBOX_shift`: box + mask + wand bounds, `WAND_EDGE_DIRTY`, as
`MOVE_apply_transform` shifts a moved float's mask). It stays when it spans cells (Select All),
or is being drawn / moved / resized, or floats (Move, Transform). Not an undo step: the
selection's own undo steps swap with whatever is live. QA: `anim-selection-follow.sh`
(`ANIMSEL active boxX boxY boxW boxH wand minX minY maxX maxY`, written with `ANIMLF`).

## The frame selection (`TOOLS/ANIM`, 2.3)

`ANIM_SEL()` + `ANIM_SEL_ANCHOR`: pure state, unit-tested. `ANIM_SEL_is%` (nothing selected =
the current frame is), `ANIM_SEL_count%`, `ANIM_SEL_click f, ctrl, shift` (plain: current +
only one; Ctrl: toggle, current when it goes in, the nearest selected when the current leaves;
Shift: anchor..f, Ctrl+Shift adds; Ctrl and plain set the anchor), `ANIM_SEL_span a, b` (first..
last when 2+ selected - Play plays that span, R-20), `ANIM_SEL_clear`. `ANIM_apply_plan` carries
the selection with the frames through every op (a new frame is unselected); `ANIM_reset` and an
undo / redo of a frame op (`ANIM_OPS_restore`) clear it. Not saved, not an undo step.
`ANIM_OP_MOVE_SEL` (10, no action id): unselected frames before `ANIM_MOVE_TO`, the selected in
order, the rest. `ANIM_OP_SET_COUNT` (11, no action id): `ANIM_COUNT_TO` frames. 2.5 / 2.7 act on this selection.

## Saved

The `drAn` PNG chunk (`draw-fileformat.md`; v2 adds the layer flags), read from .draw and plain PNG. The ask answer
and playback are not saved. Config: `FRAME_GRID`, `PREVIEW_SHOWS_FRAME`, `LIGHTBOX`, `LIGHTBOX_PANES`, `XSHEET`,
`CLIP_FRAME_LIGHTBOX`, `CLIP_FRAME_SHEET`,
`ANIM_PANEL_VISIBLE / _X / _Y`. Theme: `THEME.ANIM_FRAME_border / spare / current /
label_fg / label_bg`.

**Document paths:** `ANIM_reset` in all seven (`DRW_load_binary`, `DRW_new_canvas`,
`DRW_create_canvas_at_size`, `FILE_ASE_load`, both PSD paths, `DRW_load_from_png`;
gotcha 15). It also stops playback and clears the ask answer.

## QA

- Dump lines (`DOCK_DUMP`, written by `DOCK_dump_state$`):
  - `ANIM active count current frameW frameH gutter margin cols rows fps loop gridDrawn dx dy canvasW canvasH playing previewFrame`. `dx dy` is the canvas origin on screen when the grid is drawn.
  - `ANIMC` + per frame (<= 64): `0` for an empty cell, else the CRC32 of its pixels on every moving layer. Use it to check where drawings went.
  - `ANIMP visible docked x y w h scale% hold sizeMode pendRow`
  - `ANIMLB shown x1 y1 x2 y2 stripY stripH barY barH edY edH stripFirst stripN cellW cellH panes paneW paneH pad drawPane`, `ANIMLBC` + `x w` per transport control (1 `|<` .. 5 `>|`, 6 loop, 7 time, 8 FPS, 9 seek, 10 count, 11-13 copy / paste / cut, 14 `+`; w = 0 dropped), `ANIMLBP clipLightbox clipSheet` + `frame dx dy dw dh` per pane (its picture), `ANIMLBS dragging dropSlot anchor nSelected` + the selected frames (<= 64), `ANIMLBE editing confirmTo menuOpen menuHover seekHeld menuX menuY menuW text` (`-` = empty).
  - `ANIMPL nav r1..r6 loop rowH minusX plusX chipW pad panelW ops mode onion on1..on3 onionBefore onionAfter onionOpacity` (native px but the last three; viewport = disp + native * scale% / 100). The nav row has 5 chips (`|< < PLAY > >|`), the others 4, and the mode row 2.
- Tests: `anim-frame-grid`, `file-anim-chunk`, `anim-numpad-keys`, `anim-menu`,
  `anim-panel`, `anim-panel-spinners` (number boxes: wheel / Shift, middle click, drag, click to type, undo), `anim-frame-ops`, `anim-frame-start`, `anim-playback`, `anim-lightbox` (pane / strip contents checked by each frame's mark colour in the snapshot; the floating Preview painted out), `anim-lightbox-draw` (pane clicks / strokes / rectangles land in their frame's cell - checked with `ANIMC`; the same canvas pixel as a sheet-view click; clip on / off in both views; undo), `anim-lightbox-strip` (click / Ctrl / Shift selection, tint, Play plays the span, drag reorder of a selection / a single frame with `ANIMC` order, the drop marker, undo, wheel scroll), `anim-lightbox-bar` (loop menu, FPS spinner + wheel + undo, seek scrub, count box typing / numpad / Esc / shrink question). Unit:
  `QA/unit/anim-unit.bas`. Fixtures are built in the test with `magick` +
  `QA/fixtures/png-chunk.py put`. Run on the user profile too (`QA_USER_PROFILE=1
  QA_USER_SCREEN=1152x712@3 QA_XVFB_RES=3840x2400`); that layout has no Preview window.
- `assert_regions_differ` takes the snapshot **file paths** (`$SNAP_RESULT`), not labels.
  `snap_region` takes ~1.3 s, so don't time playback with it.

## Gotchas met here

- Reserved words as names: `on`, `off`, `key` (gotcha 20).
- In a unit test, `STR$(f%(x)) + STR$(global)` may read the global before the call (C++
  argument order). Call into a variable first.
- A harness script error (`set -u`) still reports PASS. Count the checks after a change to
  a test's dump parsing (e.g. a new field caught by the last `read` variable).
