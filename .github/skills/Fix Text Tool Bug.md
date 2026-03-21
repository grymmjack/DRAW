---
description: "Fix a bug in DRAW's text tool using the state machine diagram, source code, and QB64-PE MCP. Follows a structured workflow: diagnose → fix → verify → update diagram."
---

# Fix Text Tool Bug

When the user reports a text tool bug (e.g. "text cursor is wrong", "text bar doesn't update", "crash when typing"), execute these steps **in order**. Do not skip steps.

---

## Step 1 — Read the state machine

Read the text tool state machine diagram at `PLANS/diagrams/TOOLS/TEXT-TOOL-STATES.DOT` and the transition table at `/memories/session/text-state-transition-table.md` (if it exists). These define:

- **6 main states**: Inactive → Idle → Editing → Re-editing → Committed → Rasterized
- **6 sub-state machines**: TEXT_BAR dropdowns, Cursor blink/navigation, Selection, Rich Clipboard, Layer Pool lifecycle, History integration
- **All transitions**: with triggers, handlers, guards, and side effects

Identify **which state and transition** the bug likely occurs in based on the user's description.

---

## Step 2 — Gather source context

Read the relevant source files based on the suspected state/transition:

| State/Area | Files to read |
|------------|---------------|
| **All text states** | `TOOLS/TEXT.BI`, `TOOLS/TEXT.BM` |
| **Text layer data** | `GUI/TEXT-LAYER.BI`, `GUI/TEXT-LAYER.BM` |
| **TEXT_BAR UI** | `GUI/TEXT-BAR.BI`, `GUI/TEXT-BAR.BM` |
| **Keyboard input** | `INPUT/KEYBOARD.BM` (search for `KEYBOARD_handle_text_tool`) |
| **Mouse input** | `INPUT/MOUSE.BM` (search for `MOUSE_tool_text`, `TEXT_BAR`) |
| **Commands** | `GUI/COMMAND.BM` (see action ID table below) |
| **Rendering** | `OUTPUT/SCREEN.BM` (search for `TEXT_render_preview`, `TEXT_BAR_render`) |
| **Layer management** | `GUI/LAYERS.BM` (search for `LAYER_TYPE_TEXT`, `textDataIdx`) |
| **History** | `TOOLS/HISTORY.BI`, `TOOLS/HISTORY.BM` |
| **Font system** | `GUI/FONT-LIST.BI`, `GUI/FONT-LIST.BM` |

Use `mcp_qb64pe_analyze_qb64pe_execution_mode` or `mcp_qb64pe_analyze_qb64pe_execution_mode_file` to check execution flow if the bug involves control flow or mode switching.

---

## Step 3 — Check QB64-PE gotchas

Before diagnosing, verify the code doesn't violate these critical QB64-PE rules:

