# DRAW - Input Controls Cheatsheet

## Tool Selection (Keyboard)

| Key | Tool | Notes |
|-----|------|-------|
| `B` | Brush | Continuous freehand painting (drag to paint) |
| `D` | Dot | Single-pixel stamp (click to place, no drag painting) |
| `F` | Fill | Flood fill tool |
| `I` | Picker | Color picker/eyedropper |
| `K` | Spray | Spray paint tool |
| `L` | Line | Draw straight lines |
| `P` | Polygon | Draw polygon outlines |
| `Shift+P` | Polygon (Filled) | Draw filled polygons |
| `R` | Rectangle | Draw rectangle outlines |
| `Shift+R` | Rectangle (Filled) | Draw filled rectangles |
| `E` | Ellipse | Draw ellipse outlines |
| `Shift+E` | Ellipse (Filled) | Draw filled ellipses |
| `M` | Marquee | Rectangular selection tool |
| `W` | Magic Wand | Select contiguous same-color pixels |
| `V` | Move | Transform selected region |
| `Z` | Zoom | Zoom tool (click to zoom in, Alt+click to zoom out) |
| `T` | Text | Text entry tool |
| `*` | Transparent Color | Toggle foreground to/from transparent (eraser mode with color memory) |
| `?` | Command Palette | Search commands and hotkeys |

## Paint Opacity

### Keyboard Shortcuts
| Key | Opacity |
|-----|---------|
| `1` | 10% |
| `2` | 20% |
| `3` | 30% |
| `4` | 40% |
| `5` | 50% |
| `6` | 60% |
| `7` | 70% |
| `8` | 80% |
| `9` | 90% |
| `0` | 100% (fully opaque) |

Paint opacity applies to the entire stroke/operation as a unit — overlapping brush dabs
within the same stroke will not compound opacity. The current opacity is shown in the
status bar as `OP:nn%` when below 100%.

## Color Selection

### Keyboard Shortcuts
| Key | Action |
|-----|--------|
| `*` | **Transparent** (eraser mode toggle — press again to restore previous color) |
| `X` | Swap foreground and background colors |

### Transparent Color Mode

Press `*` (asterisk/star) to **toggle** the foreground color to/from transparent. This enables eraser-like functionality with **color memory**:

- **First press**: Saves your current foreground color, sets FG to transparent
- **Second press**: Restores your previously saved foreground color
- This lets you quickly alternate between drawing and erasing without losing your color selection

| Tool | Transparent Effect |
|------|--------------------|
| **Brush/Dot** | Erases pixels (makes transparent) |
| **Fill** | Flood-fills area with transparency |
| **Line** | Draws transparent line (erases) |
| **Rectangle** | Draws transparent rect (erases) |
| **Ellipse** | Draws transparent ellipse (erases) |
| **Polygon** | Draws transparent polygon (erases) |

**Visual Indicators:**
- Status bar shows `FG:TRN` when transparent is selected
- FG swatch displays checkerboard pattern (transparency indicator)
- Tool previews show white outline for visibility (since color is invisible)

### Palette Strip (Bottom Bar)
| Action | Function |
|--------|----------|
| **Left-click swatch** | Select as foreground color |
| **Right-click swatch** | Select as background color |
| **Click `◄` arrow** | Scroll palette left |
| **Click `►` arrow** | Scroll palette right |
| **Mouse wheel on strip** | Scroll through palette colors |
| **SHIFT + wheel** | Fast scroll (32 colors at a time) |
| **Click palette name** | Open dropdown to switch palettes |
| **Letter keys (in picker)** | Jump to first palette starting with that letter |

### Status Bar Color Swatches
| Action | Function |
|--------|----------|
| **Click FG swatch** | Open color picker for foreground |
| **Click BG swatch** | Open color picker for background |

## Grid Controls

| Key | Function |
|-----|----------|
| `'` (apostrophe) | Toggle grid visibility |
| `Shift+'` (quote) | Toggle pixel grid (400%+ zoom) |
| `;` (semicolon) | Toggle snap-to-grid |
| `Ctrl+'` | Cycle grid geometry mode (Square → Diagonal → Isometric → Hex) |
| `.` (period) | Increase grid size (+1px, max 50px) |
| `,` (comma) | Decrease grid size (-1px, min 2px) |

### Grid Geometry Modes

| Mode | Status Tag | Description |
|------|------------|-------------|
| **Square** (default) | (none) | Standard axis-aligned rectangular grid |
| **Diagonal** | `/DG` | 45° rotated diamond grid |
| **Isometric** | `/ISO` | 30°/60° isometric triangle grid |
| **Hex** | `/HEX` | Flat-top hexagonal grid with 45° diagonal sides |

Cycle through modes with `Ctrl+'`. The current mode is shown in the status bar after the grid size (e.g., `G:16/ISO`).

### Grid Cell Fill Mode

When **Grid Cell Fill** is enabled (via View menu → Grid Cell Fill), the Fill tool fills individual grid cells instead of performing a flood fill. Works with all grid geometry modes:

- **Square**: Fills rectangular cells
- **Diagonal**: Fills diamond-shaped cells
- **Isometric**: Fills triangular cells
- **Hex**: Fills hexagonal cells

Requires both grid visibility (`'`) and cell fill mode to be enabled.

### Grid Alignment Modes

| Mode | Description |
|------|-------------|
| **Corner** (default) | Snaps to grid intersection corners (top-left of cells) |
| **Center** | Snaps to center of grid cells |

