DRAW by Rick Christy <grymmjack@gmail.com>
==========================================

# REQUIRES QB64PE-v3.12+

```
DATA "XXXXXX  ", "XXXXXXXX", "XXXXXXXX", "XX  XX  XX", "  XX  XX  "
DATA "XX::::XX", "XX::::XX", "XX::::XX", "XX  XX  XX", "XX::  ::XX"
DATA "XX    XX", "XX  XX::", "XXXX  XX", "XX  XX  XX", "XX      XX"
DATA "XX    XX", "XX  ::XX", "XX::  XX", "XX  XX  XX", "XX      XX"
DATA "XXXXXXXX", "XX    XX", "XX    XX", "XXXX::XXXX", "::XX  XX::"
DATA "::::::::", "::    ::", "::    ::", "::::  ::::", "  ::  ::  "
```

DRAW is a pixel art editor written in QB64PE that can export images as sourcecode

## Features

### Drawing Tools
- **Brush/Dot** - Freehand drawing with adjustable size (1-50px) and shape (circle/square)
- **Line** - Draw straight lines
- **Rectangle** - Draw outlined or filled rectangles
- **Ellipse** - Draw outlined or filled ellipses/circles
- **Polygon** - Draw outlined or filled multi-point polygons
- **Fill** - Flood fill tool
- **Picker** - Color sampling/eyedropper
- **Marquee** - Rectangular selection with move and resize
- **Move** - Transform and position selected content
- **Text** - Text entry tool

### Grid System
- Adjustable grid overlay (2-50px spacing)
- Toggle grid visibility with `'` (apostrophe)
- Pixel grid for precise work at 400%+ zoom (`Shift+'`)
- Snap-to-grid mode with `;` (semicolon)
- Dynamic grid sizing with `.` (increase) and `,` (decrease)
- Both grids can be shown simultaneously at high zoom
- Status bar indicator shows grid size and snap state

### Color System
- 16-color EGA palette (keyboard shortcuts 0-9, !, @, #, $, %, ^, &)
- Custom color picker with true RGB support
- Click status bar swatches to open color picker
- Foreground and background color support
- Color indication in all cursor types

### Canvas & View
- 320x200 default canvas size
- Clear canvas: `Delete` (with prompt) or `Backspace` (instant)
- Infinite zoom levels (mouse wheel or Ctrl +/-)
- Pan with middle mouse button or spacebar + drag
- Keyboard panning with arrow keys
- Reset view with Ctrl+0 or double-click middle mouse
- Toggle UI elements (toolbar, status bar)

### Brush System
- Size adjustment: `[` decrease, `]` increase (1-50px)
- Shape toggle: `\` or `|` (circle/square)
- Preview mode: `` ` `` or `~` (shows outline + color preview)
- Pixel perfect mode: `F6` (removes L-corners for cleaner strokes)
- 4 brush presets (F1-F4)
- Visual cursor feedback with current color

### User Interface
- Auto-hiding toolbar and status bar during active drawing
- Manual UI toggle with Tab, F10, F11
- Status bar shows: tool, coordinates, zoom, grid state, colors
- Custom cursors for each tool with color indicators
- Smooth zoom and pan

## Quick Start

### Essential Controls

**Tools:** B (Brush), D (Dot), F (Fill), I (Picker), L (Line), R (Rectangle), E (Ellipse)  
**Colors:** 0-9 for quick palette access, or click status bar color swatches  
**Grid:** `'` (toggle), `Shift+'` (pixel grid), `;` (snap), `.` (bigger), `,` (smaller)  
**Brush Size:** `[` (smaller), `]` (bigger), F6 (pixel perfect)  
**Canvas:** Delete (clear with prompt), Backspace (clear instant)  
**View:** Mouse wheel (zoom), Middle click (pan), Ctrl+0 (reset)  
**Undo/Redo:** Ctrl+Z / Ctrl+Y

See [CHEATSHEET.md](CHEATSHEET.md) for complete controls reference.

## Building

```bash
qb64pe -w -x -o DRAW.run DRAW.BAS
```

## License

See LICENSE file for details.

