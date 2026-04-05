---
applyTo: "**"
---

# DRAW Project — Core Context

**Always start sessions with `#qb64pe`** to activate the QB64-PE MCP server.

**Project**: DRAW is a pixel art editor in QB64-PE by grymmjack (Rick Christy). Unique feature: exports artwork as QB64 source code. Build: `qb64pe -w -x -o DRAW.run DRAW.BAS`. Version: `APP_VERSION$` in `_COMMON.BI`.

---

## Architecture

### BI/BM File Separation

- **`.BI`**: Declarations only — `TYPE`, `CONST`, `DIM SHARED`, `DECLARE`
- **`.BM`**: Implementations only — `SUB`, `FUNCTION` bodies
- **`$INCLUDEONCE`** at the top of every BI/BM file
- **`_ALL.BI`** / **`_ALL.BM`**: master include chains in dependency order

### Include Order

1. `_COMMON.BI` — core types and globals
2. **CORE**: PERF, ERROR, IMAGE, PATHS
3. **CFG**: CONFIG, CONFIG-THEME, CONFIG-KEYBOARD, CONFIG-MOUSE, CONFIG-STICK, BINDINGS-\*
4. **GUI**: PALETTE, PALETTE-LOADER, PALETTE-STRIP, GUI, BRUSHES, CROSSHAIR, GRID, HELP, LAYERS, PALETTE-PICKER, PICKER, CURSOR, POINTER, STATUS, TOOLBAR, ORGANIZER, DITHER, DRAWER, PREVIEW, EDITBAR, ADVANCEDBAR, TOOLTIP, TRANSPARENCY, COMMAND, MENUBAR, SCROLLBAR, DIALOG, IMGADJ, IMAGE-ADJ, POPUP-MENU, STROKE-SEL
5. **INPUT**: MODIFIERS, KEYBOARD, MOUSE, STICK, FILE-BMP, FILE-BLOAD, FILE-PAL, FILE-ASE, FILE-PSD, API-LOSPEC
6. **OUTPUT**: SCREEN, FILE-BAS, FILE-BMP, FILE-BSAVE, FILE-EXPORT
7. **QB64_GJ_LIB**: DICT, STRINGS, VECT2D, TEXT_INPUT, MSG_BOX, COLOR_PICKER, FILE_DIALOG
8. **TOOLS**: 39 tool pairs (NULL, DOT, LINE, RECT, ELLIPSE, FILL, BRUSH, BRUSH-SIZE, BRUSH-FILL, BRUSH-FX-OUTLINE, BRUSH-TEXT, CUSTOM-BRUSH, POLY-LINE, POLY-FILL, MARQUEE, SELECTION, PAN, MOVE, MOVE-NUDGE, SAVE, LOAD, PICKER, PICKER-LOUPE, HISTORY, DRW, COLOR-FG, COLOR-BG, COLOR-INVERT, CROP, SPRAY, ZOOM, TEXT, SYMMETRY, RAY, IMAGE-IMPORT, REFIMG, ERASER, TRANSFORM, EXTRACT-IMAGES)
9. **THEME**: `ASSETS/THEMES/DEFAULT/THEME.BI`

### Directory Structure

| Directory               | Purpose                                                              |
| ----------------------- | -------------------------------------------------------------------- |
| `CFG/`                  | Configuration types, keyboard/mouse/joystick bindings                |
| `CORE/`                 | Performance counters, error handling, image utilities, OS-native path resolution |
| `GUI/`                  | UI components (toolbar, status bar, palette, grid, layers, menubar, command palette, organizer, drawer panel, preview window, edit bar, text bar, popup menus, dithering helpers, tooltips) |
| `INPUT/`                | Input handlers (mouse, keyboard, joystick), file loaders, Lospec API |
| `OUTPUT/`               | Screen rendering (`SCREEN_render`), file export (BAS, BMP, BSAVE, Export As 9 formats) |
| `TOOLS/`                | Drawing tools, history/undo system, DRW format, image import, extract images, text tool |
| `PIXEL-COACH/`          | Pixel Art Analyzer — precompute engine and analysis results          |
| `ASSETS/`               | Fonts, icons, palettes (56 GPL files), themes                        |
| `includes/QB64_GJ_LIB/` | External utility library (DICT, STRINGS, VECT2D, FILE_DIALOG, COLOR_PICKER, MSG_BOX, TEXT_INPUT) |
| `PLANS/diagrams/`       | Graphviz DOT state machine diagrams organized by category: `GLOBAL/`, `GUI/`, `TOOLS/`, `UTILITIES/`, `LAYER-OPS/`, `TRANSFORM-OPS/`, `IMAGE-OPS/`, `FILE-OPS/` |