Toggle via View menu → Grid Tile Mode. Grid alignment affects all snap-to-grid operations including drawing tools, marquee, and move.

### Grid Notes

- Regular grid shows at 100%+ zoom when enabled
- Pixel grid shows at 400%+ zoom when enabled (fine grid around each pixel)
- Both grids can be shown simultaneously at high zoom levels
- Status bar shows grid state: `G:n` (visible) or `G:n S` (snap enabled)
- Snap-to-grid rounds all drawing coordinates to nearest grid boundary
- Grid color, opacity, and angle are configurable in DRAW.cfg and theme files

## Symmetry Drawing

DRAW supports real-time symmetrical drawing with three modes: Vertical (|), Cross (+), and Asterisk (*). All drawing operations are automatically mirrored across the symmetry axes.

### Symmetry Controls

| Key | Function |
|-----|----------|
| `F7` | Cycle symmetry mode (Off → Vertical → Cross → Asterisk → Off) |
| `F8` | Turn off symmetry (instant disable) |
| `Ctrl + Left Click` | Reposition symmetry center to mouse location |

> **macOS Note:** On macOS, Ctrl+Click is intercepted by the OS and converted to a right-click.
> DRAW handles this automatically — Ctrl+Click will still set the symmetry center on macOS.
> The Command (⌘) key is **not** supported by QB64PE on macOS. See [MAC-USERS-README.md](MAC-USERS-README.md) for details.

### Symmetry Modes

| Mode | Symbol | Description |
|------|--------|-------------|
| **Off** | - | Normal drawing (no symmetry) |
| **Vertical** | \| | Mirror left/right across vertical axis (2 copies) |
| **Cross** | + | Mirror horizontally and vertically (4 copies) |
| **Asterisk** | * | Mirror across vertical, horizontal, and both diagonals (8 copies) |

### Visual Feedback

- **Guide Lines**: Semi-transparent cyan lines show active symmetry axes
- **Center Crosshair**: Yellow crosshair marks the center point of symmetry
- **Status Bar**: Shows current mode as `SYM:n` where:
  - `SYM:0` = Off
  - `SYM:1` = Vertical (|)
  - `SYM:2` = Cross (+)
  - `SYM:3` = Asterisk (*)

### Features

- **Works with all drawing tools**: Brush, Dot, Line, Rectangle, Ellipse, Polygon, Fill, Custom Brush
- **Interactive center**: Ctrl+click anywhere to reposition the symmetry center
- **Preview support**: Live preview shows symmetry during drag operations (Line, Rectangle, Ellipse)
- **Initial center**: Defaults to canvas center (160, 100 for 320x200 canvas)
- **Persistent guides**: Symmetry guides remain visible while drawing

### Workflow Tips

- Press `F7` repeatedly to cycle through modes and find the right symmetry type
- Use `Ctrl + Left Click` to quickly reposition center without changing modes
- Press `F8` for instant disable when you need to draw without symmetry
- Combine with grid snap for precise symmetrical patterns

## Mouse Controls

### General
| Action | Function |
|--------|----------|
| **Left Click** | Draw/Select/Activate tool with foreground color |
| **Right Click** | Draw with background color (Brush, Dot, Line, Rect, Ellipse, Fill, Spray) |
| **Middle Click** | Pan canvas (hold and drag) |
| **Double Middle Click** | Reset zoom and pan to default |
| **Mouse Wheel** | Zoom in/out |
| **Spacebar + Left Drag** | Pan canvas |

> **Right-click exceptions:** Picker (picks BG color), Polygon (closes shape), Brush/Dot + Shift (connecting line from last point)

### Pan Tool

The Pan (Hand) tool provides a dedicated panning mode. When selected, left-click and drag to pan the canvas without needing to hold spacebar.

Select from toolbar or note that spacebar+drag and middle-click drag also pan from any tool.

**Double-click** the Hand toolbar button to reset both pan position and zoom to 100%.

### Zoom Tool

The Zoom (`Z`) tool provides interactive zoom control:

| Action | Function |
|--------|----------|
| **Left Click** | Zoom in at cursor position |
| **Alt + Left Click** | Zoom out at cursor position |
| **Left Drag** | Draw rectangle, zoom to fit that region |
| **Double-click Hand button** | Reset zoom to 100% and center canvas |

**Zoom Snap Levels:** 25%, 50%, 100%, 200%, 300%, 400%, 500%, 600%, 700%, 800%

- Click-to-zoom centers the view on the clicked position
- Drag-to-zoom fits the dragged rectangle to fill the view
- Drag preview shown as white rectangle while dragging (minimum 8px drag distance)

### Spray Tool

The Spray (`K`) tool sprays random dots within a circular area:

| Feature | Details |
|---------|--------|
| **Nozzle Tips** | Uses current brush shape and size (circle/square, `[`/`]` to adjust) |
| **Spray Radius** | Doubles with each brush size level (size 1 = 4px, size 2 = 8px, size 3 = 16px, etc.) |
| **Density** | Proportional to radius (larger = more tips per frame) |
| **Left Click** | Spray with foreground color |
| **Right Click** | Spray with background color |
| **Shift (hold)** | Constrain spray to horizontal or vertical axis |
| **Symmetry** | Fully supported (all symmetry modes) |
| **Selection Clipping** | Respects active marquee/wand selections |
| **Preview** | Circle + dot pattern preview shown when not actively spraying |
| **Custom Brush** | When custom brush is active, stamps the brush at random positions within radius |

The spray nozzle stamps the current brush shape/size at each random position, so larger brush sizes produce thicker spray dots. The spray area radius also scales (2x per brush size level) to keep coverage proportional.

