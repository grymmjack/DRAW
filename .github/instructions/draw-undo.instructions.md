---
applyTo: "**/UNDO*.B*, **/WORKSPACE-UNDO*.B*, **/MOUSE.BM, **/KEYBOARD.BM"
---

# DRAW — Undo System

DRAW has **two independent undo systems** sharing a single Ctrl+Z/Y keybinding via timestamp-based routing.

---

## Pixel Undo (`TOOLS/UNDO.BI` / `UNDO.BM`)

Stores per-layer `_COPYIMAGE` snapshots.

**Types**: `UNDO_STATE` (`img&`, `layer_index%`, `timestamp#`), `UNDO_SYSTEM` (`current%`, `count%`, `max_states%` = 100)  
**Storage**: `DIM SHARED UNDO_STATES(100) AS UNDO_STATE`

| Function | Behavior |
|---|---|
| `UNDO_init` | Resets all states, saves initial blank canvas as state 0 |
| `UNDO_save_state` | Truncates redo branch, shifts oldest if at max, saves `_COPYIMAGE` of `LAYER_current_image&` with `TIMER` timestamp, sets `CANVAS_DIRTY% = TRUE` |
| `UNDO_undo` | Scans backward for same-layer state, restores via `_PUTIMAGE`. If no previous state, clears layer to transparent. Calls `BLEND_invalidate_cache`. |
| `UNDO_redo` | Moves forward one state, restores via `_PUTIMAGE` |
| `UNDO_get_last_timestamp#` | Returns TIMER value of current state |

**Double-save guard**: `UNDO_saved_this_frame%` — reset to `FALSE` every frame in `LOOP_start`. Always check before saving:

```qb64
IF NOT UNDO_saved_this_frame% THEN
    UNDO_save_state
    UNDO_saved_this_frame% = TRUE
END IF
```

---

## Workspace Undo (`TOOLS/WORKSPACE-UNDO.BI` / `WORKSPACE-UNDO.BM`)

Stores structural layer operations. Does NOT store pixel data.

**Action types**: `WUNDO_TYPE_LAYER_ADD=1`, `DELETE=2`, `RENAME=3`, `REORDER=4`, `MERGE=5`, `MERGE_VISIBLE=6`

**Guards**:
- `WORKSPACE_UNDO_READY%` — prevents saves during init
- `WORKSPACE_UNDO_IN_PROGRESS%` — prevents undo/redo from creating new states

**Selection rule**:
- Selection mutations must use a staged pre-change snapshot plus a post-change commit. Do NOT push a workspace undo state before the mutation is known to have changed MARQUEE state, or no-op clicks will consume undo and incorrectly truncate redo.

**Callers** (all in `GUI/LAYERS.BM`): `LAYERS_new%`, `LAYERS_duplicate`, `LAYERS_delete`, `LAYERS_rename`, `LAYERS_move_up`, `LAYERS_move_down`, `LAYERS_merge_down`, `LAYERS_merge_visible`

---

## Intelligent Ctrl+Z / Ctrl+Y Routing

```qb64
pixelUndoTs# = UNDO_get_last_timestamp#
workspaceUndoTs# = WORKSPACE_UNDO_get_last_timestamp#

IF workspaceUndoTs# > pixelUndoTs# AND WORKSPACE_UNDO_can_undo% THEN
    WORKSPACE_UNDO_undo      ' Layer op was more recent
ELSEIF pixelUndoTs# > 0 THEN
    UNDO_undo                ' Pixel change was more recent
END IF
```

---

## Where Undo States Are Created

**Mouse release handlers** (`INPUT/MOUSE.BM`):
- `MOUSE_release_brush`, `MOUSE_release_dot`, `MOUSE_release_spray` — on button up
- `MOUSE_release_line`, `MOUSE_release_rect`, `MOUSE_release_ellip` — after shape commit
- Fill tool — after flood fill completes
- Right-click shift-line — after connecting line drawn

**Selection callers**:
- Use `WORKSPACE_UNDO_stage_selection` before selection mutation and `WORKSPACE_UNDO_commit_selection` after it.
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

---

## Bug Patterns (Lessons Learned)

| Bug | Root Cause | Fix |
|---|---|---|
| Ctrl+Z does nothing for 2 presses after menu action | `TOOLBAR_CLICKED%` reset before `MOUSE_should_skip_tool_actions%`, allowing phantom undo states on release | Move reset inside `MOUSE_should_skip_tool_actions%` |
| Undo broken after Palette Random | `_DEST _CONSOLE` debug prints in `PALETTE_LOADER_load_by_index%` corrupted `_DEST` | Remove all `_DEST _CONSOLE`; use `_LOGINFO` |
| Double undo states per brush stroke | Missing `UNDO_saved_this_frame%` check | Always check flag before `UNDO_save_state` |
| Dead undo step after no-op selection click | Selection history pushed before mutation, even when MARQUEE state did not change | Stage selection first, then commit only if the post-mutation state differs |
| First pixel edit on a merged layer will not undo | New merged layer created while workspace undo auto-save is suppressed, so no pixel baseline exists for that layer | Manually call `UNDO_save_layer_state` after the merge and restore `PIXEL_UNDO_LAST_TIMESTAMP#` |
| Transform commit can create duplicate save points | Transform saved pixel undo without the standard frame guard | Wrap `UNDO_save_state` in the usual `UNDO_saved_this_frame%` guard |

## Selection Undo Pattern

Use this for any selection mutation that might be a no-op:

```qb64
WORKSPACE_UNDO_stage_selection
' ... mutate MARQUEE / selection mask ...
WORKSPACE_UNDO_commit_selection
```

Why:
- Preserves redo when the attempted selection action changes nothing
- Avoids dead Ctrl+Z steps after clicks inside the same selection
- Keeps deselect paths undoable without forcing every caller to pre-compute whether the mutation will change the mask

## Merged Layer Pixel Baseline Rule

If a command creates a brand-new raster layer while `WORKSPACE_UNDO_IN_PROGRESS% = TRUE`, the normal `LAYERS_new%` pixel baseline save is suppressed on purpose. If the new layer will later receive pixel edits, the command must manually create a pixel baseline after the structural operation completes:

```qb64
DIM savedPixelTs AS DOUBLE
savedPixelTs# = PIXEL_UNDO_LAST_TIMESTAMP#
UNDO_save_layer_state newLayerIndex%
PIXEL_UNDO_LAST_TIMESTAMP# = savedPixelTs#
```

Why:
- The first later pixel edit on that new layer needs a prior same-layer snapshot
- Restoring `PIXEL_UNDO_LAST_TIMESTAMP#` ensures Ctrl+Z still routes to workspace undo for undoing the merge itself

---

## `TOOLBAR_CLICKED%` Lifecycle (Critical for Undo Correctness)

1. **Set TRUE** when any GUI element is clicked (toolbar, organizer, palette, menubar)
2. **Checked** by `MOUSE_should_skip_tool_actions%` — when TRUE, consumes `OLD_B*` so `MOUSE_dispatch_tool_release` never fires
3. **Reset FALSE** inside `MOUSE_should_skip_tool_actions%` when all buttons are released

**CRITICAL**: Reset MUST happen inside `MOUSE_should_skip_tool_actions%`. If it resets earlier, the release-frame sees stale `OLD_B1%=TRUE` with the flag cleared — causing `MOUSE_dispatch_tool_release` to fire and create a phantom `UNDO_save_state`. Each GUI click-release creates 2 phantom undo states with identical data, making Ctrl+Z appear to "do nothing".
