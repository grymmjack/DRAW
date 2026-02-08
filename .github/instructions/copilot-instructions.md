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

### 9. `contentDirty%` vs `BLEND_invalidate_cache`
`BLEND_invalidate_cache` invalidates composite/render ordering but does NOT mark layers
`contentDirty%`. Only set `contentDirty% = TRUE` on layers whose pixel content was
actually modified. Blanket-marking all 64 layers causes O(n) per-pixel `_MEM` opacity
recalculation (~5-6% CPU per semi-transparent layer) on every invalidation.

### 10. Scene Cache Boundary for Animations
Per-frame animations (marching ants, blinking cursors) must render AFTER `SkipToPointer:`
(step 13 in render pipeline), not before the scene cache save (step 12). Placing them
before the cache save forces `SCENE_DIRTY% = TRUE` every frame, bypassing the cache and
triggering full layer compositing at 60fps.

### 11. `SCENE_CHANGED%` vs `FRAME_IDLE%` for Animations
To keep animations running without forcing full scene re-render:
- Set `FRAME_IDLE% = FALSE` — keeps the render loop active
- Do NOT set `SCENE_CHANGED% = TRUE` — that forces `SCENE_DIRTY%` and full compositing

### 12. File Load Must Reset All State
`DRW_load` must reset all tool and panel state (selection, move, layer panel scroll/drag).
Stale state from the previous document causes subtle bugs like layer eye icons not
responding to clicks (stale `scrollOffset%` or `visSwiping%`).

---

## Main Loop Structure (DRAW.BAS)

```
DO
    ' Deferred command line file loading (first frame only)
    k& = _KEYHIT
    ' Handle display scale / ESC hotkeys
    LOOP_start              ' Reset per-frame flags, TITLE_check
    MOUSE_input_handler     ' Process mouse input (drain-then-process)
    KEYBOARD_input_handler  ' Process keyboard input  
    STICK_input_handler     ' Process joystick input
    ' Idle detection (set FRAME_IDLE%, SCENE_DIRTY%)
    IF NOT FRAME_IDLE% THEN SCREEN_render  ' Render + _DISPLAY
    _LIMIT FPS                             ' Throttle AFTER render
    *_input_handler_loop    ' Post-render processing
    LOOP_end
LOOP
```

### CRITICAL: `_LIMIT` Placement

**`_LIMIT` MUST come AFTER `SCREEN_render` / `_DISPLAY`, never before.** Placing `_LIMIT`
before render introduces a full frame of latency between reading mouse input and displaying
the cursor — the pointer visibly lags behind the mouse. The correct order is:

```
Input → Render → _DISPLAY → _LIMIT (wait) → next frame
```

This ensures the mouse position captured at the top of the frame is painted to screen with
minimal delay. The frame-rate wait happens after the display flip, not before it.

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
scroll wheel, active tool states (move, text, import, command palette).

**What sets `FRAME_IDLE% = FALSE` but NOT `SCENE_DIRTY%`**: Mouse movement alone, and
active selections (marching ants animation). Mouse movement triggers a render for pointer
update via the scene cache fast path. Active selections keep the frame active (so marching
ants animate) but do NOT set `SCENE_CHANGED%` — ants are drawn after the scene cache
restore so they don't force full layer compositing.

**CRITICAL**: Never set `SCENE_CHANGED% = TRUE` for per-frame animations. Use
`FRAME_IDLE% = FALSE` to keep rendering active, and draw the animation after
`SkipToPointer:` so it works in both the full-render and cache-hit paths.

### Tool Lifecycle Pattern

1. **Activate**: Switch via keyboard shortcut or toolbar click
2. **Reset others**: Call reset subs for all other tools
3. **Mouse down**: Save undo state, begin operation (e.g., `DRAGGING = TRUE`)
4. **Mouse move**: Update tool state (end coordinates, preview)
5. **Mouse up**: Commit drawing to `SCRN.PAINTING&`, reset tool state
6. **Preview**: Rendered in `SCREEN_render()` during drag operations

---

## Rendering Layers (SCREEN_render)