**Custom Brush + Spray:**
When a custom brush is captured (`Ctrl+B`), the spray tool stamps the custom brush image at random positions within the spray radius instead of individual dots. The spray radius scales proportionally with brush size, and density is maintained for consistent coverage. Recolor mode (`F9`) applies to spray-stamped custom brushes.

### Tool-Specific
| Tool | Action | Function |
|------|--------|----------|
| **Dot** | Shift + Right Click | Draw line from last point to current |
| **Picker** | Alt (hold) | Temporarily activate picker (releasing ALT returns to previous tool without opening the menu bar) |
| **Marquee** | Drag handles | Resize selection |
| **Marquee** | Drag inside | Move selection |
| **Move** | Drag handles | Scale/resize |
| **Move** | Drag inside | Move transformed content |

## Brush Controls

| Key | Function |
|-----|----------|
| `[` or `{` | Decrease brush size |
| `]` or `}` | Increase brush size |
| `F1` | Brush preset 1 |
| `F2` | Brush preset 2 |
| `F3` | Brush preset 3 |
| `F4` | Brush preset 4 |
| `` ` `` or `~` | Toggle brush preview |
| `\` or `|` | Toggle brush shape |
| `F6` | Toggle pixel perfect mode |

Brush size and shape affect all drawing tools: Brush, Dot, Line, Rectangle, Ellipse, Polygon, and Spray. Shape tools preview the brush thickness in real-time during drag operations.

## Custom Brush
| `Ctrl+B` (with brush active) | Clear/deactivate custom brush |
| `F9` | Toggle recolor mode (paint brush in FG color) |
| `Shift+O` | Apply 1px outline using BG color (turns off recolor mode) |
| `` ` `` (backtick) | Toggle custom brush outline visibility |
| `F12` | Export active custom brush as PNG file |
| `Home` | Flip custom brush horizontally |
| `End` | Flip custom brush vertically |
| `Page Up` | Scale custom brush up |
| `Page Down` | Scale custom brush down |
| `/` | Reset custom brush scale to original size |

**Custom Brush Features:**
- Capture any rectangular area as a reusable brush pattern
- **Non-rectangular shapes**: Alpha channel is preserved during capture, so irregular/transparent shapes work as brushes (not just solid rectangles)
- Automatic transparency: background color becomes transparent
- **Recolor Mode (F9)**: Paint all non-transparent pixels in current FG color
- **Outline (Shift+O)**: Add 1px outline around non-transparent pixels using BG color
  - Automatically turns off recolor mode to preserve outline color
  - Press multiple times for thicker outlines — canvas dynamically expands to prevent clipping
- Works with LINE, RECTANGLE, ELLIPSE, and POLYGON tools
- Creates "beaded" or stamped effects along shape perimeters
- Works with SPRAY tool — stamps brush at random positions within spray radius
- Flip horizontally or vertically for variations
- Scale up/down or reset to adjust brush size
- Exported PNG files use timestamp-based filenames for unique names
- Visual feedback with marching ants during capture
- Status bar shows `CB` when active, `CB+RECOLOR` when recolor mode is on
- **Select from Current Layer** (`Ctrl+Click` layer row): Creates a selection mask from all non-transparent pixels on that layer, perfect for capturing complex shapes as custom brushes

**Outlined Text Workflow:**
1. Draw text on canvas, marquee select it, `Ctrl+B` to capture
2. Press `b` for brush tool
3. `F9` to enable recolor mode
4. Pick FG color for text fill, pick BG color for outline
5. `Shift+O` to apply outline (auto-disables recolor)
6. Click to stamp your outlined text!

## Canvas Controls

| Key | Function |
|-----|----------|
| `Delete` | Clear canvas (with confirmation prompt) |
| `Backspace` | Clear canvas (no prompt) |

## View Controls

| Key | Function |
|-----|----------|
| `Tab` | Toggle toolbar visibility |
| `Ctrl+L` | Toggle layer panel visibility |
| `F10` | Toggle status bar visibility |
| `F11` | Toggle all UI (toolbar, status bar, layer panel, menu bar) |
| `Ctrl+F11` | Toggle menu bar visibility |
| `Shift` | Show crosshair (when held) |

**Note:** Toggling the layer panel or menu bar does not shift the canvas position. UI panels overlay on top of the canvas.

### Canvas Zoom

| Key | Function |
|-----|----------|
| `Ctrl+0` | Reset zoom to 100% and center |
| `Ctrl+=` | Zoom in (25%→50%→100%→200%→300%...800%) |
| `Ctrl+-` | Zoom out (800%...300%→200%→100%→50%→25%) |
| `Ctrl+Mouse Wheel` | Zoom in/out (same levels) |

**Zoom Levels:** 25%, 50%, 100%, 200%, 300%, 400%, 500%, 600%, 700%, 800%

### Display Scale (Window Size)

| Key | Function |
|-----|----------|
| `Ctrl+Alt+Shift+NumPad+` | Increase display scale (1x→2x→3x→4x) |
| `Ctrl+Alt+Shift+NumPad-` | Decrease display scale (4x→3x→2x→1x) |

**Notes:**
- NumPad +/- work with NumLock ON or OFF
- Display scale changes window size, not canvas zoom
- Changed scale is remembered if you save config on exit

## Drawing Modifiers

