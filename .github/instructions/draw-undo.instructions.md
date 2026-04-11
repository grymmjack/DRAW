---
applyTo: "**/HISTORY*.B*, **/MOUSE.BM, **/KEYBOARD.BM"
---

# DRAW — History / Undo System

DRAW uses a **unified history system** (`TOOLS/HISTORY.BI` / `HISTORY.BM`) for all Ctrl+Z/Y undo/redo. The old separate `UNDO` (pixel snapshots) and `WORKSPACE_UNDO` (structural layer ops) systems have been removed.

---

## Unified History (`TOOLS/HISTORY.BI` / `HISTORY.BM`)

`HISTORY` records replayable operations with stable `historyId&` layer identities, typed record kinds, optional payloads, and export metadata. Up to `HISTORY_MAX_RECORDS = 1024` entries.

### Record Kinds

| Constant | Value | Use |
|---|---|---|
| `HISTORY_KIND_BRUSH` | 9 | Brush, dot, spray, eraser strokes |
| `HISTORY_KIND_LINE` | 5 | Line tool |
| `HISTORY_KIND_RECT` | 6 | Rectangle tool |
| `HISTORY_KIND_ELLIPSE` | 7 | Ellipse tool |
| `HISTORY_KIND_POLYLINE` | 12 | Polygon tool |
| `HISTORY_KIND_FILL` | 8 | Flood fill |
| `HISTORY_KIND_TRANSFORM` | 10 | Transform, move, image adjustments, flip/scale/rotate |
| `HISTORY_KIND_SELECTION_CHANGE` | 4 | Selection/marquee/wand mutations |
| `HISTORY_KIND_LAYER_ADD` | 1 | Layer created |
| `HISTORY_KIND_LAYER_DELETE` | 2 | Layer deleted |
| `HISTORY_KIND_LAYER_REORDER` | 3 | Layer z-order changed |
| `HISTORY_KIND_LAYER_RENAME` | 11 | Layer renamed |
| `HISTORY_KIND_LAYER_MERGE` | 13 | Merge down |
| `HISTORY_KIND_LAYER_MERGE_VISIBLE` | 14 | Merge all visible |
| `HISTORY_KIND_RASTERIZE` | 15 | Text layer rasterization |
| `HISTORY_KIND_GROUP_REPARENT` | 16 | Layer moved into/out of group |
| `HISTORY_KIND_MERGE_GROUP` | 17 | All group children merged into one layer |

### Key Types

**`HISTORY_RECORD`**: `kind%`, `exportKind%`, `sequence&`, `primaryLayerId&`, `secondaryLayerId&`, `slotIndex%`, `oldZIndex%`, `newZIndex%`, `img&` (before-image), `img2&`, `toolId%`, `flags&`, coordinate fields, color fields, `payloadOffset&`, `payloadLength&`, `label$`

**`HISTORY_SYSTEM`**: `current%`, `count%`, `maxRecords%`, `nextSequence&`, `recording%`

### Key Functions

| Function | Behavior |
|---|---|
| `HISTORY_init` | Initializes the history system |
| `HISTORY_clear` | Resets all history records, frees images |
| `HISTORY_can_undo%` / `HISTORY_can_redo%` | Check availability |
| `HISTORY_undo` | Undo the current record |
| `HISTORY_redo` | Redo the next record |
| `HISTORY_record_brush` | Record brush/dot/spray/eraser stroke (before-image) |
| `HISTORY_record_line` | Record line with endpoints |
| `HISTORY_record_rect` | Record rectangle with bounds |
| `HISTORY_record_ellipse` | Record ellipse with bounds |
| `HISTORY_record_polyline` | Record polygon with point arrays |
| `HISTORY_record_fill` | Record flood fill with seed point |
| `HISTORY_record_transform` | Record transform/move/image adjustment |
| `HISTORY_record_layer_add/delete/reorder/rename` | Structural layer ops |
| `HISTORY_record_layer_merge` | Merge down |
| `HISTORY_record_layer_merge_visible` | Merge visible (backs up all source layers) |
| `HISTORY_record_group_reparent` | Record group parent change |
| `HISTORY_record_merge_group` | Record group merge |
| `HISTORY_selection_stage` | Snapshot selection state before mutation |
| `HISTORY_selection_commit` | Save selection change if state differs from snapshot |
| `HISTORY_begin_group` / `HISTORY_end_group` | Group multiple records as one undo step |

### Double-Save Guard

`HISTORY_saved_this_frame%` — reset to `FALSE` every frame in `LOOP_start`. Always check before saving:

