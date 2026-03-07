# DRAW Project — Refactor Analysis
> Generated 2026-03-07 · App version 0.16.0

This document catalogues redundancy, over-large routines, deep nesting, and
responsibility violations across the DRAW codebase, sorted by impact on
cognitive load. Items marked **[DONE]** have already been addressed in this
PR. All others are future work, ranked from highest to lowest ROI.

---

## Project Stats

| Metric | Value |
|--------|-------|
| Total source files | 179 (.BM + .BI + .BAS) |
| Total lines of code | ~57,700 |
| Total SUBs | 656 |
| Total FUNCTIONs | 233 |
| Total routines | 889 |

### Lines by directory

| Directory | Files | Lines | Routines |
|-----------|------:|------:|---------:|
| GUI/      |    49 | 23,394 |      310 |
| TOOLS/    |    80 | 17,939 |      343 |
| INPUT/    |    16 |  7,522 |      115 |
| OUTPUT/   |     8 |  3,084 |       60 |
| CFG/      |    10 |  2,922 |       14 |
| CORE/     |     8 |  1,117 |       36 |
| ROOT      |     5 |  1,105 |       11 |

---

## #1 — Repeated Dirty-Flag Boilerplate **[DONE]**

**Impact: 186 lines removed · 18 files simplified · zero logic change**

The three lines

```qb64
SCENE_DIRTY% = TRUE
GUI_NEEDS_REDRAW% = TRUE
FRAME_IDLE% = FALSE
```

appeared **69 times** across 18 files, in multiple orderings, sometimes with
`CANVAS_DIRTY% = TRUE` (16 times) and/or `BLEND_invalidate_cache` (16 times)
prepended.

### Fix applied

Three helper SUBs added to `_COMMON.BM` / declared in `_COMMON.BI`:

| Helper | Meaning | Replaces |
|--------|---------|---------|
| `INVALIDATE_scene` | UI/state change — repaint only | 3-line pattern (37×) |
| `INVALIDATE_canvas` | Pixel change — also mark dirty | 4-line CANVAS+3 (16×) |
| `INVALIDATE_layers` | Layer structure change — rebuild blend cache | 5-line BLEND+CANVAS+3 (16×) |

All 69 consecutive-block occurrences have been replaced.

### Remaining standalone `SCENE_DIRTY% = TRUE` (76 occurrences)

These are **not** immediately eligible for replacement because they are:
- Partial sets (missing `GUI_NEEDS_REDRAW%` or `FRAME_IDLE%` deliberately)
- Interspersed with other logic between the flag assignments

They should be audited case-by-case in a follow-up pass.

---

## #2 — `CMD_execute_action` — 2,527-Line Monolith

**File:** `GUI/COMMAND.BM` · **Routine:** `SUB CMD_execute_action`  
**Nesting depth at peak:** 9 levels  
**CASE count:** 209

This is the single most expensive routine to maintain. Every feature, every
tool activation, every menu item, and every keyboard shortcut eventually
routes through here. The SELECT CASE block spans the entire routine.

### Recommendation

Split by action category. Each group becomes a private helper called from the
main dispatcher:

```qb64
SELECT CASE action_id%
    CASE 101 TO 121:  CMD_action_tools action_id%
    CASE 201 TO 213:  CMD_action_file action_id%
    CASE 301 TO 330:  CMD_action_edit action_id%
    CASE 401 TO 433:  CMD_action_view action_id%
    CASE 501 TO 517:  CMD_action_color action_id%
    CASE 601 TO 609:  CMD_action_brush action_id%
    CASE 701 TO 711:  CMD_action_layer action_id%
    CASE 801 TO 802:  CMD_action_canvas action_id%
    CASE 901 TO 908:  CMD_action_grid action_id%
    CASE 1001 TO 1003: CMD_action_symmetry action_id%
    CASE 1101 TO 1112: CMD_action_custom_brush action_id%
    CASE 1201 TO 1206: CMD_action_assistants action_id%
    CASE 1401 TO 1414: CMD_action_selection action_id%
    CASE 1501 TO 1513: CMD_action_palette action_id%
    CASE 1601 TO 1607: CMD_action_help action_id%
    CASE 1701 TO 1704: CMD_action_tools_menu action_id%
    CASE 1801 TO 1802: CMD_action_canvas_resize action_id%
    CASE 2001 TO 2010: CMD_action_image_adj action_id%
END SELECT
```

