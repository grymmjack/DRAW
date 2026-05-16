# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

DRAW is a pixel art editor written in **QB64-PE** (QB64 Phoenix Edition). Single executable, no runtime dependencies. Its distinguishing feature is the ability to export artwork as QB64 source code. Version constant lives in `_COMMON.BI` as `APP_VERSION$`.

## Build & Run

```bash
# Default build (uses Makefile, auto-detects OS)
make                # → DRAW.run (Linux/macOS) or DRAW.exe (Windows)
make run            # build and run
make run-logged     # build and run with full QB64-PE logging (writes DRAW.log)
make run-log-bas    # build and run with basic logging
make clean          # remove binary + log

# Override compiler path (defaults to $HOME/git/qb64pe/qb64pe)
make QB64PE=/path/to/qb64pe

# Manual invocation
qb64pe -w -x -o DRAW.run DRAW.BAS

# Run with a project/image
./DRAW.run myproject.draw
./DRAW.run --config DRAW.linux.cfg
./DRAW.run --config-upgrade        # reconcile cfg with new defaults
./DRAW.run --reset-defaults        # restore factory cfg
```

There is no test runner. Manual QA plans live in `PLANS/TESTS/`. `draw-watch.sh` launches DRAW with a CPU-usage alert threshold (useful for catching idle-loop regressions).

## Architecture

### BI/BM split (mandatory)

QB64-PE separates declarations from implementations:

- `.BI` files — `TYPE`, `CONST`, `DIM SHARED`, `DECLARE`, init calls. Declarations only.
- `.BM` files — `SUB` / `FUNCTION` bodies. No declarations.
- Every BI/BM file starts with `$INCLUDEONCE`.
- `_ALL.BI` and `_ALL.BM` are the master include chains; **order matters** and is enforced by dependencies. New modules are added to both chains in the correct group (CORE → CFG → GUI → INPUT → OUTPUT → TOOLS → PIXEL-COACH → THEME).
- `DRAW.BAS` includes `_ALL.BI` at the top and `_ALL.BM` is included implicitly. The main loop lives in `DRAW.BAS`.

### Required file-scope directives

```qb64
'$DYNAMIC
$CONSOLE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
```

### Singleton-state pattern

Most subsystems expose one `TYPE` and one `DIM SHARED` instance:

```qb64
TYPE TOOL_OBJ
    ACTIVE AS INTEGER
    ' ... state fields
END TYPE
DIM SHARED TOOL AS TOOL_OBJ
```

Heavily-used globals: `SCRN`, `MOUSE`, `CFG`, `THEME`, `CURRENT_TOOL%`, `PAINT_COLOR~&`, `PAINT_BG_COLOR~&`, `DRAW_COLOR~&`, `CANVAS_DIRTY%`, `HISTORY_saved_this_frame%`, `SCENE_DIRTY%`, `FRAME_IDLE%`, `COMP_DIRTY_X1/Y1/X2/Y2`.

### Directory layout

| Path | Role |
|------|------|
| `CFG/` | `CONFIG.BI/BM` (DRAW.cfg loader), `CONFIG-THEME.BI/BM`, `BINDINGS.BI/BM` (keyboard/mouse rebind storage) |
| `CORE/` | `PERF` (frame counters), `ERROR`, `PATHS` (OS-native dirs migrated 2026-05-02), `SOUND`, `IMAGE` |
| `GUI/` | All UI widgets: toolbar, menubar, palette strip, layer panel, drawer, preview window, organizer, edit/advanced bars, dialogs, command palette, color mixer, image browser, character map, smart guides, transparency checkerboard, popup menus, tooltips, controls dialog |
| `INPUT/` | `MOUSE.BM` (~2600 lines — the central input pipeline), `KEYBOARD.BM`, `MODIFIERS.BM`, `STICK.BM`, Aseprite/PSD/Lospec loaders |
| `OUTPUT/` | `SCREEN.BM` (the render pipeline — `SCREEN_render`), file exporters (BAS, PNG/BMP/GIF/JPG/TGA/HDR/ICO/QOI, QB64 source) |
| `TOOLS/` | Per-tool BI/BM pairs (brush, dot, line, rect, ellipse, polygon, fill, marquee, picker, move, transform, crop, spray, zoom, text, smart shapes, bezier, eraser, extract, etc.), plus `HISTORY.BI/BM` (unified undo/redo) and `DRW.BI/BM` (.draw file format) |
| `PIXEL-COACH/` | Pixel-art analyzer engine |
| `ASSETS/` | Fonts, icons, palettes (`.GPL`), themes (`THEMES/<name>/THEME.CFG` overrides compiled defaults at runtime), sounds, music |
| `includes/QB64_GJ_LIB/` | Shared QB64 utility submodule: file dialog, color picker, message box, text input, Aseprite/PSD readers. Sub-files are included directly (not via leader files) due to `$INCLUDEONCE` path-normalization issues |
| `PLANS/` | Design notes, state-machine diagrams, manual test plans (not packaged) |
| `CHEATSHEET.md` | Authoritative keyboard reference (mirrored to `DRAW-Hotkeys.html`) |

