# DRAW — Exhaustive Mouse Input Inventory

**Source of truth for a mouse test suite.** Everything below is derived from the
actual code logic in `INPUT/MOUSE.BM` (~5982 lines), `INPUT/MODIFIERS.BM`, and the
GUI handlers they call. Comments in the source were treated as claims and verified
against the surrounding code. All line references are `file:line` at the time of
writing (branch `main`).

Conventions used throughout:

- **Pressed edge** = `MOUSE.Bn% AND NOT MOUSE.OLD_Bn%`
- **Released edge** = `NOT MOUSE.Bn% AND MOUSE.OLD_Bn%`
- **Held** = `MOUSE.Bn%` (true every frame the button is down)
- B1 = left, B2 = right, B3 = middle. `MOUSE.B3%` is polled from `_MOUSEBUTTON(3)`.
- Modifiers come from the precomputed `MODIFIERS.*` fields (see §1), **not** raw
  `_KEYDOWN`, except where a tool polls a letter key directly (e.g. `_KEYDOWN(70)`
  for `F`).

---

## 1. Modifier state model (`INPUT/MODIFIERS.BM`)

`MODIFIERS_update` (`MODIFIERS.BM:53`) runs once per frame in the main loop
(before `MOUSE_input_handler`). It polls raw OS key state and precomputes:

| Field | Meaning | Line |
|---|---|---|
| `ctrl% / shift% / alt%` | raw held state (with stuck-key latch applied) | 84–86 |
| `ctrlOnly% / shiftOnly% / altOnly%` | that modifier and no other | 90–92 |
| `ctrlShift% / ctrlAlt% / shiftAlt%` | exactly two, no third | 95–97 |
| `ctrlShiftAlt%` | all three | 100 |
| `none%` | no modifier | 103 |

Gotchas that matter for tests:

- **macOS ALT** is tracked via `_KEYHIT` (`MAC_ALT_HELD%`), not `_KEYDOWN`
  (`MODIFIERS.BM:37, 63–68`). On macOS **Ctrl+Click arrives as B2** (right-click),
  which the poly/bezier tools special-case (see §6.7, §6.8).
- **Stuck-modifier latch** (`MODIFIERS.BM:74–82`): after a native dialog, a
  modifier can report `FALSE` until physically released. `MOUSE_cleanup_after_dialog`
  calls `MODIFIERS_force_release` (`MOUSE.BM:330`). Tests that open a dialog while
  holding Shift/Alt must expect the modifier to read released afterward.
- `AND`/`OR`/`NOT` in these expressions are bitwise; the fields only hold
  `0`/`-1`, so the boolean algebra is valid here.

---

## 2. Per-frame dispatch pipeline (order is load-bearing)

The main loop calls `MOUSE_input_handler` (`MOUSE.BM:5368`). Two **mode
short-circuits run first, before any state drain**:

1. **Reference-image reposition** — `IF REFIMG.REPOSITION THEN
   MOUSE_handle_refimg_reposition%` (`5371`); if it returns TRUE, `EXIT SUB`.
   This does its **own** `_MOUSEINPUT` drain and its **own** wheel/button state
   (`STATIC wasDown`), independent of `MOUSE.*` (`MOUSE.BM:344–390`).
2. **Image-import mode** — `IF IMG_IMPORT.STATE > IMPORT_STATE_IDLE THEN
   MOUSE_handle_image_import%` (`5379`); TRUE → `EXIT SUB`. Also its own drain
   and clamp (`399–544`).

Otherwise it runs `MOUSE_process_frame%` (`5258`) then, only if that returns
TRUE, `MOUSE_post_process` (`5391`).

### 2.1 `MOUSE_process_frame%` step order (`MOUSE.BM:5258`)

Each numbered step can early-exit the whole frame (`MOUSE_process_frame% = FALSE :
EXIT FUNCTION`). **First matching consumer wins.**

| # | Step | Line | Early-exit condition |
|---|---|---|---|
| 0 | `MOUSE_drain_update_state` — drains `_MOUSEINPUT`, computes `RAW_X/Y`, `X/Y`, `UNSNAPPED_X/Y`, `B1/B2/B3`, `STARTED_ON_APRON%` | 5259 | never |
| 1 | Post-dialog suppression — `MOUSE_handle_suppress_frames%` | 5264 | TRUE while `SUPPRESS_FRAMES% > 0` (forces buttons up, decrements) |
| 2 | Text-bar **wheel** (`TEXT_BAR_handle_wheel%`) — before gui_early so an open dropdown doesn't swallow it | 5272 | consumed |
| 3 | **Alt+click screen eyedropper over chrome** (`MOUSE_eyedrop_screen`) — `MODIFIERS.alt% AND NOT ctrl% AND NOT panning%` AND `REGION_hit_test% > REGION_CANVAS`; B1→FG, B2→BG | 5289 | consumed on B1/B2 pressed edge |
| 4 | `MOUSE_handle_gui_early%` — ctx-menu close, autocommit-move, command palette, menubar move+click, **text-bar clicks/right-click/hover**, palette-menu close | 5309 | TRUE if any consumed |
| 5 | `MOUSE_handle_symmetry_ctrl_click` — Ctrl-only click sets symmetry center | 5315 | no exit; sets `UI_CHROME_CLICKED` |
| 6 | `MOUSE_update_draw_color` — `DRAW_COLOR = B2/OLD_B2 ? BG : FG` | 5319 | no exit |
| 7 | `SCROLLBAR_handle_mouse%` | 5322 | consumed → `UI_CHROME_CLICKED`, exit |
| 8 | `MOUSE_handle_gui_panels` — preview, color-mixer, browser, layer panel, edit/adv wheel, toolbar/status/palette | 5328 | **no exit** (see §3 — this is a seam) |
| 9 | `MOUSE_handle_alt_picker` — ALT loupe temp-picker state machine (canvas) | 5330 | no exit |
| 10 | `MOUSE_handle_space_pan` — SPACE→TOOL_PAN swap | 5333 | no exit |
| 11 | `MOUSE_handle_b3_dblclick_reset_zoom` — MMB double-click resets zoom/pan (canvas only) | 5336 | no exit |
| 12 | `MOUSE_handle_ui_autohide_restore` — hide panels while drawing, restore on release | 5337 | no exit |
| 13 | `MOUSE_handle_panning` — Space+LMB / MMB / PAN-tool+LMB | 5340 | no exit |
| 14 | Sub-tool flyout — `SUBTOOL_FLYOUT.ACTIVE` intercepts everything | 5343 | always exit while active |
| 15 | `MOUSE_should_skip_tool_actions%` — `STARTED_ON_APRON%` or `UI_CHROME_CLICKED%` | 5355 | TRUE → consume OLD_B* transition + exit |
| 16 | `MOUSE_handle_tool_phase` — the actual tool hold/release/right-click | 5360 | — |