Estimated impact: ~2,300 lines split into ~15 focused helpers of 50–200
lines each, dropping peak nesting from 9 to ~4 levels.

---

## #3 — Three Parallel Undo Systems (2,656 Lines Total)

**Files:** `TOOLS/UNDO.BM` (545 lines), `TOOLS/WORKSPACE-UNDO.BM` (1,118 lines),
`TOOLS/HISTORY.BM` (993 lines)

`HISTORY.BM` is already flagged in `TOOLS/HISTORY.BI` as:

> *"This module is the replacement target for split pixel and workspace undo.
> It is intentionally introduced first as a compiled foundation before
> producers are rerouted to it."*

The problem is that all three systems are live and compiled together. New code
uses `HISTORY_*`; old code still calls `UNDO_save_state` and
`WORKSPACE_UNDO_*`. The routing logic in `CMD_execute_action` (Ctrl+Z/Y)
compares timestamps from TWO of the three systems.

### Recommendation

Complete the migration to `HISTORY.BM`:

1. Audit every call to `UNDO_save_state` and `WORKSPACE_UNDO_*` — map each to
   the corresponding `HISTORY_begin_record` / `HISTORY_commit_record` call.
2. Replace one module at a time, keeping the routing logic working.
3. Delete `TOOLS/UNDO.BM` and `TOOLS/WORKSPACE-UNDO.BM` when all callers
   have been migrated.

Estimated removal: **1,663 lines** of legacy undo code once migration is
complete.

---

## #4 — `GUI/LAYERS.BM` — 3,121-Line God Module

**Three distinct responsibilities in one file:**

| Responsibility | Approx. lines | Natural new file |
|----------------|----------:|-----------------|
| Layer data operations (new, delete, merge, duplicate, opacity, z-order) | ~900 | `GUI/LAYERS-OPS.BM` |
| Blend composite engine (LAYER_blend_composite, BLEND_invalidate_cache) | ~300 | `GUI/LAYERS-BLEND.BM` |
| Layer panel UI (render, click handler, scroll, drag) | ~1,600 | `GUI/LAYERS-PANEL.BM` |

`LAYER_PANEL_render` alone is 414 lines with nesting depth 11.

### Two sub-routines to extract first

```
LAYER_PANEL_render_row     — draws a single layer row (visibility/opacity/name)
LAYER_PANEL_render_header  — draws the panel header bar
```

---

## #5 — `INPUT/MOUSE.BM` — 3,306-Line Input Dispatcher

**60 SUBs/FUNCTIONs** handling every tool's mouse events in one file.

The 10 `MOUSE_release_*` functions (line, rect, ellip, brush, spray, dot,
zoom, marquee, move, text) share no code even though 7 of them:

- Capture a `_COPYIMAGE` history-before snapshot
- Draw the shape
- Restore `_DEST`
- Call `HISTORY_commit_record` / `CANVAS_DIRTY% = TRUE`

```qb64
' Pattern repeated in MOUSE_release_line, _rect, _ellip (117, 108, 78 lines):
DIM xxx_history_before AS LONG
IF NOT HISTORY_IN_PROGRESS% AND LAYERS(CURRENT_LAYER%).historyId& > 0 THEN
    xxx_history_before& = _COPYIMAGE(rect_target&, 32)
    ' ... set flags ...
END IF
_DEST rect_target&
' ... draw ...
_DEST oldDest&
IF xxx_history_before& < -1 THEN
    HISTORY_record_xxx layerId&, layerSlot%, ...
    IF xxx_history_before& < -1 THEN _FREEIMAGE xxx_history_before&
END IF
INVALIDATE_canvas
```

### Recommendation

Extract a `MOUSE_commit_shape` helper that encapsulates the history
capture/commit and dest-save/restore, accepting the draw operation as a
callback (or via a tool-specific commit SUB).

