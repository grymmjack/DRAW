DRAW by Rick Christy <grymmjack@gmail.com>
==========================================

# REQUIRES QB64PE-v4.x+

```
DATA "XXXXXX  ", "XXXXXXXX", "XXXXXXXX", "XX  XX  XX", "  XX  XX  "
DATA "XX::::XX", "XX::::XX", "XX::::XX", "XX  XX  XX", "XX::  ::XX"
DATA "XX    XX", "XX  XX::", "XXXX  XX", "XX  XX  XX", "XX      XX"
DATA "XX    XX", "XX  ::XX", "XX::  XX", "XX  XX  XX", "XX      XX"
DATA "XXXXXXXX", "XX    XX", "XX    XX", "XXXX::XXXX", "::XX  XX::"
DATA "::::::::", "::    ::", "::    ::", "::::  ::::", "  ::  ::  "
```

DRAW is a pixel art editor written in QB64PE that can export images as sourcecode

![DRAW GUI from v0.8.1](./GUI.png)

## Features

### Drawing Tools
- **Brush** - Continuous freehand painting with adjustable size (1-50px) and shape (circle/square)
- **Dot** - Single-pixel stamp tool (click to place, no drag painting)
- **Line** - Draw straight lines with brush size/shape, real-time thick preview, angle snapping
- **Rectangle** - Draw outlined or filled rectangles with brush size/shape
- **Ellipse** - Draw outlined or filled ellipses/circles with brush size/shape
- **Polygon** - Draw outlined or filled multi-point polygons with brush size/shape, angle snapping
- **Fill** - Flood fill tool
- **Spray** - Spray paint with brush-shaped nozzle tips, radius doubles per brush size level, custom brush stamp support, SHIFT axis constraint, circle preview
- **Picker** - Color sampling/eyedropper (hold ALT with any tool for temporary picker; ALT+left picks FG, ALT+right picks BG)
- **Marquee** - Rectangular selection with move and resize
- **Move** - Transform and position selected content with arrow keys, undo support, and ALT+drag clone stamping
- **Transform** - Universal flip H/V, rotate 90° CW/CCW, scale ±50% — works on layers, selections, or floating moves from any tool
- **Pan** - Dedicated canvas panning tool (hand)
- **Zoom** - Click to zoom in, Alt+click to zoom out, drag to zoom region
- **Clipboard** - Copy/Cut/Paste selections (Ctrl+C/X/V), Merged copy (Ctrl+Shift+C), Clear selection (Ctrl+E)
- **Text** - Text entry tool
- **Custom Brush** - Capture selection as reusable brush with flip/scale transforms, non-rectangular shapes via alpha channel, dynamic outline expansion
- **Reference Image** - Load a high-res image behind the canvas at adjustable opacity for tracing (`Ctrl+R` toggle, `Ctrl+Shift+Wheel` opacity, reposition via View menu); state persisted in `.draw` project files
- **Image Import** - Load images with interactive placement, rotation (90° CW/CCW), horizontal/vertical flip, zoom, pan, and resize — with live preview of all transformations
- **Crop** - Interactive canvas crop using marquee selection with dark overlay, resize handles, and size label; also supports canvas resize dialog
- **Canvas Resize** - Resize canvas to arbitrary dimensions via dialog (Canvas menu), preserving layer content at origin
- **Angle Snap** - Two modes: degree-based (configurable 15°/30°/45°/90° increments) and pixel-art (11 integer-ratio angles for clean pixel lines). Hold Ctrl+Shift to snap + bypass grid. Applies to Line, Polygon, and Brush/Dot connecting lines

### Grid System
- Adjustable grid overlay (2-50px spacing)
- Toggle grid visibility with `'` (apostrophe)
- Pixel grid for precise work at 400%+ zoom (`Shift+'`)
- Snap-to-grid mode with `;` (semicolon)
- **4 grid geometry modes**: Square, Diagonal (45°), Isometric (2:1 pixel art, 26.565°), Hexagonal — cycle with `Ctrl+'`
- **Ctrl+Shift bypasses grid snap** for freehand placement when snap-to-grid is enabled
- Grid alignment modes: Corner (snap to intersections) or Center (snap to cell centers) — toggle via View menu
- **Grid cell fill mode**: Fill tool fills individual grid cells (squares, diamonds, triangles, or hexagons) instead of flood fill — toggle via View menu
- Dynamic grid sizing with `.` (increase) and `,` (decrease)
- Both grids can be shown simultaneously at high zoom
- Configurable grid/pixel grid/crosshair color, opacity, and angle via DRAW.cfg
- Configurable transparency checkerboard colors and size
- Status bar indicator shows grid size, mode, and snap state