### 2.2 `MOUSE_post_process` (`MOUSE.BM:5224`) — only when frame not early-exited

1. redraw if palette menu visible
2. `MOUSE_handle_wheel` (zoom / brush size / SS params / shift-pan / GUI scroll) — §5
3. marquee live-update, edit-bar & adv-bar hover

> **Ordering seam:** the mouse **wheel** is dispatched in **two different
> places**: floating-panel and layer-panel wheel in step 8 (`MOUSE_handle_gui_panels`,
> inside `process_frame`), and everything else in `MOUSE_handle_wheel` in
> `post_process`. But `post_process` **only runs when the frame was not
> early-exited**. Any step that early-exits (suppress frames, alt-eyedrop,
> gui_early consume, scrollbar, subtool flyout, `should_skip_tool_actions`)
> **drops the wheel entirely** unless it was already handled in step 8. See §5.4.

### 2.3 `MOUSE_input_handler_loop` (`MOUSE.BM:5398`) — end of main loop

Copies `B*→OLD_B*`, `X/Y→OLD_X/Y`, then runs **deferred file-dialog actions**
(`DEFERRED_ACTION%`): 1=Save, 2=Import image, 3=Open DRW, 4=Export selection,
5=drawer slot import (`5406–5426`). These are set by `MOUSE_tool_save`/`_open`
and drawer/menu handlers so dialogs don't open inside the mouse loop.

---

## 3. `MOUSE_should_skip_tool_actions%` and `UI_CHROME_CLICKED%` lifecycle

`MOUSE.UI_CHROME_CLICKED%` is the master "a GUI panel already claimed this
click, don't let the canvas tool act" latch.

**Where it is SET** (grep-verified):

| Setter | Region | Line(s) |
|---|---|---|
| menubar click | menubar | 587 |
| layer-panel blend-popup / ctx-menu / dock-toggle / click / swipe / opacity / drag / scroll | layer panel | 720, 760, 778, 790, 795, 808, 816, 826, 835, 844, 852, 861, 869 |
| drawer ctx-menu / drag | drawer | 893, 902 |
| palette-ops drag/release | palette strip | 913, 917, 922 |
| toolbox/charmap/editbar/advbar dock-toggle (Ctrl+Shift) | those panels | 943, 960, 977, 994 |
| toolbar / organizer / drawer / editbar / advbar / charmap / status / palette click | those | 1005, 1012, 1019, 1025, 1030, 1035, 1039, 1044, 1053 |
| organizer drag | organizer | 1061 |
| right-click status/palette/charmap/toolbar/organizer/drawer | those | 1070, 1078, 1083, 1091, 1098, 1104 |
| middle-click palette/status/toolbar/organizer/drawer | those | 1113, 1118, 1122, 1129, 1135 |
| layer ctx-menu early close | layer panel | 4962 |
| text-bar click / right-click / drag-capture | text bar | 5000, 5037, 5057, 5089 |
| preview B2/B3 transition, click | preview | 5144, 1014 (`PREVIEW_mouse_input`) |
| color-mixer any transition | color mixer | 5163 |
| browser drag/resize/file-drag/any transition | browser | 5181, 5185, 5189 |
| edit/adv bar wheel | those | 5204, 5208 |
| Alt eyedrop chrome | chrome | 5297, 5302 |
| scrollbar | scrollbar | 5323 |
| symmetry Ctrl-click | canvas | 4487 |
| draw-on-text-layer / symbol-child / group guards | canvas | 4155, 4175, 4239 |
| apron block (implicit via `STARTED_ON_APRON%`) | apron | — |

**Where it is RESET** — critically, **only inside
`MOUSE_should_skip_tool_actions%`** (`MOUSE.BM:4834–4847`), after consuming the
`OLD_B*` transition, and **only once all buttons are released**
(`IF NOT MOUSE.B1% AND NOT MOUSE.B2% THEN UI_CHROME_CLICKED% = FALSE`). It is
also cleared by `MOUSE_reset_buttons` / `_force_buttons_up` /
`_cleanup_after_dialog` (249, 267, 313). This exact placement is gotcha #5 in
CLAUDE.md — resetting earlier produces a ghost-undo on every chrome click.