---

## #6 — `INPUT/KEYBOARD.BM` — 2,530-Line Input Handler

**28 SUBs/FUNCTIONs**, many of which replicate the `STATIC pressed AS INTEGER`
guard for key-repeat suppression.

The pattern:

```qb64
STATIC myKeyPressed AS INTEGER
IF MODIFIERS.ctrl% AND _KEYDOWN(keyCode&) THEN
    IF NOT myKeyPressed% THEN
        CMD_execute_action ACTION_ID
        myKeyPressed% = TRUE
    END IF
ELSE
    myKeyPressed% = FALSE
END IF
```

appears ~30 times with slight variations. A macro-style helper cannot be
cleanly expressed in QB64, but grouping all Ctrl+key handlers into a single
table-driven loop would eliminate the repetition.

### Highest-priority split

`KEYBOARD_handle_custom_brush` (183 lines) and
`KEYBOARD_handle_clipboard_operations` (249 lines) each handle 8–12
independent key combos. Each combo should be its own named SUB.

---

## #7 — `GUI/MENUBAR.BM` — 2,586-Line Menu System

**Three distinct responsibilities:**

| SUB | Lines | Responsibility |
|-----|------:|----------------|
| `MENUBAR_register_all` | 251 | Data: menu item registration |
| `MENUBAR_render` + `MENUBAR_render_submenu` | ~350 | Rendering |
| `MENUBAR_handle_key%` | 430 | Keyboard navigation |
| `MENUBAR_handle_mouse_move` | 245 | Mouse hover |
| `MENUBAR_handle_click%` | ~80 | Click dispatch |

`MENUBAR_handle_key%` at 430 lines is the second-largest FUNCTION in the
codebase. Its keyboard navigation logic is deeply nested (depth 9 at peak).

### Recommendation

Split into `MENUBAR-DATA.BM` (registration) and `MENUBAR-NAV.BM`
(keyboard + mouse navigation), keeping `MENUBAR.BM` for rendering only.

---

## #8 — Repeated Canvas Viewport Calculation (24 occurrences)

The four-line snippet:

```qb64
zw& = SCRN.canvasW& * SCRN.zoom!
zh& = SCRN.canvasH& * SCRN.zoom!
dx% = (SCRN.w& - zw&) \ 2 + SCRN.offsetX%
dy% = (SCRN.h& - zh&) \ 2 + SCRN.offsetY%
```

appears **24 times** across 8 files.

### Recommendation

Add to `OUTPUT/SCREEN.BI` / `SCREEN.BM`:

```qb64
SUB SCREEN_get_viewport (zw AS LONG, zh AS LONG, dx AS INTEGER, dy AS INTEGER)
    zw& = SCRN.canvasW& * SCRN.zoom!
    zh& = SCRN.canvasH& * SCRN.zoom!
    dx% = (SCRN.w& - zw&) \ 2 + SCRN.offsetX%
    dy% = (SCRN.h& - zh&) \ 2 + SCRN.offsetY%
END SUB
```

Callers already pass these as local `DIM` variables so the transition is
mechanical. Estimated impact: 72 lines removed (24 × 3 lines replaced by 1
call).

Files affected: `TOOLS/MARQUEE.BM` (8×), `OUTPUT/SCREEN.BM`, `TOOLS/TRANSFORM.BM` (3×),
`TOOLS/IMAGE-IMPORT.BM` (2×), `TOOLS/PICKER-LOUPE.BM`, `TOOLS/MOVE.BM`,
`TOOLS/ZOOM.BM` (partial).

---

## #9 — `GUI/IMGADJ.BM` + `GUI/IMAGE-ADJ.BM` — 3,630-Line Pair

These are **two distinct layers**, not a duplication:

- `IMGADJ.BM` (2,736 lines): Low-level image processing library (`GJ_IMGADJ_*`
  functions — brightness, contrast, dithering, blur, etc.)
- `IMAGE-ADJ.BM` (894 lines): DRAW-specific UI dialogs that call into IMGADJ