### Singleton State Pattern

```qb64
TYPE TOOL_OBJ
    ACTIVE AS INTEGER
    ' ... state fields
END TYPE
DIM SHARED TOOL AS TOOL_OBJ
```

Key globals: `SCRN`, `MOUSE`, `CFG`, `THEME`, `CURRENT_TOOL%`, `PAINT_COLOR~&`, `PAINT_BG_COLOR~&`, `DRAW_COLOR~&`, `CANVAS_DIRTY%`

`POINTER_OBJ` key fields: `CURSOR_ID%`, `CURSOR_FLIP%`, `HIDDEN%`, `PREV_DRAW_X/Y%`, `USING_SYSTEM_CURSOR%` (TRUE when OS `_MOUSESHOW` is active this frame — skip custom PNG draw for that cursor type)

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

## Critical Gotchas

### 1. NEVER Use `_DEST _CONSOLE`

**Never** use `_DEST _CONSOLE` + `PRINT` for debug output — corrupts the active drawing destination mid-frame, causing rendering glitches, undo corruption, and silent data loss. **Always use `_LOGINFO`, `_LOGWARN`, `_LOGERROR`** instead.

### 2. Image Handle Cleanup

Valid handles are `< -1`. Always check before freeing:

```qb64
IF handle& < -1 THEN _FREEIMAGE handle&
```

### 3. Destination/Source Context Preservation

```qb64
DIM oldDest AS LONG: oldDest& = _DEST
_DEST targetImage&
' ... draw operations ...
_DEST oldDest&
```

### 4. History System — #1 Source of Bugs

Read `draw-undo.instructions.md` before touching any code that saves history states, handles mouse press/release, opens GUI dialogs, or changes `MOUSE.UI_CHROME_CLICKED%`. DRAW uses a unified `HISTORY` system (`TOOLS/HISTORY.BI/BM`) — the old separate `UNDO` and `WORKSPACE_UNDO` systems have been removed. Common bugs: ghost history states from GUI click-release cycles, double-saves from missing guard, `_DEST` corruption from debug prints.

### 5. History Double-Save Prevention

```qb64
IF NOT HISTORY_saved_this_frame% THEN
    HISTORY_record_brush ...
    HISTORY_saved_this_frame% = TRUE
END IF
```

Reset to `FALSE` every frame in `LOOP_start`.

### 6. Coordinate Systems

- **Raw** (`MOUSE.RAW_X/Y`): Screen pixels — for GUI hit-testing
- **Canvas** (`MOUSE.X/Y`): Canvas pixels after zoom/pan + grid snap
- **Unsnapped** (`MOUSE.UNSNAPPED_X/Y`): Canvas pixels without grid snap — for fill, picker

Formula: `canvasX% = INT((rawX% - offsetX%) / zoom!)`

### 7. Tool State Reset on Switch

```qb64
MARQUEE_reset: LINE_reset: RECT_reset: ELLIPSE_reset: POLY_LINE_reset: MOVE_reset: TEXT_reset
```

### 8. Mouse Button Transition Detection

```qb64
IF MOUSE.B1% AND NOT MOUSE.OLD_B1% THEN ' Just pressed
IF NOT MOUSE.B1% AND MOUSE.OLD_B1% THEN ' Just released
```

### 9. Color Values

Colors are `_UNSIGNED LONG` via `_RGB32()` / `_RGBA32()`. Palette colors via `PAL_color~&(index%)`. **Theme color fields MUST be `~&`, never `%`** — an `INTEGER` field truncates RGB32 and causes color corruption when the palette changes.

### 10. Dialog Cleanup

After native dialogs, call `MOUSE_cleanup_after_dialog` (drains buffer, forces buttons up, sets `SUPPRESS_FRAMES% = 2`, clears keyboard buffer). File dialogs should use `MOUSE.DEFERRED_ACTION%` to defer execution to `MOUSE_input_handler_loop`.

### 11. `contentDirty%` vs `BLEND_invalidate_cache`

`BLEND_invalidate_cache` does NOT mark layers `contentDirty%`. Only set `contentDirty% = TRUE` when actual pixel content changes on a specific layer. Blanket-marking all 64 layers causes O(n) per-pixel `_MEM` opacity recalculation every invalidation.

### 12. Scene Cache Boundary for Animations

