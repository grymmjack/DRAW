---
name: qa-auto-test
description: "Create an automated QA test script for a DRAW feature or tool. Generates a bash test script in QA/tests/ using the QA harness helpers, derived from state diagrams, keyboard/mouse bindings, source code, and project instructions."
---

# QA Auto Test — Create Automated Test Script

Generate an automated bash test script for a DRAW feature or tool. The script uses the QA harness helpers (`click`, `drag`, `snap_region`, `assert_*`, etc.) to exercise the feature and verify behavior through viewport-pixel screenshot comparisons.

---

## Step 0 — Accept Test Subject

Ask the user what feature or tool to test. Normalize the name to lowercase-kebab for the filename:

| User says | File becomes |
|-----------|-------------|
| "fill tool" | `QA/tests/tool-fill.sh` |
| "layers panel" | `QA/tests/layer-ops.sh` |
| "brush tool" | `QA/tests/tool-brush.sh` |
| "menubar" | `QA/tests/gui-menubar.sh` |
| "marquee selection" | `QA/tests/tool-marquee.sh` |
| "undo redo" | `QA/tests/history-undo-redo.sh` |
| "grid snap" | `QA/tests/util-grid-snap.sh` |

Prefix convention: `tool-`, `gui-`, `layer-`, `util-`, `file-`, `transform-`, `image-`.

---

## Step 1 — Gather Knowledge

Read these sources to understand the feature's states, transitions, guards, and edge cases.

### 1a. Instructions and skills

**Always read:**
- `.github/instructions/draw-project.instructions.md` — core project context

**Read when relevant** (match to test subject):
- `.github/instructions/draw-undo.instructions.md` — history/undo system
- `.github/instructions/draw-ui-chrome.instructions.md` — menus, commands, toolbar, organizer, edit bar
- `.github/instructions/draw-mouse.instructions.md` — mouse input system
- `.github/instructions/draw-file-config-theme.instructions.md` — file format, config, theme
- `.github/instructions/draw-rendering-layers.instructions.md` — rendering pipeline, layer system
- `.github/instructions/draw-ui-geometry.instructions.md` — UI chrome geometry reference
- `.github/instructions/draw-sound.instructions.md` — sound system
- `.github/instructions/draw-text-tool.instructions.md` — text tool specifics

### 1b. State machine diagrams

Read the relevant Graphviz DOT diagrams from `PLANS/diagrams/`. Each diagram documents states, transitions, guards, and edge cases — these map directly to test cases.

#### Complete Diagram Index

##### GLOBAL (System-wide state machines)

| Diagram | File | Covers |
|---------|------|--------|
| Mouse Input | `GLOBAL/MOUSE-STATES.DOT` | Mouse pipeline, click/drag/release, UI chrome handling |
| Keyboard Input | `GLOBAL/KEYBOARD-STATES.DOT` | Key dispatch, modifiers, tool shortcuts, hotkey guards |
| UI State | `GLOBAL/UI-STATES.DOT` | Frame lifecycle, idle detection, scene dirty, render gating |

##### GUI (Panels, bars, and UI components)

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

##### TOOLS (Drawing and editing tools)

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

##### UTILITIES (Assistants and helpers)

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

##### LAYER-OPS (Layer management operations)

| Diagram | File | Covers |
|---------|------|--------|
| Add/Delete | `LAYER-OPS/LAYER-ADD-DELETE-STATES.DOT` | New layer, duplicate, delete |
| Merge | `LAYER-OPS/LAYER-MERGE-STATES.DOT` | Merge down/selected/all, flatten |
| Arrange | `LAYER-OPS/LAYER-ARRANGE-STATES.DOT` | Reorder up/down/top/bottom, drag |
| Align/Distribute | `LAYER-OPS/LAYER-ALIGN-DISTRIBUTE-STATES.DOT` | Align 6 dirs, distribute H/V |
| Multiselect | `LAYER-OPS/LAYER-MULTISELECT-STATES.DOT` | Ctrl/Shift click, solo, visibility swipe |

##### TRANSFORM-OPS (Transformation operations)