The naming convention is the problem. `IMGADJ.BM` uses the `GJ_IMGADJ_`
prefix which suggests it was copied from an external library. The file has 56
functions and should live in `includes/QB64_GJ_LIB/` alongside DICT, STRINGS,
and VECT2D — not in `GUI/`.

### Recommendation

1. Move `GUI/IMGADJ.BI` → `includes/QB64_GJ_LIB/IMGADJ/IMGADJ.BI`
2. Move `GUI/IMGADJ.BM` → `includes/QB64_GJ_LIB/IMGADJ/IMGADJ.BM`
3. Update `_ALL.BI` and `_ALL.BM` include paths accordingly
4. `IMAGE-ADJ.BM` stays in `GUI/` as the DRAW-specific dialog layer

---

## #10 — `CFG/CONFIG.BM` — Two Oversized Routines

| Routine | Lines | Issue |
|---------|------:|-------|
| `CONFIG_save` | 583 | One flat list of `PRINT #fh%, "KEY=" & value` for 80+ config keys |
| `CONFIG_load` | 252 | Large SELECT CASE parsing the same 80+ keys |
| `CFG_validate` | 257 | Range-clamping all fields |

These are inherently repetitive due to the flat config format, but they can
be made more DRY with a table-driven approach or by grouping related keys into
helper SUBs (e.g., `CONFIG_save_palette_section`, `CONFIG_save_grid_section`).

---

## #11 — Repeated `_FREEIMAGE` Guard (191 occurrences)

The pattern:
```qb64
IF someImg& < -1 THEN _FREEIMAGE someImg&
```
appears 191 times. This is correct and necessary (valid QB64 handles are < -1).
A one-liner macro like:
```qb64
' SAFE_FREE someImg&
IF someImg& < -1 THEN _FREEIMAGE someImg& : someImg& = 0
```
cannot be expressed as a SUB (SUBs cannot accept a variable by ref and also
reset it to 0 in one call without wrapping). However, the pattern is clear and
consistent — its value is as documentation rather than a refactor target.

---

## #12 — `TOOLS/DRW.BM` — 1,475 Lines, Two 500+-Line Routines

| Routine | Lines | Issue |
|---------|------:|-------|
| `DRW_load_binary` | 522 | State reset + format parsing + layer reconstruction |
| `DRW_load_from_png` | 264 | Chunk extraction + format dispatch |

Both routines would benefit from extracting:
- `DRW_reset_all_state` — the ~40-line reset block at the top of `DRW_load_binary`
- `DRW_read_palette_section` / `DRW_read_layer_section` — named section readers

---

## #13 — Deep Nesting Hotspots

Top files by structural nesting depth (IF/FOR/DO/SELECT nesting,
cumulative per file — reflects routine complexity, not just indent):

| File | Peak Depth | Peak Line | Primary Cause |
|------|----------:|----------:|---------------|
| `GUI/COMMAND.BM` | 9 | ~839 | 209-case SELECT inside nested IFs |
| `TOOLS/MARQUEE.BM` | 11 | ~2202 | Wand selection with per-pixel per-mode inner loops |
| `GUI/LAYERS.BM` | 11 | ~1823 | `LAYER_PANEL_handle_click%` — all click regions in one function |
| `INPUT/MOUSE.BM` | 8 | ~2123 | Tool dispatch with per-tool state machines |
| `GUI/MENUBAR.BM` | 9 | ~1063 | `MENUBAR_handle_key%` keyboard nav |
| `GUI/STROKE-SEL.BM` | 12 | ~372 | `STROKE_SEL_apply` — multi-mode pixel loop |
| `GUI/PALETTE-STRIP.BM` | 10 | ~487 | Inline rendering branches |

**Stroke-SEL.BM at depth 12** is the worst single-routine nesting offender.
`STROKE_SEL_apply` (280 lines) has 5 nested selection-mode branches each
containing a pixel loop. Extract per-mode helpers: `STROKE_SEL_apply_rect`,
`STROKE_SEL_apply_ellipse`, etc.

---

## #14 — `TOOLS/MARQUEE.BM` — 3,123-Line Tool File

