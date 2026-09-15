# Advanced Color Picker (`GUI/ADV-COLOR-PICKER.BM` + `ACP` widget)

A Krita-style color selector: a hue **ring** + saturation/value **triangle**, a
multi-row **shade selector**, a **color-history** strip, and a right-click history
**context menu**. It is a floating, non-modal panel that mirrors the Color Mixer panel
model (render a native buffer to screen 0 at integer toolbar scale; hit-test in
viewport/canvas space).

- **State machine:** `PLANS/diagrams/GUI/ADV-COLOR-PICKER-STATES.DOT` (`.svg`/`.png`).
- **Feature history / phased plan:** `.claude/agent-memory/main/adv-color-picker-feature.md`.
- **Widget (library) source + README:** `includes/QB64_GJ_LIB/ADV_COLOR_PICKER/` (submodule).

## The two-layer split (enforced architecture rule)

All picker *behavior* lives in the **library widget `ACP`** (submodule); the **DRAW
wrapper `ADVCP`** only frames it. Do not add picker logic to the wrapper.

| Layer | Owns |
|-------|------|
| `ACP` (`includes/QB64_GJ_LIB/ADV_COLOR_PICKER/ACP-*`) | ring/triangle math, shade rows, history strip, hue-neighbor markers, quantize; the widget's **own height** (`ACP_STATE.w`/`.h`); one "current color changed" event (`ACP_STATE.changed%`). Color-agnostic — knows nothing of FG/BG. |
| `ADVCP` (`GUI/ADV-COLOR-PICKER.BI/BM`) | title bar, drag, close, screen-0 blit, panel sizing from the widget, region + hit-testing, the history **context menu**, and mapping the widget's change event to the paint color. |

## Entry points (all fire action **2023** → `ADVCP_toggle`, `GUI/ADV-COLOR-PICKER.BM:124`)

- **View menu** item — `GUI/MENUBAR.BM:260` (registers id 2023), handled `MENUBAR.BM:793`.
- **Ctrl+Shift+M** — dispatched binding `INPUT/INPUT.BM:378` (keycode 109, `MOD_CTRL OR
  MOD_SHIFT`, `dispatched = TRUE`, action 2023). Note it is a *dispatched* central-table
  binding, not a legacy `KEYBOARD.BM` handler.
- **Command palette** — action 2023.
- **Middle-click the Color Mixer organizer button** — `GUI/ORGANIZER.BM:867` (`CASE
  ORG_COLOR_MIXER` in `ORGANIZER_handle_middle_click%` → `CMD_execute_action 2023`).

`CMD_execute_action` handler: `GUI/COMMAND.BM:1310` (`CASE 2023`).

## Region / z-order

`REGION_ADV_COLOR_PICKER = 28` (`INPUT/INPUT.BI:117`) — set each render at
`GUI/ADV-COLOR-PICKER.BM:251` with `ZORDER_FLOATING`. (28, not 20: 20 collided with
`PIXEL_COACH`; floating-panel regions run past `TOOLTIP = 19`.) A hidden panel registers
no region, so it can't eat input.

## States (see the diagram for the full graph)

1. **HIDDEN** — `ADVCP.visible% = FALSE`; nothing rendered.
2. **VISIBLE (idle)** — `ADVCP.dragging% = FALSE`, `ADVCP.cmOpen% = FALSE`,
   `ACP_STATE.dragging% = ACP_DRAG_NONE`. Panel drawn; `ADVCP_sync_from_paint` keeps the
   wheel showing `PAINT_COLOR~&`.
3. **MOVING PANEL** — `ADVCP.dragging% = TRUE` (B1 on title bar, not the ✕); persists
   `CFG.ADV_COLOR_PICKER_X%/_Y%`.
4. **CONTEXT MENU** — `ADVCP.cmOpen% = TRUE` (B2 over the history strip); **captures all
   input** until dismissed.

**Widget interaction sub-states** (`ACP_STATE.dragging%`, `ACP-TYPES.BI:17-20`), entered
while VISIBLE via `ACP_input_mouse` (`ACP-CORE.BM:337-351`): `ACP_DRAG_RING` (hue),
`ACP_DRAG_TRIANGLE` (S/V), `ACP_DRAG_NEIGHBOR` (drag a hue-neighbor range marker — **no
color change**, repaints shade rows). Shade-row and history-chip **clicks** also set the
color but are not sustained drags.