Composited back-to-front onto `SCRN.CANVAS&`, then scaled to `SCRN.WINDOW_IMG&` via `_PUTIMAGE`:

1. Transparency checkerboard
2. Layer compositing (by zIndex, bottom-to-top)
   - Normal blend: direct `_PUTIMAGE` (fast path when all layers are Normal)
   - Non-Normal blend: per-pixel composite via `COMPOSITE_BUFFER&` using `_MEM` access
   - Partial composite cache: layers below current layer are cached in `COMPOSITE_BELOW_CACHE&`
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
13. `SkipToPointer:` label — fast path target
14. **Selection overlay** (marching ants) — drawn AFTER cache so animation doesn't invalidate it
15. Pointer cursor (POINTER_update + POINTER_render)
16. Scale `SCRN.CANVAS&` → `SCRN.WINDOW_IMG&` (integer scaling, nearest neighbor)
17. `_DISPLAY`

### Performance Patterns in SCREEN_render

- **Persistent buffers**: `COMPOSITE_BUFFER&`, `SCENE_CACHE&`, `PG_CACHE_IMG&` are allocated
  once and reused. Never `_NEWIMAGE`/`_FREEIMAGE` every frame.
- **Conditional GUI redraw**: `GUI_NEEDS_REDRAW%` gates toolbar/status/palette/layer panel
  re-rendering. Set it TRUE when GUI state changes.
- **Layer render order**: `RENDER_ORDER%()` lookup table, rebuilt when `RENDER_ORDER_DIRTY%`.
- **Opacity cache**: Per-layer `opacityCacheImg&` with `opacityCacheVal%` and `contentDirty%`.
  Cache hit = skip expensive per-pixel `_MEM` opacity loop. Mark `contentDirty% = TRUE`
  **only** when actual pixel content changes on a layer (drawing, clear, merge, undo/redo).
- **`contentDirty%` discipline**: `BLEND_invalidate_cache` does NOT mark layers
  `contentDirty%`. It only sets `BLEND_COMPOSITE_DIRTY%`, `RENDER_ORDER_DIRTY%`,
  `SCENE_DIRTY%`, and `COMPOSITE_BELOW_VALID% = FALSE`. Code that modifies layer pixel
  content must explicitly set `LAYERS(idx%).contentDirty% = TRUE`. This prevents O(n)
  per-pixel opacity recalculation on every cache invalidation.
- **Blend composite cache**: `COMPOSITE_BELOW_CACHE&` stores composited layers below
  `CURRENT_LAYER%`. When only the current layer changes, layers below are restored from
  cache instead of re-composited.

---

## Window Title Bar

The title bar shows version, filename, and dirty state: `DRAW v0.7.5 - myart.draw *`

- **`TITLE_update`** (`_COMMON.BM`): Builds the title string. Prefers `CURRENT_DRW_FILENAME$`
  over `CURRENT_FILENAME$`. Extracts basename (strips path). Appends ` *` if `CANVAS_DIRTY%`.
- **`TITLE_check`** (`_COMMON.BM`): Called every frame in `LOOP_start`. Compares current
  dirty/filename state against `TITLE_PREV_DIRTY%` / `TITLE_PREV_FILENAME$`. Only calls
  `_TITLE` when something changed (avoids per-frame string allocation + syscall).
- **`APP_VERSION$`**: Constant in `_COMMON.BI`. Update when releasing.

When setting `CURRENT_DRW_FILENAME$` programmatically (e.g., command-line loading), title
automatically updates on the next frame via `TITLE_check`.

---

## Native File Format (.draw)

| Section | Fields |
|---------|--------|
| **Header** | Magic `"DRW1"`, version (`INTEGER`, currently 3), canvas W×H (`LONG`) |
| **Palette** | Color count, `_UNSIGNED LONG` per color, FG/BG indices |
| **Layers** | Count, current layer index. Per layer: name (`STRING*16`), visible, opacity, zIndex, blendMode (v2+), opacityLock (v2+), pixel data (W×H `_UNSIGNED LONG`) |
| **Tool State** | Current tool, brush size, pixel perfect, grid visible, grid size |
| **Palette Name** | v3+: palette name (`STRING*64`) — matched against GPL files on load |