`STARTED_ON_APRON%` (set in `drain_update_state:196` when a press begins outside
the canvas screen rect) has the **same** consume-and-reset lifecycle, except
**TOOL_MARQUEE is exempt** so edge selections can start off-canvas
(`4814–4833`).

> **SEAM (core): step 8 handlers do NOT early-exit.** `MOUSE_handle_gui_panels`
> runs preview → mixer → browser → layer panel → edit/adv → toolbar/status/palette
> **all in the same frame, each independently geometry-testing**. They set
> `UI_CHROME_CLICKED%` but nothing stops a later handler in the same frame from
> also matching overlapping bounds. Only the *tool phase* (step 16) is gated by
> the latch. So two panels with overlapping rects both run their click handler.

---

## 4. Coordinate + clamp model (`MOUSE_drain_update_state`, `MOUSE.BM:54`)

- `RAW_X/Y = _MOUSEX \ displayScale` — **viewport pixels**, used for all GUI
  hit-tests.
- `X/Y` — canvas pixels after zoom/pan (`dx/dy` centering incl. `panelShiftX%`),
  then grid/char snap, then clamp.
- `UNSNAPPED_X/Y` — canvas pixels **without** grid snap (fill, picker, wand,
  move, marquee handle hit-test, symmetry).
- **Snapping** (`150–156`): skipped entirely when `MODIFIERS.ctrlShift%`;
  `CHARMAP.charGridSnap%` takes precedence over `GRID_snap_xy`.
- **Clamp branches** (both for unsnapped `127–146` and snapped `160–175`):
  - `CROP_STATE_ACTIVE` → allow ±canvas beyond bounds (grow handles)
  - `MOUSE_tool_allowed_in_apron%(CURRENT_TOOL%)` → extend into apron `±APRON_W/H`
  - else → clamp to `[0, canvasW-1] × [0, canvasH-1]`
- `patternTileMode%` remaps via 3×3 modulo wrap and snaps `OLD_X/Y` on tile
  boundary crossing to prevent cross-canvas line interpolation (`97–117`).
- Apron whitelist (`MOUSE_tool_allowed_in_apron%`, `19–41`): brush/dot/line/rect/
  ellipse/polygon/spray/bezier/eraser/marquee/all selects/move/all smart-shapes.
  Fill, picker, zoom, crop, text, pan stay clamped.
- macOS trackpad tap-to-click: button state OR-captured during the drain
  (`57–68, 178–187`).

---

## 5. Wheel events

### 5.1 Wheel in `MOUSE_handle_gui_panels` (step 8, runs inside process_frame)

| Consumer | Guard | Zeros `wheel_delta`? | Line |
|---|---|---|---|
| palette dropdown menu | `PALETTE_MENU_VISIBLE%` | **yes** | 5128 |
| preview scroll (`PREVIEW_mouse_scroll`) | `PREVIEW_hit_window%` and not covered by browser | **no** | 5148 |
| color mixer (`COLORMIXER_mouse_input delta`) | `COLORMIXER_hit_window%` | **no** | 5165 |
| browser (`BROWSER_mouse_input delta`) | `BROWSER_hit_window%` | **no** | 5191 |
| layer panel (`LAYER_PANEL_handle_wheel`) | `LAYER_PANEL_in_bounds%` | **yes** (`wheel_delta=0`, `MOUSE.BM:800`) | 5198→799 |
| edit bar / adv bar scroll | `EDITBAR/ADVBAR_is_over_area%` | no (but sets `UI_CHROME_CLICKED`) | 5202, 5206 |

### 5.2 Wheel in `MOUSE_handle_wheel` (post_process, `MOUSE.BM:3862`)

Single long `IF/ELSEIF` — **first match wins**, most consume (`MOUSE.SW% = 0`):

1. command palette open + in bounds → nav up/down; open but outside → consume
2. `FILL_ADJ_is_active%` → tile scaling
3. `MENUBAR_is_open%` → scroll submenu
4. `PALETTE_MENU_VISIBLE%` → palette scroll
5. layer panel in bounds → `LAYER_PANEL_handle_wheel`
6. palette dropdown button → ignore/consume
7. palette strip in bounds → `PALETTE_STRIP_handle_wheel`
8. toolbar over-area → ignore/consume
9. organizer over-area → `ORGANIZER_handle_wheel` (cycle widgets)
10. drawer over-area → `DRAWER_handle_wheel`
11. charmap over-area → `CHARMAP_scroll`
12. status-bar band → ignore/consume
13. **Ctrl+Shift** → canvas border opacity ± / reference-image opacity ±
14. preview/mixer/browser hit → consume ("already handled in gui_panels")
15. **Ctrl** → brush size ± (wheel up=increase)
16. **SS sub-tool dragging** (cube/bevel/arrow/polygon/pie/rr/tab/pill/pacman/3d-text)
    → per-tool param; step `5`, or `25` with Shift (`3999`: bevel step 1/5)
17. **Shift only** → vertical canvas pan (`offsetY += SW*40`)
18. else → **canvas zoom** centered on cursor (apron anchors to canvas center)

### 5.3 Reference-image reposition wheel

When `REFIMG.REPOSITION`, wheel resizes the reference image
(`REFIMG_reposition_wheel`, `MOUSE.BM:373`) — bypasses all of the above.

### 5.4 Wheel drop seam

Because `MOUSE_handle_wheel` lives in `post_process`, any frame that early-exits
`process_frame` **loses the wheel** unless a step-8 handler already ate it. E.g.
wheeling while `UI_CHROME_CLICKED%` is latched from a chrome drag, or during a
subtool flyout, silently discards the tick.

---

## 6. Canvas tool events (`MOUSE_handle_tool_phase` → dispatch, `MOUSE.BM:4861`)