Per-frame animations (marching ants, blinking cursors) must render **after** `SkipToPointer:` (step 13 in render pipeline), not before the scene cache save. Placing them before forces `SCENE_DIRTY% = TRUE` every frame, defeating the cache.

### 13. UI_CHROME_CLICKED% and Spurious Undo States

`MOUSE.UI_CHROME_CLICKED%` lifecycle is critical for undo correctness:
1. **Set TRUE** when any GUI element is clicked
2. **Checked** by `MOUSE_should_skip_tool_actions%` — consumes `OLD_B*` transition when TRUE, preventing `MOUSE_dispatch_tool_release` from firing
3. **Reset FALSE** inside `MOUSE_should_skip_tool_actions%` when all buttons released

**CRITICAL**: The reset MUST happen inside `MOUSE_should_skip_tool_actions%`, NEVER before it — otherwise the release-frame fires a spurious history save.

### 14. `SCENE_CHANGED%` vs `FRAME_IDLE%` for Animations

- Set `FRAME_IDLE% = FALSE` — keeps render loop active
- Do NOT set `SCENE_CHANGED% = TRUE` — forces full compositing

### 15. File Load Must Reset All State

`DRW_load_binary` must reset all tool and panel state after loading. When adding new tool/panel state, ensure `DRW_load_binary` resets it.

### 16. Grid Drawing Must Be Triggered

Changing grid settings requires calling `GRID_draw` to re-render into `GRID.imgHandle&`. Also set `SCENE_DIRTY% = TRUE` and `FRAME_IDLE% = FALSE`.

### 17. THEME.BI Include-Order Timing

`SCREEN.BI` (line 70 in `_ALL.BI`) calls `SCREEN_init` inline. `THEME.BI` (line 121) sets compiled-in default THEME values **after** `SCREEN_init` has already executed. Any `SUB *_init` called from `SCREEN_init` that reads `THEME.*` string or numeric fields will see **empty strings / zeros** — not the compiled defaults.

**Fix**: Defer `THEME.*` reads until the first render (lazy-load pattern). Example: `EDITBAR_load_icons` resolves `THEME.EDIT_BAR_ICON_*$` at first-render time, not in `EDITBAR_init`.

### 18. Panel Visibility — Default-Hidden Must Set ManuallyHidden

When adding a new hideable panel that **defaults to hidden**, you MUST set `ManuallyHidden% = TRUE` alongside `show% = FALSE`. The auto-hide restore logic in `MOUSE_handle_ui_autohide_restore` checks `NOT show% AND NOT ManuallyHidden%` and restores the panel to visible — so a panel initialized with `show%=FALSE` + `ManuallyHidden%=FALSE` becomes visible on the first frame.

Follow the `PREVIEW_init` pattern:

```qb64
SCRN.showMyPanel% = FALSE
SCRN.myPanelManuallyHidden% = TRUE
IF CFG.MY_PANEL_VISIBLE% THEN
    SCRN.showMyPanel% = TRUE
    SCRN.myPanelManuallyHidden% = FALSE
END IF
```

### 19. Organizer Icon Filenames Must Match Code

Icon PNGs are loaded by filename from the theme directory. Mismatches cause silent failures (e.g., `grid-snap-center-off.png` vs `grid-snap-off-center.png`).

### 20. `_KEYHIT` Is Unreliable for Ctrl+ Combos on Linux/SDL2

**NEVER use `_KEYHIT` character codes for hotkeys involving Ctrl or Alt.** Always use `_KEYDOWN(physicalKeyCode)` with a `STATIC pressed%` guard. Put Ctrl+Alt hotkeys in `KEYBOARD.BM`, never in `DRAW.BAS`.

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

Key physical codes: `KEY_PGUP& = 18688`, `KEY_PGDN& = 20736`, `.` = 46, `,` = 44, `/` = 47, `R/r` = 82/114

### 21. Custom Brush Rendering Must Handle Eraser Mode

`CUSTOM_BRUSH_render()` bypasses `PAINT_pset_with_symmetry()` — it uses `_PUTIMAGE` with `_BLEND`, which silently drops transparent pixels. When adding new rendering paths through custom brush, always check `PAL_FG_IS_TRANSPARENT%` and use `_DONTBLEND` + per-pixel PSET of `_RGBA32(0,0,0,0)` for eraser mode, matching the pattern in `PAINT_pset_with_symmetry()`.

---

## Main Loop Structure (DRAW.BAS)

