---
applyTo: "**"
---

# DRAW Project Context for AI Agents

## Session Initialization

**Always start sessions with `#qb64pe`** to activate the QB64-PE MCP server, which provides syntax validation, compilation, keyword lookup, and debugging tools.

**Project**: DRAW is a pixel art editor written in QB64-PE by grymmjack (Rick Christy). Unique feature: exports artwork as QB64 source code. Build with: `qb64pe -w -x -o DRAW.run DRAW.BAS`

---

## Architecture

### BI/BM File Separation Pattern

- **`.BI` files**: Declarations only — `TYPE`, `CONST`, `DIM SHARED`, `DECLARE`
- **`.BM` files**: Implementations only — `SUB`, `FUNCTION` bodies
- **Include chain**: `_ALL.BI` includes all `.BI` files in dependency order; `_ALL.BM` includes all `.BM` files
- **Always use**: `$INCLUDEONCE` at top of every BI/BM file

### Directory Structure

| Directory | Purpose |
|-----------|---------|
| `CFG/` | Configuration types, keyboard/mouse/joystick bindings |
| `GUI/` | UI components (toolbar, status bar, palette, grid, layers) |
| `INPUT/` | Input handlers, file loaders (BMP, PAL, BLOAD) |
| `OUTPUT/` | Screen rendering, file export (BAS, BMP, BSAVE) |
| `TOOLS/` | Drawing tools (brush, line, rect, fill, marquee, etc.) |
| `includes/QB64_GJ_LIB/` | External utility library (BBX, DICT, STRINGS, VECT2D) |

### Singleton State Pattern

Each system/tool uses a shared state object:
```qb64
TYPE TOOL_OBJ
    ACTIVE AS INTEGER
    ' ... state fields
END TYPE
DIM SHARED TOOL AS TOOL_OBJ
```

Key globals: `SCRN` (screen state), `MOUSE` (input state), `CFG` (config), `CURRENT_TOOL%`, `PAINT_COLOR~&`

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

### 1. Image Handle Cleanup
Valid image handles are `< -1`. Always check before freeing:
```qb64
IF handle& < -1 THEN _FREEIMAGE handle&
```

### 2. Destination/Source Context Preservation
Always save and restore `_DEST` and `_SOURCE` when changing them:
```qb64
DIM oldDest AS LONG: oldDest& = _DEST
_DEST targetImage&
' ... draw operations ...
_DEST oldDest&
```

### 3. Undo Double-Save Prevention
Check the frame flag before saving undo state:
```qb64
IF NOT UNDO_saved_this_frame% THEN
    UNDO_save_state
    UNDO_saved_this_frame% = TRUE
END IF
```

### 4. Coordinate Transformation
Mouse has two coordinate systems:
- **Raw** (`MOUSE.RAW_X/Y`): Screen pixels
- **Canvas** (`MOUSE.X/Y`): Canvas pixels after zoom/pan transform

Formula: `canvasX% = INT((rawX% - offsetX%) / zoom!)`

### 5. Tool State Reset on Switch
When activating a tool, reset ALL other tool states to prevent interference:
```qb64
MARQUEE_reset: LINE_reset: RECT_reset: ELLIPSE_reset: POLY_LINE_reset: MOVE_reset
```

### 6. Mouse Button Press/Release Detection
Track previous state to detect transitions:
```qb64
IF MOUSE.B1% AND NOT MOUSE.OLD_B1% THEN ' Just pressed
IF NOT MOUSE.B1% AND MOUSE.OLD_B1% THEN ' Just released
```

### 7. Color Values
Colors are `_UNSIGNED LONG` using `_RGB32()` or `_RGBA32()`. Access palette colors via `PAL_color~&(index%)` function.

### 8. Dialog Cleanup
After native dialogs (`_MESSAGEBOX`, `_OPENFILEDIALOG$`), drain mouse buffer and reset button state:
```qb64
DO WHILE _MOUSEINPUT: LOOP
MOUSE_force_buttons_up
```

---

## Main Loop Structure (DRAW.BAS)

```
DO
    k& = _KEYHIT
    LOOP_start              ' Reset per-frame flags
    MOUSE_input_handler     ' Process mouse input
    KEYBOARD_input_handler  ' Process keyboard input  
    STICK_input_handler     ' Process joystick input
    _LIMIT CFG.FPS_LIMIT%
    SCREEN_render           ' Render all layers
    *_input_handler_loop    ' Post-render processing
    LOOP_end
LOOP
```

### Tool Lifecycle Pattern

1. **Activate**: Switch via keyboard shortcut or toolbar click
2. **Reset others**: Call reset subs for all other tools
3. **Mouse down**: Save undo state, begin operation (e.g., `DRAGGING = TRUE`)
4. **Mouse move**: Update tool state (end coordinates, preview)
5. **Mouse up**: Commit drawing to `SCRN.PAINTING&`, reset tool state
6. **Preview**: Rendered in `SCREEN_render()` during drag operations

---

## Rendering Layers (SCREEN_render)

Composited back-to-front:
1. `SCRN.PAINTING&` — User's artwork
2. Grid overlay (if visible)
3. Symmetry guides (if enabled)
4. Tool previews (line/rect/ellipse during drag)
5. `SCRN.GUI&` — Toolbar, status bar
6. Marquee selection, move preview, text preview

---

## Key Files for Onboarding

| File | Contains |
|------|----------|
| `_COMMON.BI` | Core types (`SCREEN_OBJ`, `MOUSE_OBJ`), global state |
| `DRAW.BAS` | Main loop, application entry point |
| `GUI/GUI.BI` | Tool constants (`TOOL_BRUSH`, `TOOL_LINE`, etc.) |
| `CHEATSHEET.md` | All keyboard shortcuts and features |
| `CFG/CONFIG.BI` | Configuration structure and defaults |

---

## QB64-PE APIs Frequently Used

- **Graphics**: `_NEWIMAGE`, `_COPYIMAGE`, `_PUTIMAGE`, `_FREEIMAGE`, `_LOADIMAGE`
- **Drawing context**: `_DEST`, `_SOURCE`, `_BLEND`, `_DONTBLEND`, `_SETALPHA`
- **Input**: `_KEYHIT`, `_KEYDOWN()`, `_MOUSEINPUT`, `_MOUSEWHEEL`, `_MOUSEMOVE`
- **Dialogs**: `_MESSAGEBOX()`, `_OPENFILEDIALOG$()`, `_SAVEFILEDIALOG$()`
- **Logging**: `_LOGINFO`, `_LOGWARN`, `_LOGERROR` (use `$CONSOLE` directive)
- **System**: `_TITLE`, `_LIMIT`, `_FULLSCREEN`, `_DESKTOPWIDTH/HEIGHT`

---

## Adding New Tools

1. Create `TOOLS/MYTOOL.BI` (TYPE + DIM SHARED + init call)
2. Create `TOOLS/MYTOOL.BM` (implementation)
3. Add `CONST TOOL_MYTOOL` to `GUI/GUI.BI`
4. Add includes to `_ALL.BI` and `_ALL.BM`
5. Add keyboard binding in `KEYBOARD_tools()`
6. Add mouse handling in `MOUSE_input_handler()`
7. Add preview rendering in `SCREEN_render()` if needed
