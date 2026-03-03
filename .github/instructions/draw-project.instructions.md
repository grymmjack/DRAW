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
2. **CORE**: PERF, ERROR, IMAGE
3. **CFG**: CONFIG, CONFIG-THEME, CONFIG-KEYBOARD, CONFIG-MOUSE, CONFIG-STICK, BINDINGS-\*
4. **GUI**: PALETTE, PALETTE-LOADER, PALETTE-STRIP, GUI, BRUSHES, CROSSHAIR, GRID, HELP, LAYERS, PALETTE-PICKER, PICKER, CURSOR, POINTER, STATUS, TOOLBAR, ORGANIZER, TRANSPARENCY, COMMAND, MENUBAR, SCROLLBAR, DIALOG, IMGADJ, IMAGE-ADJ, STROKE-SEL
5. **INPUT**: MODIFIERS, KEYBOARD, MOUSE, STICK, FILE-BMP, FILE-BLOAD, FILE-PAL, API-LOSPEC
6. **OUTPUT**: SCREEN, FILE-BAS, FILE-BMP, FILE-BSAVE
7. **QB64_GJ_LIB**: DICT, STRINGS, VECT2D
8. **TOOLS**: 37 tool pairs (NULL, DOT, LINE, RECT, ELLIPSE, FILL, BRUSH, BRUSH-SIZE, BRUSH-FILL, BRUSH-FX-OUTLINE, BRUSH-TEXT, CUSTOM-BRUSH, POLY-LINE, POLY-FILL, MARQUEE, SELECTION, PAN, MOVE, MOVE-NUDGE, SAVE, LOAD, PICKER, UNDO, WORKSPACE-UNDO, DRW, COLOR-FG, COLOR-BG, COLOR-INVERT, CROP, SPRAY, ZOOM, TEXT, SYMMETRY, RAY, IMAGE-IMPORT, REFIMG, ERASER)
9. **THEME**: `ASSETS/THEMES/DEFAULT/THEME.BI`

### Directory Structure

| Directory               | Purpose                                                              |
| ----------------------- | -------------------------------------------------------------------- |
| `CFG/`                  | Configuration types, keyboard/mouse/joystick bindings                |
| `CORE/`                 | Performance counters, error handling, image utilities                |
| `GUI/`                  | UI components (toolbar, status bar, palette, grid, layers, menubar, command palette, organizer) |
| `INPUT/`                | Input handlers (mouse, keyboard, joystick), file loaders, Lospec API |
| `OUTPUT/`               | Screen rendering (`SCREEN_render`), file export (BAS, BMP, BSAVE)   |
| `TOOLS/`                | Drawing tools, undo systems, DRW format, image import                |
| `ASSETS/`               | Fonts, icons, palettes (56 GPL files), themes                        |
| `includes/QB64_GJ_LIB/` | External utility library (DICT, STRINGS, VECT2D)                     |

### Singleton State Pattern

```qb64
TYPE TOOL_OBJ
    ACTIVE AS INTEGER
    ' ... state fields
END TYPE
DIM SHARED TOOL AS TOOL_OBJ
```

Key globals: `SCRN`, `MOUSE`, `CFG`, `THEME`, `CURRENT_TOOL%`, `PAINT_COLOR~&`, `PAINT_BG_COLOR~&`, `DRAW_COLOR~&`, `CANVAS_DIRTY%`

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

### 4. Undo System — #1 Source of Bugs

Read `draw-undo.instructions.md` before touching any code that saves undo states, handles mouse press/release, opens GUI dialogs, or changes `MOUSE.TOOLBAR_CLICKED%`. Common bugs: ghost undo states from GUI click-release cycles, double-saves from missing guard, `_DEST` corruption from debug prints.

### 5. Undo Double-Save Prevention

