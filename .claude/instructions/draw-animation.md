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
| 2527 | Onion skin on / off (`CFG.ONION_SKIN`, Num /; lightbox only) |
| 2528 | Onion skin red / blue tint (`CFG.ONION_TINT`) |
| 2529 | Replace FG color with BG in the selected frames (`ANIM_OPS_swap_fg_bg`; sheet view too) |
| 2530 | Reference Layer - the current layer (`ANIM_LF_toggle ANIM_LF_REF`) |
| 2531 | Layer Same on Every Frame - the current layer (`ANIM_LF_toggle ANIM_LF_SAME`) |
| 2532 | Export Animated GIF... (`ANIM_EXPORT_action`, `TOOLS/ANIM-EXPORT`) |
| 2533 | Export Scale 1x / 2x / 4x (cycles `CFG.ANIM_EXPORT_SCALE`) |
| 2534 | Export PNG Sequence... (`ANIM_PNGSEQ_export%`) |
| 2535 | Export Sprite Sheet + Frame Data... (`ANIM_SHEET_export%`: .png + .json + .bi) |
| 2536 | Export Animated PNG (APNG)... (`ANIM_APNG_export%`) |
| 2537 | Export BAS Player (DATA)... (`ANIM_BAS_export%`) |
| 2538 | Export BAS Player + Sheet PNG... (`ANIM_BAS_sheet_export%`) |
| 2539 | Full-Screen Preview (`ANIM_FS_show`, `TOOLS/ANIM-FS`, Num .) |
| 2541 / 2542 | Link Cells / Unlink Cells (`ANIM_LK_action`, `TOOLS/ANIM-OPS`, the current layer, the selected frames) |
| 2543 / 2544 | Tag Frames... / Delete Tag (`ANIM_TG_action`, `TOOLS/ANIM-OPS`, 4.4) |
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

## Onion skin (`TOOLS/ANIM-LB`, 2.6)

R-09: the lightbox only, on the **current pane** only (drawing in another pane doesn't make it
current). `ANIM_LB_onion` runs in the pane loop of `ANIM_LB_render` right after the picture:
for `CFG.ONION_BEFORE` / `ONION_AFTER` (0-5, `ANIM_ONION_MAX`) frames, farthest first so the
nearest lands on top, it builds the cell into `ANIM_LB.onionImg` from the composite with `_MEM`
and `_PUTIMAGE`s it scaled over the picture. Alpha = pixel alpha x `ONION_OPACITY`% x
(n - d + 1) / n. A pixel shows only where it **differs from the current frame** and **is not
that frame's background** (`ANIM_LB_cell_bg%`: the colour 3 or 4 corners share) - so a solid
background layer doesn't tint the whole pane, and a static scene stays clear. Tint: 3/4 red
(255,48,48) before, 3/4 blue (48,112,255) after. No wrap at the ends; nothing while playing.
Settings are DRAW.cfg (`ONION_*`), not undo steps: ANIM menu (2527 / 2528), Num / (numpad slot
15), and the Animation panel's ONION / TINT chips + BEFORE / AFTER / OPACITY steppers
(`ANIMP_CTL_ON0`.. ids 28-35, `ANIMP_onY`; a held stepper saves the cfg on its release). Cost is
per real render (not cursor-only frames): fine for pixel-art cells; a 512x512 frame with 5 + 5
neighbours would be the case to cache. QA dump `ANIMLBO on before after opacity tint prevPx
nextPx`; `ANIMPL` gained `yOnion onY1..3` at the end (read it with a trailing `_`).

## Apply to the selected frames (2.7)

In the lightbox, commands act on the strip's selected frames (`ANIM_SEL_is%`: the current frame
when none is), each one undo step. A user marquee selection keeps the commands' own behaviour.

- **Effects** (`ANIM_FM_wants%`: 2001-2011, 2101-2289, 2350-2352, Remap to Palette 1516): the top
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
