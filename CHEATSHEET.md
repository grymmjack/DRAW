# DRAW - Input Controls Cheatsheet

## Tool Selection (Keyboard)

| Key | Tool | Notes |
|-----|------|-------|
| `B` | Brush | Paintbrush tool |
| `D` | Dot | Single pixel dot tool |
| `F` | Fill | Flood fill tool |
| `I` | Picker | Color picker/eyedropper |
| `L` | Line | Draw straight lines |
| `P` | Polygon | Draw polygon outlines |
| `Shift+P` | Polygon (Filled) | Draw filled polygons |
| `R` | Rectangle | Draw rectangle outlines |
| `Shift+R` | Rectangle (Filled) | Draw filled rectangles |
| `E` | Ellipse | Draw ellipse outlines |
| `Shift+E` | Ellipse (Filled) | Draw filled ellipses |
| `M` | Marquee | Selection tool |
| `V` | Move | Transform selected region |
| `T` | Text | Text entry tool |

## Color Selection

### Keyboard Shortcuts
| Key | Color |
|-----|-------|
| `0-7` | Colors 0-7 |
| `8` or `)` | Color 8 |
| `9` or `!` | Color 9 |
| `@` | Color 10 |
| `#` | Color 11 |
| `$` | Color 12 |
| `%` | Color 13 |
| `^` | Color 14 |
| `&` | Color 15 |

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
| `.` (period) | Increase grid size (+1px, max 50px) |
| `,` (comma) | Decrease grid size (-1px, min 2px) |

**Notes:**
- Regular grid shows at 100%+ zoom when enabled
- Pixel grid shows at 400%+ zoom when enabled (fine grid around each pixel)
- Both grids can be shown simultaneously at high zoom levels
- Status bar shows grid state: `G:n` (visible) or `G:n S` (snap enabled)
- Snap-to-grid rounds all drawing coordinates to nearest grid boundary

## Symmetry Drawing

DRAW supports real-time symmetrical drawing with three modes: Vertical (|), Cross (+), and Asterisk (*). All drawing operations are automatically mirrored across the symmetry axes.

### Symmetry Controls

| Key | Function |
|-----|----------|
| `F7` | Cycle symmetry mode (Off → Vertical → Cross → Asterisk → Off) |
| `F8` | Turn off symmetry (instant disable) |
| `Ctrl + Left Click` | Reposition symmetry center to mouse location |

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
- Works great with dither patterns for complex symmetrical textures

## Mouse Controls

### General
| Action | Function |
|--------|----------|
| **Left Click** | Draw/Select/Activate tool |
| **Right Click** | Sample background color |
| **Middle Click** | Pan canvas (hold and drag) |
| **Double Middle Click** | Reset zoom and pan to default |
| **Mouse Wheel** | Zoom in/out |
| **Spacebar + Left Drag** | Pan canvas |

### Tool-Specific
| Tool | Action | Function |
|------|--------|----------|
| **Dot** | Shift + Right Click | Draw line from last point to current |
| **Picker** | Alt + Left Click | Temporarily activate picker |
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

## Dither Pattern Mode

DRAW includes 10 dither patterns (0-9) that can be applied to brush, dot, and fill tools. Patterns are tiled seamlessly across the entire canvas.

### Pattern Selection (NumLock ON or OFF)

| NumPad Key | Pattern | Description |
|------------|---------|-------------|
| `0` | Solid | No dithering (default) |
| `1` | Light Dots | Very sparse dots (6% fill) |
| `2` | Dots | Sparse dot pattern (12% fill) |
| `3` | Checkerboard | Fine alternating pixels (50% fill) |
| `4` | Medium Dots | Offset dot pattern (25% fill) |
| `5` | Grid | 2x2 box grid pattern |
| `6` | Horizontal | Alternating horizontal lines |
| `7` | Vertical | Alternating vertical lines |
| `8` | Diagonal \ | Diagonal backslash line |
| `9` | Checker 2x2 | Checkerboard with 2x2 blocks |

**Notes:**
- NumPad keys work with NumLock **ON** or **OFF**
- Active pattern shown in status bar: `[PATTERN NAME]`
- Pattern `0` disables dithering (solid fill)
- Brush preview shows active pattern at current brush size
- Patterns tile seamlessly across entire canvas using global coordinates
- Works with: Brush, Dot, filled shapes (Rectangle, Ellipse, Polygon), and Fill tool

### NumLock Indicator

| Status Bar | Meaning |
|------------|---------|
| `NUM` | NumLock is ON |
| (no indicator) | NumLock is OFF |

## Custom Brush