| Tool | Modifier | Effect |
|------|----------|--------|
| **Line/Rect/Ellipse** | Shift (drag) | Constrain to horizontal/vertical |
| **Brush/Spray** | Shift (drag) | Constrain to horizontal or vertical axis |
| **Line/Polygon** | Ctrl+Shift (drag/click) | Snap to angle increments (see Angle Snapping below) |
| **Rectangle** | Ctrl (drag) | Draw perfect square |
| **Rectangle** | Shift (drag center) | Draw from center |
| **Ellipse** | Ctrl (drag) | Draw perfect circle |
| **Ellipse** | Shift (drag center) | Draw from center |

## Angle Snapping

Precise angle control for line and polygon drawing. Hold **Ctrl+Shift** to snap endpoints to configured angle increments.

### Controls

| Key | Function |
|-----|----------|
| `Ctrl+Shift` (hold while dragging) | Snap line/polygon angles to increments |

### Snap Increments

The default snap angle is **45°** (8 directions), configurable in `DRAW.cfg`:

| Angle | Directions | Positions |
|-------|------------|-----------|
| **45°** (default) | 8 | 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315° |
| **30°** | 12 | Every 30° around circle |
| **15°** | 24 | Fine-grained precision (every 15°) |
| **90°** | 4 | Horizontal/vertical only (0°, 90°, 180°, 270°) |

**Configuration**: Edit `ANGLE_SNAP_DEGREES=` in `DRAW.cfg` (valid range: 1-90)

### Supported Tools

- **Line Tool**: Snap endpoint angle while dragging
- **Polygon Tool**: Snap each segment angle as you click points
- **Polygon Filled Tool**: Snap each filled polygon segment

### Features

- Preserves line distance while snapping angle
- Visual feedback shows snapped position in real-time
- Works with symmetry drawing for complex symmetrical patterns
- Combines with grid snap for precise positioned + angled lines

## Clipboard Operations

| Key | Function |
|-----|----------|
| `Ctrl+C` | Copy selection to clipboard |
| `Ctrl+X` | Cut selection (copy + clear original with BG color) |
| `Ctrl+V` | Paste clipboard at mouse cursor (centered, engages Move tool) |
| `Ctrl+E` | Clear/erase selection (fill with BG color, or transparent for magic wand) |

**Workflow:**
1. Use Marquee (`M`) or Magic Wand (`W`) to select an area
2. Copy (`Ctrl+C`) or Cut (`Ctrl+X`) the selection
3. Move mouse to desired location
4. Paste (`Ctrl+V`) - creates selection centered on cursor, auto-engages Move tool
5. Position content, press `Enter` to apply or `Escape` to cancel

## Marquee/Selection Controls

DRAW supports Photoshop-style selections that act as clipping masks. When a selection is active, **all drawing tools** (brush, fill, line, rect, ellipse, polygon) only affect pixels inside the selection area.

### Selection Modes

| Key | Mode | Description |
|-----|------|-------------|
| `M` | Rectangle Marquee | Draw rectangular selection by dragging |
| `W` | Magic Wand | Click to select contiguous pixels of same color |

### Marquee Tool

The Marquee (`M`) creates rectangular selections:

| Action | Function |
|--------|----------|
| **Left Drag** | Create rectangular selection |
| **Shift + Drag** | Add to existing selection (union) |
| **Alt + Drag** | Subtract from existing selection |

### Magic Wand Tool

The Magic Wand (`W`) selects all contiguous pixels of the same color as the clicked pixel:

| Action | Function |
|--------|----------|
| **Left Click** | Select contiguous pixels matching clicked color |
| **Shift + Click** | Add to existing selection (union) || **Alt + Click** | Subtract from existing selection |
**Magic Wand Features:**
- Selects all connected pixels of the same color (flood-fill style)
- Visual marching ants outline shows the selection boundary
- Works with `Ctrl+E` to clear selected pixels to transparent
- Selection persists when switching tools (acts as clipping mask)

### Selection as Clipping Mask

When a selection is active (marquee or magic wand), it acts as a **clipping mask**:

- **Brush/Dot**: Only paints inside selection boundary
- **Fill**: Only fills pixels inside selection
- **Line**: Only draws line segments inside selection
- **Rectangle**: Only draws rect portions inside selection
- **Ellipse**: Only draws ellipse portions inside selection
- **Polygon**: Only draws polygon portions inside selection

**Visual Feedback:** Marching ants display around the selection from any tool.

### Keyboard Controls

| Key | Function |
|-----|----------|
| `Ctrl+A` | Select all (entire canvas) |
| `Ctrl+Shift+I` | Invert selection |
| `Ctrl+D` | Deselect/clear selection (works from **any tool**) |
| `Escape` | Deselect/clear selection (works from **any tool**) |
| Arrow Keys | Move selection (1px) |
| Shift + Arrows | Move selection (10px) |
| Ctrl + Arrows | Resize selection (1px) |
| Ctrl+Shift + Arrows | Resize selection (10px) |

### Clipboard with Selections

| Key | Function |
|-----|----------|
| `Ctrl+C` | Copy selection to clipboard |
| `Ctrl+X` | Cut selection (copy + clear with BG color) |
| `Ctrl+V` | Paste at mouse cursor |
| `Ctrl+E` | Clear selection (fill with BG color, or transparent for magic wand) |

## Polygon Tool

| Key/Action | Function |
|------------|----------|
| **Left Click** | Place point |
| **Enter** | Complete polygon |
| **Escape** | Cancel polygon |

## Text Tool