- Extension: `.draw` (changed from `.drw` in v0.7.4 to avoid CorelDRAW conflict)
- Constants: `DRW_MAGIC$ = "DRW1"`, `DRW_VERSION% = 3` (in `TOOLS/DRW.BI`)
- Load function: `DRW_load filename$` — does NOT set `CURRENT_DRW_FILENAME$` (caller must)
- Save/Open dialogs: `DRW_save_dialog` / `DRW_open_dialog` — set `CURRENT_DRW_FILENAME$`

---

## OS Integration & Icons

### Application Icon

- **`$EXEICON:'./ASSETS/ICONS/icon.ico'`** in `DRAW.BAS` — Windows only, embeds icon in .exe
- **`_ICON` + `_LOADIMAGE`** in `SCREEN_init` — runtime window icon via SDL2 (all platforms)
- **macOS `.app` bundle**: Created by CI workflow and `install-mac.command`, uses `icon.icns`
- **Source**: `ASSETS/ICONS/icon.svg` → generated by `ASSETS/ICONS/generate-icons.sh`

### Platform Installers

| Script | What It Does | Uninstall |
|--------|--------------|-----------|
| `install-linux.sh` | Desktop launcher, MIME type `application/x-draw-project`, hicolor icons (16–256px for apps + mimetypes) | `--uninstall` |
| `install-windows.cmd` | Per-user registry: `.draw` → `DRAW.Project` file association + icon, Start Menu shortcut | `/uninstall` |
| `install-mac.command` | `~/Applications/DRAW.app` bundle with `Info.plist` (UTI + document type), LaunchServices registration | `--uninstall` |

### File Association Files

- `draw-project.xml`: Linux MIME type definition (`application/x-draw-project`, glob `*.draw`)
- `DRAW.desktop`: Linux desktop launcher template (uses `DRAW_INSTALL_PATH` placeholder)
- `ASSETS/ICONS/Info.plist`: macOS app bundle manifest (also generated by `install-mac.command`)

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

## Cache Invalidation Rules

### When to mark `contentDirty%`

Set `LAYERS(idx%).contentDirty% = TRUE` when layer pixel content actually changes:
- Drawing/painting on a layer (brush stroke committed)
- `LAYERS_clear` (already sets it)
- `LAYERS_merge_down` (target layer gets merged pixels)
- `LAYERS_duplicate` (new layer gets copied pixels)
- `WORKSPACE_UNDO_undo` / `WORKSPACE_UNDO_redo` (may restore layer pixel data)
- Any operation using `_COPYIMAGE` or `_PUTIMAGE` to modify layer `imgHandle&`

Do NOT blanket-set `contentDirty%` on all layers in `BLEND_invalidate_cache`. That
function handles composite/render ordering — not pixel content changes.

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

**Rule**: Per-frame animations (marching ants, blinking cursors) MUST be rendered after
`SkipToPointer:`. If placed before the scene cache save, they force `SCENE_DIRTY% = TRUE`
every frame, defeating the cache and causing full layer compositing at 60fps.

---

## File Load State Reset

`DRW_load` must reset **all** tool and panel state after loading a file. Stale state from
the previous document causes subtle bugs (e.g., layer panel clicks not registering due to
old scroll offset, or selection tools interfering with the new canvas).

Required resets in `DRW_load` (after clearing undo history):
```qb64
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

When adding new tool or panel state, ensure `DRW_load` resets it too.

---

## Adding New Tools

1. Create `TOOLS/MYTOOL.BI` (TYPE + DIM SHARED + init call)
2. Create `TOOLS/MYTOOL.BM` (implementation)
3. Add `CONST TOOL_MYTOOL` to `GUI/GUI.BI`
4. Add includes to `_ALL.BI` and `_ALL.BM`
5. Add keyboard binding in `KEYBOARD_tools()`
6. Add mouse handling in `MOUSE_input_handler()`
7. Add preview rendering in `SCREEN_render()` if needed
