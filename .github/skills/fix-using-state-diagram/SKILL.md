---
name: fix-using-state-diagram
description: "Fix a bug in DRAW using a state machine diagram to guide diagnosis. Structured workflow: select diagram → diagnose → fix → verify → update BUGS.md → update diagram if needed."
---

# Fix Using State Diagram

When the user reports a bug in any part of DRAW, use the matching state machine diagram to systematically diagnose and fix it. Follow these steps **in order**. Do not skip steps.

---

## Step 0 — Select the state machine diagram

Ask the user which area of DRAW the bug is in, then load the matching diagram from `PLANS/diagrams/`. If the user is unsure, use the table below to find the best match based on their description.

### Diagram Index

#### GLOBAL (system-wide state machines)

| Diagram | File | Covers |
|---------|------|--------|
| Mouse Input | `GLOBAL/MOUSE-STATES.DOT` | Mouse pipeline, click/drag/release, UI chrome handling |
| Keyboard Input | `GLOBAL/KEYBOARD-STATES.DOT` | Key dispatch, modifiers, tool shortcuts, hotkey guards |
| UI State | `GLOBAL/UI-STATES.DOT` | Frame lifecycle, idle detection, scene dirty, render gating |

#### GUI (panels, bars, and UI components)

| Diagram | File | Covers |
|---------|------|--------|
| Menubar | `GUI/MENUBAR-STATES.DOT` | Menu open/close, keyboard nav, cascading submenus |
| Layers Panel | `GUI/LAYERS-PANEL-STATES.DOT` | Layer list, selection, visibility, drag reorder in panel |
| Toolbox | `GUI/TOOLBOX-STATES.DOT` | Toolbar grid, tool switching, active indicator |
| Organizer | `GUI/ORGANIZER-STATES.DOT` | 4×3 icon widget, collapsible sections |
| Drawer | `GUI/DRAWER-STATES.DOT` | 30-slot brush/pattern panel, import/export, context menus |
| Tooltip | `GUI/TOOLTIP-STATES.DOT` | Hover delay, show/hide, positioning |
| Edit Bar | `GUI/EDITBAR-STATES.DOT` | Vertical icon bar, docking LEFT/RIGHT, F5 toggle |
| Status Bar | `GUI/STATUSBAR-STATES.DOT` | Coord display, tool info, mode indicators |
| Palette Strip | `GUI/PALETTE-STRIP-STATES.DOT` | Color swatches, FG/BG click, scroll |
| Command Palette | `GUI/COMMAND-PALETTE-STATES.DOT` | Fuzzy search, action dispatch, keyboard nav |
| Preview | `GUI/PREVIEW-STATES.DOT` | Floating preview, magnifier mode, pan/zoom, resize |
| Dialogs | `GUI/DIALOG-STATES.DOT` | Modal dialogs, native file pickers, deferred actions |
| Widgets | `GUI/WIDGETS-STATES.DOT` | Shared widget patterns (scrollbar, checkbox, slider) |

#### TOOLS (drawing and editing tools)

| Diagram | File | Covers |
|---------|------|--------|
| Text Tool | `TOOLS/TEXT-TOOL-STATES.DOT` | Text editing, TEXT_BAR, cursor, selection, rich clipboard |
| Dot | `TOOLS/DOT-STATES.DOT` | Single pixel placement |
| Brush | `TOOLS/BRUSH-STATES.DOT` | Freehand brush strokes, custom brushes |
| Spray | `TOOLS/SPRAY-STATES.DOT` | Spray can density/radius |
| Eraser | `TOOLS/ERASER-STATES.DOT` | Transparent pixel painting |
| Fill | `TOOLS/FILL-STATES.DOT` | Flood fill, tolerance, fill modes |
| Line | `TOOLS/LINE-STATES.DOT` | Two-point line drawing |
| Poly Line | `TOOLS/POLY-LINE-STATES.DOT` | Multi-segment polyline/polygon |
| Rectangle | `TOOLS/RECT-STATES.DOT` | Rectangle/square drawing |
| Ellipse | `TOOLS/ELLIPSE-STATES.DOT` | Ellipse/circle drawing |
| Marquee | `TOOLS/MARQUEE-STATES.DOT` | Selection rectangle, move, copy |
| Move | `TOOLS/MOVE-STATES.DOT` | Layer/selection movement, nudge |
| Pan | `TOOLS/PAN-STATES.DOT` | Canvas panning |
| Zoom | `TOOLS/ZOOM-STATES.DOT` | Canvas zoom in/out |
| Crop | `TOOLS/CROP-STATES.DOT` | Canvas crop to selection |
| Picker | `TOOLS/PICKER-STATES.DOT` | Color picker (eyedropper) |
| Save/Load | `TOOLS/SAVE-LOAD-STATES.DOT` | File save/load, DRW format, recent files |
| Cheatsheet | `TOOLS/CHEATSHEET-STATES.DOT` | Help overlay rendering |