| Key | Function |
|-----|----------|
| **T** | Text tool with VGA font (default) |
| **Shift+T** | Text tool with Tiny5 font |
| **Ctrl+T** | Text tool with custom loaded font |
| **Type** | Enter text |
| **Enter** | New line |
| **Backspace** | Delete character |
| **Escape** | Apply/finish text |

### Custom Font Loading

| Action | Function |
|--------|----------|
| **Middle-click text icon** | Open font dialog to load custom TTF/OTF font |

**Custom Font Features:**
- Middle-click the Text tool icon (toolbar) to load any `.ttf` or `.otf` font file
- Font loads with natural kerning pairs and built-in hinting (proportional spacing)
- No anti-aliasing for crisp pixel-perfect rendering (DONTBLEND)
- Automatically tries multiple sizes: 16px → 12px → 8px → 20px (uses first success)
- Once loaded, use `Ctrl+T` to activate text tool with custom font
- Custom font persists across tool resets until manually replaced
- Regular `T` key continues to use standard VGA font
- `Shift+T` continues to use Tiny5 small font

## Transform Operations

Transform operations work universally on the current layer, active selection, or floating move selection — no specific tool required.

| Key | Function |
|-----|----------|
| **H** | Flip horizontally |
| **Ctrl+Shift+H** | Flip vertically |
| **>** | Rotate 90° clockwise |
| **<** | Rotate 90° counter-clockwise |
| **Ctrl+Shift+-** | Scale down 50% |
| **Ctrl+Shift+=** | Scale up 50% |

These also work on custom brushes when one is active (flip, rotate, scale).

## Move Tool

| Key | Function |
|-----|----------|
| **Arrow Keys** | Move selection (1px) |
| **Shift + Arrows** | Move selection (10px) |
| **Ctrl + Arrows** | Resize/scale selection (1px) |
| **Ctrl+Shift + Arrows** | Resize/scale selection (10px) |
| **Alt (hold)** | Clone mode (keeps original pixels) |
| **Enter** | Apply transformation and return to Marquee |
| **Escape** | Cancel current drag operation |

## File Operations

### Standard Image Save/Load (CTRL)
| Key | Function |
|-----|----------|
| `Ctrl+N` | New canvas (prompts to save unsaved changes, then resets to blank canvas) |
| `Ctrl+O` | Open/import image file (PNG, BMP, JPG, GIF) |
| `Ctrl+S` | Save (silently if previously saved, dialog if new) |
| `Ctrl+Shift+S` | Save As (always prompts for filename) |
| `Ctrl+Alt+Shift+S` | Export selection as cropped image |

### Reference Image

Load a high-resolution image behind the canvas at adjustable opacity for tracing.
The reference image is non-destructive and renders behind all layers.
Reference image state (position, scale, opacity, visibility, filename) is saved and restored with `.draw` project files (DRW v4+).

| Key | Function |
|-----|----------|
| `Ctrl+R` | Toggle reference image on/off (loads if none loaded) |
| `Ctrl+Shift+Wheel` | Adjust reference image opacity (5-100%) |

**Reposition Mode** (View → Reposition Reference):

| Action | Function |
|--------|----------|
| **Drag** | Move reference image |
| **Mouse Wheel** | Scale reference image up/down |
| **Arrow Keys** | Nudge reference image 1px |
| **Enter** | Confirm and exit reposition mode |
| **Escape** | Cancel and exit reposition mode |

**View Menu Commands:**

| Command | Function |
|---------|----------|
| View → Reference Image | Toggle visibility (Ctrl+R) |
| View → Load Reference | Load a new reference image file |
| View → Clear Reference | Remove the current reference image |
| View → Reposition Reference | Enter reposition mode for drag/resize |

### DRAW Project Files (ALT)
| Key | Function |
|-----|----------|
| `Alt+O` | Open DRAW project (.draw) |
| `Alt+X` | Exit DRAW (prompts if unsaved) |

### File Menu Commands
| Command | Function |
|---------|----------|
| File → New | Create a new empty canvas (prompts to save unsaved changes) |
| File → Open | Open a .draw project file |
| File → Import Image | Open/import image file |
| File → Save | Save (silently if previously saved, dialog if new) |
| File → Save As... | Save with a new filename (always prompts) |
| File → Export Layer | Export current layer as PNG |
| File → Export Brush | Export active custom brush as PNG |
| File → Exit | Exit DRAW (`Alt+X`) |

**Note:** .draw files are PNG images with an embedded `drAw` chunk that preserves all layers, blend modes, palette colors, tool states, reference image configuration, and other project data. They can be previewed in any image viewer. Standard image saves flatten all visible layers to a single image.

## Undo/Redo

| Key | Function |
|-----|----------|
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |

## Layers

DRAW supports a Photoshop-style layer system with up to 32 layers. Each layer has independent opacity, visibility, blend mode, and stacking order.

### Layer Panel

The layer panel is displayed on the left side of the screen and can be toggled with **Ctrl+L**.

| Key | Function |
|-----|----------|
| `Ctrl+L` | Toggle layer panel visibility |
| `Ctrl+Shift+N` | Create new layer (note: `Ctrl+N` creates new canvas) |
| `Ctrl+Shift+D` | Duplicate current layer |
| `Ctrl+Shift+Delete` | Delete current layer |
| `Ctrl+PgUp` | Move layer up in stack |
| `Ctrl+PgDn` | Move layer down in stack |
| `Ctrl+Alt+E` | Merge current layer down |
| `Ctrl+Alt+Shift+E` | Merge all visible layers |

### Layer Panel UI