## Mouse dispatch order (`ADVCP_mouse_input`, `GUI/ADV-COLOR-PICKER.BM:357`)

Priority matters — each stage `EXIT SUB`s:

1. Bail if not visible / auto-hidden / uninitialized.
2. **Context menu open** → route to it; any press acts on the hovered row and closes it;
   sets `MOUSE.UI_CHROME_CLICKED% = TRUE`.
3. **Active title-bar drag** (`ADVCP.dragging%`) → update `dispX/Y`, clamp, persist.
4. **Title-bar press** → ✕ hot-zone (`nativeX ≥ panelW-12`) toggles closed; else start drag.
5. **B2 over history strip** (`ACP_over_history%`) → `ADVCP_open_context_menu`.
6. Otherwise **`ACP_input_mouse`** drives ring/triangle/shades/history. If
   `ACP_STATE.changed%`, push the widget's color into `PAINT_COLOR~&` **and**
   `DRAW_COLOR~&`, clear `PAL_FG_IS_TRANSPARENT%`, mark `STATUS_NEEDS_REDRAW%`.

Coordinates: `RAW_X/Y − dispX/Y` → local, `/ renderScale!` → native, then `− ADVCP_TITLE_H`
before handing Y to the widget (widget space excludes the title bar).

## Color model — left = FG everywhere; **X key swaps FG/BG**

Right-click no longer edits BG (that convention was dropped, 2026-09-07). LEFT-click
anywhere in the picker sets the **foreground**; right-click is the history **context
menu**. The widget stays FG/BG-agnostic; `ADVCP.editTarget%` remains for a possible future
BG path but is effectively 0 (FG). See the "OBSOLETE FG/BG convention" note in the memory
file before reintroducing any right-click-color behavior.

## Shade selector, history, context menu

- **Shade rows** are built each render by `ADVCP_apply_shade_config`
  (`GUI/ADV-COLOR-PICKER.BM:461`) from the preset + spreads; the widget model is
  `value = base + c·delta + shift` per HSV axis. A row-count change **reallocates the
  widget buffer and resizes the panel** — the widget's height is runtime, not a `CONST`.
- **History** — the widget owns the ring (`ACP_history*`); the wrapper pushes
  `PAINT_COLOR~&` on stroke commit (`HISTORY_saved_this_frame%` edge).
- **Context menu** (`ADVCP_open_context_menu:519`, `ADVCP_render_context_menu`,
  `ADVCP_context_menu_act`): **Create Palette** → `ADVCP_history_to_palette:604` writes the
  history to `PATHS_data$("PALETTES/CREATED/")*.gpl`, rescans, and loads it into the palette
  bar; **Clear History** → `ACP_history_clear`.

## Persistence + config

16 `CFG.ADV_COLOR_PICKER_*` fields persist to `DRAW.cfg`: `VISIBLE`, `X`/`Y`, shade
(`PRESET`, `SPREAD_V/S/H`, `WARMCOOL`, `PATCHES`, `CURVE`, `LABELS`), `QUANTIZE`,
`HUE_NEIGHBORS`, `HISTORY`, `BG_COLOR`/`BG_CUSTOM`.

**Standing rule:** every picker option lives in the **Settings dialog** (Settings → PANELS
→ Advanced Color Picker), mirroring Krita's config tabs — **not** a separate config panel.
Add new options there, and follow gotcha #15 discipline (reset any new tool/panel state in
all three document-creation paths) for any new stateful field.

## Gotchas

- **Widget owns height.** Never hard-code the panel height; read `ACP_STATE.h` and let
  `ADVCP_apply_shade_config` resize `panelImg`/`dispH` when the line count changes.
- **`sync_from_paint` one-way.** `ADVCP_sync_from_paint` (`:229`) pulls `PAINT_COLOR~&`
  into the widget; a widget-driven change pushes back out in `ADVCP_mouse_input`. Don't add
  a second sync path or you'll fight the drag.
- **`UI_CHROME_CLICKED%` discipline.** Context-menu and history-strip presses set it so the
  release frame doesn't fire a spurious history save (per project gotcha #5).
- **Neighbor drag ≠ color change.** `ACP_DRAG_NEIGHBOR` changes only the shade range;
  `ADVCP_mouse_input` force-repaints (`SCENE_DIRTY%`) without touching the paint color.