| Diagram | File | Covers |
|---------|------|--------|
| Quick Transform | `TRANSFORM-OPS/QUICK-TRANSFORM-STATES.DOT` | Flip, rotate 90°, scale ±50% |
| Transform Overlay | `TRANSFORM-OPS/TRANSFORM-OVERLAY-STATES.DOT` | Interactive transform with handles (scale/rotate/shear/distort/perspective) |

##### IMAGE-OPS (Image-level operations)

| Diagram | File | Covers |
|---------|------|--------|
| Resize/Crop | `IMAGE-OPS/IMAGE-RESIZE-CROP-STATES.DOT` | Canvas resize dialog, crop tool |
| Adjustments | `IMAGE-OPS/IMAGE-ADJUSTMENT-STATES.DOT` | Brightness, hue, levels, blur, posterize, etc. |

##### FILE-OPS (File/IO operations)

| Diagram | File | Covers |
|---------|------|--------|
| Import Image | `FILE-OPS/IMAGE-IMPORT-STATES.DOT` | Image import, placement, resize handles, crop/zoom |
| Extract Images | `FILE-OPS/EXTRACT-IMAGES-STATES.DOT` | Sprite extraction, component detection, PNG export |
| Load Recent | `FILE-OPS/LOAD-RECENT-STATES.DOT` | File open, recent files, format detection, state reset |

### 1c. Source code

Read the relevant source files to understand implementation details:

| Feature area | Key source files |
|-------------|-----------------|
| Drawing tools | `TOOLS/{TOOL}.BI`, `TOOLS/{TOOL}.BM` |
| GUI panels | `GUI/{PANEL}.BI`, `GUI/{PANEL}.BM` |
| Mouse dispatch | `INPUT/MOUSE.BM` (tool hold/release handlers) |
| Keyboard | `INPUT/KEYBOARD.BM` (hotkey handlers) |
| Commands | `GUI/COMMAND.BM` (`CMD_execute_action`) |
| Rendering | `OUTPUT/SCREEN.BM` (`SCREEN_render` pipeline) |
| History | `TOOLS/HISTORY.BI`, `TOOLS/HISTORY.BM` |
| Layers | `GUI/LAYERS.BI`, `GUI/LAYERS.BM` |

### 1d. Keyboard and mouse bindings

Read `CHEATSHEET.md` for the keyboard shortcuts and mouse bindings relevant to the test subject.

### 1e. QB64PE MCP (optional)

Use `qb64pe-lookup_qb64pe_keyword` or `qb64pe-search_qb64pe_wiki` if you need to verify QB64PE API behavior that affects test expectations.

---

## Step 2 — Design Test Cases

For each testable behavior identified from the state diagrams, source code, and bindings, design a test case following this pattern:

### Test case structure

1. **Setup** — Select the correct tool, ensure canvas focus, establish known state
2. **Capture before** — `snap_region` of the area that will change
3. **Action** — Perform the action being tested (click, drag, key press, etc.)
4. **Assert** — Verify the result (screenshot comparison, crash check, window title)
5. **Cleanup** — Undo destructive changes, restore default tool/state

### Test dimensions to cover

For each feature, generate tests across these dimensions:

1. **Mouse interactions** — Click, drag, release, right-click, double-click, wheel
2. **Keyboard interactions** — Hotkeys, modifiers (Ctrl/Shift/Alt), tool switching
3. **Visual verification** — Before/after screenshot comparison of affected regions
4. **Edge cases from state diagrams** — Guards, error transitions, cancellation, re-entry
5. **Integration points** — Undo/redo after action, tool switch during action, panel interaction during tool use

### Coordinate calculation

All coordinates are in **viewport pixels** (not physical/OS pixels). Use the harness variables:

- Canvas center: `$CANVAS_CX`, `$CANVAS_CY`
- Work area bounds: `$WORK_LEFT`, `$WORK_RIGHT`, `$WORK_TOP`, `$WORK_BOTTOM`
- For offsets from center: `$((CANVAS_CX + 20))`, `$((CANVAS_CY - 10))`
- Panel regions: `$LAYER_PANEL_W`, `$TOOLBAR_W`, `$MENU_BAR_H`, `$STATUS_H`

---

## Step 3 — Generate the Test Script