`MOUSE_handle_tool_phase` order:

1. LMB pressed on canvas clears `MULTI_SELECT` (unless TOOL_MOVE) (`4864`).
2. **Grid-offset pick mode** (`GRID_OFFSET_PICK_MODE%`): next LMB press sets grid
   origin, `EXIT SUB` (`4872`).
3. **On-canvas TRANSFORM overlay** intercept (`TRANSFORM.ACTIVE`): B1 press/hold/
   release → `TRANSFORM_mouse_*`, `EXIT SUB` (blocks right-click too) (`4887`).
4. **Fill-adjust mode** intercept (`FILL_ADJ.ACTIVE%`): B1 press/hold/release,
   `EXIT SUB` (`4899`).
5. If `SCRN.panning%` → do nothing.
6. Else if `B1 OR B2` → apron-demote current layer if a non-apron tool just
   pressed (`4918`), then `MOUSE_dispatch_tool_hold`.
7. Else (`NOT B1`) → `MOUSE_dispatch_tool_release`, clear DRAG$/constrain.
8. `B2` pressed edge → `MOUSE_handle_right_click`.
9. `MOUSE_handle_shift_constrain`.

`MOUSE_dispatch_tool_hold` (`4131`) first runs **layer-type guards** (text/symbol
-child/group) that alert + `EXIT SUB` + `UI_CHROME_CLICKED` on draw-tool press
(group auto-add layer falls through), then a `SELECT CASE CURRENT_TOOL%` to the
per-tool hold handler. `MOUSE_dispatch_tool_release` (`4381`) has the same
text-layer guard, stops loop sounds, and — only if `(OLD_B1 OR OLD_B2) AND NOT
HISTORY_saved_this_frame%` — calls the per-tool release handler.

### 6.1 Brush / Eraser — `MOUSE_tool_brush` (`2632`) / `MOUSE_release_brush` (`3433`)

| Event | Guard | Action |
|---|---|---|
| B1 pressed, or **B2 pressed w/o Shift** | `(B1&!OLD_B1) OR (B2&!OLD_B2&!shift)` | reset pixel-perfect stroke, snapshot before-image, `STROKE_begin` |
| B1 held, or B2 held w/o Shift | `B1 OR (B2 & !shift)` | paint; tracks DRAG$ |
| **Shift + B1 held (Eraser)** | `CURRENT_TOOL=ERASER AND shift AND B1` | `ERASER_smart_on` (smart erase all layers) |
| release | via dispatch_release | pixel-perfect flush + per-layer smart-erase undo grouping |

`DRAW_COLOR` is FG on B1, BG on B2 (`MOUSE_update_draw_color`). B2+Shift is
**reserved for connecting-line right-click** (§6.15), so brush hold ignores it.

### 6.2 Dot — `MOUSE_tool_dot` (`2683`) / `MOUSE_release_dot` (`3499`)

Single stamp on **pressed edge only** (`(B1&!OLD_B1) OR (B2&!OLD_B2&!shift)`).
Sets `OLD_X/Y = X/Y` to kill line interpolation. Char-mode-on-text-layer fills a
cell instead. Updates `DOT.LAST_X/Y/HAS_LAST` for Shift+RightClick lines.

### 6.3 Line — `MOUSE_tool_line` (`2094`) / `MOUSE_release_line` (`2912`)

- Start on `(B1&!OLD_B1) OR (B2&!OLD_B2)`. **Ctrl+Shift** uses unsnapped coords +
  `SNAP_to_angle`. **SPACE held mid-drag** → `SHAPE_space_drag_delta` translates
  the whole line, `EXIT SUB`.
- Release draws the line; supports custom brush / thick / clipped / symmetry /
  spokes / end-caps; records history.

### 6.4 Rect / Rect-filled — `MOUSE_tool_rect` (`2478`) / `MOUSE_release_rect` (`3052`)

- Start on `(B1&!OLD_B1) OR (B2&!OLD_B2)`. **Shift** = square-from-center,
  **Ctrl** = draw-from-center, **SPACE** = translate. Filled = `CURRENT_TOOL =
  TOOL_RECT_FILLED` (not the button).
- Release: char-mode cell fill path; FILL_ADJ intercept for custom-brush/paint-mode
  filled rects; symmetry.

### 6.5 Ellipse / Ellipse-filled — `MOUSE_tool_ellip` (`2556`) / `_release_ellip` (`3256`)

Same modifier model as rect (Shift = circle, Ctrl = from center, SPACE =
translate). Filled = `CURRENT_TOOL = TOOL_ELLIPSE_FILLED`.

### 6.6 Spray — `MOUSE_tool_spray` (`2710`) / `_release_spray` (`3557`)

- **B1 held** → spray FG; **B2 held** → spray BG (`2741`). Both begin a stroke on
  their pressed edge. Shift axis-constrain via `CON_X/Y`.

### 6.7 Polygon / Polygon-filled — `MOUSE_tool_poly` (`2150`)

- Add vertex on B1 pressed edge. **macOS:** Ctrl+Shift arrives as B2 → treated as
  B1 (`2157–2162`). **Ctrl+Shift** = unsnapped + angle snap to previous vertex.
- **Right-click finishes** (§6.15 → `MOUSE_handle_right_click:3732`): filled poly
  closes + scanline-fills; `POLY_LINE_reset`, tool stays selected. macOS skips the
  finish when Ctrl+Shift (that B2 is a point placement).

### 6.8 Bezier — `MOUSE_tool_bezier` (`2245`) / `MOUSE_release_bezier` (`2425`)