#### UTILITIES (assistants and helpers)

| Diagram | File | Covers |
|---------|------|--------|
| Assistants | `UTILITIES/ASSISTANTS-STATES.DOT` | Drawing assistants overview |
| Crosshair | `UTILITIES/CROSSHAIR-STATES.DOT` | Crosshair guide lines |
| Picker Loupe | `UTILITIES/PICKER-LOUPE-STATES.DOT` | Magnified color picker view |
| Symmetry | `UTILITIES/SYMMETRY-STATES.DOT` | Symmetry modes (H/V/4-way), center control |
| Pattern/Tile | `UTILITIES/PATTERN-TILE-STATES.DOT` | Pattern and gradient fill modes, Fill-Adj |
| Grid | `UTILITIES/GRID-STATES.DOT` | Grid snap, display modes, cell fill |
| Brush Size | `UTILITIES/BRUSH-SIZE-STATES.DOT` | Brush size/shape, presets F1-F4 |
| Color Mode | `UTILITIES/COLOR-MODE-STATES.DOT` | FG/BG swap, invert, reset |
| Reference Image | `UTILITIES/REFIMG-STATES.DOT` | Reference image overlay |

#### LAYER-OPS (layer management operations)

| Diagram | File | Covers |
|---------|------|--------|
| Add/Delete | `LAYER-OPS/LAYER-ADD-DELETE-STATES.DOT` | New layer, duplicate, delete |
| Merge | `LAYER-OPS/LAYER-MERGE-STATES.DOT` | Merge down/selected/all, flatten |
| Arrange | `LAYER-OPS/LAYER-ARRANGE-STATES.DOT` | Reorder up/down/top/bottom, drag |
| Align/Distribute | `LAYER-OPS/LAYER-ALIGN-DISTRIBUTE-STATES.DOT` | Align 6 dirs, distribute H/V |
| Multiselect | `LAYER-OPS/LAYER-MULTISELECT-STATES.DOT` | Ctrl/Shift click, solo, visibility swipe |

#### TRANSFORM-OPS (transformation operations)

| Diagram | File | Covers |
|---------|------|--------|
| Quick Transform | `TRANSFORM-OPS/QUICK-TRANSFORM-STATES.DOT` | Flip, rotate 90°, scale ±50% |
| Transform Overlay | `TRANSFORM-OPS/TRANSFORM-OVERLAY-STATES.DOT` | Interactive transform with handles (scale/rotate/shear/distort/perspective) |

#### IMAGE-OPS (image-level operations)

| Diagram | File | Covers |
|---------|------|--------|
| Resize/Crop | `IMAGE-OPS/IMAGE-RESIZE-CROP-STATES.DOT` | Canvas resize dialog, crop tool |
| Adjustments | `IMAGE-OPS/IMAGE-ADJUSTMENT-STATES.DOT` | Brightness, hue, levels, blur, posterize, etc. |

#### FILE-OPS (file/IO operations)