| Element | Function |
|---------|----------|
| **Eye icon (O/-)** | Toggle layer visibility (click to toggle) |
| **Lock icon (L)** | Opacity lock indicator |
| **Layer name** | Click to select layer, right-click to rename |
| **Opacity bar** | Shows opacity level, click/drag to adjust |

### Layer Panel Buttons

| Button | Symbol | Function |
|--------|--------|----------|
| Move Up | `^` | Move selected layer up in stack |
| Move Down | `v` | Move selected layer down in stack |
| Merge Down | `#` | Merge selected layer into layer below |
| Delete | `x` | Delete selected layer |
| New | `+` | Create new layer |

### Mouse Controls (Layer Panel)

| Action | Function |
|--------|----------|
| **Left-click layer row** | Select layer |
| **Ctrl+Left-click layer row** | Select non-transparent pixels (creates marquee selection mask) |
| **Right-click layer row** | Select and rename layer |
| **Shift+Right-click layer row** | Cycle blend mode (Normal → Multiply → Screen → ... → Luminosity) |
| **Alt+Left-click visibility icon** | Solo/unsolo layer (hide all others) |
| **Click visibility icon** | Toggle layer visibility |
| **Click+drag across visibility icons** | Swipe to show/hide multiple layers at once |
| **Click lock area** | Toggle opacity lock |
| **Click/drag opacity bar** | Adjust layer opacity |
| **Drag layer row** | Reorder layers (drag and drop) |
| **Mouse wheel on panel** | Scroll layer list |
| **Mouse wheel on opacity bar** | Adjust opacity (up = more opaque) |
| **Escape (while dragging)** | Cancel layer drag operation |

### Drag and Drop Reordering

Layers can be reordered by dragging them to a new position:

- **Click and hold** on a layer row (not on visibility/lock/opacity controls)
- **Drag up or down** to move the layer
- A **blue indicator line** shows where the layer will be dropped
- A **preview box** follows the cursor showing the layer being dragged
- **Release** to drop the layer at the new position
- **Auto-scroll** activates when dragging near the top/bottom edges of the panel
- Press **Escape** to cancel the drag operation

### Layer Features

- **32 layers maximum** (configurable in DRAW.cfg)
- **Per-layer opacity** (0-255, displayed as percentage)
- **Per-layer visibility** toggle
- **Per-layer blend mode** (19 Photoshop-style blend modes)
- **Solo layer** (Alt+click eye icon to isolate a single layer)
- **Visibility swipe** (click+drag across eye icons to rapidly show/hide layers)
- **Opacity lock** prevents drawing on transparent pixels (enforced by all tools: Brush, Dot, Line, Rectangle, Ellipse, Polygon, Fill, Spray)
- **Background layer** created automatically on startup
- **Transparency** shown as checkerboard pattern behind layers
- **Drawing tools** automatically target the currently selected layer
- **Merge operations** combine layers while preserving opacity

### Blend Modes

Each layer can use one of 19 blend modes. **Shift+Right-click** a layer row to cycle through modes. The current blend mode abbreviation is shown on the layer row.

| Mode | Abbr | Description |
|------|------|-------------|
| Normal | Nrm | Standard alpha compositing (default) |
| Multiply | Mul | Darkens by multiplying colors — great for shadows |
| Screen | Scr | Lightens by inverting, multiplying, inverting — great for glows |
| Overlay | Ovr | Combines Multiply and Screen based on base brightness |
| Add (Linear Dodge) | Add | Adds channel values, brightening the result |
| Subtract | Sub | Subtracts source from destination, darkening |
| Difference | Dif | Absolute difference between layers |
| Darken | Drk | Keeps the darker pixel from each layer |
| Lighten | Lgt | Keeps the lighter pixel from each layer |
| Color Dodge | CDg | Brightens base by dividing by inverted source |
| Color Burn | CBn | Darkens base by dividing inverted base by source |
| Hard Light | HdL | Like Overlay but based on source brightness |
| Soft Light | SfL | Gentle contrast adjustment (Pegtop formula) |
| Exclusion | Exc | Similar to Difference but lower contrast |
| Vivid Light | VvL | Combines Color Dodge and Color Burn at midpoint |
| Linear Light | LnL | Linear Dodge + Linear Burn combination |
| Pin Light | PnL | Replaces pixels based on brightness comparison |
| Color | Clr | Applies source hue/saturation with destination luminance |
| Luminosity | Lum | Applies source luminance with destination hue/saturation |

### Layer Workflow Tips

- New layers are created above the current layer
- Deleting a layer automatically selects the next available layer
- Lower the opacity slider to see layers underneath
- Use merge down to flatten specific layers together
- The canvas offset adjusts when layer panel is visible
- Export/save operations flatten all visible layers

## Image Import (Oversized Images)

When loading an image larger than the canvas, DRAW enters **Image Import Mode** allowing you to interactively position, zoom, pan, and crop the image before placing it.

### How It Works
1. Load an image via `Ctrl+O` that is larger than your canvas
2. DRAW enters import mode with a semi-transparent overlay
3. Draw a marquee to define where the image will be placed (or press Enter for full canvas)
4. Adjust zoom, pan, and position as needed
5. Press **Enter** to apply or **Escape** to cancel

### Image Import Controls