```qb64
IF NOT UNDO_saved_this_frame% THEN
    UNDO_save_state
    UNDO_saved_this_frame% = TRUE
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
MARQUEE_reset: LINE_reset: RECT_reset: ELLIPSE_reset: POLY_LINE_reset: MOVE_reset
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

### 13. TOOLBAR_CLICKED% and Spurious Undo States

`MOUSE.TOOLBAR_CLICKED%` lifecycle is critical for undo correctness:
1. **Set TRUE** when any GUI element is clicked
2. **Checked** by `MOUSE_should_skip_tool_actions%` — consumes `OLD_B*` transition when TRUE, preventing `MOUSE_dispatch_tool_release` from firing
3. **Reset FALSE** inside `MOUSE_should_skip_tool_actions%` when all buttons released

**CRITICAL**: The reset MUST happen inside `MOUSE_should_skip_tool_actions%`, NEVER before it — otherwise the release-frame fires a spurious `UNDO_save_state`.

### 14. `SCENE_CHANGED%` vs `FRAME_IDLE%` for Animations

- Set `FRAME_IDLE% = FALSE` — keeps render loop active
- Do NOT set `SCENE_CHANGED% = TRUE` — forces full compositing

### 15. File Load Must Reset All State

`DRW_load_binary` must reset all tool and panel state after loading. When adding new tool/panel state, ensure `DRW_load_binary` resets it.

### 16. Grid Drawing Must Be Triggered

Changing grid settings requires calling `GRID_draw` to re-render into `GRID.imgHandle&`. Also set `SCENE_DIRTY% = TRUE` and `FRAME_IDLE% = FALSE`.

### 17. Organizer Icon Filenames Must Match Code

Icon PNGs are loaded by filename from the theme directory. Mismatches cause silent failures (e.g., `grid-snap-center-off.png` vs `grid-snap-off-center.png`).

### 18. `_KEYHIT` Is Unreliable for Ctrl+ Combos on Linux/SDL2

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

---

## Main Loop Structure (DRAW.BAS)

```
DO
    0.  _EXIT check → CMD_execute_action 212 (graceful exit with unsaved-changes dialog)
    1.  Deferred command-line file load (first frame only)
    2.  Windows drag-and-drop (_ACCEPTFILEDROP)
    3.  k& = _KEYHIT + MODIFIERS_track_alt_keyhit + MODIFIERS_update
    4.  LOOP_start — resets UNDO_saved_this_frame%, calls TITLE_check
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
| `GUI/IMAGE-ADJ.BI/BM`     | Image adjustment dialogs (Brightness/Contrast, Hue/Sat, Levels, Blur, etc.) with live preview |
| `GUI/COMMAND.BM`          | Central action dispatcher (all 200+ commands)                       |
| `INPUT/MOUSE.BM`          | Mouse processing pipeline (~2590 lines)                             |
| `INPUT/KEYBOARD.BM`       | Keyboard shortcuts and handler                                      |
| `TOOLS/UNDO.BM`           | Pixel undo system                                                   |
| `TOOLS/WORKSPACE-UNDO.BM` | Workspace undo system                                               |
| `OUTPUT/SCREEN.BM`        | Render pipeline (`SCREEN_render`)                                   |
| `GUI/LAYERS.BM`           | Layer management (~2305 lines)                                      |
| `GUI/MENUBAR.BM`          | Menu bar with keyboard navigation                                   |
| `GUI/TOOLBAR.BI`          | Layout constants (`TB_COLS`, `TB_ROWS`), button-to-tool mapping     |
| `GUI/TOOLBAR.BM`          | Toolbar rendering, click handling, active indicator                 |
| `GUI/ORGANIZER.BI`        | Organizer widget constants (`ORG_*`), 4×3 layout                    |
| `TOOLS/ERASER.BI/BM`      | Eraser tool (transparent painting via brush pipeline)               |
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
7. Add mouse handling: hold in `MOUSE_dispatch_tool_hold`, release in `MOUSE_dispatch_tool_release` (with `UNDO_save_state` on commit)
8. Add preview rendering in `SCREEN_render()` before scene cache save
9. Register menu item in `MENUBAR_init` with action ID
10. Ensure `DRW_load_binary` resets any new tool state