### Main loop (DRAW.BAS)

```
DO
  0  _EXIT → CMD_execute_action 212 (graceful exit w/ unsaved dialog)
  1  Deferred command-line file load (first frame only)
  2  Windows drag-and-drop (_ACCEPTFILEDROP)
  3  _KEYHIT + MODIFIERS_update
  4  LOOP_start — resets HISTORY_saved_this_frame%, TITLE_check
  5  MUSIC_tick
  6  MOUSE_input_handler
  7  KEYBOARD_input_handler
  8  STICK_input_handler
  9  Idle detection → FRAME_IDLE%, SCENE_DIRTY%
  10 IF NOT FRAME_IDLE% THEN SCREEN_render
  11 _LIMIT (15 FPS idle / CFG.FPS_LIMIT% active) — MUST be AFTER render
  12 *_input_handler_loop (post-render)
  13 PERF_frame_end, LOOP_end
LOOP
```

Idle frames skip `SCREEN_render` entirely. `_LIMIT` placed before `SCREEN_render` introduces visible cursor lag.

### Render pipeline (`OUTPUT/SCREEN.BM` → `SCREEN_render`)

Layers composite back-to-front into `SCRN.CANVAS&`, then GPU-scale to window. The scene is cached in `SCENE_CACHE&`; cursor-only frames skip to the `SkipToPointer:` label and re-blit the cache. **Per-frame animations (marching ants, blinking cursors) must render AFTER `SkipToPointer:`** — otherwise they force `SCENE_DIRTY% = TRUE` every frame and defeat the cache. See `.github/instructions/draw-rendering.instructions.md` for the full step list and cache invariants.

### Coordinate systems

- `MOUSE.RAW_X/Y` — screen pixels (GUI hit-testing)
- `MOUSE.X/Y` — canvas pixels, post-zoom/pan + grid snap
- `MOUSE.UNSNAPPED_X/Y` — canvas pixels without grid snap (fill, picker)
- `canvasX% = INT((rawX% - offsetX%) / zoom!)`

### Action dispatcher

All commands route through `CMD_execute_action <id>` in `GUI/COMMAND.BM` (200+ actions). New keybindings register an action ID in `CMD_init` and a handler in `CMD_execute_action`; user-customizable bindings live in `CFG/BINDINGS.BI/BM`.

## Naming conventions

- Types: `UPPER_CASE` or `NAME_OBJ` (`MOUSE_OBJ`, `DRAW_GRID`)
- Constants: `CONST TOOL_BRUSH = 1`, `CONST KEY_ESCAPE& = 27`
- SUBs / FUNCTIONs: `MODULE_action` (`MOUSE_input_handler`, `FILL_flood`, `HISTORY_record_brush`)
- Type suffixes: `%` INTEGER, `&` LONG, `~&` _UNSIGNED LONG (colors), `$` STRING, `!` SINGLE, `#` DOUBLE

## Critical gotchas

These reflect real bugs that have shipped. Read `.github/instructions/draw-project.instructions.md` for the full list with examples — what follows is the short version.