| Key | Function |
|-----|----------|
| **Mouse Drag** | Draw placement marquee |
| **Shift + Corner Drag** | Resize with constrained proportions |
| **Mouse Wheel** | Zoom into/out of image |
| **Arrow Keys** | Move destination box (1px) |
| **Shift + Arrows** | Move destination box (10px) |
| **Ctrl + Arrows** | Resize destination box (1px) |
| **Ctrl+Shift + Arrows** | Resize destination box (10px) |
| **Alt + Arrows** | Pan within image crop (1px) |
| **Alt+Shift + Arrows** | Pan within image crop (10px) |
| **Right-click drag** | Pan image within crop area |
| **`>`** (Shift+.) | Rotate image 90° clockwise |
| **`<`** (Shift+,) | Rotate image 90° counter-clockwise |
| **Home** | Flip image horizontally |
| **End** | Flip image vertically |
| **Enter** | Apply import to canvas |
| **Escape** | Cancel import |

### Visual Indicators
- **Dimmed overlay** shows the canvas area outside your placement box
- **Live preview** shows the cropped/scaled/rotated/flipped image in real-time
- **Marching ants** border indicates the destination box
- **Resize handles** at corners and edges for mouse resizing

### Workflow Tips
- Use **wheel zoom** to magnify a specific area of the source image
- Use **Alt+Arrows** or **right-drag** to pan to different parts of the zoomed image
- Combine zoom and pan to precisely select which portion of an oversized image to use
- The image is scaled to fit your destination box while maintaining the current crop
- Rotation and flip transformations update the preview in real-time
- Images are centered on the canvas at their original size (or proportionally fit if larger)

## Crop Tool

The crop tool lets you trim the canvas to a selected region. It uses the **Marquee** tool for all selection interaction.

### How It Works
1. Activate crop from the **Edit** menu or command palette
2. Click and drag on the canvas to define the crop region (marquee selection)
3. Resize using handles, move by dragging inside, nudge with arrow keys
4. Press **Enter** to apply the crop or **Escape** to cancel

### Crop Controls

| Key | Function |
|-----|----------|
| **Click + Drag** | Draw crop region |
| **Drag handles** | Resize crop region |
| **Drag inside** | Move crop region |
| **Arrow Keys** | Nudge crop region (1px) |
| **Shift + Arrows** | Nudge crop region (10px) |
| **Ctrl + Arrows** | Resize crop region from bottom-right |
| **Enter** | Apply crop (resize canvas to selection) |
| **Escape** | Cancel crop |

### Visual Indicators
- **Dark overlay** dims the area outside the crop region
- **Marching ants** border with resize handles (from marquee tool)
- **Size label** shows crop dimensions above the selection
- Status bar shows "CROP" with contextual hints

### Notes
- Crop resets undo history (canvas dimensions change)
- Crop resets zoom/pan to fit the new canvas size
- All layers are cropped to the selected region simultaneously

## Menu Bar

DRAW has an optional menu bar at the top of the screen providing access to all commands organized by category.

### Menu Bar Controls

| Key | Function |
|-----|----------|
| `Alt` (tap and release) | Open/close menu bar |
| `Ctrl+F11` | Toggle menu bar visibility |
| `Left/Right Arrow` | Navigate between menus (when open) |
| `Up/Down Arrow` | Navigate menu items (when open) |
| `Enter` | Execute selected menu item |
| `Escape` | Close menu |

### Menu Bar Features

- **Keyboard navigation**: Tap `Alt` to activate, then use arrow keys to browse
- **Mouse navigation**: Click menu labels to open, hover to switch menus
- **Hotkey hints**: Each menu item shows its keyboard shortcut on the right
- **Checkmarks**: Toggle items (grid, toolbar, etc.) show current state
- **Dividers**: Visual separators group related commands

### Menu Categories

| Menu | Contents |
|------|----------|
| **File** | New, Open, Import Image, Save, Save As, Export Layer, Export Brush, Exit |
| **Edit** | Undo, Redo, Cut, Copy, Paste, Select All, Deselect, Invert Selection, Flip H/V, Scale, Rotate 90° CW/CCW, Canvas Resize, Canvas Crop |
| **View** | Toolbar, Status Bar, Layer Panel, Menu Bar, Cursors, Grid, Pixel Grid, Snap, Crosshair, Reference Image (toggle/load/clear/reposition) |
| **Canvas** | Clear Canvas, Zoom In/Out, Reset Zoom |
| **Tools** | All drawing tools (Dot, Brush, Line, etc.) |
| **Palette** | Color Picker, Load Palette, Swap Colors |
| **Help** | Command Palette, Cheatsheet |

## UI Behavior

- **Auto-hide**: UI elements automatically hide when actively dragging tools over them
- **Manual hide**: Use Tab/F10/F11 to manually toggle UI (stays hidden until manually shown)
- **Toolbar clicks**: Clicking toolbar buttons only changes tools, doesn't activate them on canvas

## Toolbar Layout

The toolbar is displayed on the right edge of the screen as a 3-column, 7-row grid of icon buttons:

| Row | Left | Center | Right |
|-----|------|--------|-------|
| 1 | Save | Open | QB64 Code |
| 2 | Move (V) | Hand/Pan | Zoom (Z) |
| 3 | Marquee (M) | Picker (I) | Text (T) |
| 4 | Dot (D) | Brush (B) | Spray (K) |
| 5 | Line (L) | Polyline (P) | Poly Fill (Shift+P) |
| 6 | Fill (F) | Rect (R) | Rect Filled (Shift+R) |
| 7 | Help (?) | Ellipse (E) | Ellipse Filled (Shift+E) |

### Toolbar Button Actions

