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

## Files

| File | Role |
|---|---|
| `TOOLS/ANIM.BI/BM` | State + pure math: layout (`ANIM_set_layout%`, `ANIM_cols/rows/cells%`, `ANIM_cell_rect%`, `ANIM_rect_at`, `ANIM_span&`, `ANIM_frame_at%`), holds, stepping, `ANIM_serialize$ / ANIM_deserialize%`, frame-op planner (`ANIM_plan%`, `ANIM_op_refusal$`, `ANIM_sheet_h&`, `ANIM_apply_plan`), playback (`ANIM_play_start% / _next% / _advance% / _stop`). Touches only `ANIM*` and `SCRN.canvasW/H`, so **`QA/unit/anim-unit.bas` tests it headless** (110 checks) |
| `TOOLS/ANIM-VIEW.BI/BM` | Frame grid overlay (`ANIM_VIEW_render_grid`, View > Frame Grid 2500), frame keys (numpad + Alt), `ANIM_VIEW_goto`, play toggle + tick, the Preview window's frame view, the `ANIM` QA dump line |
| `TOOLS/ANIM-OPS.BI/BM` | Frame operations, layout changes (re-slice / resize), timing changes, whole-sheet snapshots, the undo record, `ANIMC` dump line |
| `GUI/ANIM-PANEL.BI/BM` | The Animation panel (2505): FPANEL window like `GUI/PEN-PANEL` (dock slot `DP_ANIM`, `REGION_ANIM_PANEL`, `WZ_*`, auto-hide, F11, workspace element `ANIM_PANEL`, `ANIM_PANEL_VISIBLE/X/Y`) |
| `TOOLS/ANIM-LB.BI/BM` | The lightbox view (2.1): layout (`ANIM_LB_layout`, bands strip / transport bar / editor, `ANIM_LB_area` + `ANIM_LB_clear_floats`), `ANIM_LB_render` (cut from the composite), transport bar controls `LB_CTL_*`, `ANIM_LB_mouse`, the `ANIMLB` / `ANIMLBC` / `ANIMLBP` dump lines; drawing in the panes (2.2): the pane view (`ANIM_LB_view_push / _pick / _pop`, `ANIM_LB_pane_view%`), overlays (`ANIM_LB_overlay_begin% / _end`), strokes clipped to a frame (`ANIM_LB_clip_*`) |
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
| 2510-2518 | Frame ops: op = id - `ANIM_ACT_OP0` (2509) = `ANIM_OP_APPEND` .. `ANIM_OP_REVERSE` (`ANIM_OPS_action`; Shift on Add = blank) |

Grep before adding one (CLAUDE.md gotcha 17).

## Keys

- **Numpad:** 1 / 4 / 5 / 9 first / prev / next / last, `+` add (Shift: blank), Enter play, 0 lightbox, `*` lightbox panes.
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
  back - a wheel zoom or a pan made in the lightbox is dropped.
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

The `drAn` PNG chunk (`draw-fileformat.md`), read from .draw and plain PNG. The ask answer
and playback are not saved. Config: `FRAME_GRID`, `PREVIEW_SHOWS_FRAME`, `LIGHTBOX`, `LIGHTBOX_PANES`,
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
  - `ANIMLB shown x1 y1 x2 y2 stripY stripH barY barH edY edH stripFirst stripN cellW cellH panes paneW paneH pad`, `ANIMLBC` + `x w` per transport control (1 `|<` .. 5 `>|`, 6 loop, 7 time, 8 FPS, 9 seek, 10 count, 11-13 copy / paste / cut, 14 `+`; w = 0 dropped), `ANIMLBP clipLightbox clipSheet` + `frame dx dy dw dh` per pane (its picture), `ANIMLBS dragging dropSlot anchor nSelected` + the selected frames (<= 64), `ANIMLBE editing confirmTo menuOpen menuHover seekHeld menuX menuY menuW text` (`-` = empty).
  - `ANIMPL nav r1..r6 loop rowH minusX plusX chipW pad panelW ops mode` (native px; viewport = disp + native * scale% / 100). The nav row has 5 chips (`|< < PLAY > >|`), the others 4, and the mode row 2.
- Tests: `anim-frame-grid`, `file-anim-chunk`, `anim-numpad-keys`, `anim-menu`,
  `anim-panel`, `anim-frame-ops`, `anim-frame-start`, `anim-playback`, `anim-lightbox` (pane / strip contents checked by each frame's mark colour in the snapshot; the floating Preview painted out), `anim-lightbox-draw` (pane clicks / strokes / rectangles land in their frame's cell - checked with `ANIMC`; the same canvas pixel as a sheet-view click; clip on / off in both views; undo), `anim-lightbox-strip` (click / Ctrl / Shift selection, tint, Play plays the span, drag reorder of a selection / a single frame with `ANIMC` order, the drop marker, undo, wheel scroll), `anim-lightbox-bar` (loop menu, FPS spinner + wheel + undo, seek scrub, count box typing / numpad / Esc / shrink question). Unit:
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
