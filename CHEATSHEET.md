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
| **Type** | Enter text |
| **Enter** | New line |
| **Backspace** | Delete character |
| **Escape** | Apply/finish text |

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

## UI Behavior

- **Auto-hide**: UI elements automatically hide when actively dragging tools over them
- **Manual hide**: Use Tab/F10/F11 to manually toggle UI (stays hidden until manually shown)
- **Toolbar clicks**: Clicking toolbar buttons only changes tools, doesn't activate them on canvas