| Diagram | File | Covers |
|---------|------|--------|
| Import Image | `FILE-OPS/IMAGE-IMPORT-STATES.DOT` | Image import, placement, resize handles, crop/zoom |
| Extract Images | `FILE-OPS/EXTRACT-IMAGES-STATES.DOT` | Sprite extraction, component detection, PNG export |
| Load Recent | `FILE-OPS/LOAD-RECENT-STATES.DOT` | File open, recent files, format detection, state reset |

---

## Step 1 — Read the state machine

Read the selected `.DOT` file. Parse its structure to identify:

- **States**: All labeled nodes (numbered states like `S_IDLE`, `S_EDITING`, etc.)
- **Transitions**: All edges with triggers, handlers, and guards
- **Sub-state clusters**: Grouped behaviors within `subgraph cluster_*` blocks
- **Side effects**: Actions noted in edge labels (history recording, state resets, etc.)

Identify **which state and transition** the bug likely occurs in based on the user's description.

---

## Step 2 — Map diagram to source files

Use the diagram's node labels, cluster labels, and edge annotations to identify the relevant source files. Common mappings:

| Diagram Area | Typical Source Files |
|-------------|---------------------|
| Tool states | `TOOLS/<TOOLNAME>.BI`, `TOOLS/<TOOLNAME>.BM` |
| GUI panels | `GUI/<PANEL>.BI`, `GUI/<PANEL>.BM` |
| Mouse handling | `INPUT/MOUSE.BM` (search for `MOUSE_dispatch_tool_*`, `MOUSE_tool_*`) |
| Keyboard handling | `INPUT/KEYBOARD.BM` (search for `KEYBOARD_tools`, `KEYBOARD_handle_*`) |
| Commands | `GUI/COMMAND.BM` (search for action ID in `CMD_execute_action`) |
| Rendering | `OUTPUT/SCREEN.BM` (search for `SCREEN_render`, tool-specific render calls) |
| Layer operations | `GUI/LAYERS.BM` (search for `LAYERS_*`) |
| History | `TOOLS/HISTORY.BI`, `TOOLS/HISTORY.BM` |
| Configuration | `CFG/CONFIG.BI`, `CFG/CONFIG.BM` |
| Image operations | `GUI/IMAGE-ADJ.BI`, `GUI/IMAGE-ADJ.BM`, `GUI/IMGADJ.BM` |
| Transform | `TOOLS/TRANSFORM.BI`, `TOOLS/TRANSFORM.BM` |
| File I/O | `INPUT/FILE-*.BM`, `OUTPUT/FILE-*.BM`, `TOOLS/DRW.BM` |

Read the relevant source files. Focus on the handler functions and guards mentioned in the diagram transitions.

---

## Step 3 — Check QB64-PE gotchas

Before diagnosing, verify the code doesn't violate these critical QB64-PE rules:

