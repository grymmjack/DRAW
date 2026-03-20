---
description: "Fix a bug in DRAW's text tool using the state machine diagram, source code, and QB64-PE MCP. Follows a structured workflow: diagnose → fix → verify → update diagram."
---

# Fix Text Tool Bug

When the user reports a text tool bug (e.g. "text cursor is wrong", "text bar doesn't update", "crash when typing"), execute these steps **in order**. Do not skip steps.

---

## Step 1 — Read the state machine

Read the text tool state machine diagram at `PLANS/diagrams/TEXT-TOOL-STATES.DOT` and the transition table at `/memories/session/text-state-transition-table.md` (if it exists). These define:

- **6 main states**: Inactive → Idle → Editing → Re-editing → Committed → Rasterized
- **Sub-state machines**: TEXT_BAR dropdowns, Cursor blink/navigation, Selection, Layer Pool lifecycle, History integration
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
| **Commands** | `GUI/COMMAND.BM` (actions 712, 713, 714) |
| **Rendering** | `OUTPUT/SCREEN.BM` (search for `TEXT_render_preview`, `TEXT_BAR`) |
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

1. Search the file for the bug description matching what was just fixed (look for `- [ ]` items under `## TEXT TOOL`).
2. Change the checkbox from `- [ ]` to `- [x]` on the matching line **and** all its indented sub-lines (keep sub-lines as-is, just mark the top-level checkbox).
3. **Move the completed item to the bottom of the file.** If there is already a `## COMPLETED` section at the bottom, move it there. If not, create one:
   ```markdown
   ## COMPLETED

   - [x] The bug description
     - sub-detail preserved as-is
   ```
4. Ensure incomplete `- [ ]` items stay in their original position — only move the completed item and its indented children.

---

## Step 7 — Update the state machine diagram

After the user confirms the bug is fixed, update `PLANS/diagrams/TEXT-TOOL-STATES.DOT` **if the fix changed any state transitions, guards, or added new behavior**:

- **New transitions**: Add edges with appropriate colors (green=activate, red=deactivate, blue=re-edit, yellow=commit, purple=rasterize)
- **New guards**: Update node labels to document new invariants or bounds checks
- **Modified transitions**: Update edge labels to reflect changed behavior
- **New sub-states**: Add nodes to existing clusters or create new clusters if needed

Re-render the diagram:

```bash
dot -Tsvg PLANS/diagrams/TEXT-TOOL-STATES.DOT -o PLANS/diagrams/TEXT-TOOL-STATES.svg
dot -Tpng -Gdpi=150 PLANS/diagrams/TEXT-TOOL-STATES.DOT -o PLANS/diagrams/TEXT-TOOL-STATES.png
```

Verify both render without errors.

---

## Key state variables reference

| Variable | Type | Meaning |
|----------|------|---------|
| `TEXT.ACTIVE` | INTEGER | TRUE when actively editing text |
| `TEXT.editingTextLayer%` | INTEGER | Layer index being edited (1–64, 0 = none) |
| `TEXT.CURSOR_X/Y` | INTEGER | Visual cursor position (canvas coords) |
| `TEXT.CURSOR_BLINK` | INTEGER | 0 or 1, toggles every 0.5s |
| `TEXT.selStart%/selEnd%` | INTEGER | Selection range (-1 = none) |
| `TEXT.selActive%` | INTEGER | TRUE when selection is active |
| `TEXT_BAR.visible%` | INTEGER | TRUE when bar should render |
| `TEXT_BAR.editingLayerIdx%` | INTEGER | Layer index wired to bar (0 = none) |
| `TEXT_BAR.selectedFontIdx%` | INTEGER | Current font in FONT_LIST |
| `TEXT_BAR.selectedSize%` | INTEGER | Current font size in pixels |
| `TEXT_BAR.fontDropdownOpen%` | INTEGER | Font dropdown state |
| `TEXT_BAR.sizeDropdownOpen%` | INTEGER | Size dropdown state |
| `TEXT_BAR.boldActive%` | INTEGER | Bold toggle for new chars |
| `TEXT_BAR.italicActive%` | INTEGER | Italic toggle for new chars |
| `TEXT_BAR.underlineActive%` | INTEGER | Underline toggle |
| `TEXT_BAR.strikeActive%` | INTEGER | Strikethrough toggle |
| `TEXT_LAYER_DATA(idx%).charCount` | INTEGER | Characters in pool slot |
| `TEXT_LAYER_DATA(idx%).cursorPos` | INTEGER | Cursor position in char array |
| `TEXT_LAYER_DATA(idx%).lineCount` | INTEGER | Number of lines |
| `TEXT_LAYER_DATA(idx%).dirty` | INTEGER | TRUE = needs re-render |
| `CURRENT_TOOL%` | INTEGER | Must be `TOOL_TEXT` for text ops |
| `LAYERS(idx%).layerType%` | INTEGER | `LAYER_TYPE_TEXT` or `LAYER_TYPE_IMAGE` |
| `LAYERS(idx%).textDataIdx%` | INTEGER | Pool slot index (0 = none) |

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