| Button | Left-click | Right-click | Middle-click |
|--------|-----------|-------------|--------------|
| **Marquee** | Rectangle selection | Magic Wand mode | - |
| **Text** | VGA font | Tiny5 font | Load custom font |
| **Open** | Open DRW project | Import image | - |
| **Hand/Pan** | Pan mode | - | Double-click resets zoom+pan |
| **Zoom** | Zoom tool mode | - | - |
| **Help** | Open command palette | - | - |

### Toolbar Scale

The toolbar can be scaled 1-4x via `TOOLBAR_SCALE` in `DRAW.cfg`.

## Command Palette

Press `?` to open the Command Palette - a searchable list of all commands and their hotkeys.

### Controls

| Key | Function |
|-----|----------|
| `?` | Open/close command palette |
| **Type** | Filter commands by name |
| `Up/Down Arrow` | Navigate results |
| `Enter` | Execute selected command |
| `Escape` | Close command palette |
| `Backspace` | Delete search character |

### Features

- **Fuzzy search**: Partial matches work (e.g., "br" finds "Brush", "Brush Size")
- **Category display**: Commands grouped by category (Tools, View, File, etc.)
- **Hotkey hints**: Shows keyboard shortcuts for each command
- **Real-time filtering**: Results update as you type
- **Visual feedback**: Selected command is highlighted
- **Scrollable list**: Use arrow keys to navigate through all matches

## Configuration File (DRAW.cfg)

DRAW stores settings in `DRAW.cfg` in the application directory. Settings are loaded at startup and can be saved on exit.

### Startup Defaults

| Setting | Description | Default |
|---------|-------------|---------|
| `DEFAULT_TOOL` | Tool selected at startup (1-18) | 3 (Brush) |
| `DEFAULT_BRUSH_SIZE` | Initial brush size (1-50) | 1 |
| `DEFAULT_LAYER_BG_COLOR` | Background color for new layers (hex AARRGGBB) | 00000000 (transparent) |
| `DEFAULT_SAVE_DIR` | Default directory for save dialogs | (empty = current dir) |
| `DEFAULT_OPEN_DIR` | Default directory for open dialogs | (empty = current dir) |
| `PALETTE_DEFAULT_FG_COLOR_INDEX` | Initial foreground color index | 15 |
| `PALETTE_DEFAULT_BG_COLOR_INDEX` | Initial background color index | 0 |

### Tool Numbers

| Value | Tool |
|-------|------|
| 1 | Dot |
| 2 | Picker |
| 3 | Brush |
| 4 | Fill |
| 5 | Line |
| 6 | Rectangle |
| 7 | Rectangle Filled |
| 8 | Ellipse |
| 9 | Ellipse Filled |
| 10 | Polygon |
| 11 | Polygon Filled |
| 12 | Marquee |
| 13 | Move |
| 14 | Text |
| 15 | Pan |
| 16 | Spray |
| 17 | Crop |
| 18 | Zoom |

### Other Notable Settings

| Setting | Description |
|---------|-------------|
| `CANVAS_W`, `CANVAS_H` | Canvas dimensions |
| `DISPLAY_SCALE` | Window scale multiplier (1-4) |
| `FPS_LIMIT` | Frame rate limit |
| `ANGLE_SNAP_DEGREES` | Angle snap increment for lines/polygons |
| `GRID_SIZE` | Grid cell size in pixels |
| `GRID_COLOR_FG` | Grid line color (hex RGB, 0=use theme) |
| `GRID_OPACITY` | Grid line opacity 0-255 (0=use theme) |
| `GRID_ANGLE` | Grid rotation angle in degrees (0=use theme) |
| `GRID_MODE` | Grid geometry mode (0=square, 1=diagonal, 2=isometric, 3=hex) |
| `GRID_CELL_FILL` | Grid cell fill mode (0=off, 1=on) |
| `PIXELGRID_COLOR_FG` | Pixel grid line color (hex RGB, 0=use theme) |
| `PIXELGRID_OPACITY` | Pixel grid line opacity 0-255 (0=use theme) |
| `CROSSHAIR_FG` | Crosshair line color (hex RGB, 0=use theme) |
| `CROSSHAIR_OPACITY` | Crosshair line opacity 0-255 (0=use theme) |
| `CROSSHAIR_ANGLE` | Crosshair rotation angle in degrees (0=use theme) |
| `TRANSPARENCY_CHECK_COLOR1` | Light checkerboard color (hex RGB) |
| `TRANSPARENCY_CHECK_COLOR2` | Dark checkerboard color (hex RGB) |
| `TRANSPARENCY_CHECK_SIZE_X` | Checkerboard square width (0=use theme) |
| `TRANSPARENCY_CHECK_SIZE_Y` | Checkerboard square height (0=use theme) |
| `MAX_LAYERS` | Maximum number of layers (1-64) |
| `LAYER_PANEL_WIDTH` | Width of layer panel in pixels |

## Command Line

DRAW can be launched with a file argument to automatically load an image or project:

```bash
# Load a DRAW project file
./DRAW.run myproject.draw

# Load an image file (PNG, BMP, JPG, GIF)
./DRAW.run image.png
```

| Extension | Behavior |
|-----------|----------|
| `.draw` | Loads as DRAW project (layers, palette, tool states) |
| `.png, .bmp, .jpg, .gif` | Loads image into current layer |

If the image is larger than the canvas, import placement mode is activated automatically.

## macOS Platform Notes

See [MAC-USERS-README.md](MAC-USERS-README.md) for macOS-specific behavior including:
- Ctrl+Click is converted to right-click by macOS (DRAW handles this for symmetry center)
- Command (⌘) key is not detected by QB64PE
- Running DRAW on Windows via Parallels may have OpenGL compatibility issues
