---
applyTo: "**"
---

# DRAW Project Context for AI Agents

## Session Initialization

**Always start sessions with `#qb64pe`** to activate the QB64-PE MCP server, which provides syntax validation, compilation, keyword lookup, and debugging tools.

**Project**: DRAW is a pixel art editor written in QB64-PE by grymmjack (Rick Christy). Unique feature: exports artwork as QB64 source code. Build with: `qb64pe -w -x -o DRAW.run DRAW.BAS`

**Version**: `APP_VERSION$` constant in `_COMMON.BI` (currently `"0.8.1"`).

---

## Architecture

### BI/BM File Separation Pattern

- **`.BI` files**: Declarations only — `TYPE`, `CONST`, `DIM SHARED`, `DECLARE`
- **`.BM` files**: Implementations only — `SUB`, `FUNCTION` bodies
- **Include chain**: `_ALL.BI` includes all `.BI` files in dependency order; `_ALL.BM` includes all `.BM` files
- **Always use**: `$INCLUDEONCE` at top of every BI/BM file

### Include Order (`_ALL.BI` / `_ALL.BM`)

1. `_COMMON.BI` — core types and globals
2. **CORE**: PERF, ERROR, IMAGE
3. **CFG**: CONFIG, CONFIG-THEME, CONFIG-KEYBOARD, CONFIG-MOUSE, CONFIG-STICK, BINDINGS-*
4. **GUI**: PALETTE, PALETTE-LOADER, PALETTE-STRIP, GUI, BRUSHES, CROSSHAIR, GRID, HELP, LAYERS, PALETTE-PICKER, PICKER, CURSOR, POINTER, STATUS, TOOLBAR, ORGANIZER, TRANSPARENCY, COMMAND, MENUBAR
5. **INPUT**: MODIFIERS, KEYBOARD, MOUSE, STICK, FILE-BMP, FILE-BLOAD, FILE-PAL, API-LOSPEC
6. **OUTPUT**: SCREEN, FILE-BAS, FILE-BMP, FILE-BSAVE
7. **QB64_GJ_LIB**: BBX, DICT, STRINGS, VECT2D
8. **TOOLS**: All 36 tool pairs (NULL, DOT, LINE, RECT, ELLIPSE, FILL, BRUSH, BRUSH-SIZE, BRUSH-FILL, BRUSH-FX-OUTLINE, BRUSH-TEXT, CUSTOM-BRUSH, POLY-LINE, POLY-FILL, MARQUEE, SELECTION, PAN, MOVE, MOVE-NUDGE, SAVE, LOAD, PICKER, UNDO, WORKSPACE-UNDO, DRW, COLOR-FG, COLOR-BG, COLOR-INVERT, CROP, SPRAY, ZOOM, TEXT, SYMMETRY, RAY, IMAGE-IMPORT, REFIMG)
9. **THEME**: `ASSETS/THEMES/DEFAULT/THEME.BI` (executed at include time, sets all `THEME.*`)

### Directory Structure

| Directory | Purpose |
|-----------|---------|
| `CFG/` | Configuration types, keyboard/mouse/joystick bindings |
| `CORE/` | Performance counters, error handling, image utilities |
| `GUI/` | UI components (toolbar, status bar, palette, grid, layers, menubar, command palette, organizer, pointer/cursor) |
| `INPUT/` | Input handlers (mouse, keyboard, joystick), file loaders (BMP, PAL, BLOAD), Lospec API |
| `OUTPUT/` | Screen rendering (`SCREEN_render`), file export (BAS, BMP, BSAVE) |
| `TOOLS/` | Drawing tools (brush, line, rect, fill, marquee, etc.), undo systems, DRW format, image import |
| `ASSETS/` | Fonts, icons, palettes (56 GPL files), primitives, themes |
| `ASSETS/THEMES/DEFAULT/IMAGES/` | Theme images in subfolders: `TOOLBOX/` (toolbar icons), `DRAWER/` (organizer), `LAYERS/` (layer panel), `PALETTE/`, `PATTERNS/`, `ORPHANED/` |
| `ASSETS/THEMES/DEFAULT/FONTS/` | Theme fonts (e.g., `Tiny5-Regular.ttf`, `PICO-8.ttf`) |
| `includes/QB64_GJ_LIB/` | External utility library (BBX, DICT, STRINGS, VECT2D) |
| `DEV-ONLY/` | Test/sample files excluded from release builds (`.draw`, `.run`, `.log`, screenshots) |

### Singleton State Pattern

Each system/tool uses a shared state object:
```qb64
TYPE TOOL_OBJ
    ACTIVE AS INTEGER
    ' ... state fields
END TYPE
DIM SHARED TOOL AS TOOL_OBJ
```

Key globals: `SCRN` (screen state), `MOUSE` (input state), `CFG` (config), `THEME` (colors/icons), `CURRENT_TOOL%`, `PAINT_COLOR~&`, `PAINT_BG_COLOR~&`, `DRAW_COLOR~&` (opacity-adjusted), `CANVAS_DIRTY%`

---

## Naming Conventions

- **Types**: `UPPER_CASE` or `NAME_OBJ` (e.g., `MOUSE_OBJ`, `DRAW_GRID`)
- **Constants**: `CONST TOOL_BRUSH = 1`, `CONST KEY_ESCAPE& = 27`
- **Subs/Functions**: `Module_action` (e.g., `MOUSE_input_handler`, `FILL_flood`)
- **Type suffixes**: `%` INTEGER, `&` LONG, `~&` UNSIGNED LONG (colors), `$` STRING, `!` SINGLE

**Required at file scope**:
```qb64
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC
```

---

## Critical Gotchas (MUST READ)

### 1. NEVER Use `_DEST _CONSOLE`
**NEVER use `_DEST _CONSOLE` + `PRINT` for debug output.** This corrupts the active
drawing destination (`_DEST`) mid-frame. Even if you restore `_DEST` afterward, any
intervening code that assumes `_DEST` is set to a canvas/layer will malfunction. This has
caused rendering glitches, undo corruption, and silent data loss.

**Always use `_LOGINFO`, `_LOGWARN`, `_LOGERROR`** for all diagnostic output. These write
to the QB64-PE log system without touching `_DEST`.

### 2. Image Handle Cleanup
Valid image handles are `< -1`. Always check before freeing:
```qb64
IF handle& < -1 THEN _FREEIMAGE handle&
```

### 3. Destination/Source Context Preservation
Always save and restore `_DEST` and `_SOURCE` when changing them:
```qb64
DIM oldDest AS LONG: oldDest& = _DEST
_DEST targetImage&
' ... draw operations ...
_DEST oldDest&
```

### 4. Undo System — The #1 Source of Bugs
The undo system is the single largest source of recurring bugs. Read the entire "Undo
System Deep Dive" section below before touching any code that:
- Saves undo states (`UNDO_save_state`)
- Handles mouse button press/release
- Opens GUI menus or dialogs
- Changes `MOUSE.TOOLBAR_CLICKED%`