B1-only state machine (`BEZIER.STATE`): click-near-first-anchor closes; in
PLACED, hit-tests anchors then handles (radius 5px; handle hit-test skipped when
`SHOW_HANDLES%` off); otherwise plots a new anchor. B1 held drags handle/anchor;
**Ctrl** = corner node (no mirror), default = smooth. 3px dead-zone.

### 6.9 Fill — `MOUSE_tool_fill` (`1446`)

Flood on `(B1&!OLD_B1) OR (B2&!OLD_B2)` AND `NOT HISTORY_saved_this_frame%`.
Uses **UNSNAPPED** coords. Branches:
- Grid-cell fill when `GRID.CELL_FILL% AND (GRID.SHOW% OR charGridShow)` (+
  symmetry mirrored cells).
- **`F` key held** (`_KEYDOWN(70/102)`): global fill; **+Shift** = replace all
  matching on all layers, else contiguous all layers. `EXIT SUB`.
- FILL_ADJ intercept for custom-brush/pattern/gradient (no symmetry, no shift).
- **Shift** = `FILL_flood_merged` (sample merged canvas). Else `FILL_flood`.
- B2 fills with BG via `DRAW_COLOR`.

### 6.10 Picker — `MOUSE_tool_picker` (`1555`)

B1 pressed → pick FG (`PICKER_pick_color …,1`, unsnapped). B2 pressed → pick BG,
handled in `MOUSE_handle_right_click:3616`.

### 6.11 Move — `MOUSE_tool_move` (`2013`) / `MOUSE_release_move` (`2885`)

- **Shift-only + press** → select topmost non-transparent layer at cursor, scroll
  panel, fall through (`2016`).
- **Alt** = clone mode (`MOVE.CLONING`); Alt on release stamps a copy (`2891`).
- Handle hit-test (MARQUEE→MOVE handle remap `2048`), inside = move from center,
  outside = commit + fresh capture. Uses UNSNAPPED coords.

### 6.12 Marquee (all selection variants) — `MOUSE_tool_marquee` (`1804`) / `_release_marquee` (`2830`)

Selection **mode from modifiers**: Shift=ADD, Alt=SUBTRACT, else REPLACE
(`1816`). Per `MARQUEE.VARIANT`:

| Variant | Press | Drag | Release | Right-click |
|---|---|---|---|---|
| WAND | single click; **E**=flood erase, **F**=flood fill, **W**=select-all-color-merged (each `_KEYDOWN`, own `EXIT SUB`); else wand select | — | nothing | — |
| FREE (lasso) | start freehand (grid-snap) | add points | finish + auto-close | — |
| POLY | add vertex; Ctrl+Shift angle-snap | — | nothing | **close** (≥3 pts) `3599` |
| ELLIPSE | start | update | finish (ellipse mask) | — |
| RECT (default) | handle-resize / move-inside / new drag (replace); ADD/SUB always new drag | update resize/move/drag | finish drag/resize/move; bare click deselects | — |

Marquee is **allowed to start on the apron** (exempt from `STARTED_ON_APRON%`
block, `4826`). `MARQUEE_update` also runs every frame in `post_process` for
keyboard nudge (`5232`).

### 6.13 Smart-Shapes (9 sub-tools) — `MOUSE_tool_ss_*` / `MOUSE_release_ss_*` (`5434`+)

Uniform model for polygon, pie/donut, rounded-rect, tab, pill, pacman, 3d-cube,
bevel-rect, arrow, 3d-text:

- Start on `(B1&!OLD_B1) OR (B2&!OLD_B2)`; **`.FILLED = (B2 pressed edge)`** —
  **B1 = outline, B2 = filled** (differs from rect/ellipse which key on tool id).