```
DO
    0.  _EXIT check → CMD_execute_action 212 (graceful exit with unsaved-changes dialog)
    1.  Deferred command-line file load (first frame only)
    2.  Windows drag-and-drop (_ACCEPTFILEDROP)
    3.  k& = _KEYHIT + MODIFIERS_track_alt_keyhit + MODIFIERS_update
    4.  LOOP_start — resets HISTORY_saved_this_frame%, calls TITLE_check
    5.  MUSIC_tick — auto-shuffle to next track when current ends
    6.  MOUSE_input_handler
    7.  KEYBOARD_input_handler
    8.  STICK_input_handler
    9.  Idle detection → FRAME_IDLE%, SCENE_DIRTY%
    10. IF NOT FRAME_IDLE% THEN SCREEN_render
    11. _LIMIT (15 FPS idle / CFG.FPS_LIMIT% active)
    12. MOUSE/KEYBOARD/STICK_input_handler_loop (post-render)
    13. PERF_frame_end, LOOP_end
LOOP
```

**`_LIMIT` MUST come AFTER `SCREEN_render`/`_DISPLAY`**, never before — placing it before introduces visible pointer lag.

A frame is "idle" when no input, mouse movement, GUI changes, or active tool operations occurred. Idle frames skip `SCREEN_render` entirely and throttle to 15 FPS.

---

## QB64-PE APIs Frequently Used

- **Graphics**: `_NEWIMAGE`, `_COPYIMAGE`, `_PUTIMAGE`, `_FREEIMAGE`, `_LOADIMAGE`
- **Drawing context**: `_DEST`, `_SOURCE`, `_BLEND`, `_DONTBLEND`, `_SETALPHA`
- **Memory**: `_MEM`, `_MEMIMAGE`, `_MEMGET`, `_MEMPUT`, `_MEMFREE`
- **Input**: `_KEYHIT`, `_KEYDOWN()`, `_MOUSEINPUT`, `_MOUSEWHEEL`, `_MOUSEMOVE`
- **Dialogs**: `_MESSAGEBOX()`, `_OPENFILEDIALOG$()`, `_SAVEFILEDIALOG$()`
- **Logging**: `_LOGINFO`, `_LOGWARN`, `_LOGERROR` — **ALWAYS use these, NEVER `_DEST _CONSOLE`**
- **Compression**: `_DEFLATE$`, `_INFLATE$`
- **CRC**: `_CRC32`
- **System**: `_TITLE`, `_LIMIT`, `_FULLSCREEN`, `_DESKTOPWIDTH/HEIGHT`

---

## Key Files

| File                      | Contains                                                            |
| ------------------------- | ------------------------------------------------------------------- |
| `_COMMON.BI`              | Core types, global state, tool constants                            |
| `_COMMON.BM`              | Stroke system, title bar, paint helpers                             |
| `DRAW.BAS`                | Main loop, application entry point                                  |
| `GUI/GUI.BI`              | Tool constants (`TOOL_SELECT_*`, `TOOL_ERASER`), GUI context        |
| `GUI/IMAGE-ADJ.BI/BM`     | Image adjustment dialogs (Brightness/Contrast, Hue/Sat, Levels, Blur, Posterize, Pixelate, etc.) with live preview |
| `GUI/COMMAND.BM`          | Central action dispatcher (all 200+ commands)                       |
| `GUI/DITHER.BI/BM`        | Shared dithering algorithms and threshold helpers for gradients and posterize |
| `INPUT/MOUSE.BM`          | Mouse processing pipeline (~2590 lines)                             |
| `INPUT/KEYBOARD.BM`       | Keyboard shortcuts and handler                                      |