The marquee file is large because it handles 5 tool variants (rect, free,
poly, ellipse, wand) in one file, plus:
- `MAGIC_WAND_select_with_mode` (251 lines)
- `MAGIC_WAND_select_merged` (247 lines)
- Per-pixel flood-fill inner loop at depth 11

### Recommendation

Split into:
- `TOOLS/MARQUEE.BM` — shared marquee state and commit logic
- `TOOLS/MARQUEE-WAND.BM` — magic wand algorithms
- `TOOLS/MARQUEE-POLY.BM` — polygon marquee state machine

---

## Summary Table — Refactor Priority

| Priority | Item | Type | Lines affected | Risk |
|----------|------|------|---------------|------|
| ✅ DONE | INVALIDATE_* helpers | DRY | 186 removed | None |
| 2 | Complete HISTORY migration | Dedup | ~1,663 removable | High — needs careful routing |
| 3 | Split `CMD_execute_action` | SRP | 2,527 → 15×~150 | Medium |
| 4 | Split `GUI/LAYERS.BM` | SRP | 3,121 → 3 files | Medium |
| 5 | `SCREEN_get_viewport` helper | DRY | 72 removable | Low |
| 6 | Split `INPUT/MOUSE.BM` | SRP | 3,306 → 2 files | Medium |
| 7 | `MOUSE_commit_shape` helper | DRY | ~300 removable | Medium |
| 8 | Split `INPUT/KEYBOARD.BM` | SRP | 2,530 → 3 files | Medium |
| 9 | Move IMGADJ to GJ_LIB | Structure | 2,736 relocated | Low |
| 10 | Split `GUI/MENUBAR.BM` | SRP | 2,586 → 3 files | Low |
| 11 | Reduce `STROKE_SEL_apply` nesting | Nest | 280 lines, depth 12 | Low |
| 12 | `DRW_reset_all_state` extract | SRP | 522 → ~400 | Low |
| 13 | Split `TOOLS/MARQUEE.BM` | SRP | 3,123 → 3 files | Medium |
| 14 | Table-drive `CFG/CONFIG.BM` | DRY | reduces ~400 lines | Low |

---

## Top 20 Largest Routines

| Rank | Lines | File | Routine |
|------|------:|------|---------|
| 1 | 2,527 | `GUI/COMMAND.BM` | `CMD_execute_action` |
| 2 | 583 | `CFG/CONFIG.BM` | `CONFIG_save` |
| 3 | 567 | `INPUT/API-LOSPEC.BM` | `LOSPEC_show_dialog` |
| 4 | 522 | `TOOLS/DRW.BM` | `DRW_load_binary` |
| 5 | 430 | `GUI/MENUBAR.BM` | `MENUBAR_handle_key%` |
| 6 | 414 | `GUI/LAYERS.BM` | `LAYER_PANEL_render` |
| 7 | 408 | `OUTPUT/SCREEN.BM` | `SCREEN_render` |
| 8 | 376 | `CFG/CONFIG-THEME.BM` | `THEME_load` |
| 9 | 363 | `GUI/POINTER.BM` | `POINTER_build` |
| 10 | 352 | `GUI/STATUS.BM` | `STATUS_render` |
| 11 | 319 | `GUI/LAYERS.BM` | `LAYER_PANEL_handle_click%` |
| 12 | 280 | `GUI/STROKE-SEL.BM` | `STROKE_SEL_apply` |
| 13 | 274 | `OUTPUT/SCREEN.BM` | `RENDER_tool_previews` |
| 14 | 264 | `TOOLS/WORKSPACE-UNDO.BM` | `WORKSPACE_UNDO_undo` |
| 15 | 264 | `TOOLS/DRW.BM` | `DRW_load_from_png` |
| 16 | 259 | `GUI/ORGANIZER.BM` | `ORGANIZER_render` |
| 17 | 257 | `CFG/CONFIG.BM` | `CFG_validate` |
| 18 | 252 | `CFG/CONFIG.BM` | `CONFIG_load` |
| 19 | 251 | `TOOLS/MARQUEE.BM` | `MAGIC_WAND_select_with_mode` |
| 20 | 251 | `GUI/MENUBAR.BM` | `MENUBAR_register_all` |