| Key | Function |
|-----|----------|
| `Ctrl+B` | Capture custom brush (drag to select area) |
| `F12` | Export active custom brush as PNG file |
| `Home` | Flip custom brush horizontally |
| `End` | Flip custom brush vertically |
| `Page Up` | Scale custom brush up |
| `Page Down` | Scale custom brush down |
| `/` | Reset custom brush scale to original size |

**Custom Brush Features:**
- Capture any rectangular area as a reusable brush pattern
- Automatic scaling to fit within 32x32 pixel limit (preserves aspect ratio)
- Works with LINE, RECTANGLE, ELLIPSE, and POLYGON tools
- Creates "beaded" or stamped effects along shape perimeters
- Flip horizontally or vertically for variations
- Scale up/down or reset to adjust brush size
- Exported PNG files use timestamp-based filenames for unique names
- Visual feedback with marching ants during capture
- Status bar shows brush preview when active

## Canvas Controls

| Key | Function |
|-----|----------|
| `Delete` | Clear canvas (with confirmation prompt) |
| `Backspace` | Clear canvas (no prompt) |

## View Controls

| Key | Function |
|-----|----------|
| `Tab` | Toggle toolbar visibility |
| `F10` | Toggle status bar visibility |
| `F11` | Toggle both toolbar and status bar |
| `Shift` | Show crosshair (when held) |
| `Ctrl+0` | Reset zoom to 100% and center |
| `Ctrl+=` | Zoom in 100% |
| `Ctrl+-` | Zoom out 100% |
| `Ctrl+2` | Set zoom to 200% |

## Drawing Modifiers

| Tool | Modifier | Effect |
|------|----------|--------|
| **Line/Rect/Ellipse** | Shift (drag) | Constrain to horizontal/vertical |
| **Rectangle** | Ctrl (drag) | Draw perfect square |
| **Rectangle** | Shift (drag center) | Draw from center |
| **Ellipse** | Ctrl (drag) | Draw perfect circle |
| **Ellipse** | Shift (drag center) | Draw from center |

## Clipboard Operations

| Key | Function |
|-----|----------|
| `Ctrl+C` | Copy selection to clipboard |
| `Ctrl+X` | Cut selection (copy + clear original with BG color) |
| `Ctrl+V` | Paste clipboard at mouse cursor (centered, engages Move tool) |
| `Ctrl+E` | Clear/erase selection (fill with background color) |

**Workflow:**
1. Use Marquee (`M`) to select an area
2. Copy (`Ctrl+C`) or Cut (`Ctrl+X`) the selection
3. Move mouse to desired location
4. Paste (`Ctrl+V`) - creates selection centered on cursor, auto-engages Move tool
5. Position content, press `Enter` to apply or `Escape` to cancel

## Marquee/Selection Controls

### Keyboard (when marquee active)
| Key | Function |
|-----|----------|
| Arrow Keys | Move selection (1px) |
| Shift + Arrows | Move selection (10px) |
| Ctrl + Arrows | Resize selection (1px) |
| Ctrl+Shift + Arrows | Resize selection (10px) |
| Ctrl+D | Deselect/clear marquee |

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

## Move/Transform Tool

| Key | Function |
|-----|----------|
| **Arrow Keys** | Move selection (1px) |
| **Shift + Arrows** | Move selection (10px) |
| **Ctrl + Arrows** | Resize/scale selection (1px) |
| **Ctrl+Shift + Arrows** | Resize/scale selection (10px) |
| **H** | Flip selection horizontally |
| **V** | Flip selection vertically |
| **Alt (hold)** | Clone mode (keeps original pixels) |
| **Enter** | Apply transformation and return to Marquee |
| **Escape** | Cancel current drag operation |

## Undo/Redo

| Key | Function |
|-----|----------|
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |

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
| **Enter** | Apply import to canvas |
| **Escape** | Cancel import |

### Visual Indicators
- **Dimmed overlay** shows the canvas area outside your placement box
- **Preview** shows the cropped/scaled image in real-time
- **Marching ants** border indicates the destination box
- **Resize handles** at corners and edges for mouse resizing

### Workflow Tips
- Use **wheel zoom** to magnify a specific area of the source image
- Use **Alt+Arrows** or **right-drag** to pan to different parts of the zoomed image
- Combine zoom and pan to precisely select which portion of an oversized image to use
- The image is scaled to fit your destination box while maintaining the current crop

## UI Behavior

- **Auto-hide**: UI elements automatically hide when actively dragging tools over them
- **Manual hide**: Use Tab/F10/F11 to manually toggle UI (stays hidden until manually shown)
- **Toolbar clicks**: Clicking toolbar buttons only changes tools, doesn't activate them on canvas