1. **Never use `_DEST _CONSOLE` + `PRINT` for debug.** Corrupts the active drawing destination mid-frame. Use `_LOGINFO` / `_LOGWARN` / `_LOGERROR`.
2. **Image handle validity:** `IF handle& < -1 THEN _FREEIMAGE handle&`. Zero and -1 are invalid.
3. **Preserve `_DEST`:** save `oldDest& = _DEST`, do work, restore. The same applies to `_SOURCE`, `_FONT`.
4. **History is the #1 bug source.** All Ctrl+Z/Y goes through the unified `HISTORY` system in `TOOLS/HISTORY.BI/BM`. Old `UNDO` / `WORKSPACE_UNDO` systems were removed — do not reintroduce. Always guard saves with `IF NOT HISTORY_saved_this_frame% THEN ... HISTORY_saved_this_frame% = TRUE`. Reset in `LOOP_start`. See `.github/instructions/draw-undo.instructions.md`.
5. **`MOUSE.UI_CHROME_CLICKED%` must be reset INSIDE `MOUSE_should_skip_tool_actions%`**, never before — otherwise the release-frame fires a spurious history save (ghost undo states from clicking GUI chrome).
6. **`_KEYHIT` is unreliable for Ctrl+/Alt+ combos on Linux/SDL2.** Use `_KEYDOWN(physicalCode&)` with a `STATIC pressed%` guard. Put Ctrl+Alt hotkeys in `KEYBOARD.BM`, never in `DRAW.BAS`. Key physical codes: `KEY_PGUP& = 18688`, `KEY_PGDN& = 20736`, `.` = 46, `,` = 44, `/` = 47.
7. **Mouse button transitions:** `IF MOUSE.B1% AND NOT MOUSE.OLD_B1% THEN` (pressed) / `IF NOT MOUSE.B1% AND MOUSE.OLD_B1% THEN` (released).
8. **Colors are `_UNSIGNED LONG` (`~&`).** Theme color fields **must** be `~&`, never `%` — `INTEGER` truncates RGB32 and silently corrupts colors when the palette changes.
9. **Tool-switch reset:** call every `*_reset` (`MARQUEE_reset`, `LINE_reset`, `RECT_reset`, `ELLIPSE_reset`, `POLY_LINE_reset`, `MOVE_reset`, `TEXT_reset`) when changing `CURRENT_TOOL%`.
10. **`contentDirty%` discipline:** `BLEND_invalidate_cache` does NOT mark layers `contentDirty%`. Only set `layer.contentDirty% = TRUE` when actual pixel content changes on that specific layer. Blanket-marking is O(n) per-pixel `_MEM` opacity recalc per invalidation.
11. **THEME.BI include-order timing:** `SCREEN_init` runs at include-time (from `SCREEN.BI`) before `THEME.BI` resets compiled-in defaults. Any `*_init` reading `THEME.*` fields at include-time sees empty values. **Fix:** lazy-load — resolve `THEME.*` on first render, not in `_init`. `DRAW.BAS` re-runs `THEME_load` after all BI includes for this reason.
12. **Default-hidden panels must set `ManuallyHidden% = TRUE`** alongside `show% = FALSE`. Auto-hide restore logic checks `NOT show% AND NOT ManuallyHidden%` and will unhide a panel that was initialized hidden but not manually hidden. Follow `PREVIEW_init`.
13. **QB64 passes SUB/FUNCTION params BY REFERENCE.** `BYVAL` only works on `DECLARE LIBRARY`. If a SUB takes a `SHARED` global as a param and the body calls anything that mutates that global, the param is silently corrupted. Copy to a local at function entry.
14. **Apron coordinate offset:** when a layer is promoted (`apronW% > 0`), its `imgHandle&` is larger than the canvas. Canvas coord `(cx, cy)` maps to buffer coord `(cx + apronW, cy + apronH)`. Never write raw canvas coords into a promoted buffer.
15. **`DRW_load_binary` must reset all tool/panel state.** When you add new tool or panel state, add the reset to `DRW_load_binary` — otherwise stale state leaks across project loads.
16. **Custom brush rendering must handle eraser mode.** `CUSTOM_BRUSH_render` uses `_PUTIMAGE` + `_BLEND`, which silently drops transparent pixels. Check `PAL_FG_IS_TRANSPARENT%` and use `_DONTBLEND` + per-pixel `PSET _RGBA32(0,0,0,0)` to match `PAINT_pset_with_symmetry`.

## Adding a new tool

1. `TOOLS/MYTOOL.BI` — `TYPE`, `DIM SHARED`, init call
2. `TOOLS/MYTOOL.BM` — implementation
3. `CONST TOOL_MYTOOL` in `_COMMON.BI` (or `GUI/GUI.BI` for higher IDs)
4. Add includes to `_ALL.BI` and `_ALL.BM` (correct ordering group)
5. Keyboard binding in `KEYBOARD_tools()`
6. Action ID in `CMD_init`, handler in `CMD_execute_action`
7. Mouse handling in `MOUSE_dispatch_tool_hold` / `MOUSE_dispatch_tool_release` (with `HISTORY_record_*` on commit)
8. Preview rendering in `SCREEN_render()` **before** the scene cache save
9. Menu entry in `MENUBAR_init` with the action ID
10. Reset state in `DRW_load_binary`

## Specialized instruction files

`.github/instructions/` contains focused, scope-tagged deep-dives. Read the relevant one before touching that area:

| File | Scope |
|------|-------|
| `draw-project.instructions.md` | Master overview, all gotchas, every key file |
| `draw-undo.instructions.md` | History system internals, record kinds, double-save guard |
| `draw-rendering.instructions.md` | Render pipeline, scene cache, blend compositing |
| `draw-mouse.instructions.md` | MOUSE dispatch pipeline, UI_CHROME_CLICKED lifecycle |
| `draw-ui.instructions.md` | Panel docking, auto-hide, tooltips, edit/advanced bars |
| `draw-fileformat.instructions.md` | `.draw` PNG+drAw-chunk binary format versions |
| `draw-chrome-geometry.instructions.md` | Toolbar/panel layout math |
| `draw-sound.instructions.md` | Sound slots, music, SF2 MIDI |
| `draw-text-tool.instructions.md` | Text tool state machine |

## Config

User config lives at OS-native paths (migrated 2026-05-02):
- Linux: `~/.config/DRAW/`, `~/.local/share/DRAW/`, `~/.cache/DRAW/`
- macOS / Windows: platform equivalents

`DRAW.cfg.default` ships the factory defaults. Platform-specific overrides: `DRAW.macOS.cfg`, `DRAW.linux.cfg`, `DRAW.windows.cfg`. Priority: `--config` arg > OS-specific cfg > `DRAW.cfg`. On first run with no cfg, DRAW auto-detects display scale, toolbar scale, and viewport size.