| `OUTPUT/SCREEN.BM`        | Render pipeline (`SCREEN_render`)                                   |
| `GUI/LAYERS.BM`           | Layer management (~2305 lines)                                      |
| `GUI/MENUBAR.BM`          | Menu bar with keyboard navigation and cascading submenu support     |
| `GUI/TOOLBAR.BI`          | Layout constants (`TB_COLS`, `TB_ROWS`), button-to-tool mapping     |
| `GUI/TOOLBAR.BM`          | Toolbar rendering, click handling, active indicator                 |
| `GUI/ORGANIZER.BI`        | Organizer widget constants (`ORG_*`), 4×3 layout                    |
| `GUI/DRAWER.BI/BM`        | 30-slot brush/pattern/gradient drawer panel with mini palette, slot context menus, and `.dset` import/export |
| `GUI/PREVIEW.BI/BM`       | Floating preview window with two modes (Follow magnifier / Floating Image), Bin Quick Look drawer hover preview, color picking, recent preview images, pan/zoom, resize, and work-area clamping |
| `GUI/EDITBAR.BI/BM`       | Vertical icon bar mirroring Edit menu actions; dockable LEFT/RIGHT; toggle F5 |
| `GUI/ADVANCEDBAR.BI/BM`   | Vertical icon bar with 26+ quick-access toggle buttons; dockable LEFT/RIGHT; toggle Shift+F5 |
| `GUI/TOOLTIP.BI/BM`       | Tooltip system for toolbar, organizer, mini-palette, edit bar, and advanced bar |
| `GUI/POPUP-MENU.BI/BM`    | Shared popup menu layout/rendering used by drawer and other contextual overlays |
| `TOOLS/HISTORY.BI/BM`     | Unified history system for all Ctrl+Z/Y undo/redo                   |
| `TOOLS/ERASER.BI/BM`      | Eraser tool (transparent painting via brush pipeline)               |
| `TOOLS/TRANSFORM.BI/BM`   | On-canvas transform overlay (Scale/Rotate/Shear/Distort/Perspective); activated via Edit→TRANSFORM...; not a toolbar tool |
| `TOOLS/EXTRACT-IMAGES.BI/BM` | Extract individual sprites/components from sprite sheets or multi-layer artwork as separate PNGs; supports flood fill, per-layer, or merged extraction; config persisted in DRW v14+ |
| `TOOLS/TEXT.BI/BM`        | Text tool state machine and keyboard input handler for text entry on canvas |
| `GUI/TEXT-BAR.BI/BM`      | Text tool property bar (font, size, bold/italic/underline/strikethrough, colors, spacing) |
| `GUI/TEXT-LAYER.BI/BM`    | Text layer data storage, serialization/deserialization, and rendering |
| `GUI/FONT-LIST.BI/BM`     | Font registry (VGA, Tiny5, custom TTF/OTF) with size management |
| `GUI/CHARMAP.BI/BM`       | Character map panel (16×16 glyph grid), Character Mode (useChars), virtual cursor, bitmap font rendering, char grid overlay |
| `TOOLS/FILL-ADJ.BI/BM`   | Interactive Fill Adjustment overlay (F8) for custom brush and paint mode tiled fills; L-handle for independent X/Y scaling |
| `GUI/CROSSHAIR.BI/BM`    | Crosshair assistant line rendering with configurable outline stroke |
| `GUI/PALETTE-OPS.BI/BM`  | Palette Ops mode (on-strip palette editing: change, delete, insert, rearrange, wand select) with [DOCUMENT] palette auto-creation and snapshot/restore |
| `GUI/GJ-DIALOG-SCALE.BM` | Custom GUI dialog wrappers (`DRAW_pick_color&`, `DRAW_open_file$`, `DRAW_save_file$`, `DRAW_msg_box`, `DRAW_input_box$`, `DRAW_input_box_ex$`) injecting `CFG.TOOLBAR_SCALE%` into QB64_GJ_LIB dialogs |
| `GUI/SETTINGS.BI/BM`     | GIMP-style tabbed settings dialog (General, Grid, Palette, Panels, Audio, Fonts, Appearance, Directories) |
| `GUI/ABOUT.BI/BM`        | About screen dialog with animated logo, version, credits, clickable GitHub link |
| `CFG/CONFIG.BI`           | Configuration structure                                             |
| `CORE/SOUND.BI/BM`        | Sound constants, loader, playback SUBs                              |
| `CHEATSHEET.md`           | All keyboard shortcuts                                              |

---

## Adding New Tools

1. Create `TOOLS/MYTOOL.BI` (TYPE + DIM SHARED + init call)
2. Create `TOOLS/MYTOOL.BM` (implementation)
3. Add `CONST TOOL_MYTOOL` to `_COMMON.BI` or `GUI/GUI.BI`
4. Add includes to `_ALL.BI` and `_ALL.BM`
5. Add keyboard binding in `KEYBOARD_tools()`
6. Add action ID in `CMD_init`, handler in `CMD_execute_action`
7. Add mouse handling: hold in `MOUSE_dispatch_tool_hold`, release in `MOUSE_dispatch_tool_release` (with `HISTORY_record_*` on commit)
8. Add preview rendering in `SCREEN_render()` before scene cache save
9. Register menu item in `MENUBAR_init` with action ID
10. Ensure `DRW_load_binary` resets any new tool state
