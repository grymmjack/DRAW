# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

DRAW is a pixel art editor written in **QB64-PE** (QB64 Phoenix Edition). Single executable, no runtime dependencies. Its distinguishing feature is the ability to export artwork as QB64 source code. Version constant lives in `_COMMON.BI` as `APP_VERSION$`.

## Build & Run

> **Toolchain (as of 2026-08-22):** a740g's GLFW work (PR #701) — including the OS
> hardware cursor (`_MOUSECURSOR`), DRAW's sole cursor path — has **merged upstream**,
> so the Makefile default is back to the **stock main-repo compiler**
> (`~/git/qb64pe/qb64pe`, QB64-PE v4.6.0+, which now has `_MOUSECURSOR`). The standalone
> a740g checkout is no longer required — keep it only for parity testing
> (`make a740g` → `~/git/qb64pe-a740g-test/qb64pe-regen`). The old pre-GLFW v4.5.0 build
> (`make v450` → `~/git/qb64pe-450`) still **fails** on `_MOUSECURSOR` and is kept for
> regression testing only.

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
./DRAW.run --options-list          # print every config option + default + description, then exit
./DRAW.run --option KEY=VALUE      # override any config key from the CLI (repeatable; beats the .cfg)
./DRAW.run --option TOOLTIPS_DISABLED=TRUE --option GROUP_DRAW_AUTO_LAYER=TRUE
```

### QA

`QA/draw-qa.sh` is an xdotool-driven GUI harness — ~97 test files in `QA/tests/`, each launched against a fresh DRAW using the pinned `QA/DRAW.qa.cfg` so runs never touch the user's own config.

> **As of 2026-08-12, `QA/draw-qa.sh` is a thin wrapper** that forwards to the standalone [qa-harness](https://github.com/grymmjack/qa-harness) toolkit (`~/git/qa-harness`, override with `QA_HARNESS`) using its DRAW adapter. The CLI below is unchanged and DRAW's `QA/tests/*.sh` run verbatim, but the harness *implementation* (runner, region-diff asserts, driver, geometry) now lives in the toolkit — `core/`, `drivers/linux-x11/`, `adapters/draw/`. Runs default to **offscreen (Xvfb)**; add `--onscreen` to watch. The pre-extraction single-file harness is in git history (before this date). Details: `.claude/agent-memory/main/qa-harness-toolkit.md`.

> **Headless / automation safety:** DRAW is a GUI app and needs an X11/Wayland display. A GUI launch with **no display now exits cleanly** (logs + a console message, exit code 3) instead of crashing into a desktop crash dialog that would hang automation behind an OK button. Set **`DRAW_HEADLESS=1`** to force that path on any OS; it also switches DRAW's crash notice from a blocking modal to a non-blocking auto-dismiss banner (same as `--developer`). Run the GUI under **Xvfb** (as `draw-qa.sh` does) for automated testing. Console-only flags (`--version`, `--help`, `--options-list`) always work headless.

```bash
cd QA
./draw-qa.sh                     # whole suite
./draw-qa.sh tests/smoke.sh      # one file
./draw-qa.sh --rerun-passed ...  # ignore the passed-test cache
./draw-qa.sh --developer ...     # DRAW logs every dispatched action to ./inputs.log
```

Tests assert visually: `snap_region x y w h label` then `assert_regions_differ` / `assert_regions_same`. Coordinates are **viewport pixels**, mapped to the screen by `_abs()`.

**When many unrelated tests fail with "regions are identical (action had no effect?)", suspect the harness first.** That message means a click missed its target or a capture framed the wrong pixels — not necessarily that DRAW is broken. Run `tests/harness-calibration.sh`, which pins the viewport→screen mapping against the menu bar (12px), a layer row (20px) and the status bar (11px); all three are smaller than the kind of drift that causes this. To settle whether DRAW received an input at all, run with `--developer` and grep `inputs.log` for `[FIRE] ... action=`.

Derive UI coordinates from the render constants rather than probing them — the geometry arithmetic is correct (status bar `SCRN.h - THEME.STATUS_height%`, layer panel `panelY% = 0` with a 16px header and 20px rows, toolbar `TB_TOP = 0`). Note `PALETTE_H` in the harness is a conservative reservation, not the real 12px strip, so `PAL_Y` must not be used to click palette chips.

Manual QA plans live in `PLANS/TESTS/`. `draw-watch.sh` launches DRAW with a CPU-usage alert threshold (useful for catching idle-loop regressions).

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
| `GUI/` | All UI widgets: toolbar, menubar, palette strip, layer panel, drawer, preview window, organizer, edit/advanced bars, dialogs, command palette, color mixer, image browser, character map, smart guides, transparency checkerboard, popup menus, tooltips, controls dialog. Also the font backends: `FONT-LIST` (TTF/bitmap/CBF) and `TDF-FONT`/`TDF-BROWSER` (TheDraw) |
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

Layers composite back-to-front into `SCRN.CANVAS&`, then GPU-scale to window. The scene is cached in `SCENE_CACHE&`; cursor-only frames skip to the `SkipToPointer:` label and re-blit the cache. **Per-frame animations (marching ants, blinking cursors) must render AFTER `SkipToPointer:`** — otherwise they force `SCENE_DIRTY% = TRUE` every frame and defeat the cache. See `.claude/instructions/draw-rendering.md` for the full step list and cache invariants.

### Coordinate systems

- `MOUSE.RAW_X/Y` — screen pixels (GUI hit-testing)
- `MOUSE.X/Y` — canvas pixels, post-zoom/pan + grid snap
- `MOUSE.UNSNAPPED_X/Y` — canvas pixels without grid snap (fill, picker)
- `canvasX% = INT((rawX% - offsetX%) / zoom!)`

### Action dispatcher

All commands route through `CMD_execute_action <id>` in `GUI/COMMAND.BM` (200+ actions). New keybindings register an action ID in `CMD_init` and a handler in `CMD_execute_action`.

### Input system (NEW — branch `input-rearchitecture`)

DRAW is migrating from scattered IF/STATIC keyboard/mouse handlers to a unified event-dispatch table in `INPUT/INPUT.BI/BM`:

- **Bindings declared in a table** via `INPUT_register_key%`, `INPUT_register_mouse%`, `INPUT_register_wheel%`, `INPUT_register_hover%` (all centralized in `INPUTS_register_all` in `INPUT/INPUT.BM`).
- **Regions** (GUI panels) call `REGION_set_bounds REGION_<NAME>, x, y, w, h, ZORDER_*` in their render SUBs. Hidden panels stay inactive via `REGION_clear_all` at the top of `SCREEN_render`.
- **Events** flow: keyboard edges + mouse click/dblclick/drag state machines + hover enter/leave + wheel ticks → `DETECTED_EVENTS` queue → `INPUT_dispatch_frame` matches against bindings → `CMD_execute_action`.
- **Conflict detection** runs at startup in developer mode (`--developer` CLI flag, `CFG.DEVELOPER_MODE=TRUE`, or `DRAW_DEVELOPER=1` env). Writes to `./inputs.log`.
- **Migration is phased**: bindings marked `dispatched = FALSE` are metadata-only (legacy code still owns dispatch); bindings marked `dispatched = TRUE` fire through the central dispatcher. Current state: 88 keyboard bindings + 14 panel regions registered as metadata, 0 audit conflicts.

See `PLANS/REARCHITECTURE.md` for the full spec, `.claude/agent-memory/main/reference_input_system.md` for the quick reference, and `.claude/instructions/input-system.md` for the implementation guide.

## Naming conventions

- Types: `UPPER_CASE` or `NAME_OBJ` (`MOUSE_OBJ`, `DRAW_GRID`)
- Constants: `CONST TOOL_BRUSH = 1`, `CONST KEY_ESCAPE& = 27`
- SUBs / FUNCTIONs: `MODULE_action` (`MOUSE_input_handler`, `FILL_flood`, `HISTORY_record_brush`)
- Type suffixes: `%` INTEGER, `&` LONG, `~&` _UNSIGNED LONG (colors), `$` STRING, `!` SINGLE, `#` DOUBLE

## Critical gotchas

These reflect real bugs that have shipped. Read `.claude/instructions/draw-project.md` for the full list with examples — what follows is the short version.

1. **Never use `_DEST _CONSOLE` + `PRINT` for debug.** Corrupts the active drawing destination mid-frame. Use `_LOGINFO` / `_LOGWARN` / `_LOGERROR`.
2. **Image handle validity:** `IF handle& < -1 THEN _FREEIMAGE handle&`. Zero and -1 are invalid.
3. **Preserve `_DEST`:** save `oldDest& = _DEST`, do work, restore. The same applies to `_SOURCE`, `_FONT`.
4. **History is the #1 bug source.** All Ctrl+Z/Y goes through the unified `HISTORY` system in `TOOLS/HISTORY.BI/BM`. Old `UNDO` / `WORKSPACE_UNDO` systems were removed — do not reintroduce. Always guard saves with `IF NOT HISTORY_saved_this_frame% THEN ... HISTORY_saved_this_frame% = TRUE`. Reset in `LOOP_start`. See `.claude/instructions/draw-undo.md`.
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
15. **All THREE document-creation paths must reset tool/panel state** — `DRW_load_binary` (open), `DRW_new_canvas` (File > New), and `DRW_create_canvas_at_size` (New from Clipboard / New from AI). They drifted apart once already: New reset the smart shapes but not the basic shape tools or the transform overlay; Open reset neither set. Stale state is not merely cosmetic — `TRANSFORM` holds a handle to the old layer, and `BEZIER`/`POLY_LINE`/`SPRAY`/`ERASER` each hold a canvas snapshot for undo, so a carried-over shape commits an undo state belonging to a document that is already closed. When you add tool or panel state, add its reset to **all three**, and diff them against each other afterwards.
16. **Custom brush rendering must handle eraser mode.** `CUSTOM_BRUSH_render` uses `_PUTIMAGE` + `_BLEND`, which silently drops transparent pixels. Check `PAL_FG_IS_TRANSPARENT%` and use `_DONTBLEND` + per-pixel `PSET _RGBA32(0,0,0,0)` to match `PAINT_pset_with_symmetry`.
17. **Grep before allocating an action ID.** `CMD_execute_action` is one `SELECT CASE action_id%` spanning ~4,400 lines of `GUI/COMMAND.BM`. BASIC takes the **first** matching `CASE`, so a duplicate label is silent, unreachable dead code — QB64-PE emits no warning. This has shipped twice: AI actions took 1801–1809 and killed five Image-menu commands (fixed in 1.7.0 by moving AI to 1820–1828), and text styles took 1510–1512 from the Palette actions (fixed by moving to 1520–1522). Audit with:<br>`grep -n '^        CASE [0-9]' GUI/COMMAND.BM | sed 's/.*CASE //' | awk '{print $1}' | sort | uniq -d`
18. **`AND` / `OR` do NOT short-circuit — use `_ANDALSO` / `_ORELSE`.** Both sides are always evaluated, so a guard does not protect what follows it: `IF idx >= 1 AND arr(idx).field THEN` still subscripts `arr` when `idx` is 0. On a 1-based array that raises **ERR 9 "Subscript out of range"**, and because `FatalError` does `RESUME NEXT` the branch may then run *anyway* with the bad index — the `IF` result is unreliable, not merely noisy. 21 such sites were fixed in 1.7.0; the worst fired on every `Ctrl+A` outside a text layer. Audit with:<br>`grep -rnP '\b(\w+%?)\s*(>=|>|<=|<)\s*[-\w]+\s+AND\b.*\(\s*\1\s*[,)]' --include='*.BM' .`<br>Note the **BAS exporter emits `AND` guards into generated code**, so exported programs inherit the pattern.
19. **`NOT` is bitwise, not logical — use `_NEGATE`.** It only behaves logically on exactly `0`/`-1`: `NOT 0` = `-1`, `NOT -1` = `0`, but **`NOT 1` = `-2`, still truthy**. Any `IF NOT someFunction%` is wrong when that function returns an id, count or handle. This shipped: `TI_process_key%` returns the focused widget's ID, so `IF NOT tiAte%` always passed and ENTER submitted the AI dialog even after the text area consumed it. Related built-ins: `_IIF(cond,a,b)`, `_TRUE`/`_FALSE`, `_LESS`/`_EQUAL`/`_GREATER` (the `SGN`/`_STRCMP` domain). DRAW's own unprefixed `TRUE`/`FALSE` in `_COMMON.BI` are equivalent and fine — do not mass-rename ~7,300 uses.
20. **Reserved words rejected as identifiers.** `pos`, `palette`, `screen`, `color`, `scale`, `step`, `timer`, `width`, `height`, `key`, `line`, `point` and friends fail as a variable/parameter/field name with `Name already in use (pos)`. Prefix instead (`atPos`, `srcPalette`). Probe with a 6-line standalone file rather than a ~5-minute full build.

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

## Recording notes — always OS-stamp (automatic)

When recording any durable note, memory, or gotcha about tool / build / runtime /
environment / shell behavior, **automatically tag it with the OS it was observed on**,
detected from the session environment (`Platform` / `OS Version`: `macOS / Darwin …`,
`Linux`, `Windows`). Never ask the user to specify the platform. Lead OS-specific
facts with an OS tag (e.g. `[macOS]`); if confirmed on one OS but untested elsewhere,
say so; group multi-OS facts per OS; leave truly OS-agnostic facts untagged. DRAW is
cross-platform (macOS/Linux/Windows), so this keeps a single note safe to read on any
machine. Same convention is documented in the `grymmjack/qb64pe-mcp-server-bash` repo.

## Specialized instruction files

`.claude/instructions/` contains focused deep-dives. Read the relevant one before touching that area:

| File | Scope |
|------|-------|
| `.claude/instructions/draw-project.md` | Master overview, all gotchas, every key file |
| `.claude/instructions/draw-undo.md` | History system internals, record kinds, double-save guard |
| `.claude/instructions/draw-rendering.md` | Render pipeline, scene cache, blend compositing |
| `.claude/instructions/draw-mouse.md` | MOUSE dispatch pipeline, UI_CHROME_CLICKED lifecycle, floating-window precedence |
| `.claude/instructions/draw-zorder.md` | The one z-stack for render AND input: cursor overlay, `ZORDER_FLOATING`, `BROWSER_owns_mouse%`, `REGION_CANVAS` floor |
| `.claude/instructions/draw-ui.md` | Panel docking, auto-hide, tooltips, edit/advanced bars |
| `.claude/instructions/draw-fileformat.md` | `.draw` PNG+drAw-chunk binary format versions |
| `.claude/instructions/draw-chrome-geometry.md` | Toolbar/panel layout math |
| `.claude/instructions/draw-sound.md` | Sound slots, music, SF2 MIDI |
| `.claude/instructions/draw-text-tool.md` | Text tool state machine (points to `fix-text-tool-bug` skill) |
| `.claude/instructions/draw-tdf-fonts.md` | TheDraw `.TDF` fonts: binary format, CP437 cell rasteriser, `.TDX` index, dedup repacker |
| `.claude/instructions/draw-multi-instance.md` | Multiple isolated instances: heartbeat registry, seeded per-instance config, Copy/Paste/Send Layer (`CORE/INSTANCE`, `TOOLS/LAYERXFER`), QB64-PE IPC constraints |
| `.claude/instructions/draw-drag-drop.md` | Target-aware OS file-drop (`INPUT/DROP.BM`): no-drop-coords workaround, region routing to canvas/layer-panel/brush-bin/menu-bar, size gate + Shift placement |

The `.claude/skills/` directory contains procedural workflows for common tasks (release prep, QA test generation, bug fixing with state diagrams, PDF manual build, image upscaling, mind-map generation, QB64-PE porting/debugging). Each subdirectory has a `SKILL.md` invoked as a slash command.

## Config

User config lives at OS-native paths (migrated 2026-05-02):
- Linux: `~/.config/DRAW/`, `~/.local/share/DRAW/`, `~/.cache/DRAW/`
- macOS / Windows: platform equivalents

`DRAW.cfg.default` ships the factory defaults. Platform-specific overrides: `DRAW.macOS.cfg`, `DRAW.linux.cfg`, `DRAW.windows.cfg`. Priority: `--config` arg > OS-specific cfg > `DRAW.cfg`. On first run with no cfg, DRAW auto-detects display scale, toolbar scale, and viewport size.