1. **`AND` is bitwise, not short-circuit!** `IF idx% > 0 AND arr(idx%) = val` crashes if idx%=0. Must use nested IF.
2. **Image handles valid only when `< -1`**. Always `IF handle& < -1 THEN _FREEIMAGE handle&`.
3. **Save/restore `_DEST`/`_SOURCE`** around all drawing operations.
4. **STATIC pressed% guards** required for all `_KEYDOWN()` Ctrl/Alt hotkeys (Gotcha #20 in project instructions).
5. **Layer indices are 1–64**, NOT 1–`LAYER_COUNT%`. Sparse allocation — valid layers can exist at any slot.
6. **`_UNSIGNED LONG` for colors** — using `INTEGER (%)` truncates `_RGB32` values.
7. **NEVER `_DEST _CONSOLE`** — use `_LOGINFO`, `_LOGWARN`, `_LOGERROR` for debug output.
8. **`HISTORY_saved_this_frame%`** must be checked before recording history to prevent double-saves.
9. **Render path awareness** — `SCREEN_render` has multiple fast paths. Overlays drawn after `SkipToPointer:` must ensure ALL paths reach them.
10. **`MOUSE.X/Y%` vs `MOUSE.UNSNAPPED_X/Y%`** — Grid-snapped coords cause shimmer in hit-tests. Use unsnapped coords for boundary testing.
11. **`UI_CHROME_CLICKED%` lifecycle** — Must be reset inside `MOUSE_should_skip_tool_actions%`, NEVER before it. Otherwise release-frame fires spurious history save.
12. **`contentDirty%` vs `BLEND_invalidate_cache`** — Only set `contentDirty% = TRUE` when actual pixel content changes on a specific layer.
13. **`FRAME_IDLE%` vs `SCENE_CHANGED%`** — For animations, set `FRAME_IDLE% = FALSE` (keeps loop active) but NOT `SCENE_CHANGED% = TRUE` (forces full composite).
14. **`DRW_load_binary` must reset all state** — When adding new tool/panel state, ensure file load resets it.
15. **THEME.BI include-order timing** — `THEME.*` fields are empty during `SCREEN_init`. Defer reads to first render (lazy-load pattern).
16. **Panel default-hidden must set ManuallyHidden** — A panel with `show%=FALSE` + `ManuallyHidden%=FALSE` auto-restores visible on first frame.

---

## Step 4 — Diagnose and fix

Trace the bug through the state machine:

1. **Identify the source state** — what state is the system in when the bug occurs?
2. **Identify the trigger** — what user action (key, click, menu, timer) causes the bug?
3. **Trace the transition** — follow the handler function that processes this trigger. Is the side effect correct? Are all guards in place?
4. **Check adjacent transitions** — could a different transition have left the system in a bad state before this one fires?
5. **Verify state cleanup** — when exiting a state, are ALL relevant variables reset?
6. **Check cross-state dependencies** — does this state machine interact with another one? (e.g., tool state + history, dialog + mouse, layer ops + rendering)

Apply the fix using the code edit tools. Prioritize:
- **CRASH fixes** (bounds, null handles, division by zero) first
- **CORRUPTION fixes** (orphan state, data loss, history pollution) second
- **VISUAL fixes** (rendering glitches, cursor position, flickering) third
- **UX fixes** (wrong behavior, missing feedback) fourth

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

1. Search the file for the bug description matching what was just fixed (look for `- [ ]` items under the relevant `###` heading in `## TO DO`).
2. Change the checkbox from `- [ ]` to `- [x]` on the matching line. Keep all its indented sub-lines as-is.
3. **Move the completed item** (and all indented children) from `## TO DO` to the matching `###` section under `## COMPLETED` at the bottom of the file.
4. Ensure incomplete `- [ ]` items stay in their original position — only move the completed item and its indented children.

**BUGS.md structure:**
```markdown
# BUGS

## TO DO

### SECTION NAME
- [ ] uncompleted bug ...
  - sub-detail

---

## COMPLETED

### SECTION NAME
- [x] completed bug ...
  - sub-detail preserved
```

---

## Step 7 — Update the state machine diagram

After the user confirms the bug is fixed, update the `.DOT` diagram file **if the fix changed any state transitions, guards, or added new behavior**:

- **New transitions**: Add edges with appropriate colors:
  - `#66cc66` (green) = activate / load
  - `#cc6666` (red, dashed) = deactivate / cancel
  - `#cccc66` (yellow) = commit / record history
  - `#6699ff` (blue) = re-edit / mode switch
  - `#cc66cc` (magenta) = special / rasterize
  - `#88aacc` (gray-blue) = self-transition
  - `#555555` (gray, dotted) = cross-links
- **New guards**: Update node labels to document new invariants or bounds checks
- **Modified transitions**: Update edge labels to reflect changed behavior
- **New sub-states**: Add nodes to existing clusters or create new clusters

Re-render the diagram if graphviz is available:

```bash
dot -Tsvg PLANS/diagrams/<CATEGORY>/<DIAGRAM>.DOT -o PLANS/diagrams/<CATEGORY>/<DIAGRAM>.svg
dot -Tpng -Gdpi=150 PLANS/diagrams/<CATEGORY>/<DIAGRAM>.DOT -o PLANS/diagrams/<CATEGORY>/<DIAGRAM>.png
```

---