### Color System
- **Dynamic Palette System** - Load palettes from .GPL files (GIMP Palette format)
- **Palette Strip** - Shows current palette colors with scroll arrows for large palettes
- **Palette Dropdown** - Click palette name to switch between available palettes
- **Left-click swatch** - Select foreground color
- **Right-click swatch** - Select background color
- **Mouse wheel on strip** - Scroll through palette colors
- **SHIFT + wheel** - Fast scroll (32 colors at a time)
- Custom color picker with true RGB support
- Click status bar FG/BG swatches to open color picker
- Keyboard shortcuts 0-9, !, @, #, $, %, ^, & for quick color access

### Canvas & View
- Configurable canvas size (up to 4096x4096)
- Clear canvas: `Delete` (with prompt) or `Backspace` (instant)
- Infinite zoom levels (mouse wheel or Ctrl +/-)
- Pan with middle mouse button or spacebar + drag
- Scrollbars for canvases larger than the viewport
- Keyboard panning with arrow keys
- Reset view with Ctrl+0 or double-click middle mouse
- Toggle UI elements (toolbar, status bar, menu bar, layer panel)

### Brush System
- Size adjustment: `[` decrease, `]` increase (1-50px)
- Shape toggle: `\` or `|` (circle/square)
- Preview mode: `` ` `` or `~` (shows outline + color preview)
- Pixel perfect mode: `F6` (removes L-corners for cleaner strokes)
- 4 brush presets (F1-F4)
- Visual cursor feedback with current color

### Layer System
- Up to 32 layers with per-layer opacity, visibility, and blend mode
- **19 blend modes**: Normal, Multiply, Screen, Overlay, Add, Subtract, Difference, Darken, Lighten, Color Dodge, Color Burn, Hard Light, Soft Light, Exclusion, Vivid Light, Linear Light, Pin Light, Color, Luminosity
- Solo layer (Alt+click eye icon) and visibility swipe (drag across eye icons)
- Drag-and-drop layer reordering with visual feedback
- Opacity lock prevents drawing on transparent pixels (enforced by all drawing tools including shape tools)
- Select from current layer: Ctrl+Click a layer row to create a selection mask from its non-transparent pixels
- Merge down, merge visible, duplicate layers
- CTRL+Click layer to create selection from non-transparent pixels
- **Recent Files** - File menu tracks up to 10 recently opened projects with submenu navigation
- DRW project format: PNG with embedded `drAw` chunk — preserves layers, blend modes, opacity, palette, tool states, grid state, and reference image configuration while remaining viewable in any image viewer

### User Interface
- Themeable PNG icon toolbar (21 buttons in 3×7 grid)
- PNG cursors with theme-configurable hotspots and alpha transparency
- Layer panel with PNG icons (visibility, lock, action buttons)
- **Menu bar** with File, Edit, View, Select, Tools, Brush, Layers, Help menus and full keyboard navigation
- Submenus auto-position within menu bar bounds (no toolbar/panel overlap)
- Auto-hiding toolbar and status bar during active drawing
- Manual UI toggle with Tab, F10, F11 — toggling panels does not shift the canvas
- Status bar shows: tool, coordinates, zoom, grid state, colors
- Smooth zoom and pan
- Help button opens searchable command palette

## Quick Start

### Essential Controls

**Tools:** B (Brush), D (Dot/Stamp), F (Fill), I (Picker), K (Spray), L (Line), R (Rectangle), E (Ellipse), Z (Zoom)  
**Drawing:** Left-click draws with FG color, Right-click draws with BG color (all drawing tools)  
**Colors:** Left-click palette swatch for FG, Right-click for BG, `*` toggles transparent/eraser mode with color memory; hold ALT for temporary eyedropper  
**Palette:** Click palette name dropdown to switch palettes, SHIFT+wheel for fast scroll  
**Grid:** `'` (toggle), `Shift+'` (pixel grid), `;` (snap), `Ctrl+'` (cycle mode), `.` (bigger), `,` (smaller)  
**Brush Size:** `[` (smaller), `]` (bigger), F6 (pixel perfect)  
**Canvas:** Delete (clear with prompt), Backspace (clear instant)  
**View:** Mouse wheel (zoom), Middle click (pan), Ctrl+0 (reset)  
**Clipboard:** Ctrl+C (copy), Ctrl+X (cut), Ctrl+V (paste at cursor), Ctrl+E (clear)  
**Files:** Ctrl+N (new), Alt+O (open .draw), Ctrl+S (save), Ctrl+Shift+S (save as), Alt+X (exit)  
**Reference:** Ctrl+R (toggle), Ctrl+Shift+Wheel (opacity)  
**Undo/Redo:** Ctrl+Z / Ctrl+Y