Common undo bugs:
- **Ghost undo states** from GUI click-release cycles (see Gotcha #13)
- **Double-saves** from missing `UNDO_saved_this_frame%` guard
- **`_DEST` corruption** from debug `PRINT` statements (see Gotcha #1)

### 5. Undo Double-Save Prevention
Check the per-frame flag before saving undo state:
```qb64
IF NOT UNDO_saved_this_frame% THEN
    UNDO_save_state
    UNDO_saved_this_frame% = TRUE
END IF
```
This flag is reset to `FALSE` every frame in `LOOP_start`. It prevents multiple undo
states from one continuous brush stroke or rapid-fire operations.

### 6. Coordinate Transformation
Mouse has three coordinate systems:
- **Raw** (`MOUSE.RAW_X/Y`): Screen pixels (for GUI hit-testing)
- **Canvas** (`MOUSE.X/Y`): Canvas pixels after zoom/pan transform + grid snap
- **Unsnapped** (`MOUSE.UNSNAPPED_X/Y`): Canvas pixels without grid snap (for fill, picker)

Formula: `canvasX% = INT((rawX% - offsetX%) / zoom!)`

### 7. Tool State Reset on Switch
When activating a tool, reset ALL other tool states to prevent interference:
```qb64
MARQUEE_reset: LINE_reset: RECT_reset: ELLIPSE_reset: POLY_LINE_reset: MOVE_reset
```

### 8. Mouse Button Press/Release Detection
Track previous state to detect transitions:
```qb64
IF MOUSE.B1% AND NOT MOUSE.OLD_B1% THEN ' Just pressed
IF NOT MOUSE.B1% AND MOUSE.OLD_B1% THEN ' Just released
```

### 9. Color Values and Theme Colors
Colors are `_UNSIGNED LONG` using `_RGB32()` or `_RGBA32()`. Access palette colors via
`PAL_color~&(index%)` function.

**Theme colors must be `_UNSIGNED LONG` (`~&`), not `INTEGER` (`%`).** An `INTEGER` field
truncates RGB32 values and then `PAL_color()` interprets them as palette indices, causing
color corruption when the palette changes. If a theme color field is `INTEGER`, the toolbar
background will change whenever the user switches palettes.

### 10. Dialog Cleanup
After native dialogs (`_MESSAGEBOX`, `_OPENFILEDIALOG$`), use `MOUSE_cleanup_after_dialog`
which: drains mouse buffer, forces buttons up, sets `SUPPRESS_FRAMES% = 2` (catches late
SDL events after GTK dialogs), clears keyboard buffer. Alternatively:
```qb64
POINTER_hide_for_dialog
' ... dialog call ...
POINTER_show_after_dialog
DO WHILE _MOUSEINPUT: LOOP
MOUSE_force_buttons_up
```
File dialogs that block the main loop should use `MOUSE.DEFERRED_ACTION%` to defer execution
to `MOUSE_input_handler_loop` (post-frame processing).

### 11. `contentDirty%` vs `BLEND_invalidate_cache`
`BLEND_invalidate_cache` invalidates composite/render ordering but does NOT mark layers
`contentDirty%`. Only set `contentDirty% = TRUE` on layers whose pixel content was
actually modified. Blanket-marking all 64 layers causes O(n) per-pixel `_MEM` opacity
recalculation (~5-6% CPU per semi-transparent layer) on every invalidation.

### 12. Scene Cache Boundary for Animations
Per-frame animations (marching ants, blinking cursors) must render AFTER `SkipToPointer:`
(step 13 in render pipeline), not before the scene cache save (step 12). Placing them
before the cache save forces `SCENE_DIRTY% = TRUE` every frame, bypassing the cache and
triggering full layer compositing at 60fps.

### 13. TOOLBAR_CLICKED% and Spurious Undo States
**`MOUSE.TOOLBAR_CLICKED%`** is the flag that prevents canvas tool actions when the user
clicks GUI elements (toolbar, organizer, menubar, palette strip, layer panel). Its lifecycle
is critical for undo correctness:

1. **Set TRUE** when any GUI element is clicked (toolbar, organizer, palette, menubar, etc.)
2. **Checked** by `MOUSE_should_skip_tool_actions%` — when TRUE, it consumes the OLD_B*
   button transition (sets OLD_B = current) so `MOUSE_dispatch_tool_release` never fires
3. **Reset FALSE** inside `MOUSE_should_skip_tool_actions%` when all buttons are released

**CRITICAL**: The reset MUST happen inside `MOUSE_should_skip_tool_actions%`, NEVER before
it in the frame pipeline. If the flag resets before the skip check, the release-frame sees
`OLD_B1%=TRUE` (from the GUI click) with the skip flag already cleared, causing
`MOUSE_dispatch_tool_release` to fire and create a spurious `UNDO_save_state` call. Each
GUI click-release cycle (open menu + click item) creates 2 phantom undo states with
identical canvas data, making undo appear to "do nothing" for those presses.

### 14. `SCENE_CHANGED%` vs `FRAME_IDLE%` for Animations
To keep animations running without forcing full scene re-render:
- Set `FRAME_IDLE% = FALSE` — keeps the render loop active
- Do NOT set `SCENE_CHANGED% = TRUE` — that forces `SCENE_DIRTY%` and full compositing

### 15. File Load Must Reset All State
`DRW_load` (specifically `DRW_load_binary`) must reset all tool and panel state after
loading a file. Stale state from the previous document causes subtle bugs like layer eye
icons not responding to clicks (stale `scrollOffset%` or `visSwiping%`).

### 16. Grid Drawing Must Be Triggered
Changing grid settings (mode, snap, align, size, visibility) requires calling `GRID_draw`
to re-render the grid into its cached image (`GRID.imgHandle&`). Without this call, the
visual grid won't update even though the state changed. Also set `SCENE_DIRTY% = TRUE`
and `FRAME_IDLE% = FALSE`.

### 17. Organizer Icon Filenames Must Match Code
The organizer widget loads icon PNGs by filename from the theme directory. The filenames
in the code must exactly match the filenames on disk. Mismatches cause silent failures
where icon state changes don't show visually (e.g., `grid-snap-center-off.png` vs
`grid-snap-off-center.png`).

### 18. `_KEYHIT` Is Unreliable for Ctrl+ Combos on Linux/SDL2
**NEVER use `_KEYHIT`-returned character codes to detect hotkeys that involve Ctrl, Alt, or
both.** On Linux under SDL2, `_KEYHIT` returns modified or suppressed values for non-letter
keys when Ctrl is held (e.g., `_KEYHIT` will not return ASCII 62 for `>` when Ctrl is held).

**Always use `_KEYDOWN(physicalKeyCode)`** for any hotkey that requires Ctrl or Alt. Pair it
with a `STATIC pressed AS INTEGER` guard to fire once per keypress, not once per frame.
**Always put Ctrl+Alt hotkeys in `KEYBOARD.BM`** (inside the appropriate `KEYBOARD_handle_*`
sub), never in `DRAW.BAS`.

Working pattern (see `ctrlAltRPressed%` in `KEYBOARD.BM` as the canonical example):
```qb64
STATIC myActionPressed AS INTEGER
IF MODIFIERS.ctrl% AND MODIFIERS.alt% AND _KEYDOWN(physicalCode&) THEN
    IF NOT myActionPressed% THEN
        CMD_execute_action ACTION_ID
        FRAME_IDLE% = FALSE
        myActionPressed% = TRUE
    END IF
ELSEIF NOT _KEYDOWN(physicalCode&) THEN
    myActionPressed% = FALSE
END IF
```

Key physical codes relevant to DRAW:
- `KEY_PGUP& = 18688` — Page Up (Ctrl+PgUp = display scale up)
- `KEY_PGDN& = 20736` — Page Down (Ctrl+PgDn = scale down, Ctrl+Alt+PgDn = scale reset)
- `46` — period `.`
- `44` — comma `,`
- `47` — slash `/`
- `82` / `114` — `R` / `r`

**Super/Windows key (100311/100312)**: Unavailable on Linux — the compositor captures it
before SDL2 sees it.

---

## Undo System Deep Dive

DRAW has **two independent undo systems** that share a single CTRL+Z/Y keybinding via
timestamp-based intelligent routing.

### Pixel Undo (`TOOLS/UNDO.BI` / `UNDO.BM`)

Stores per-layer image snapshots. Each state is a `_COPYIMAGE` of the current layer when
it was modified.

**Types**:
- `UNDO_STATE`: `img&` (image handle), `layer_index%`, `timestamp#` (TIMER value)
- `UNDO_SYSTEM`: `current%`, `count%`, `max_states%` (100)

**Storage**: `DIM SHARED UNDO_STATES(100) AS UNDO_STATE` — fixed array

**Key functions**:
- `UNDO_init`: Resets all states, saves initial blank canvas as state 0
- `UNDO_save_state`: Truncates redo branch, shifts oldest if at max, saves `_COPYIMAGE`
  of `LAYER_current_image&` with `TIMER` timestamp, sets `CANVAS_DIRTY% = TRUE`
- `UNDO_undo`: Scans backward for same-layer state, restores via `_PUTIMAGE`. If no
  previous state found, clears layer to transparent. Calls `BLEND_invalidate_cache`.
- `UNDO_redo`: Moves forward one state, restores via `_PUTIMAGE`
- `UNDO_get_last_timestamp#`: Returns TIMER value of current state for routing comparison

**Double-save prevention**: `UNDO_saved_this_frame%` (reset every frame in `LOOP_start`)

### Workspace Undo (`TOOLS/WORKSPACE-UNDO.BI` / `WORKSPACE-UNDO.BM`)

Stores structural layer operations (add, delete, rename, reorder, merge). Does NOT store
pixel data changes — those are handled by Pixel Undo.

**Action types**: `WUNDO_TYPE_LAYER_ADD=1`, `DELETE=2`, `RENAME=3`, `REORDER=4`, `MERGE=5`

**Guards**: Every save function checks `WORKSPACE_UNDO_READY%` (prevents saves during init)
and `WORKSPACE_UNDO_IN_PROGRESS%` (prevents undo/redo from creating new states).

**Callers**: All in `GUI/LAYERS.BM` — `LAYERS_new%`, `LAYERS_duplicate`, `LAYERS_delete`,
`LAYERS_rename`, `LAYERS_move_up`, `LAYERS_move_down`, `LAYERS_merge_down`.

### Intelligent CTRL+Z / CTRL+Y Routing

In `KEYBOARD_handle_clipboard_undo` and `CMD_execute_action CASE 301/302`:

```
pixelUndoTs# = UNDO_get_last_timestamp#
workspaceUndoTs# = WORKSPACE_UNDO_get_last_timestamp#

IF workspaceUndoTs# > pixelUndoTs# AND WORKSPACE_UNDO_can_undo% THEN
    WORKSPACE_UNDO_undo          ' Layer operation was more recent
ELSEIF pixelUndoTs# > 0 THEN
    UNDO_undo                    ' Pixel change was more recent
END IF
```

The system undoes whichever operation happened most recently by comparing TIMER timestamps.

### Where Undo States Are Created

**In Mouse release handlers** (`INPUT/MOUSE.BM`):
- `MOUSE_release_brush`, `MOUSE_release_dot`, `MOUSE_release_spray` — on button up
- `MOUSE_release_line`, `MOUSE_release_rect`, `MOUSE_release_ellip` — after shape commit
- Fill tool (`MOUSE_handle_fill`) — after flood fill completes
- Right-click shift-line — after connecting line drawn

**In Tool implementations**:
- `TOOLS/BRUSH.BM`: `PAINT_clear_no_prompt` (BACKSPACE key)
- `TOOLS/MOVE.BM`: Before move operations begin
- `TOOLS/TEXT.BM`: `TEXT_apply` — stamps text to canvas
- `TOOLS/MARQUEE.BM`: After marquee region actions
- `TOOLS/SELECTION.BM`: Before clear/invert selection operations
- `TOOLS/IMAGE-IMPORT.BM`: Before import operations

**In Command dispatcher** (`GUI/COMMAND.BM`):
- Copy to new layer, fill FG/BG, flip H/V, scale up/down, rotate CW/CCW

### Undo Bug Patterns (Lessons Learned)

| Bug | Root Cause | Fix |
|-----|-----------|-----|
| CTRL-Z does nothing for 2 presses after menu action | `TOOLBAR_CLICKED%` reset happened before `MOUSE_should_skip_tool_actions%`, allowing `MOUSE_dispatch_tool_release` to create phantom undo states | Move flag reset inside `MOUSE_should_skip_tool_actions%` |
| Undo broken after Palette Random | `PALETTE_LOADER_load_by_index%` had `_DEST _CONSOLE` debug prints that corrupted `_DEST` | Remove all `_DEST _CONSOLE`; use `_LOGINFO` |
| Double undo states per brush stroke | Missing `UNDO_saved_this_frame%` check | Always check flag before calling `UNDO_save_state` |

---

## Mouse Input System Deep Dive

**Files**: `INPUT/MOUSE.BI` (type), `INPUT/MOUSE.BM` (~2590 lines)

### MOUSE_OBJ Type

| Field | Type | Purpose |
|-------|------|---------|
| X, Y | INTEGER | Canvas coordinates (zoom/pan-adjusted, grid-snapped) |
| OLD_X, OLD_Y | INTEGER | Previous frame canvas coordinates |
| RAW_X, RAW_Y | INTEGER | Raw screen pixel coordinates (for GUI hit-testing) |
| UNSNAPPED_X, UNSNAPPED_Y | INTEGER | Canvas coords before grid snap (for fill, picker) |
| B1, B2, B3 | INTEGER | Current button states |
| OLD_B1, OLD_B2, OLD_B3 | INTEGER | Previous frame button states (for transition detection) |
| TOOLBAR_CLICKED% | INTEGER | GUI click flag — prevents canvas tool actions |
| DEFERRED_ACTION% | INTEGER | Post-frame file dialog (0=none, 1=save, 2=import, 3=open DRW) |
| SUPPRESS_FRAMES% | INTEGER | Frames to suppress input after dialog cleanup |

### Single-Frame Processing Flow

```
MOUSE_input_handler()
├── Special modes: REFIMG reposition / IMAGE_IMPORT direct polling
├── MOUSE_process_frame%()                    ← main frame processing
│   ├── MOUSE_drain_update_state()            ← drain all _MOUSEINPUT, accumulate wheel,
│   │                                            convert screen→canvas, grid snap, clamp
│   ├── MOUSE_handle_suppress_frames%()       ← force buttons FALSE for N frames post-dialog
│   ├── MOUSE_handle_gui_early%()             ← command palette, menubar, palette menu close
│   │   ├── MOUSE_autocommit_move_if_click_on_gui()
│   │   ├── MOUSE_handle_command_palette_click%()
│   │   ├── MOUSE_handle_menubar_mouse_move()
│   │   ├── MOUSE_handle_menubar_click%()     ← sets TOOLBAR_CLICKED% on menu clicks
│   │   └── MOUSE_handle_palette_menu_close%()
│   ├── MOUSE_handle_symmetry_ctrl_click()
│   ├── MOUSE_update_draw_color()             ← applies opacity to paint color
│   ├── MOUSE_handle_gui_panels()             ← layer panel, toolbar, status, palette strip
│   │   ├── MOUSE_handle_layer_panel()
│   │   └── MOUSE_handle_toolbar_status_palette()  ← sets TOOLBAR_CLICKED% on GUI clicks
│   ├── MOUSE_handle_alt_picker()
│   ├── MOUSE_handle_space_pan()
│   ├── MOUSE_handle_b3_dblclick_reset_zoom()
│   ├── MOUSE_handle_ui_autohide_restore()
│   ├── MOUSE_handle_panning()
│   ├── MOUSE_should_skip_tool_actions%()     ← checks TOOLBAR_CLICKED%, consumes OLD_B*,
│   │                                            resets flag when buttons released
│   └── MOUSE_handle_tool_phase()
│       ├── MOUSE_dispatch_tool_hold()        ← SELECT CASE CURRENT_TOOL% for drawing
│       ├── MOUSE_dispatch_tool_release()     ← commits shapes, creates undo states
│       └── MOUSE_handle_right_click()
├── MOUSE_post_process()                      ← wheel events, marquee updates
│
MOUSE_input_handler_loop()                    ← post-render, end of main loop
├── Update OLD_X/Y, OLD_B1/B2/B3
└── Process DEFERRED_ACTION% (file dialogs)
```

### Key Mechanisms

**Drain-then-process pattern**: `MOUSE_drain_update_state` consumes ALL queued `_MOUSEINPUT`
events in a tight loop, then a single processing pass runs against the final state snapshot.
This is critical for performance — processing every mouse event individually would cause
multiple draw operations per frame.

**SUPPRESS_FRAMES%**: Set to 2 by `MOUSE_force_buttons_up` / `MOUSE_cleanup_after_dialog`.
SDL2 can produce spurious button events when the window regains focus after a GTK/native
dialog closes, arriving 1-2 frames after the dialog. This suppression catches them.

**DEFERRED_ACTION%**: File dialogs (`_OPENFILEDIALOG$`, `_SAVEFILEDIALOG$`) block the main
loop. To avoid corrupting mouse state mid-processing, toolbar clicks set
`MOUSE.DEFERRED_ACTION%` and the actual dialog opens in `MOUSE_input_handler_loop` (after
all mouse processing is complete). Values: 1=save, 2=import image, 3=open DRW project.

---

## Menu Bar System

**Files**: `GUI/MENUBAR.BI`, `GUI/MENUBAR.BM` (~1382 lines)

### Root Menus (indices 0-8)

FILE(0), EDIT(1), VIEW(2), SELECT(3), TOOLS(4), BRUSH(5), LAYER(6), PALETTE(7), HELP(8)

### Key Mechanisms

- **ALT tap toggle**: ALT pressed then released without other keys = toggle FILE menu
- **Keyboard navigation (`kbActive%`)**: Arrow keys navigate root/submenu items. When
  `kbActive% = TRUE`, mouse hover is ignored until the mouse actually moves. This prevents
  the mouse cursor position from overriding keyboard-driven menu selection.
- **Recent files submenu**: Cascading submenu for action ID 213 (File > Recent). Uses
  `MENU_BAR.recentX/Y/W/H` for bounds. Right arrow opens, Left/Escape closes. Full
  keyboard + mouse navigation with Clear Recent option.
- **Dynamic state sync**: `MENUBAR_update_checkboxes` syncs checkboxes from live app state
  (grid, snap, tool visibility), updates enabled states (undo/redo availability, paste
  buffer, recent files list).
- **Click dispatch**: `MENUBAR_handle_click` identifies which item was clicked and calls
  `CMD_execute_action` with the item's `actionId`.

---

## Command System

**Files**: `GUI/COMMAND.BI`, `GUI/COMMAND.BM` (~1992 lines)

`CMD_execute_action(action_id%)` is the central dispatcher for ALL application actions.
Menu items, keyboard shortcuts, command palette, and toolbar clicks all funnel through here.

### Action ID Ranges

| Range | Category | Key Actions |
|-------|----------|-------------|
| 101-117 | Tools | Brush, Dot, Fill, Picker, Line, Polygon, Rect, Ellipse, Marquee, Move, Text, MagicWand |
| 201-213 | File | Open, Save, SaveAs, Export, Import, New, Template, Revert, Recent, Exit |
| 301-323 | Edit | Undo, Redo, Copy, Cut, Paste, Clear, Select All, Fill FG/BG, Flip, Scale, Rotate, CopyToNewLayer |
| 401-413 | View | Toolbar, StatusBar, LayerPanel, MenuBar, Zoom, DisplayScale, Cursors |
| 408 | View | Display Scale Up (`Ctrl+PgUp`) |
| 409 | View | Display Scale Down (`Ctrl+PgDn`) |
| 416 | View | Display Scale Reset (`Ctrl+Alt+PgDn`) |
| 501-517 | Color | Opacity presets (10-100%), Swap FG/BG |
| 601-609 | Brush | Size dec/inc, presets, preview, shape, pixel perfect |
| 701-710 | Layer | New, Delete, MoveUp/Down, MergeDown, MergeVisible, Duplicate, ArrangeTop/Bottom |
| 801-802 | Canvas | Pan, Reset Pan |
| 901-908 | Grid | Toggle, Pixel Grid, Snap, Size, AlignMode, MatchBrush, CellFill |
| 1001-1003 | Symmetry | Cycle, Clear, Set Center |
| 1101-1112 | Custom Brush | Capture, Clear, Recolor, Outline, Flip, Scale, Export, Rotate |
| 1201-1206 | Assistants | Constrain, AngleSnap, Square/Circle, Center, Clone, TempPicker |
| 1401-1409 | Selection | SelectFromLayer, Nudge 1/10px |
| 1501-1513 | Palette/Ref | RefImage, Palette Import/Export/Random, Color Picker, Swap FG/BG |
| 1601-1607 | Help | About, CheatSheet, Manual, GitHub, Issues, Credits |
| 1701-1704 | Tools (menu) | Zoom, Spray, CmdPalette, CodeExport |

### Command Palette

Opened with Ctrl+Shift+P. Fuzzy search against all registered commands. `CMD_fuzzy_match%`
checks if search characters appear in order in target string. Supports keyboard navigation
(up/down/page up/page down) and mouse clicks.

---

## Main Loop Structure (DRAW.BAS)

```
DO
    1. Deferred command-line file loading (first frame only)
    2. Windows drag-and-drop handling (_ACCEPTFILEDROP)
    3. k& = _KEYHIT + MODIFIERS_track_alt_keyhit + MODIFIERS_update
    4. LOOP_start — resets UNDO_saved_this_frame%, calls TITLE_check
    5. MOUSE_input_handler (perf tracked)
    6. KEYBOARD_input_handler (perf tracked)  ← display scale hotkeys handled here
    7. STICK_input_handler (perf tracked)
    8. Idle detection → sets FRAME_IDLE%, SCENE_DIRTY%
    9. IF NOT FRAME_IDLE% THEN SCREEN_render
   10. _LIMIT (IDLE_FPS_LIMIT=15 when idle, CFG.FPS_LIMIT%=60 otherwise)
   11. MOUSE/KEYBOARD/STICK_input_handler_loop (post-render)
   12. PERF_frame_end, LOOP_end
LOOP
```

### CRITICAL: `_LIMIT` Placement

**`_LIMIT` MUST come AFTER `SCREEN_render` / `_DISPLAY`, never before.** Placing `_LIMIT`
before render introduces a full frame of latency between reading mouse input and displaying
the cursor — the pointer visibly lags behind the mouse. The correct order is:

```
Input → Render → _DISPLAY → _LIMIT (wait) → next frame
```

### Idle Detection & Scene Cache

The main loop implements a two-tier optimization to save CPU:

1. **Frame idle detection** (`FRAME_IDLE%`): Checked after input handlers. A frame is
   "idle" when no keys, buttons, mouse movement, wheel, tools, or GUI changes occurred.
   Idle frames skip `SCREEN_render` entirely (previous frame stays on display) and throttle
   to `IDLE_FPS_LIMIT` (15 FPS). Active frames run at `CFG.FPS_LIMIT%` (default 60).

2. **Scene cache** (`SCENE_CACHE&`, `SCENE_DIRTY%`): Within `SCREEN_render`, when only the
   cursor moved (mouse moved but no scene-changing event like button press, key, or GUI
   update), `SCENE_DIRTY%` stays FALSE. The renderer takes a fast path: copies the cached
   scene image then jumps to `SkipToPointer:` to only redraw the pointer. This avoids
   full layer compositing, grid rendering, and tool preview drawing for cursor-only updates.

**What sets `SCENE_DIRTY%`**: Key press, mouse button held, GUI redraw needed, panning,
scroll wheel, active tool states (move, text, import, command palette), menubar open.

**What sets `FRAME_IDLE% = FALSE` but NOT `SCENE_DIRTY%`**: Mouse movement alone (cursor
update via scene cache fast path), and active selections (marching ants animate after
`SkipToPointer:` so they don't force full compositing).

**CRITICAL**: Never set `SCENE_CHANGED% = TRUE` for per-frame animations. Use
`FRAME_IDLE% = FALSE` to keep rendering active, and draw the animation after
`SkipToPointer:` so it works in both the full-render and cache-hit paths.

### Idle Detection Logic (what triggers activity)

```qb64
IF k& <> 0 THEN FRAME_IDLE% = FALSE: SCENE_CHANGED% = TRUE           ' Key pressed
IF MOUSE.B1% OR MOUSE.B2% OR MOUSE.B3% THEN ...                      ' Button held
IF MOUSE.RAW_X% changed OR MOUSE.RAW_Y% changed THEN FRAME_IDLE% = FALSE ' Mouse moved
IF GUI_NEEDS_REDRAW% THEN ...                                         ' GUI state changed
IF SCRN.panning% THEN ...                                             ' Panning active
IF MODIFIERS.shift% THEN ...                                          ' SHIFT held
IF MOUSE.SW% <> 0 THEN ...                                            ' Wheel scrolled
IF CURRENT_TOOL% = TOOL_MOVE AND MOVE.ACTIVE THEN ...                 ' Active transform
IF CURRENT_TOOL% = TOOL_TEXT AND TEXT.ACTIVE THEN ...                  ' Active text entry
IF IMG_IMPORT.STATE > IMPORT_STATE_IDLE THEN ...                       ' Importing image
IF CMD_PALETTE.visible THEN ...                                        ' Command palette open
IF MENUBAR_is_open% THEN ...                                           ' Menu bar open
IF SELECTION_has_active% THEN FRAME_IDLE% = FALSE                      ' Marching ants only
IF SCENE_CHANGED% THEN SCENE_DIRTY% = TRUE
```

### Tool Lifecycle Pattern

1. **Activate**: Switch via keyboard shortcut, toolbar click, or command palette
2. **Reset others**: Call reset subs for all other tools
3. **Mouse down**: Save undo state (before drawing), begin operation
4. **Mouse move**: Update tool state (end coordinates, preview)
5. **Mouse up**: Commit drawing to layer image via `MOUSE_dispatch_tool_release`, call
   `UNDO_save_state` (after drawing), reset tool drag state
6. **Preview**: Rendered in `SCREEN_render()` during drag operations (drawn on canvas
   BEFORE scene cache save, so previews are cached when scene isn't dirty)

---

## Rendering Pipeline (SCREEN_render)

Composited back-to-front onto `SCRN.CANVAS&`, then GPU-scaled to window via `_PUTIMAGE`:

1. Transparency checkerboard
2. Layer compositing (by zIndex, bottom-to-top)
   - Normal blend: direct `_PUTIMAGE` (fast path when all layers are Normal)
   - Non-Normal blend: per-pixel composite via `COMPOSITE_BUFFER&` using `_MEM` access
   - Partial composite cache: layers below current layer cached in `COMPOSITE_BELOW_CACHE&`
   - Opacity adjustment: cached per-layer in `opacityCacheImg&` (invalidated by `contentDirty%`)
3. Grid overlay (regular grid at 100%+ zoom, pixel grid at 400%+ zoom with cached image)
4. Symmetry guides
5. Canvas border
6. Image import preview
7. **Tool previews** (marquee, line, rect, ellipse, polygon, move, text, zoom)
8. GUI layer (`SCRN.GUI&` — toolbar, status bar, palette strip, layer panel)
9. Image import / move status bars
10. Crosshair (SHIFT held)
11. Command palette
12. **Scene cache save** → `SCENE_CACHE&` (everything above, before pointer/overlays)
13. `SkipToPointer:` label — fast path target for cursor-only updates
14. **Selection overlay** (marching ants) — drawn AFTER cache so animation doesn't
    invalidate it
15. Pointer cursor (POINTER_update + POINTER_render)
16. Scale `SCRN.CANVAS&` to window (integer scaling via `glutReshapeWindow`, nearest neighbor)
17. `_DISPLAY`

### Performance Patterns

- **Persistent buffers**: `COMPOSITE_BUFFER&`, `SCENE_CACHE&`, `PG_CACHE_IMG&` allocated
  once and reused. Never `_NEWIMAGE`/`_FREEIMAGE` every frame.
- **Conditional GUI redraw**: `GUI_NEEDS_REDRAW%` gates toolbar/status/palette/layer panel
  re-rendering. Set it TRUE when GUI state changes.
- **Layer render order**: `RENDER_ORDER%()` lookup table, rebuilt when `RENDER_ORDER_DIRTY%`.
- **Opacity cache**: Per-layer `opacityCacheImg&` with `opacityCacheVal%` and `contentDirty%`.
  Cache hit = skip expensive per-pixel `_MEM` opacity loop. Mark `contentDirty% = TRUE`
  **only** when actual pixel content changes on a layer.
- **`contentDirty%` discipline**: `BLEND_invalidate_cache` does NOT mark layers
  `contentDirty%`. It only sets `BLEND_COMPOSITE_DIRTY%`, `RENDER_ORDER_DIRTY%`,
  `SCENE_DIRTY%`, and `COMPOSITE_BELOW_VALID% = FALSE`.
- **Blend composite cache**: `COMPOSITE_BELOW_CACHE&` stores composited layers below
  `CURRENT_LAYER%`. When only the current layer changes, layers below are restored from
  cache instead of re-composited.

---

## Layer System

**Files**: `GUI/LAYERS.BI`, `GUI/LAYERS.BM` (~2305 lines)

### DRAW_LAYER Type

| Field | Type | Purpose |
|-------|------|---------|
| zIndex | INTEGER | Compositing order |
| imgHandle& | LONG | QB64 image handle for pixel data |
| visible | INTEGER | Layer visibility |
| name | STRING*64 | Layer name |
| opacity | INTEGER | 0-255 |
| opacityLock | INTEGER | Prevent alpha changes |
| blendMode | INTEGER | One of 19 blend modes |
| contentDirty% | INTEGER | Marks pixel content changed (invalidates opacity cache) |
| opacityCacheImg& | LONG | Cached opacity-adjusted image |

Max 64 layers. 19 blend modes (Normal through Divide).

`LAYER_current_image&`: Returns `LAYERS(CURRENT_LAYER%).imgHandle&` or falls back to
`SCRN.PAINTING&` if invalid.

### Layer Panel

Full drag-and-drop reorder, visibility swiping, solo mode, opacity slider drag, scroll
with mousewheel. State stored in `LAYER_PANEL` UDT.

---

## Palette System

### Palette Loader (`GUI/PALETTE-LOADER.BI/BM`)

56 hardcoded palettes registered in `PALETTE_LOADER_scan_folder`. Loads GPL (GIMP Palette)
format. Palettes stored in `PALETTE_LIST(0 TO 255) AS PALETTE_INFO`.

- `PALETTE_LOADER_next%` / `PALETTE_LOADER_prev%`: Cycle with wrapping
- `PALETTE_LOADER_load_by_index%`: Load specific palette by index
- `PALETTE_LOADER_CURRENT_IDX%`: Currently active palette index
- `PALETTE_EMBEDDED_NAME$` / `PALETTE_EMBEDDED_ACTIVE%`: For palettes embedded in .draw files

### Palette Strip (`GUI/PALETTE-STRIP.BI/BM`)

Dynamic-height color swatch strip at screen bottom. Multi-row support configurable via
`CFG.PALETTE_CHIPS_ROW_THRESHOLD%`. FG/BG indicators with white+black outlines. Palette
dropdown menu with scroll. Left/Right buttons for palette navigation.

---

## Grid System

**Files**: `GUI/GRID.BI`, `GUI/GRID.BM` (~957 lines)

4 grid modes: `GRID_MODE_SQUARE=0`, `DIAGONAL=1`, `ISOMETRIC=2`, `HEX=3`
2 alignment modes: `GRID_ALIGN_CORNER=0`, `CENTER=1`

**`GRID_draw`**: Pre-renders grid lines into `GRID.imgHandle&`. MUST be called whenever
grid settings change (mode, size, alignment, visibility). The grid image is drawn onto the
canvas during `SCREEN_render` at the appropriate zoom level.

**`GRID_snap_xy`**: Snaps coordinates to grid cell boundaries based on current mode and
alignment.

---

## Organizer Panel

**Files**: `GUI/ORGANIZER.BI`, `GUI/ORGANIZER.BM` (~567 lines)

3x3 grid of widget buttons beneath the toolbar. 8 slots:

| Slot | ID | Purpose | Mousewheel Action |
|------|----|---------|-------------------|
| 0 | ORG_CANVAS_OPS | Canvas operations | — |
| 1 | ORG_BRUSH_SIZE | Brush size | Cycles through 4 size presets |
| 2 | ORG_PATTERN_MODE | Pattern mode | — |
| 3 | ORG_TRANSFORM_OPS | Transform ops | — |
| 4 | ORG_COLOR_MODE | Color mode | — |
| 5 | ORG_SYMMETRY_MODE | Symmetry | Cycles 4 states (off + 3 modes) |
| 6 | ORG_GRID_VIS | Grid visibility | Cycles grid modes (must call `GRID_draw`) |
| 7 | ORG_GRID_SNAP | Grid snap | Toggles snap + alignment |

Each widget has up to 4 state images loaded from the theme directory.

---

## Native File Format (.draw)

The `.draw` format is a **valid PNG image** containing a custom ancillary `drAw` chunk
before the IEND marker. The PNG image data is a flattened preview of all visible layers.
The `drAw` chunk contains DEFLATE-compressed binary project data.

### drAw Chunk Payload

```
[2 bytes] Chunk format version (little-endian INTEGER)
[4 bytes] Uncompressed data size (little-endian LONG)
[N bytes] DEFLATE-compressed binary project data
```

### Binary Project Data

| Section | Fields | Version |
|---------|--------|---------|
| Header | Magic `"DRW1"`, version(2), canvasW(4), canvasH(4) | v1+ |
| Palette | count(2), colors(4 each), fg_idx(2), bg_idx(2) | v1+ |
| Layers | count(2), current(2), per-layer: name(16), visible(2), opacity(2), zIndex(2), blendMode(2), opacityLock(2), pixel data (W×H×4) | v1+ |
| Tool State | tool(2), brush_size(2), pixel_perfect(2), grid_visible(2), grid_size(2) | v1+ |
| Palette Name | name(64) | v3+ |
| Reference Image | hasImage(2), filename(260), posX/Y(4), scaleW/H(4), visible(2), opacity(2) | v4+ |
| Brush Shape | shape(2) | v5+ |
| Grid State | mode(2), cellFill(2), snap(2), alignMode(2) | v6+ |

- Constants: `DRW_MAGIC$ = "DRW1"`, `DRW_VERSION% = 6`, `DRW_CHUNK_VERSION% = 1`
- Extension: `.draw` (changed from `.drw` in v0.7.4 to avoid CorelDRAW conflict)
- `DRW_load filename$` — auto-detects PNG vs legacy binary format
- `DRW_save` — creates flattened PNG + embeds drAw chunk
- `DRW_save_dialog` / `DRW_open_dialog` — set `CURRENT_DRW_FILENAME$`, add to recent files

### State Reset on File Load

`DRW_load_binary` resets all tool/panel state after loading:
```qb64
UNDO_init
WORKSPACE_UNDO_clear
MARQUEE_reset
MOVE_init
MAGIC_WAND_reset
LAYER_PANEL.scrollOffset% = 0
LAYER_PANEL.soloLayer% = 0
LAYER_PANEL.visSwiping% = FALSE
LAYER_PANEL.dragPending% = FALSE
LAYER_PANEL.isDragging% = FALSE
LAYER_PANEL.dragLayerIdx% = 0
LAYER_PANEL.opacityDrag% = FALSE
```

When adding new tool or panel state, ensure `DRW_load_binary` resets it too.

---

## Config System

**Files**: `CFG/CONFIG.BI`, `CFG/CONFIG.BM` (~1019 lines)

Config file: `DRAW.cfg` — plain text, one `key=value` per line. Loaded by `CONFIG_load`,
saved by `CONFIG_save`.

### Key Config Fields

| Category | Fields |
|----------|--------|
| Display | DISPLAY_SCALE%, FULLSCREEN%, FPS_LIMIT% |
| Canvas | SCREEN_WIDTH%, SCREEN_HEIGHT% |
| Palette | DEFAULT_PALETTE$, PALETTE_CHIP_WIDTH/HEIGHT%, PALETTE_MIN/MAX_ROWS% |
| Brush | DEFAULT_TOOL%, DEFAULT_BRUSH_SIZE%, DEFAULT_BRUSH_SHAPE% |
| Grid | GRID_MODE%, GRID_SIZE_X/Y%, GRID_CELL_FILL% |
| Undo | WORKSPACE_UNDO_MAX_STATES% |
| Per-op dirs | LAST_DIR_OPEN$, LAST_DIR_SAVE$, LAST_DIR_IMPORT$, LAST_DIR_EXPORT_BRUSH/LAYER$, LAST_DIR_PALETTE$ |
| Template | TEMPLATE_DIR$ |

Defaults: DOT tool, brush size 1, square shape, 60 FPS, auto-detect scale (90% of desktop, up to 4x cap), 128×128 canvas, 4 layers.

### Auto-Detection (First Launch)

When `DISPLAY_SCALE=0` or no config exists, `SCREEN_detect_display_scale%` targets 90% of
desktop resolution and finds the highest integer scale (capped at 4) where the viewport is
at least 320×200. Viewport dimensions = (desktop × 0.9) ÷ scale, rounded to even pixels.
`TOOLBAR_SCALE=0` auto-detects from viewport height (≥800=4x, ≥600=3x, ≥400=2x, else 1x).
Manual `DISPLAY_SCALE` supports up to `DISPLAY_SCALE_MAX` (8). All auto-detected values are
saved to the config file on first launch via `CONFIG_NEEDS_INITIAL_SAVE%`.

---

## Theme System

**Files**: `CFG/CONFIG-THEME.BI` (DRAW_THEME UDT + DECLARE), `CFG/CONFIG-THEME.BM` (runtime loader), `ASSETS/THEMES/DEFAULT/THEME.BI` (compiled-in defaults), `ASSETS/THEMES/DEFAULT/THEME.CFG` (runtime overrides)

### Two-Tier Theme Loading

Theme values are applied in two stages:
1. **Compile time** (`THEME.BI`): Hardcoded defaults set at include time. Always present. Serves as fallback.
2. **Runtime** (`THEME.CFG`): Human-editable `key=value` text file in the theme directory. Loaded in `SCREEN_init` by `THEME_load` after `CONFIG_load`. Overrides any compiled-in defaults. **Edit this file to change theme colors without recompiling.**

`THEME_load` (in `CFG/CONFIG-THEME.BM`) parses `ASSETS/THEMES/DEFAULT/THEME.CFG`, dispatching via `SELECT CASE UCASE$(key$)`. Colors are specified as `R,G,B,A` and parsed by `THEME_parse_rgba~&(val$)`.

### DRAW_THEME UDT Fields

Theme colors are `_UNSIGNED LONG` (`~&`) for RGB32 values. **Never use `INTEGER` for color fields** — it truncates RGB32 and causes corruption when the palette changes.

Key fields added in v0.9.0:

| Field | Type | Purpose |
|-------|------|------|
| `TOOLBAR_btn_overlay~&` | `_UNSIGNED LONG` | Fill color of active toolbar button overlay (default: `_RGBA32(0,0,0,128)`) |
| `TOOLBAR_btn_stroke~&` | `_UNSIGNED LONG` | Border color of active toolbar button indicator (default: `_RGBA32(255,255,255,255)`) |
| `GLOBAL_FONT_FILE AS STRING` | `STRING` | Filename of main UI font (e.g., `Tiny5-Regular.ttf`); resolved via `THEME_font_path$()` |
| `ALT_FONT_FILE AS STRING` | `STRING` | Filename of alternate font (e.g., `PICO-8.ttf`); resolved via `THEME_font_path$()` |

### `THEME_font_path$(filename$)`

Declared in `CFG/CONFIG-THEME.BI`, implemented in `CFG/CONFIG-THEME.BM`. Resolves a font filename to an absolute path using a two-tier fallback:
1. `ASSETS/THEMES/{CFG.THEME$}/FONTS/{filename}` — theme-specific font
2. `ASSETS/FONTS/{filename}` — global fallback

Logs `_LOGERROR` if neither location exists. **Always use this function** for `_LOADFONT` calls instead of hardcoded paths.

```qb64
' Correct pattern for loading theme fonts:
DIM fontPath AS STRING
fontPath = THEME_font_path$(THEME.GLOBAL_FONT_FILE$)
IF myFont& < -1 THEN _FREEFONT myFont&
myFont& = _LOADFONT(fontPath, fontSize%, "MONOSPACE")
```

### Theme Image Subfolders

All theme images are stored in subfolders under `ASSETS/THEMES/{name}/IMAGES/`:
- `TOOLBOX/` — toolbar button icons (loaded by `GUI/TOOLBAR.BM`)
- `DRAWER/` — organizer widget icons (loaded by `GUI/ORGANIZER.BM`)
- `LAYERS/` — layer panel icons (loaded by `GUI/LAYERS.BM`)
- `PALETTE/` — palette-related icons
- `PATTERNS/` — pattern/brush pattern images
- `ORPHANED/` — images with no current code references (see README.md in that folder)

**Custom themes** must use this subfolder structure. Image references in code already include the subfolder prefix (e.g., `themeImgDir$ + "IMAGES/TOOLBOX/" + iconName$`).
1. A filled rectangle (`LINE ... BF`) in `TOOLBAR_btn_overlay~&` over the whole button
2. Four non-overlapping filled border rectangles in `TOOLBAR_btn_stroke~&` (top, bottom, left inset, right inset)

Border thickness scales with `TOOLBAR_SCALE` (`bt% = scale%`, minimum 1). The four-rect approach (not `LINE ... B`) is required to avoid double alpha-compositing at corners, which would make corners appear brighter than edges.

Cursor configuration defines 13 cursor types with PNG filenames and hotspot expressions.

---

## Stroke Opacity System (`_COMMON.BM`)

For sub-100% paint opacity, overlapping brush dabs within a single stroke must not compound:

1. **`STROKE_begin`**: On mouse down (if `PAINT_OPACITY% < 100`), saves `_COPYIMAGE` of
   current layer as `STROKE_BACKUP&`
2. **Drawing**: Brush paints at full alpha during the stroke
3. **`STROKE_commit`**: On mouse up, per-pixel `_MEM` lerp between backup (original) and
   current (full-opacity stroke) by `PAINT_OPACITY%`, producing correct blended result

---

## Window Title Bar

`DRAW v0.9.0 - myart.draw *`

- **`TITLE_update`** (`_COMMON.BM`): Builds title string. Prefers `CURRENT_DRW_FILENAME$`.
- **`TITLE_check`** (`_COMMON.BM`): Called every frame in `LOOP_start`. Only calls `_TITLE`
  when dirty state or filename actually changes (avoids per-frame string allocation + syscall).

---

## OS Integration & Icons

### Application Icon

- **`$EXEICON:'./ASSETS/ICONS/icon.ico'`** in `DRAW.BAS` — Windows only, embeds icon in .exe
- **`_ICON` + `_LOADIMAGE`** in `SCREEN_init` — runtime window icon via SDL2 (all platforms)
- **macOS `.app` bundle**: Created by CI workflow and `install-mac.command`, uses `icon.icns`

### Platform Installers

| Script | What It Does | Uninstall |
|--------|--------------|-----------|
| `install-linux.sh` | Desktop launcher, MIME type `application/x-draw-project`, hicolor icons | `--uninstall` |
| `install-windows.cmd` | Per-user registry: `.draw` → `DRAW.Project` file assoc + icon | `/uninstall` |
| `install-mac.command` | `~/Applications/DRAW.app` bundle with Info.plist, UTI + doc type | `--uninstall` |

---

## Cache Invalidation Rules

### When to mark `contentDirty%`

Set `LAYERS(idx%).contentDirty% = TRUE` when layer pixel content actually changes:
- Drawing/painting on a layer (brush stroke committed)
- `LAYERS_clear` (already sets it)
- `LAYERS_merge_down` (target layer gets merged pixels)
- `LAYERS_duplicate` (new layer gets copied pixels)
- `WORKSPACE_UNDO_undo` / `WORKSPACE_UNDO_redo` (may restore layer pixel data)
- Any operation using `_COPYIMAGE` or `_PUTIMAGE` to modify layer `imgHandle&`

Do NOT blanket-set `contentDirty%` on all layers in `BLEND_invalidate_cache`.

### When to call `BLEND_invalidate_cache`

Call when layer structure or visibility changes (not pixel content):
- Layer added, deleted, reordered
- Layer visibility toggled, opacity changed, blend mode changed
- Current layer selection changed
- File loaded (`DRW_load`)

### Scene cache boundary

Anything rendered **before** step 12 (`SCENE_CACHE&` save) is cached and only redrawn
when `SCENE_DIRTY%` is TRUE. Anything rendered **after** step 13 (`SkipToPointer:`) is
redrawn every active frame regardless of `SCENE_DIRTY%`.

**Rule**: Per-frame animations MUST be rendered after `SkipToPointer:`. If placed before
the scene cache save, they force `SCENE_DIRTY% = TRUE` every frame, defeating the cache.

---

## Key Files for Onboarding

| File | Contains |
|------|----------|
| `_COMMON.BI` | Core types (`SCREEN_OBJ`, `MOUSE_OBJ`), global state, tool constants |
| `_COMMON.BM` | Stroke system, title bar, paint helpers |
| `DRAW.BAS` | Main loop, application entry point |
| `GUI/GUI.BI` | Additional tool constants, GUI context |
| `GUI/COMMAND.BM` | Central action dispatcher (all 200+ commands) |
| `INPUT/MOUSE.BM` | Mouse processing pipeline (~2590 lines) |
| `INPUT/KEYBOARD.BM` | Keyboard shortcuts and handler |
| `TOOLS/UNDO.BM` | Pixel undo system |
| `TOOLS/WORKSPACE-UNDO.BM` | Workspace undo system |
| `OUTPUT/SCREEN.BM` | Render pipeline (`SCREEN_render`) |
| `GUI/LAYERS.BM` | Layer management (~2305 lines) |
| `GUI/MENUBAR.BM` | Menu bar with keyboard nav |
| `CFG/CONFIG.BI` | Configuration structure |
| `CHEATSHEET.md` | All keyboard shortcuts |

---

## QB64-PE APIs Frequently Used

- **Graphics**: `_NEWIMAGE`, `_COPYIMAGE`, `_PUTIMAGE`, `_FREEIMAGE`, `_LOADIMAGE`
- **Drawing context**: `_DEST`, `_SOURCE`, `_BLEND`, `_DONTBLEND`, `_SETALPHA`
- **Memory**: `_MEM`, `_MEMIMAGE`, `_MEMGET`, `_MEMPUT`, `_MEMFREE` (per-pixel blending)
- **Input**: `_KEYHIT`, `_KEYDOWN()`, `_MOUSEINPUT`, `_MOUSEWHEEL`, `_MOUSEMOVE`
- **Dialogs**: `_MESSAGEBOX()`, `_OPENFILEDIALOG$()`, `_SAVEFILEDIALOG$()`
- **Logging**: `_LOGINFO`, `_LOGWARN`, `_LOGERROR` — **ALWAYS use these, NEVER `_DEST _CONSOLE`**
- **Compression**: `_DEFLATE$`, `_INFLATE$` (DRW file format)
- **CRC**: `_CRC32` (PNG chunk checksums)
- **System**: `_TITLE`, `_LIMIT`, `_FULLSCREEN`, `_DESKTOPWIDTH/HEIGHT`

---

## Adding New Tools

1. Create `TOOLS/MYTOOL.BI` (TYPE + DIM SHARED + init call)
2. Create `TOOLS/MYTOOL.BM` (implementation)
3. Add `CONST TOOL_MYTOOL` to `_COMMON.BI` or `GUI/GUI.BI`
4. Add includes to `_ALL.BI` and `_ALL.BM`
5. Add keyboard binding in `KEYBOARD_tools()`
6. Add action ID in `CMD_init` and handler in `CMD_execute_action`
7. Add mouse handling: hold in `MOUSE_dispatch_tool_hold`, release in
   `MOUSE_dispatch_tool_release` (with `UNDO_save_state` on commit)
8. Add preview rendering in `SCREEN_render()` if needed (before scene cache save)
9. Register menu item in `MENUBAR_init` with action ID
10. Ensure `DRW_load_binary` resets any new tool state