1. **`AND` is bitwise, not short-circuit!** `IF idx% > 0 AND arr(idx%) = val` crashes if idx%=0. Must use nested IF.
2. **Image handles valid only when `< -1`**. Always `IF handle& < -1 THEN _FREEIMAGE handle&`.
3. **Save/restore `_DEST`/`_SOURCE`** around all drawing operations.
4. **STATIC pressed% guards** required for all `_KEYDOWN()` Ctrl/Alt hotkeys (Gotcha #20).
5. **Layer indices are 1–64**, NOT 1–`LAYER_COUNT%`. Sparse allocation means valid layers can exist at any slot.
6. **`_UNSIGNED LONG` for colors** — using `INTEGER (%)` truncates `_RGB32` values.
7. **NEVER `_DEST _CONSOLE`** — use `_LOGINFO`, `_LOGWARN`, `_LOGERROR` for debug output.
8. **`HISTORY_saved_this_frame%`** must be checked before recording history to prevent double-saves.
9. **Render path awareness** — `SCREEN_render` has 4 fast paths (GUI-ONLY, STATUS-ONLY, dirty-rect, full render). Any text tool overlay drawn after `SkipToPointer:` must ensure ALL fast paths reach it or gate their partial-present `EXIT SUB`. See `draw-rendering.instructions.md`.
10. **`MOUSE.X/Y%` vs `MOUSE.UNSNAPPED_X/Y%`** — Grid-snapped coords (`MOUSE.X/Y%`) cause shimmer in hit-tests when grid snap is active. Use `MOUSE.UNSNAPPED_X/Y%` for text layer boundary hit-testing.

---

## Step 4 — Diagnose and fix

Trace the bug through the state machine:

1. **Identify the source state** — what state is the text tool in when the bug occurs?
2. **Identify the trigger** — what user action (key, click, menu) causes the bug?
3. **Trace the transition** — follow the handler function that processes this trigger. Is the side effect correct? Are all guards in place?
4. **Check adjacent transitions** — could a different transition have left the system in a bad state before this one fires?
5. **Verify state cleanup** — when exiting a state, are ALL relevant variables reset? (`TEXT.ACTIVE`, `TEXT.editingTextLayer%`, `TEXT_BAR.editingLayerIdx%`, `TEXT.CURSOR_X/Y`, selection state, etc.)

Apply the fix using the code edit tools. Prioritize:
- **CRASH fixes** (bounds, null handles) first
- **CORRUPTION fixes** (orphan state, data loss) second
- **VISUAL fixes** (cursor position, rendering) third

---

## Step 5 — Compile and verify

Compile the project:

```bash
cd /home/grymmjack/git/DRAW && /home/grymmjack/git/qb64pe/qb64pe -w -x DRAW.BAS -o DRAW.run 2>&1 | tail -20
```

Fix any compilation errors. Only pre-existing warnings are acceptable.

Tell the user to test the fix and **wait for confirmation** before proceeding to Step 6.

---

## Step 6 — Mark bug as fixed in BUGS.md

After the user confirms the bug is fixed, update `PLANS/BUGS.md`:

1. Search the file for the bug description matching what was just fixed (look for `- [ ]` items under `### TEXT TOOL` in `## TO DO`).
2. Change the checkbox from `- [ ]` to `- [x]` on the matching line. Keep all its indented sub-lines as-is.
3. **Move the completed item** (and all indented children) from `## TO DO` → `### TEXT TOOL` to the `## COMPLETED` → `### TEXT TOOL` section at the bottom of the file.
4. Ensure incomplete `- [ ]` items stay in their original position — only move the completed item and its indented children.

**BUGS.md actual structure:**
```markdown
# BUGS

## TO DO

### TEXT TOOL
- [ ] uncompleted bug ...
  - sub-detail

---

## COMPLETED

### TEXT TOOL
- [x] completed bug ...
  - sub-detail preserved
```

---

## Step 7 — Update the state machine diagram

After the user confirms the bug is fixed, update `PLANS/diagrams/TOOLS/TEXT-TOOL-STATES.DOT` **if the fix changed any state transitions, guards, or added new behavior**:

- **New transitions**: Add edges with appropriate colors (green=activate, red=deactivate, blue=re-edit, yellow=commit, purple=rasterize)
- **New guards**: Update node labels to document new invariants or bounds checks
- **Modified transitions**: Update edge labels to reflect changed behavior
- **New sub-states**: Add nodes to existing clusters or create new clusters if needed

Re-render the diagram:

```bash
dot -Tsvg PLANS/diagrams/TOOLS/TEXT-TOOL-STATES.DOT -o PLANS/diagrams/TOOLS/TEXT-TOOL-STATES.svg
dot -Tpng -Gdpi=150 PLANS/diagrams/TOOLS/TEXT-TOOL-STATES.DOT -o PLANS/diagrams/TOOLS/TEXT-TOOL-STATES.png
```

Verify both render without errors.

---

## Command action IDs

| Action ID | Command | Keyboard | Handler |
|-----------|---------|----------|---------|
| **114** | Text Tool | T | `KEYBOARD_tools "t"` |
| **115** | Text Tool (Tiny5) | Shift+T | Sets `TEXT.USE_TINY5`, switches tool |
| **116** | Text Tool (Custom Font) | Ctrl+T | Sets `TEXT.USE_CUSTOM`, switches tool |
| **712** | New Text Layer | — | Creates new text layer at canvas center |
| **713** | Rasterize Text Layer | — | `TEXT_LAYER_rasterize` + `HISTORY_record_brush` |
| **714** | Rasterize All Text Layers | — | Iterates all LAYER_TYPE_TEXT layers |

All registered in `CMD_init` (`GUI/COMMAND.BM`), handled in `CMD_execute_action`.

---

## Key functions reference

| Function | File | Purpose |
|----------|------|---------|
| `TEXT_start(x%, y%)` | `TOOLS/TEXT.BM` | Start new text layer at canvas click pos |
| `TEXT_re_edit(li%)` | `TOOLS/TEXT.BM` | Re-enter editing on existing text layer |
| `TEXT_commit()` | `TOOLS/TEXT.BM` | Exit editing, keep layer as LAYER_TYPE_TEXT |
| `TEXT_cancel()` | `TOOLS/TEXT.BM` | Exit editing, delete if empty, commit if not |
| `TEXT_reset()` | `TOOLS/TEXT.BM` | Full state teardown (tool switch cleanup) |
| `TEXT_apply()` | `TOOLS/TEXT.BM` | Rasterize to pixels + record history |
| `TEXT_add_char(ch$)` | `TOOLS/TEXT.BM` | Insert character at cursor (with overflow check) |
| `TEXT_render_preview()` | `TOOLS/TEXT.BM` | Draw text preview overlay on canvas dest |
| `TEXT_sync_bar_to_cursor()` | `TOOLS/TEXT.BM` | Update TEXT_BAR to match char attrs at cursor |
| `TEXT_clear_selection()` | `TOOLS/TEXT.BM` | Reset selection range to -1 |
| `TEXT_delete_selection()` | `TOOLS/TEXT.BM` | Delete selected characters |
| `KEYBOARD_handle_text_tool%()` | `INPUT/KEYBOARD.BM` | Process keys during editing (returns TRUE if handled) |
| `MOUSE_tool_text()` | `INPUT/MOUSE.BM` | Mouse click/drag handling for text tool |
| `TEXT_LAYER_alloc%()` | `GUI/TEXT-LAYER.BM` | Allocate pool slot (returns 1-based index) |
| `TEXT_LAYER_free(idx%)` | `GUI/TEXT-LAYER.BM` | Free pool slot |
| `TEXT_LAYER_render(idx%)` | `GUI/TEXT-LAYER.BM` | Render rich text to layer image buffer |
| `TEXT_LAYER_rasterize(li%)` | `GUI/TEXT-LAYER.BM` | Convert text layer to image (irreversible) |
| `TEXT_LAYER_add_char()` | `GUI/TEXT-LAYER.BM` | Insert char into pool slot data |
| `TEXT_LAYER_delete_char()` | `GUI/TEXT-LAYER.BM` | Remove char from pool slot data |
| `TEXT_LAYER_newline()` | `GUI/TEXT-LAYER.BM` | Insert line break |
| `TEXT_LAYER_get_char_at_pos%()` | `GUI/TEXT-LAYER.BM` | Hit-test: canvas coords → char index |
| `TEXT_LAYER_get_cursor_at_pos%()` | `GUI/TEXT-LAYER.BM` | Hit-test: canvas coords → cursor position |
| `TEXT_LAYER_get_char_x%()` | `GUI/TEXT-LAYER.BM` | Char index → canvas X position |
| `TEXT_LAYER_get_line_y%()` | `GUI/TEXT-LAYER.BM` | Line index → canvas Y position |
| `TEXT_LAYER_prev_word_pos%()` | `GUI/TEXT-LAYER.BM` | Word boundary navigation (backward) |
| `TEXT_LAYER_next_word_pos%()` | `GUI/TEXT-LAYER.BM` | Word boundary navigation (forward) |
| `TEXT_BAR_render()` | `GUI/TEXT-BAR.BM` | Render the formatting bar |
| `TEXT_BAR_apply_style_to_selection()` | `GUI/TEXT-BAR.BM` | Apply B/I/U/S to selected chars |

---

## Key state variables reference

### TEXT_OBJ (TOOLS/TEXT.BI)

| Variable | Type | Meaning |
|----------|------|---------|
| `TEXT.ACTIVE` | INTEGER | TRUE when actively editing text |
| `TEXT.editingTextLayer` | INTEGER | Layer index being edited (1–64, 0 = none) |
| `TEXT.START_X / START_Y` | INTEGER | Initial click position (left margin, first line) |
| `TEXT.CURSOR_X / CURSOR_Y` | INTEGER | Visual cursor position (canvas coords) |
| `TEXT.CURSOR_BLINK` | INTEGER | 0 or 1, toggles every 0.5s |
| `TEXT.BLINK_TIMER` | SINGLE | Timer for cursor blink cycle |
| `TEXT.TEXT_SIZE` | INTEGER | Text size multiplier (1 = default) |
| `TEXT.MAX_LINES` | INTEGER | Maximum number of lines allowed |
| `TEXT.LINE_COUNT` | INTEGER | Current number of lines |
| `TEXT.selStart / selEnd` | INTEGER | Selection range (-1 = no selection) |
| `TEXT.selActive` | INTEGER | TRUE when text selection is active |
| `TEXT.USE_TINY5` | INTEGER | Whether to use Tiny5 font (vs VGA default) |
| `TEXT.FONT_HANDLE` | LONG | Handle to loaded Tiny5 font |
| `TEXT.USE_CUSTOM` | INTEGER | Whether to use custom font loaded from disk |
| `TEXT.CUSTOM_FONT_HANDLE` | LONG | Handle to custom font |
| `TEXT.CUSTOM_FONT_PATH` | STRING*260 | Path of active custom font |
| `TEXT.CUSTOM_FONT_SIZE` | INTEGER | Loaded custom font size |
| `TEXT.CHAR_WIDTH` | INTEGER | Character width (5 for Tiny5, 8 for VGA) |
| `TEXT.LINE_HEIGHT` | INTEGER | Line height (8 for Tiny5, 13 for VGA) |
| `TEXT.OVERFLOW_FLASH` | INTEGER | Countdown frames for overflow visual feedback |

### Preview cache (TOOLS/TEXT.BI)

| Variable | Type | Meaning |
|----------|------|---------|
| `TEXT_PREVIEW_CACHE` | LONG | Cached preview image handle |
| `TEXT_PREVIEW_CACHE_W / _H` | INTEGER | Cache dimensions |

### Rich clipboard (TOOLS/TEXT.BI)

| Variable | Type | Meaning |
|----------|------|---------|
| `TEXT_CLIP_COUNT` | INTEGER | Number of chars in clipboard |
| `TEXT_CLIP_PLAIN` | STRING | Plain text mirror (detects external clipboard changes) |
| `TEXT_CLIP_CHAR()` | STRING*1 | Per-char character data |
| `TEXT_CLIP_FG() / _BG()` | _UNSIGNED LONG | Per-char foreground/background colors |
| `TEXT_CLIP_FONT_IDX() / _FONT_SIZE()` | INTEGER | Per-char font and size |
| `TEXT_CLIP_BOLD() / _ITALIC()` | INTEGER | Per-char bold/italic flags |
| `TEXT_CLIP_UNDERLINE() / _STRIKE()` | INTEGER | Per-char underline/strikethrough flags |
| `TEXT_CLIP_KERN() / _BASELINE()` | INTEGER | Per-char kerning and baseline offsets |

### TEXT_BAR (GUI/TEXT-BAR.BI)

| Variable | Type | Meaning |
|----------|------|---------|
| `TEXT_BAR.visible` | INTEGER | TRUE when bar should render |
| `TEXT_BAR.editingLayerIdx` | INTEGER | Layer index wired to bar (0 = none) |
| `TEXT_BAR.selectedFontIdx` | INTEGER | Current font in FONT_LIST |
| `TEXT_BAR.selectedSize` | INTEGER | Current font size in pixels |
| `TEXT_BAR.fontDropdownOpen` | INTEGER | Font dropdown state |
| `TEXT_BAR.sizeDropdownOpen` | INTEGER | Size dropdown state |
| `TEXT_BAR.boldActive` | INTEGER | Bold toggle for new chars |
| `TEXT_BAR.italicActive` | INTEGER | Italic toggle for new chars |
| `TEXT_BAR.underlineActive` | INTEGER | Underline toggle |
| `TEXT_BAR.strikeActive` | INTEGER | Strikethrough toggle |

### TEXT_LAYER_DATA pool (GUI/TEXT-LAYER.BI)

| Variable | Type | Meaning |
|----------|------|---------|
| `TEXT_LAYER_DATA(idx%).used` | INTEGER | TRUE when slot is allocated |
| `TEXT_LAYER_DATA(idx%).charCount` | INTEGER | Characters in pool slot |
| `TEXT_LAYER_DATA(idx%).cursorPos` | INTEGER | Cursor position in char array |
| `TEXT_LAYER_DATA(idx%).lineCount` | INTEGER | Number of lines |
| `TEXT_LAYER_DATA(idx%).dirty` | INTEGER | TRUE = needs re-render |
| `TEXT_LAYER_DATA(idx%).fontIdx` | INTEGER | Default font index for the layer |
| `TEXT_LAYER_DATA(idx%).fontSize` | INTEGER | Default font size for the layer |
| `TEXT_LAYER_DATA(idx%).defaultLeading` | INTEGER | Line spacing override |
| `TEXT_LAYER_DATA(idx%).monospace` | INTEGER | Monospace mode flag |
| `TEXT_LAYER_DATA(idx%).startX / startY` | INTEGER | Canvas origin position |

### Layer integration

| Variable | Type | Meaning |
|----------|------|---------|
| `CURRENT_TOOL%` | INTEGER | Must be `TOOL_TEXT` for text ops |
| `LAYERS(idx%).layerType%` | INTEGER | `LAYER_TYPE_TEXT` or `LAYER_TYPE_IMAGE` |
| `LAYERS(idx%).textDataIdx%` | INTEGER | Pool slot index (0 = none) |

---

## State machine transition table

| # | From | To | Trigger | Handler | Guards / Side Effects |
|---|------|----|---------|---------|----------------------|
| 1 | S1 Inactive | S2 Idle | Toolbar click / T key | `TOOLBAR_click` · `KEYBOARD_tools` | Sets `CURRENT_TOOL% = TOOL_TEXT`, `TEXT_BAR.visible = TRUE` |
| 2 | S2 Idle | S1 Inactive | Switch to another tool | `TEXT_reset()` | Clears all TEXT state, hides TEXT_BAR |
| 3 | S2 Idle | S3 Editing | Canvas click (B1) | `MOUSE_tool_text` → `TEXT_start(x,y)` | Creates new LAYER_TYPE_TEXT, allocs pool slot |
| 4 | S2 Idle | S4 Re-editing | Click/dbl-click text layer | `MOUSE_tool_text` → `TEXT_re_edit(li%)` | Cursor at click pos, `TEXT_sync_bar_to_cursor` |
| 5 | S3 Editing | S5 Committed | ESC (with text) / Tool switch | `TEXT_cancel` → `TEXT_commit()` | Layer stays LAYER_TYPE_TEXT, no history entry |
| 6 | S3 Editing | S1 Inactive | ESC (empty layer) | `TEXT_cancel()` → `LAYERS_delete()` | Layer removed entirely |
| 7 | S3 Editing | S6 Rasterized | Menu action 713 | `TEXT_commit` → `TEXT_LAYER_rasterize()` | `HISTORY_record_brush`, irreversible |
| 8 | S3 Editing | S3 Editing | Click on active text | `MOUSE_tool_text` → `get_cursor_at_pos` | Moves cursor, no new layer |
| 9 | S4 Re-editing | S5 Committed | ESC / Tool switch | `TEXT_commit()` | Layer stays editable |
| 10 | S4 Re-editing | S6 Rasterized | Menu action 713/714 | `TEXT_LAYER_rasterize()` | Irreversible |
| 11 | S5 Committed | S4 Re-editing | Click/dbl-click text layer | `TEXT_re_edit(layer%)` | Cursor at click pos, `TEXT_sync_bar_to_cursor` |
| 12 | S5 Committed | S6 Rasterized | Menu action 713/714 | `CMD_execute_action(713/714)` | Irreversible |
| 13 | S3 Editing | S1 Inactive | `DRW_load_binary` | `TEXT_cancel` → `TEXT_reset()` | File load resets all state |
| 14 | S3 Editing | S1 Inactive | `LAYERS_delete(editingLayer)` | Forced cleanup | Resets TEXT.ACTIVE, editingTextLayer, TEXT_BAR.editingLayerIdx |
| 15 | S4 Re-editing | S1 Inactive | `LAYERS_delete(editingLayer)` | Forced cleanup | Same forced reset |

---

## DOT diagram color conventions

| Edge Color | Meaning |
|------------|---------|
| `#66cc66` (green) | Activate / Enter state |
| `#cc6666` (red dashed) | Deactivate / Exit state |
| `#ff6666` (bright red) | Forced cleanup (e.g. LAYERS_delete) |
| `#6699ff` (blue) | Re-edit existing layer |
| `#cccc66` (yellow) | Commit (keep editable) |
| `#cc66cc` (purple) | Rasterize (permanent) |
| `#88aacc` (light blue) | Sub-state transitions |
| `#555555` (dark gray dotted) | Cross-links between clusters |

---

## Common bug patterns

| Pattern | Symptom | Likely Cause |
|---------|---------|--------------|
| **Orphan editing state** | TEXT_BAR stays visible after tool switch | `TEXT_reset()` not called, or `TEXT_BAR.visible` not cleared |
| **Ghost cursor** | Cursor blinks on wrong layer | `TEXT.editingTextLayer` points to deleted/wrong layer |
| **Double history save** | Two undo steps for one action | Missing `HISTORY_saved_this_frame%` guard |
| **Selection corruption** | Selection highlights wrong chars | `selStart/selEnd` not reset after edit operation shifts indices |
| **Pool leak** | "No free text slots" error | `TEXT_LAYER_free()` not called on layer delete/tool switch |
| **Clipboard paste crash** | Crash on Ctrl+V | External clipboard changed but `TEXT_CLIP_PLAIN$` still matches old content |
| **Render path bypass** | Overlays don't appear consistently | Fast path `EXIT SUB` before `SkipToPointer:` — needs partial-present gate |
| **Grid snap shimmer** | Hover outline flickers | Hit-test using `MOUSE.X/Y%` instead of `MOUSE.UNSNAPPED_X/Y%` |
| **Hotkey leaks during editing** | Global shortcuts fire while typing | Missing `TEXT.ACTIVE` guard in keyboard handler |
| **Font metrics drift** | Cursor position wrong after style change | `TEXT_sync_bar_to_cursor` or cursor X recompute not called after style toggle |