See [CHEATSHEET.md](CHEATSHEET.md) for complete controls reference.

## Command Line

DRAW can be launched with a file argument to automatically load an image or project:

```bash
# Load a DRAW project file
./DRAW.run myproject.draw

# Load an image file (PNG, BMP, JPG, GIF)
./DRAW.run image.png

# File paths with spaces need quotes
./DRAW.run "path/to/my image.png"
```

Supported formats:
- **.draw** - DRAW project files (preserves layers, blend modes, palette, tool states)
- **.png, .bmp, .jpg, .jpeg, .gif** - Image files (loads into current layer)

### Command Line Options

| Argument | Description |
|----------|-------------|
| `--config <file>` / `-c <file>` | Load a specific config file instead of the default |
| `--config-upgrade` | Reconcile existing config with latest defaults (adds missing keys) |

```bash
# Use a specific config file
./DRAW.run --config DRAW.macOS.cfg

# Short form
./DRAW.run -c DRAW.linux.cfg

# Upgrade an existing config with new default settings
./DRAW.run --config-upgrade

# Upgrade a specific config file
./DRAW.run -c DRAW.macOS.cfg --config-upgrade

# Combine with a project file
./DRAW.run -c DRAW.macOS.cfg myproject.draw
```

### OS-Specific Configuration

DRAW automatically detects the operating system and looks for a platform-specific config file before falling back to `DRAW.cfg`:

| OS | Config File | Fallback |
|----|-------------|----------|
| macOS | `DRAW.macOS.cfg` | `DRAW.cfg` |
| Linux | `DRAW.linux.cfg` | `DRAW.cfg` |
| Windows | `DRAW.windows.cfg` | `DRAW.cfg` |

**Priority order:** `--config` argument > OS-specific config > `DRAW.cfg`

This allows you to maintain separate configurations per platform (e.g., different display scales, toolbar sizes) while sharing the same project directory across platforms.

### Auto-Detection

On first launch (or when no config file exists), DRAW auto-detects optimal settings:

- **Display scale** — Targets 90% of desktop, picks highest integer scale up to 4x where the viewport fits (manual override via `DISPLAY_SCALE` supports up to 8x)
- **Toolbar scale** — Calculated from viewport height (>=800px=4x, >=600px=3x, >=400px=2x, else 1x)
- **Screen dimensions** — Viewport = 90% of desktop ÷ scale, rounded to even pixels
- All auto-detected values are saved to the config file for consistent subsequent launches

## Building

```bash
qb64pe -w -x -o DRAW.run DRAW.BAS
```

## Installation

Each platform has an installer that registers `.draw` file associations, installs app icons, and creates launcher entries.

### Linux

```bash
chmod +x install-linux.sh
./install-linux.sh
```

Installs a `.desktop` launcher, registers the `application/x-draw-project` MIME type for `.draw` files, and installs icons into the hicolor theme. To uninstall:

```bash
./install-linux.sh --uninstall
```

### Windows

Right-click `install-windows.cmd` and select **Run as administrator** (or run from an elevated command prompt). Registers the `.draw` file association in the registry with the DRAW icon and adds a Start Menu shortcut. To uninstall:

```cmd
install-windows.cmd /uninstall
```

### macOS

```bash
chmod +x install-mac.command
./install-mac.command
```

Or double-click `install-mac.command` in Finder. Creates a `DRAW.app` bundle in `~/Applications`, registers `.draw` file associations via LaunchServices, and sets the app icon. To uninstall:

```bash
./install-mac.command --uninstall
```

> **macOS users:** There are platform-specific input differences on macOS. See [MAC-USERS-README.md](MAC-USERS-README.md) for details on Ctrl+Click behavior, Command key limitations, and Parallels compatibility.

## License

See LICENSE file for details.