Output a bash script at `QA/tests/{name}.sh`.

### Available harness helpers

All coordinates are in viewport pixels. These functions are provided by the QA harness and available in every test script:

```bash
# Mouse actions
click X Y [btn]              # Click at viewport coords (btn: 1=left default, 3=right)
right_click X Y              # Right-click at viewport coords
double_click X Y             # Double-click at viewport coords
drag X1 Y1 X2 Y2 [btn]      # Click-drag from (X1,Y1) to (X2,Y2)
scroll_up X Y                # Mouse wheel up at position
scroll_down X Y              # Mouse wheel down at position

# Keyboard actions
type_text "string"           # Type printable characters one at a time
key combo [combo2 ...]       # Key press (e.g. key ctrl+z, key b, key ctrl+shift+n)

# Timing
wait_for N "message"         # Sleep N seconds with log message

# Screenshot capture
screenshot "label"           # Full window capture, returns path
snap_region X Y W H "label"  # Capture viewport sub-region, returns path

# Assertions
assert_no_crash              # Verify DRAW process is still alive
assert_window_exists         # Verify DRAW window still open
assert_window_title "str"    # Check window title contains substring
assert_regions_differ F1 F2 "msg"  # FAIL if two snapshots are identical
assert_regions_same F1 F2 "msg"    # FAIL if two snapshots differ

# Logging
info "message"               # Log informational message
pass "message"               # Log pass result + increment pass counter
fail "message"               # Log fail result + increment fail counter
warn "message"               # Log warning
skip "message"               # Log skip + increment skip counter
```

### Available variables

These are set by the harness before the test script runs:

```bash
# Canvas geometry (viewport pixels)
$CANVAS_CX            # Canvas center X
$CANVAS_CY            # Canvas center Y
$CANVAS_W             # Canvas width
$CANVAS_H             # Canvas height

# Viewport geometry
$VIEWPORT_W           # Viewport width in internal pixels
$VIEWPORT_H           # Viewport height in internal pixels
$DISPLAY_SCALE        # Physical pixel multiplier (1-4)

# Panel geometry
$LAYER_PANEL_W        # Layer panel width (default 100)
$LAYERS_DOCK          # "LEFT" or "RIGHT"
$TOOLBAR_W            # Toolbar column width
$TOOLBAR_SCALE        # Toolbar scale factor (1-4)
$MENU_BAR_H           # Menu bar height (12)
$STATUS_H             # Status bar height (11)

# Work area bounds (canvas viewport region)
$WORK_LEFT            # Left edge of canvas work area
$WORK_RIGHT           # Right edge of canvas work area
$WORK_TOP             # Top edge (below menu bar)
$WORK_BOTTOM          # Bottom edge (above status/palette)
$WORK_W               # Work area width
$WORK_H               # Work area height

# Process info
$DRAW_PID             # DRAW process ID
$DRAW_WID             # DRAW window ID (X11)
```

### Key viewport regions for snap_region

Use these coordinates for capturing specific UI areas:

```bash
# Layer panel (LEFT dock default)
snap_region 0 12 $LAYER_PANEL_W 68 "layer-panel"

# Canvas area (centered sub-region for drawing tests)
snap_region $((CANVAS_CX - 40)) $((CANVAS_CY - 40)) 80 80 "canvas-center"

# Toolbar (RIGHT dock default)
snap_region $((VIEWPORT_W - TOOLBAR_W)) 12 $TOOLBAR_W $((83 * TOOLBAR_SCALE)) "toolbar"

# Organizer (below toolbar, RIGHT dock)
snap_region $((VIEWPORT_W - TOOLBAR_W)) $((12 + 83 * TOOLBAR_SCALE)) $TOOLBAR_W $((32 * TOOLBAR_SCALE)) "organizer"

# Status bar
snap_region 0 $((VIEWPORT_H - STATUS_H)) $VIEWPORT_W $STATUS_H "status-bar"

# Full work area
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "work-area"
```

### Script template

Every generated test script MUST follow this structure:

```bash
#!/bin/bash
# =============================================================================
# QA Auto Test: {Feature Name}
# Tests: {brief description of what is tested}
# Generated: {date}
# =============================================================================

# ---------------------------------------------------------------------------
# Setup — establish known state
# ---------------------------------------------------------------------------
info "=== {Feature Name} Tests ==="

# Select default tool (brush) and click canvas for focus
key b
wait_for 0.3 "Tool selected"
click $CANVAS_CX $CANVAS_CY
wait_for 0.2 "Canvas focused"
assert_no_crash

# ---------------------------------------------------------------------------
# Test 1: {Test Name}
# ---------------------------------------------------------------------------
info "Test 1: {Test Name}"

# Capture before state
BEFORE=$(snap_region ... "before-{test}")

# Perform action
{action commands}
wait_for 0.3 "Action performed"
assert_no_crash

# Capture after state
AFTER=$(snap_region ... "after-{test}")

# Assert change occurred
assert_regions_differ "$BEFORE" "$AFTER" "{Test Name} should change canvas"
pass "Test 1: {Test Name}"

# Cleanup
key ctrl+z
wait_for 0.3 "Undo cleanup"

# ---------------------------------------------------------------------------
# Test N: ...
# ---------------------------------------------------------------------------

# ... more tests ...

# ---------------------------------------------------------------------------
# Final cleanup and verification
# ---------------------------------------------------------------------------
info "=== Cleanup ==="
key b
click $CANVAS_CX $CANVAS_CY
assert_window_exists
info "=== {Feature Name} Tests Complete ==="
```

### Script conventions

1. **Shebang**: Always `#!/bin/bash`
2. **Header comment**: Test name, what it tests, generation date
3. **Initial setup**: `key b` + `click $CANVAS_CX $CANVAS_CY` to ensure known tool + canvas focus
4. **Visual assertions**: Use `snap_region` before/after for every action that should produce a visual change
5. **Crash checks**: `assert_no_crash` after every significant action (tool switch, draw, menu interaction)
6. **Wait times**: `wait_for 0.2`–`wait_for 0.5` after actions that need a render frame to take effect. Use `wait_for 1` or more for animations or multi-step operations
7. **Undo cleanup**: Undo destructive actions at the end of each test with `key ctrl+z`
8. **Independence**: Each test must not depend on side effects from previous tests. Reset state between tests
9. **Final check**: End with `assert_window_exists` to confirm DRAW survived all tests
10. **Variable capture**: Assign `snap_region` results to variables for later comparison:
    ```bash
    BEFORE=$(snap_region $((CANVAS_CX - 30)) $((CANVAS_CY - 30)) 60 60 "before-draw")
    ```

### Naming the snap_region labels

Use descriptive, unique labels for each snapshot to aid debugging:

- `before-{test-name}` / `after-{test-name}` for comparison pairs
- `{feature}-{state}` for state verification (e.g. `toolbar-brush-active`)
- Keep labels lowercase-kebab, max ~30 chars

---

## Step 4 — Validate

Before delivering the script, verify:

1. **Helpers only** — Script uses ONLY the documented harness helpers listed above. No raw `xdotool`, `import`, `sleep`, or direct X11 commands
2. **Viewport coordinates** — All X/Y values are in viewport pixels, using harness variables (`$CANVAS_CX`, `$WORK_LEFT`, etc.) and arithmetic (`$((CANVAS_CX + 20))`)
3. **Self-contained** — Test does not depend on state from other test scripts or prior runs
4. **Cleanup** — Destructive actions (drawing, deleting layers, changing settings) are undone
5. **Crash checks** — `assert_no_crash` appears after every significant action
6. **No hardcoded geometry** — Uses `$TOOLBAR_W`, `$LAYER_PANEL_W`, etc. instead of magic numbers for panel positions
7. **Bash syntax** — Run `bash -n QA/tests/{name}.sh` to check for syntax errors

If any check fails, fix the script and re-validate.

---

## Step 5 — Report

After generating the script, print a summary:

```
✅ Generated: QA/tests/{name}.sh

Tests: {N} test cases
Coverage:
  - {list of tested behaviors}
  - {list of tested behaviors}

Harness helpers used:
  - click, drag, key, snap_region, assert_regions_differ, assert_no_crash, ...

Run with:
  bash QA/run.sh tests/{name}.sh
```