```qb64
IF NOT HISTORY_saved_this_frame% THEN
    HISTORY_record_brush layerId&, slotIdx%, drawColor~&, flags&, beforeImg&, "Brush"
    HISTORY_saved_this_frame% = TRUE
END IF
```

---

## Ctrl+Z / Ctrl+Y Routing (`INPUT/KEYBOARD.BM`)

Routing is direct — no multi-system timestamp comparison:

```qb64
IF HISTORY_can_undo% THEN
    HISTORY_undo
END IF
' ...
IF HISTORY_can_redo% THEN
    HISTORY_redo
END IF
```

Special case: Active polygon in-progress is cancelled instead of undoing.

---

## Where History States Are Created

**Mouse release handlers** (`INPUT/MOUSE.BM`):
- Brush, dot, spray, eraser — on button up via `HISTORY_record_brush`
- Line, rect, ellipse — after shape commit via `HISTORY_record_line/rect/ellipse`
- Fill — after flood fill completes via `HISTORY_record_fill`
- Polygon — on close/commit via `HISTORY_record_polyline`

**Selection callers**:
- Use `HISTORY_selection_stage` before selection mutation and `HISTORY_selection_commit` after it.
- This pattern applies to wand select, marquee finish/resize/move, polygon close, Select All, Invert, Deselect, and click-outside-selection deselect paths.

**Tool implementations**:
- `TOOLS/BRUSH.BM`: `PAINT_clear_no_prompt` (Backspace key)
- `TOOLS/MOVE.BM`: Before move operations begin
- `TOOLS/TEXT.BM`: `TEXT_apply` — stamps text to canvas
- `TOOLS/MARQUEE.BM`: After marquee region actions
- `TOOLS/SELECTION.BM`: Before clear/invert selection
- `TOOLS/IMAGE-IMPORT.BM`: Before import operations

**Command dispatcher** (`GUI/COMMAND.BM`):
- Copy to new layer, fill FG/BG, flip H/V, scale, rotate
- Image adjustments, stroke selection

**Layer operations** (`GUI/LAYERS.BM`):
- `LAYERS_new%`, `LAYERS_duplicate`, `LAYERS_delete`, `LAYERS_rename`
- `LAYERS_move_up`, `LAYERS_move_down`
- `LAYERS_merge_down`, `LAYERS_merge_visible`
- `LAYERS_new_group%`, `LAYERS_group_from_selection%`, `LAYERS_ungroup`, `LAYERS_merge_group`
- `LAYERS_move_into_group`, `LAYERS_move_out_of_group` (reparent operations)

---

## Selection Undo Pattern

Use this for any selection mutation that might be a no-op:

```qb64
HISTORY_selection_stage
' ... mutate MARQUEE / selection mask ...
HISTORY_selection_commit
```

Why:
- Preserves redo when the attempted selection action changes nothing
- Avoids dead Ctrl+Z steps after clicks inside the same selection
- Keeps deselect paths undoable without forcing every caller to pre-compute whether the mutation will change the mask

---

## Bug Patterns (Lessons Learned)

| Bug | Root Cause | Fix |
|---|---|---|
| Ctrl+Z does nothing for 2 presses after menu action | `UI_CHROME_CLICKED%` reset before `MOUSE_should_skip_tool_actions%`, allowing phantom history states on release | Move reset inside `MOUSE_should_skip_tool_actions%` |
| Undo broken after Palette Random | `_DEST _CONSOLE` debug prints corrupted `_DEST` | Remove all `_DEST _CONSOLE`; use `_LOGINFO` |
| Double history states per brush stroke | Missing `HISTORY_saved_this_frame%` check | Always check flag before recording |
| Dead undo step after no-op selection click | Selection history pushed before mutation, even when state did not change | Stage selection first, then commit only if the post-mutation state differs |

---

## `UI_CHROME_CLICKED%` Lifecycle (Critical for Undo Correctness)

1. **Set TRUE** when any GUI element is clicked (toolbar, organizer, palette, menubar)
2. **Checked** by `MOUSE_should_skip_tool_actions%` — when TRUE, consumes `OLD_B*` so `MOUSE_dispatch_tool_release` never fires
3. **Reset FALSE** inside `MOUSE_should_skip_tool_actions%` when all buttons are released

**CRITICAL**: Reset MUST happen inside `MOUSE_should_skip_tool_actions%`. If it resets earlier, the release-frame sees stale `OLD_B1%=TRUE` with the flag cleared — causing `MOUSE_dispatch_tool_release` to fire and create a phantom history record.
