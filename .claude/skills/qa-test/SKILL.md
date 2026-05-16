---
name: qa-test
description: "Create a manual QA test checklist for a DRAW feature or tool. Generates a hierarchical checklist in PLANS/TESTS/ with test cases derived from state diagrams, keyboard/mouse bindings, source code, and project instructions."
---

# QA Test — Create Test Checklist

When the user invokes this skill (e.g. "create tests for X", "qa-test for FILL", "test the menubar"), generate a comprehensive manual test checklist for the specified DRAW feature. Follow these steps **in order**. Do not skip steps.

---

## Step 0 — Accept test subject

Ask the user:

> "What feature or area of DRAW should I create tests for?"

The answer becomes `{NAME}` — used as the filename and title throughout. Normalize to UPPERCASE for filenames (e.g. "fill tool" → `FILL`, "menubar" → `MENUBAR`, "layers panel" → `LAYERS-PANEL`).

If the user already named the feature in their request, skip the question and proceed.

---

## Step 1 — Gather knowledge

Collect context in this priority order (per `PLANS/TESTING.md`):

### 1a — Instructions and skills

Read `.claude/instructions/draw-project.md` (always). Then read any instruction file whose topic matches the feature's source files:

| Feature Area | Instruction File |
|-------------|-----------------|
| Mouse/input tools | `draw-mouse.md` |
| Screen/rendering | `draw-rendering.md`, `draw-chrome-geometry.md` |
| UI panels/toolbar/menubar | `draw-ui.md`, `draw-chrome-geometry.md` |
| Undo/history | `draw-undo.md` |
| Text tool | `draw-text-tool.md` |
| File formats/DRW | `draw-fileformat.md` |
| Sound/music | `draw-sound.md` |

### 1b — State machine diagram

Find the matching diagram in `PLANS/diagrams/` using this index:

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

Read the matching `.DOT` file and parse:
- **States**: All labeled nodes
- **Transitions**: All edges with triggers, guards, and actions
- **Sub-state clusters**: `subgraph cluster_*` blocks
- **Error/edge transitions**: Timeouts, cancellation, invalid input paths

### 1c — Source code

Read the relevant `.BI` and `.BM` files for the feature. Use this mapping:

| Feature Area | Source Files |
|-------------|-------------|
| Tool states | `TOOLS/{TOOLNAME}.BI`, `TOOLS/{TOOLNAME}.BM` |
| GUI panels | `GUI/{PANEL}.BI`, `GUI/{PANEL}.BM` |
| Mouse handling | `INPUT/MOUSE.BM` |
| Keyboard handling | `INPUT/KEYBOARD.BM` |
| Commands | `GUI/COMMAND.BM` |
| Rendering | `OUTPUT/SCREEN.BM` |
| Layer operations | `GUI/LAYERS.BM` |
| History | `TOOLS/HISTORY.BI`, `TOOLS/HISTORY.BM` |
| Configuration | `CFG/CONFIG.BI`, `CFG/CONFIG.BM` |
| Image operations | `GUI/IMAGE-ADJ.BI`, `GUI/IMAGE-ADJ.BM` |
| Transform | `TOOLS/TRANSFORM.BI`, `TOOLS/TRANSFORM.BM` |
| File I/O | `INPUT/FILE-*.BM`, `OUTPUT/FILE-*.BM`, `TOOLS/DRW.BM` |

### 1d — Keyboard/mouse bindings

Read `CHEATSHEET.md` and extract all bindings relevant to the feature being tested.

### 1e — MCP tools (optional)

If the `#qb64pe` MCP server is active, use `lookup_qb64pe_keyword` or `search_qb64pe_wiki` for any QB64-PE API behaviour that affects the feature's test cases.

---

## Step 2 — Create test file

Create the file `PLANS/TESTS/{NAME}.md` using this exact template structure:

```markdown
# [ ] {NAME} TESTING

## [ ] CATEGORY OF TEST

### [ ] SUB-CATEGORY NAME OF TEST
What is being tested. How to test. How to setup for the test.

#### [ ] TEST NAME
1. [ ] Step description
2. [ ] Step description
```

**Rules**:
- Every heading level gets a `[ ]` checkbox
- Categories group related test areas (e.g. "MOUSE INTERACTIONS", "KEYBOARD SHORTCUTS", "RENDERING", "UNDO/REDO", "STATE TRANSITIONS")
- Sub-categories are more specific groups within a category
- Test names are individual test cases with numbered steps
- Steps are concrete, actionable instructions a human can follow
- Include setup/precondition info in the sub-category description

---

## Step 3 — Populate tests

Generate test cases covering **all four interaction dimensions** from `PLANS/TESTING.md`:

### Mouse interactions
- Click, drag, release for every mouse button the feature uses
- Right-click context menus if applicable
- Mouse wheel behaviour
- Hover states and tooltips
- Drag boundaries (what happens at canvas edges, panel edges)
- Double-click behaviour if applicable

### Keyboard interactions
- All hotkeys from `CHEATSHEET.md` that relate to this feature
- Modifier combinations (Ctrl, Alt, Shift, Ctrl+Alt, Ctrl+Shift)
- Key repeat / held key behaviour
- Escape to cancel
- Enter to confirm

### Design considerations
- Multiple zoom levels (1x, 2x, 8x, 16x)
- Different canvas sizes (small 16×16, medium 128×128, large 320×200)
- Multiple layers (1 layer, many layers, hidden layers)
- Grid snap on/off
- Symmetry modes active
- Different brush sizes and shapes
- Different paint modes (normal, custom brush, pattern)
- Edge cases from state diagram guard conditions

### Tool-specific GUI / chrome
- Panel visibility toggling
- Panel resizing/docking (if applicable)
- Interaction with other active panels
- Status bar updates
- Toolbar active indicator

### State machine edge cases
For each state transition in the diagram that has:
- **Guards/conditions**: Test both the true and false paths
- **Error transitions**: Trigger the error condition and verify recovery
- **Cancellation paths**: Verify clean state reset
- **Re-entry**: Enter a state, leave, and re-enter — verify no stale state
- **Rapid transitions**: Quick successive inputs (double-click, fast key repeat)

### Undo/redo
- Perform the action, Ctrl+Z to undo, verify canvas state
- Undo then Ctrl+Y to redo, verify canvas state
- Multiple operations then multiple undos
- Undo across tool switches

---

## Step 4 — Announce completion

When the test file is complete, output:

> **Ready for tests.** Created `PLANS/TESTS/{NAME}.md` with N categories, M sub-categories, and P individual test cases.

The human will then use the `qa-test-run` skill in separate chat sessions to execute the tests.