- **Shift** during drag = circular/square constrain; **SPACE** = translate.
- **Wheel during drag** adjusts a shape param (see §5.2 #16); consumed, never
  zooms.
- SS drag states also feed the drag-sound cardinal logic (`4261`).

### 6.14 Zoom tool — `MOUSE_tool_zoom` (`2778`) / `MOUSE_release_zoom` (`2802`)

B1 press starts a drag box (RAW coords). Release: box ≥8×8 → `ZOOM_to_region`;
else click → `ZOOM_in_at` (Alt → `ZOOM_out_at`).

### 6.15 Right-click dispatch — `MOUSE_handle_right_click` (`3584`)

Runs on B2 pressed edge from tool_phase. Early `SELECT CASE`:
- LINE/RECT/RECT_FILLED/ELLIPSE/ELLIPSE_FILLED/FILL → `EXIT SUB` (B2 already = shape/BG)
- BRUSH/DOT/ERASER → `EXIT SUB` unless **Shift** (B2 no-shift = draw with BG)
- SPRAY → `EXIT SUB` (handled in tool_spray)

Then: Poly-select close; Picker BG pick; **Shift+RightClick brush/dot/eraser =
connecting line from `DOT.LAST` to cursor** (Ctrl+Shift angle-snaps), always FG
color; Polygon/Polygon-filled finish (macOS Ctrl+Shift skip).

### 6.16 Drag-direction sound + Shift constrain

`MOUSE.DRAG$` (L/R/U/D) set by brush/spray from `X` vs `OLD_X/Y`.
`MOUSE_handle_shift_constrain` (`3840`) locks an axis (`CON_X/Y`,
`CONSTRAIN_X/Y`) on first Shift-drag direction. Draw sounds are pitched by
cardinal-direction change + stroke distance (`4252–4314`).

---

## 7. Modifier + mouse gesture matrix (canvas)

| Gesture | Effect | Line |
|---|---|---|
| **Ctrl-only + B1/B2 press** | set symmetry center; blocks tool (`UI_CHROME_CLICKED`) | 4478 |
| **Ctrl+Shift** (drawing) | bypass grid snap, use angle snap (line/poly/poly-sel/shift-rclick) | 150, 2103, 2167, 1924 |
| **Ctrl+Shift+Click on a panel** | toggle that panel's dock edge L↔R (layer panel 766; toolbox/charmap/editbar/advbar 930) | — |
| **Ctrl+Wheel** | brush size ± | 3961 |
| **Ctrl+Shift+Wheel** | canvas-border + reference-image opacity ± | 3931 |
| **Shift+Wheel** | vertical canvas pan | 4030 |
| **Alt+Click on canvas** | temporary loupe color picker (`MOUSE_handle_alt_picker`) | 4551 |
| **Alt+Click on chrome** | screen eyedropper (`MOUSE_eyedrop_screen`) FG/BG | 5289 |
| **Alt (Move tool)** | clone mode / stamp | 2035, 2891 |
| **Alt (Marquee)** | subtract from selection | 1818 |
| **Alt+Click (Zoom)** | zoom out | 2816 |
| **Shift (Marquee)** | add to selection | 1816 |
| **Shift (Move)** | select topmost layer under cursor | 2016 |
| **Shift (shape tools)** | square/circle constrain | 2523, 2599 |
| **Shift+F+click (Fill)** | replace-all global fill | 1497 |
| **Space+LMB / MMB / PAN tool+LMB** | pan | 1362 |
| **MMB double-click (canvas only)** | reset zoom=1, offset=0 | 1145 |

### 7.1 ALT loupe picker state machine (`MOUSE_handle_alt_picker`, `4551`)

Enters TOOL_PICKER on **ALT rising edge** with a drawing tool, `NOT Ctrl`, not
over menubar/preview/text-bar, `NOT UI_CHROME_CLICKED`. Exits on ALT release or
Ctrl added; restores `PREVIOUS_TOOL%`. While active, B1=FG pick, B2=BG pick,
**skipped when over preview window** (preview owns its own picking). Interacts
with `MENU_BAR.altTapped%` to suppress the menu-open-on-ALT-tap.

### 7.2 Space→Pan tool swap (`MOUSE_handle_space_pan`, `4736`)

Separate from `MOUSE_handle_panning`. On SPACE rising edge (not text-active, not
already PAN) swaps `CURRENT_TOOL%→TOOL_PAN`; restores on release. **Suppressed
while a shape drag is in progress** (`SHAPE_drag_in_progress`, `4683`) so SPACE
routes to shape reposition instead.

---

## 8. GUI panel / chrome events (per region)

All bounds tests use **RAW (viewport) coords**. Each panel guards on its own
`SCRN.show*%` / `.visible%` flag in the caller. Panels are processed in
`MOUSE_handle_gui_panels` (step 8) and `MOUSE_handle_toolbar_status_palette`.

### 8.1 Menubar (`MOUSE_handle_menubar_click%`, `580`)

LMB pressed only. Consumed if in bounds of any of ~10 menubar sub-rects (main,
submenu, recent, random, transform, layout, overflow, pvw, pvw-recent, export)
(`585`). Click **outside while open** closes all. Hover-switch via
`MOUSE_handle_menubar_mouse_move` (in gui_early, `4982`, skipped when layer-panel
popups open).

### 8.2 Layer panel (`MOUSE_handle_layer_panel`, `683`)

- Blend-popup + ctx-menu **hover always** (may extend beyond panel).
- Blend-popup click intercept (B1/B2) → apply blend/pass-through, close,
  `UI_CHROME_CLICKED`, `EXIT SUB` (`696`).
- Ctx-menu click intercept (B1/B2) → hit codes: -2 close, pass-through, blend 0–18,
  ≥700 command, `EXIT SUB` (`726`).
- **Ctrl+Shift+B1** in bounds → dock-edge toggle, `EXIT SUB` (`766`).
- In bounds (not panning): B1 → `LAYER_PANEL_handle_click% …,1`; B2 →
  `…,2`; wheel → `LAYER_PANEL_handle_wheel` (**zeros wheel_delta**).
- Persistent drags handled **even outside bounds**: vis-swipe, opacity drag,
  layer reorder drag, scrollbar thumb drag (`804–872`, mirrored in ELSEIF block
  for out-of-bounds continuation).
- `LAYER_PANEL_in_bounds%` spans `panelX1..panelX2 × [0, h - bottomBars)` — i.e.
  **nearly the full screen height** on its docked edge (`LAYERS.BM:2900`).

### 8.3 Toolbar / Organizer / Drawer / Edit bar / Adv bar / Char map / Status / Palette strip (`MOUSE_handle_toolbar_status_palette`, `883`)

- Drawer ctx-menu (hover + B1/B2 hit → activate/close, `EXIT SUB`).
- Drawer bin drag + palette-ops strip drag continue outside bounds.
- Ctrl+Shift+B1 dock toggles for toolbox / charmap / editbar / advbar (each
  `EXIT SUB`).
- **B1 pressed (not panning), non-ELSEIF sibling `IF`s** (`1000–1055`): palette
  menu (priority, `EXIT SUB`), toolbar, organizer, drawer, edit bar, adv bar,
  charmap, status bar, palette strip — **each geometry-tested independently**.
- Organizer opacity-slider drag continues on B1 held (`1058`).
- **B2 pressed** (`1067`): status, palette strip, charmap right-clicks.
- **B2 pressed** (`1088`): toolbar/organizer/drawer right-clicks.
- **B3 pressed** (`1109`): palette-ops delete/insert, status swatch native
  chooser, toolbar/organizer/drawer middle-clicks.

### 8.4 Command palette (`MOUSE_handle_command_palette_click%`, `555`)

LMB pressed → `CMD_handle_click`; consumes and syncs OLD_B*, `EXIT`. Wheel
navigates the list (§5.2 #1).

### 8.5 Scrollbar (`SCROLLBAR_handle_mouse%`, step 7 `5322`)

Runs before gui_panels; consumes → `UI_CHROME_CLICKED` + frame exit.

---

## 9. Floating windows (Preview / Color-mixer / Browser) — the fragile zone

### 9.1 Dispatch inside `MOUSE_handle_gui_panels` (`5134–5195`)

Order: **preview → color-mixer → browser → layer panel**. Each:

- Preview runs `PREVIEW_mouse_input` when visible & not covered by browser;
  `PREVIEW_hit_window%` sets `UI_CHROME_CLICKED` **only on B2/B3 transitions**
  (B1 handled inside), and scrolls on wheel.
- Color-mixer runs `COLORMIXER_mouse_input` when `dragging%` or hit; sets
  `UI_CHROME_CLICKED` on **any** B1/B2/B3 transition.
- Browser runs `BROWSER_mouse_input` when dragging/resizing/file-drag/hit; blocks
  tool dispatch while file drag-out is in progress.

**Cross-window precedence is hand-coded, not z-ordered:** browser-over-preview
guard (`5135`), browser-over-mixer guard (`5155`), preview-vs-browser guard in
alt-picker (`4599`).

### 9.2 `PREVIEW_mouse_input` (`PREVIEW.BM:980`)

- B1 pressed inside window → `UI_CHROME_CLICKED = TRUE`, then close/minimize/
  follow-pointer/color-pick-checkbox buttons (native coords), title-bar drag,
  resize-edge grab (`PREVIEW_hit_resize_edge%`, 8-way), pan, or color pick — each
  its own `EXIT SUB`.
- B1 released → clears dragging/resizing.
- Drag/resize/pan continue on B1 (or B3 pan) held (`1244, 1254, 1300`).
- `PREVIEW_mouse_scroll` (`1320`) exits unless `PREVIEW_hit_window%(RAW_X,RAW_Y)`.
- **Region registered `ZORDER_PANEL`** (`337`) — same z as docked panels.

### 9.3 Preview cursor-under-pane bug context (the reported issue)

- Preview registers `REGION_PREVIEW` at `ZORDER_PANEL` = 100 (`PREVIEW.BM:337`),
  **the same z-order as the layer panel (4), status bar, toolbar, etc.**
  `REGION_hit_test%` (`INPUT.BM:720`) breaks z-ties by keeping the **first**
  (lowest region index) match (`IF zOrder > bestZ`, strict). So when the preview
  window overlaps the layer panel, `REGION_hit_test%` returns
  `REGION_LAYER_PANEL` (4), **not** `REGION_PREVIEW` (10) — the region system
  reports the panel *under* the floating window as the hit. Actual dispatch
  disagrees (it gives preview priority via hand-coded ordering), so the region
  table is not the authority for float input.
- The preview cursor / crosshair overlay is a per-frame animation that must be
  drawn after `SkipToPointer:` in `SCREEN_render` (see `.claude/instructions/
  draw-rendering.md`). If it is drawn before the preview pane composites, it
  renders *under* the pane — the visual symptom the user reported. Verify draw
  order of the preview cursor vs the preview pane blit in `OUTPUT/SCREEN.BM`.

---

## 10. Special / modal input owners (each fully intercepts)

| Owner | Guard | Own drain? | Line |
|---|---|---|---|
| Reference-image reposition | `REFIMG.REPOSITION` | yes | 344 |
| Image import | `IMG_IMPORT.STATE > IDLE` | yes | 399 |
| Sub-tool flyout | `SUBTOOL_FLYOUT.ACTIVE` | no (uses MOUSE.*) | 5343 |
| On-canvas TRANSFORM | `TRANSFORM.ACTIVE` | no | 4887 |
| Fill-adjust | `FILL_ADJ.ACTIVE%` | no | 4899 |
| Command palette | `CMD_PALETTE.visible` | no | 555 |
| Palette dropdown menu | `PALETTE_MENU_VISIBLE%` | no | 1003, 5128 |
| Grid-offset pick | `GRID_OFFSET_PICK_MODE%` | no | 4872 |
| Post-dialog suppression | `SUPPRESS_FRAMES% > 0` | drains | 5264 |

---

## SEAMS/GAPS

- **S1 — Floating panels share `ZORDER_PANEL` with docked panels.** `REGION_hit_test%`
  ties break to the *lowest region index*, so it reports the docked panel *under*
  a preview/mixer/browser window (e.g. returns `REGION_LAYER_PANEL` where
  `REGION_PREVIEW` visually sits). Test: with preview overlapping the layer panel,
  assert `REGION_hit_test%` vs. which handler actually consumes the click.
  (`INPUT.BI:99–101, 126`; `INPUT.BM:720`; `PREVIEW.BM:337`)
- **S2 — Step-8 handlers never early-exit; overlapping bounds double-fire.**
  `MOUSE_handle_gui_panels` runs preview→mixer→browser→layer-panel→toolbar/status
  every frame with independent geometry tests. A click where a floating window
  overlaps `LAYER_PANEL_in_bounds%` (which spans ~full screen height on its dock
  edge) runs **both** the float handler **and** `LAYER_PANEL_handle_click`. Test:
  click preview title bar positioned over the layer list; assert no layer
  selection / visibility toggle / context menu fires underneath. (`MOUSE.BM:5114–5214`,
  `783–802`; `LAYERS.BM:2900`)
- **S3 — Wheel double-consumption / drop.** In gui_panels, preview/mixer/browser
  scroll do **not** zero `wheel_delta`, but the layer panel **does** (`MOUSE.BM:800`).
  A wheel over a preview that overlaps the layer panel scrolls **both**. Conversely,
  any early-exit frame skips `post_process`, so `MOUSE_handle_wheel` never sees the
  tick (§5.4). Test: wheel over overlapping preview+layer-panel; wheel while
  `UI_CHROME_CLICKED` latched. (`MOUSE.BM:5148, 5198→799, 5229`)
- **S4 — `MOUSE_handle_toolbar_status_palette` uses non-ELSEIF sibling `IF`s**
  for toolbar/organizer/drawer/editbar/advbar/charmap/status/palette (`1009–1054`).
  Any two panels whose RAW-coord bounds overlap will both run their click handler
  and both set `UI_CHROME_CLICKED`. Test: dock two bars so their rects touch/overlap,
  click the seam.
- **S5 — Preview owns B1 internally but only flags chrome on B2/B3 transitions**
  (`MOUSE.BM:5143`; `PREVIEW.BM:1014`). If `PREVIEW_mouse_input`'s internal B1
  handling misses (window moved between drain and hit-test, or `PREVIEW_hit_window%`
  disagrees between `mouse_input` and `mouse_scroll`), a B1 click can leak to the
  canvas tool. Test: rapid B1 clicks on preview edges/handles; assert no canvas
  stroke.
- **S6 — Preview cursor render order.** Preview crosshair/cursor overlay must be
  drawn after `SkipToPointer:` and after the preview pane blit, or it renders
  *under* the pane (the reported symptom). Verify draw order in `OUTPUT/SCREEN.BM`
  against `.claude/instructions/draw-rendering.md`. (Rendering, not input — flagged
  because it's the user's actual complaint.)
- **S7 — Region hit-test authority mismatch.** Only the Alt-eyedropper
  (`REGION_hit_test% > REGION_CANVAS`, `MOUSE.BM:5294`) and the dev-mode conflict
  audit consult the region table; **all real dispatch uses per-handler geometry**
  (`*_is_over_area%` / `*_hit_window%` / `*_in_bounds%`). The two can disagree
  (S1). Any future migration to region-driven dispatch inherits S1's tie-break bug.
- **S8 — `REGION_CANVAS` (1) is never registered.** Canvas/dead-space returns
  `REGION_GLOBAL` (0). The eyedropper relies on `> REGION_CANVAS` specifically so
  it doesn't fire over canvas (`MOUSE.BM:5290–5294`). A stray registration of
  `REGION_CANVAS`, or any panel leaving stale bounds active (panels rely on
  `REGION_clear_all` at top of `SCREEN_render`), would misroute Alt-clicks. Test:
  Alt-click canvas vs. each panel; assert loupe vs. screen-eyedrop path.
- **S9 — Wheel over floating window vs. `MOUSE_handle_wheel` "already handled"**
  branches (`MOUSE.BM:3952–3959`) assume gui_panels consumed it. If a float is
  `autoHidden%` or its `hit_window` disagrees between the two call sites, the wheel
  falls through to canvas zoom unexpectedly. Test: wheel at the 1px border of a
  floating window.
- **S10 — Dual pan systems.** `MOUSE_handle_space_pan` (tool swap) and
  `MOUSE_handle_panning` (offset drag) both key off SPACE/MMB and both exclude the
  same GUI list, but independently. `SHAPE_drag_in_progress` gates space_pan but
  `MOUSE_handle_panning` re-checks `SHAPE_drag_in_progress` separately (`1392`).
  Test: SPACE during a shape drag, then release drag with SPACE still held (pan
  must engage without a lost frame).
- **S11 — Apron-start block is tool-conditional.** `STARTED_ON_APRON%` blocks all
  tools *except* TOOL_MARQUEE (`MOUSE.BM:4814–4832`). Marquee can begin off-canvas;
  every other apron-whitelisted tool cannot start a stroke from the apron even
  though `MOUSE_tool_allowed_in_apron%` lets its coords range there. Test: press on
  apron with brush vs. marquee.
- **S12 — macOS Ctrl+Click→B2 collides with symmetry Ctrl-click and poly/bezier.**
  `MOUSE_handle_symmetry_ctrl_click` fires on Ctrl-only B1 **or B2** (`4479`); poly
  tool remaps Ctrl+Shift B2→B1 (`2159`); right-click handler skips poly-finish on
  Ctrl+Shift (macOS, `3734`). These three interpret a Ctrl-bearing B2 differently —
  high-value cross-platform test surface.
- **S13 — `MOUSE_autocommit_move_if_click_on_gui` GUI list is a manual subset**
  (`MOUSE.BM:633–643`) that does **not** include the color mixer, preview, char-map
  right-dock edge cases uniformly, nor scrollbar. A GUI click on an unlisted panel
  won't auto-commit a floating Move transform. Test: with a full-layer Move pending,
  click each panel; assert commit.
- **S14 — Text tool multi-click uses RAW-coord spatial tolerance (≤4px) + 300ms**
  (`MOUSE.BM:1611–1619`) with `STATIC` state that is **not reset on tool switch**;
  a fast click after re-selecting Text could inherit a stale click count. Test:
  quadruple-click, switch tool, switch back, single-click.
