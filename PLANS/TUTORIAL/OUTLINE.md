# OUTLINE.md

# 01 - 🎬 Introduction & Setup

## EP01: What Is DRAW? — Overview & Philosophy

### 🎯 Goal: Understand what DRAW is and why it exists

### Pixel art editor written in QB64-PE (BASIC!)

### Unique feature: exports artwork as QB64 source code

### Open source — GitHub repo walkthrough

### Inspired by classic DPaint / ProMotion / Deluxe Paint

### Cross-platform: Windows, Linux, macOS

### Feature highlights reel — quick demo of capabilities

### 64 layers, 19 blend modes, full text system

### Theming, audio, custom brushes, symmetry drawing

### Native .draw format (PNG with embedded project data)

## EP02: Getting DRAW — Download, Build & Install

### 🎯 Goal: Get DRAW running on your machine

### Option A: Download Pre-Built Release

- GitHub Releases page walkthrough
- Choose your platform (Win/Linux/Mac)
- Extract and run — zero dependencies

### Option B: Build From Source

- Install QB64-PE compiler
- Clone the DRAW repo
- Build command: qb64pe -w -x DRAW.BAS -o DRAW.run
- Makefile targets explained

### Platform-Specific Setup

- Linux: .desktop file + MIME type registration
- Windows: Registry + Start Menu installer
- macOS: install-mac.command walkthrough

### First launch — auto-detection of display & scale

### DRAW.cfg — where settings live

## EP03: Your First 5 Minutes — UI Tour

### 🎯 Goal: Navigate the interface confidently

### Screen Layout Overview

- Menu Bar (11 menus: File → Audio)
- Toolbar (4×7 grid, 28 tool buttons)
- Canvas (center — your drawing area)
- Palette Strip (bottom — color swatches)
- Status Bar (info: coords, zoom, tool, grid)
- Layer Panel (right side)

### Hidden Panels (toggle on/off)

- Organizer Widget — brush presets & toggles
- Drawer Panel — 30 reusable brush/pattern slots
- Edit Bar (F5) — quick edit actions
- Advanced Bar (Shift+F5) — 26+ toggles
- Preview Window (F4) — magnifier or floating
- Character Map (Ctrl+M) — glyph grid

### Docking system — Ctrl+Shift+Click to swap sides

### F11 = Toggle ALL UI / Ctrl+F11 = Menu only

### Tab = Toggle Toolbar visibility

### Command Palette ( ? key) — searchable command list

---

# 02 - 🖌️ Core Drawing Fundamentals

## EP04: Brush, Dot & Freehand Drawing

### 🎯 Goal: Master basic freehand pixel drawing

### Brush tool (B) — drag to paint freehand strokes

### Dot tool (D) — precision single-pixel stamps

### Brush size: [ and ] keys (1–50px)

### Brush shape: \ key (circle ↔ square)

### Brush preview: ` key (outline + color)

### Left-click = FG color / Right-click = BG color

### Shift = constrain to horizontal/vertical axis

### Shift+Right-Click = connecting line (last to current)

### Pixel Perfect mode (F6) — removes L-shaped corners

### 4 size presets in the Organizer widget

### 🎨 Exercise: Draw a simple sprite

- Start small: 16×16 character
- Use Dot for placement, Brush for fills
- Try different brush sizes for outlines vs fill

## EP05: Lines, Rectangles & Ellipses

### 🎯 Goal: Draw clean geometric shapes

### Line Tool (L)

- Click-drag = draw line preview
- Uses current brush size for thickness
- Shift = constrain H/V
- Ctrl+Shift = angle snap (15°/30°/45°)

### Rectangle Tool (R / Shift+R)

- R = outlined rectangle
- Shift+R = filled rectangle
- Ctrl = perfect square
- Shift (while drawing) = from center

### Ellipse Tool (C / Shift+C)

- C = outlined ellipse/circle
- Shift+C = filled ellipse
- Ctrl = perfect circle
- Shift (while drawing) = from center

### All shapes respect brush size & color

### All shapes support symmetry drawing

### 🎨 Exercise: Build a scene with shapes

- House: rectangles + triangle roof
- Sun: filled circle + lines for rays
- Ground: filled rectangle

## EP06: Polygons & Fill Tool

### 🎯 Goal: Draw complex shapes and fill regions

### Polygon Tool (P / Shift+P)

- P = outlined polygon
- Shift+P = filled polygon
- Click = add vertex point
- Enter = close and finish
- Ctrl+Shift = angle snap between points

### Flood Fill Tool (F)

- Click to fill contiguous same-color region
- Shift = sample from all visible layers (merged)
- Works with custom brushes (tiled fill!)
- Supports pattern and gradient paint modes

### Fill Adjustment Overlay (F8)

- Activate after filling with custom brush
- Drag canvas = reposition tile origin
- Mouse wheel = uniform scale
- L-handle = independent X/Y scale
- Rotation handle (arc drag)
- Enter = apply / Esc = cancel

### 🎨 Exercise: Create a tileable pattern

- Draw a small tile (8×8 or 16×16)
- Capture as custom brush
- Fill a large area with tiled fill
- Adjust with F8 overlay

## EP07: Spray Tool & Eraser

### 🎯 Goal: Use spray can effects and clean up mistakes

### Spray Tool (K)

- Spray paint with randomized dot placement
- Nozzle radius doubles per brush size level
- Density scales with radius
- Supports custom brush stamping
- Shift = constrain to axis

### Eraser Tool (E)

- Paints transparent pixels (reveals bg)
- Hold E = temporary eraser (any tool)
- Uses current brush size & shape
- Shift = Smart Erase (all visible layers!)
- Custom brush support for shaped erasing
- Status bar shows FG:TRN indicator

### Tip: Eraser + opacity lock = paint only on existing pixels

---

# 03 - 🎨 Color & Palette Mastery

## EP08: Color Basics — FG, BG & Palette Strip

### 🎯 Goal: Select, swap, and manage colors

### Left-click palette swatch = set FG color

### Right-click palette swatch = set BG color

### X key = swap FG ↔ BG colors

### Ctrl+D = reset to white FG / black BG

### Shift+Delete = set BG to transparent

### Mouse wheel on strip = scroll palette

### Shift+wheel = fast scroll (32 colors)

### ALT+Left-click = temp FG eyedropper (any tool)

### ALT+Right-click = temp BG eyedropper (any tool)

### Paint Opacity: keys 1-9 = 10-90%, 0 = 100%

### Per-stroke compositing (no compounding!)

## EP09: Color Picker, Color Mixer & Custom RGB

### 🎯 Goal: Use the full RGB color picker and live Color Mixer

### Click FG/BG swatches in status bar → open picker

### Picker tool (I) — eyedropper with loupe overlay

### Loupe shows RGB + hex values on hover

### True 24-bit RGB color selection

### Hex input support

### Invert colors command (toolbar)

### Color Mixer Panel (View → Color Mixer)

- Floating panel for live RGB/HSV color editing

- RGB sliders — adjust Red, Green, Blue independently

- HSV sliders — adjust Hue, Saturation, Value (brightness)

- Hex input field — type any hex color value directly

- FG/BG swatches — click to apply mixed color to foreground or background

- Stays open while drawing — tweak colors without interrupting your flow

- Visibility persisted in DRAW.cfg

## EP10: Palette Management — 56 Built-In Palettes

### 🎯 Goal: Switch, browse, and manage palettes

### Palette dropdown — click name to switch

### 56 bundled .GPL palettes (GIMP format)

### Classic palettes: NES, PICO-8, Commodore 64, Game Boy

### Letter keys jump to palette name in dropdown

### Palette Workflows

- Download from Lospec (online palette database)
- Create palette from existing image
- Import/Export .GPL files
- Remap existing artwork to new palette

## EP11: Palette Ops — Edit Colors Directly

### 🎯 Goal: Modify palette colors and remap on canvas

### Enable Palette Ops mode (Organizer toggle)

### Double-click = change color (replaces on canvas!)

### Right-click = mark color with indicator

### Middle-click = delete color (remap to nearest)

### Shift+Middle-click = insert transparent color

### Drag = rearrange palette order

### Left-click = magic wand select matching pixels

### Auto [DOCUMENT] palette creation

### Snapshot/restore for safe experimentation

---

# 04 - 📚 Layer System Deep Dive

## EP12: Layer Basics — Create, Delete & Reorder

### 🎯 Goal: Work with multiple layers

### Up to 64 layers — enormous creative flexibility

### New Layer (Ctrl+Shift+N)

### Delete Layer (Ctrl+Shift+Delete)

### Duplicate Layer (Ctrl+Shift+D)

### Drag & drop to reorder in layer panel

### Move Up/Down (Ctrl+PgUp/PgDn)

### Arrange to Top/Bottom (Ctrl+Home/End)

### Right-click layer = context menu

### Rename layers (right-click → Rename)

### 🎨 Exercise: Multi-layer sprite

- Layer 1: Background/scene
- Layer 2: Character outline
- Layer 3: Character colors
- Layer 4: Highlights/effects

## EP13: Opacity, Visibility & Opacity Lock

### 🎯 Goal: Control layer transparency and protection

### Opacity bar — drag or mouse wheel (0–100%)

### Eye icon = toggle visibility

### Alt+click eye = Solo mode (hide all others)

### Drag across eye icons = swipe visibility

### Lock icon = Opacity Lock (draw only on existing pixels)

### Great for recoloring without changing shape

### 🎨 Demo: Opacity lock workflow

- Draw character on one layer
- Enable opacity lock
- Paint new colors — stays within outline!

## EP14: Blend Modes — 19 Modes Explained

### 🎯 Goal: Understand and use blend modes creatively

### Basic Modes

- Normal — standard opaque overlay
- Multiply — darken (shadows, ambient occlusion)
- Screen — lighten (glow, highlights)
- Overlay — contrast boost

### Math Modes

- Add (Linear Dodge) — bright glow effects
- Subtract — remove light
- Difference — psychedelic color inversion

### Comparison Modes

- Darken — keep darker of two pixels
- Lighten — keep lighter of two pixels

### Dodge/Burn & Light Modes

- Color Dodge / Color Burn
- Hard Light / Soft Light
- Vivid Light / Linear Light / Pin Light

### Color Modes

- Exclusion — soft difference
- Color — apply hue+saturation, keep luminance
- Luminosity — apply brightness, keep color

### Shift+Right-Click layer row = cycle blend mode

### 🎨 Exercise: Lighting with blend modes

- Base sprite on layer 1
- Shadows layer: Multiply mode
- Highlights layer: Screen or Add mode
- Color wash layer: Color mode

## EP15: Layer Groups & Advanced Operations

### 🎯 Goal: Organize complex artwork with groups

### Layer Groups

- Create group (Ctrl+G)
- Group from selected layers (Ctrl+Shift+G)
- Ungroup (Ctrl+Shift+U)
- Collapse/expand with triangle toggle
- Drag layers into/out of groups
- Arbitrary nesting depth
- Pass Through blend mode for groups

### Merge Operations

- Merge Down (Ctrl+Alt+E)
- Merge Visible (Ctrl+Alt+Shift+E)
- Merge Selected layers
- Merge Group to single layer

### Multi-Layer Select

- Ctrl+Click = toggle individual selection
- Shift+Click = range selection
- Bulk ops: clear, fill, flip, scale, rotate
- Select All in Group

### Layer Alignment & Distribution

- Align Left / Center / Right
- Align Top / Middle / Bottom
- Distribute Horizontally / Vertically

### Symbol Layers

- Symbol Parent + one or more Symbol Children

- Draw on the parent → all children auto-sync

- Children can be independently scaled and repositioned

- Rasterize: bake a symbol child into a normal pixel layer

- Detach: break the sync link — child becomes independent

- Useful for repeated elements (coins, enemies, tiles, UI components)

- Created via Layer menu → New Symbol Layer / Convert to Symbol

---

# 05 - ✂️ Selection & Clipboard

## EP16: Selection Tools — Marquee, Freehand & Wand

### 🎯 Goal: Select regions for editing and manipulation

### Marquee Tool (M)

- Drag = create rectangular selection
- Shift+Drag = add to selection (union)
- Alt+Drag = subtract from selection
- Resize handles on selection edges
- Drag inside = move selection
- Arrow keys = nudge (1px, Shift=10px)

### Freehand Select — draw selection boundary

### Polygon Select — click-to-point boundary

### Ellipse Select — oval selection area

### Magic Wand (W)

- Click = select contiguous same-color pixels
- Shift+Click = add to selection
- Alt+Click = subtract from selection
- Hold F+Click = instant flood fill with FG
- Hold E+Click = instant erase to transparent
- Hold W+Click = select from merged canvas

### Select All (Ctrl+A) / Deselect (Ctrl+D)

### Invert Selection (Ctrl+Shift+I)

### Expand / Contract selection

### Selection from current layer (non-transparent pixels)

### Selection from selected layers (union mask)

### Selections clip ALL drawing tools (marching ants)

## EP17: Copy, Cut, Paste & Clipboard Power

### 🎯 Goal: Master clipboard operations

### Copy (Ctrl+C) — selection to clipboard

### Cut (Ctrl+X) — copy + clear

### Paste (Ctrl+V) — at cursor, auto-engages Move tool

### Paste in Place (Ctrl+Alt+Shift+V) — same position

### Copy Merged (Ctrl+Shift+C) — all visible layers

### Copy to New Layer (Ctrl+Alt+C)

### Cut to New Layer (Ctrl+Alt+X)

### Paste from OS Clipboard (Ctrl+Shift+V)

### Clear/Erase (Ctrl+E or Delete)

### Stroke Selection (Edit menu)

- Add stroke around selection boundary
- Configurable width (px)
- Position: inside / outside / center
- FG or custom color

---

# 06 - 🔄 Transforms & Image Adjustments

## EP18: Quick Transforms — Flip, Rotate & Scale

### 🎯 Goal: Transform layers and selections quickly

### Flip Horizontal (H key)

### Flip Vertical (Ctrl+Shift+H)

### Rotate 90° CW (> key)

### Rotate 90° CCW (< key)

### Scale Up 50% (Ctrl+Shift+=)

### Scale Down 50% (Ctrl+Shift+-)

### All work on single or multi-selected layers

### Canvas-level flip in Image menu (affects ALL layers)

## EP19: Transform Overlay — Scale, Rotate, Distort

### 🎯 Goal: Use the interactive on-canvas transform tool

### Activate: Edit → TRANSFORM (or command palette)

### 5 Transform Modes

- Scale — drag handles, Shift = lock aspect ratio
- Rotate — drag outside box, Shift = 15° snap
- Shear — drag edges to skew
- Distort — move corners independently
- Perspective — Shift = wall projection

### Themeable frame and handles

### Enter = apply / Esc = cancel

### Full undo support after applying

## EP20: Move Tool & Smart Guides

### 🎯 Goal: Reposition content precisely

### Move Tool (V)

- Drag to reposition layer content
- Arrow keys = nudge 1px (Shift = 10px)
- Alt+Drag = clone stamp (duplicate while moving)
- Ctrl+Arrows = resize
- Shift+Click = auto-select topmost layer

### Smart Guides

- Alignment lines when moving layers
- Snap to canvas edges and centers
- Snap to other layer edges
- Toggle visibility: Ctrl+Shift+;
- Toggle snap: Ctrl+;
- Themeable colors and opacity

## EP21: Image Adjustments — Color Correction & Effects

### 🎯 Goal: Apply per-layer color adjustments

### Dialog-Based (Live Preview)

- Brightness / Contrast
- Hue / Saturation
- Levels (Black/White/Gamma)
- Color Balance (Shadows/Mid/Highlights)
- Blur (Gaussian, adjustable radius)
- Sharpen (adjustable intensity)

### One-Shot Adjustments

- Invert (RGB negative)
- Desaturate (luminosity grayscale)
- Posterize (N levels + dithering options)
- Pixelate (block cell size)
- Remove Background

### Mouse wheel on sliders for fine control

### Alpha channel always preserved

### Ctrl+Z = undo any adjustment

---

# 07 - 📝 Text System

## EP22: Text Tool Basics — Fonts & Entry

### 🎯 Goal: Add text to your pixel art

### Text tool (T) — click to place text cursor

### Type to enter text, Enter for new line

### Escape = apply and finish

### Built-in Fonts

- VGA (T key) — classic 8×8 monospace
- Tiny5 (Shift+T) — minimal 5×5
- Custom TTF/OTF (Ctrl+T, Middle-click to load)

### Color Bitmap Fonts (24 bundled)

- DPaint-style .bmp spritesheet fonts
- Preserve original pixel colors
- Fixed native glyph height
- PSF, BDF, Fontaption formats supported

### Text Property Bar — font dropdown, size, toggles

## EP23: Rich Text — Per-Character Formatting

### 🎯 Goal: Apply advanced text formatting

### Selection Methods

- Shift+Arrow = select characters
- Double-click = select word
- Triple-click = select line
- Quad-click = select all
- Ctrl+A = select all

### Per-Character Properties

- Bold / Italic / Underline / Strikethrough
- Outline (color + size)
- Shadow (color + X/Y offset 1-10px)
- Per-character FG/BG colors
- Letter spacing / line height

### Auto-wrap mode

### Style Presets — Save/Load/Update/Delete

### Text-local undo/redo (Ctrl+Z/Y, 128 states)

### Sound feedback on keystroke

## EP24: Text Layers & Character Mode

### 🎯 Goal: Master persistent text and ANSI-style art

### Text Layers

- Click existing text layer to re-edit
- Persisted in .draw files
- Full undo/redo support
- Rasterize single or all text layers
- New Text Layer from Layer menu

### Character Mode (useChars)

- Virtual cursor — free grid navigation
- F1-F12 = ANSI block characters (░▒▓█▀▄▌▐)
- Font stickiness while navigating
- DOT/RECT drawing fills cells with glyphs
- Alt+U = pick colors from character at cursor
- Character grid overlay with snap

### Character Map Panel (Ctrl+M)

- 16×16 glyph grid (256 characters)
- Click glyph = insert or use as custom brush
- Dockable left/right
- Unicode/CP437 mode toggle (Ctrl+Shift+U)

---

# 08 - 📐 Grid, Symmetry & Drawing Aids

## EP25: Grid System — 4 Geometry Modes

### 🎯 Goal: Use grids for precise pixel art layout

### Grid toggle: ' (apostrophe)

### Pixel grid: Shift+' (shows at 400%+ zoom)

### Snap-to-grid: ; (semicolon)

### Grid size: . (increase) , (decrease) — 2 to 50px

### 4 Geometry Modes (Ctrl+')

- Square (default) — standard tile grid
- Diagonal — 45° rotated diamonds
- Isometric — 2:1 pixel art standard
- Hexagonal — flat-top hexagons

### Alignment: Corner (intersections) vs Center (cells)

### Grid Cell Fill Mode

- Fills squares, diamonds, triangles, or hexagons
- Depends on current geometry mode

### Ctrl+Shift = bypass grid snap for freehand

### Grid state saved in .draw files

### 🎨 Demo: Isometric pixel art with grid

- Set isometric mode + snap
- Draw iso cube / building
- Grid guides perfect 2:1 angles

## EP26: Symmetry Drawing — Mirror & Kaleidoscope

### 🎯 Goal: Create symmetrical art effortlessly

### Cycle modes with F7: Off → | → + → *

### Symmetry Modes

- Vertical | — 2 copies (bilateral symmetry)
- Cross + — 4 copies (quad symmetry)
- Asterisk * — 8 copies (kaleidoscope)

### Ctrl+Click = reposition symmetry center

### Visual guide lines and crosshair

### Works with ALL drawing tools

### F8 = disable symmetry (or open fill adjust)

### Status bar shows SYM:0/1/2/3

### 🎨 Demo: Mandala creation

- Set asterisk mode (8-way)
- Center on canvas
- Draw one slice — 8 copies appear instantly
- Layer blend modes for complexity

## EP27: Drawing Aids — Angle Snap, Crosshair & Assists

### 🎯 Goal: Use helpers for clean, precise artwork

### Angle Snap (Ctrl+Shift while drawing)

- Degree mode: 15°/30°/45°/90° snapping
- Pixel Art mode: integer ratio angles (clean lines)
- Works: Line, Polygon, Brush, Dot connecting lines
- Configurable in DRAW.cfg

### Crosshair Assistant

- Hold Shift to display
- Configurable: color, opacity, width
- Outline stroke for visibility on any bg

### Pixel Perfect mode (F6) — cleanest edges

### Grayscale Preview (Ctrl+Alt+Shift+G) — check values

### Pattern Tile Mode (Shift+Tab) — seamless texture preview

### Canvas border toggle (# key)

---

# 09 - 🪄 Custom Brushes & Drawer Panel

## EP28: Custom Brushes — Capture, Transform & Paint

### 🎯 Goal: Create and use custom brushes

### Creating Custom Brushes

- Make a selection → capture as brush
- Select from Current Layer (non-transparent pixels)
- Select from Selected Layers (union)
- Non-rectangular shapes via alpha channel

### Brush Transform Controls

- Flip H (Home) / Flip V (End)
- Scale Up (PgUp) / Scale Down (PgDn)
- Reset Scale ( / key)

### Recolor Mode (F9) — paint brush in FG color

### Outline Mode (Shift+O) — add BG-colored outline

### Export as PNG (F12)

### Works with Line, Rect, Ellipse, Poly, Fill, Spray

### Custom brush + tiled fill = powerful patterns

## EP29: Drawer Panel — 30 Reusable Slots

### 🎯 Goal: Organize and reuse brushes and patterns

### 3 Drawer Modes

- Brush Mode (F1) — stamp and paint
- Gradient Mode (F2) — color transitions
- Pattern Mode (F3) — tiled fill patterns

### Shift+Left-Click = store current brush to slot

### Right-Click = context menu (load, save, clear)

### Load Images — batch import to slots

### Drag & Drop to reorder slots

### .dset Import/Export — share brush sets

### Mini Palette in drawer

### 1-Bit Patterns (opaque background)

### Paint Modes

- Normal (solid color)
- Pattern (from drawer slot)
- Gradient (from drawer slot)

### Dithering Algorithms

- Ordered (Bayer 2×2, 4×4, 8×8)
- Floyd-Steinberg error diffusion
- Atkinson / Stucki / Blue Noise

---

# 10 - 💾 File I/O & Export

## EP30: Opening & Saving — Formats Explained

### 🎯 Goal: Understand all file format options

### Open/Import

- Open Image (Ctrl+O) — PNG/BMP/JPG/GIF
- Open Project (Alt+O) — .draw format
- Open Aseprite (.ase/.aseprite)
- Open Photoshop (.psd)
- Import Image — oversized interactive placement
- Drag & Drop files onto window (Windows)
- Command line argument

### Save Options

- Save (Ctrl+S) — silent resave
- Save As (Ctrl+Shift+S) — prompt new name
- Export Selection (Ctrl+Alt+Shift+S)
- Export Layer as PNG
- Export Brush as PNG (F12)

### Recent Files — up to 10, Alt+1-0 quick access

### New from Template

## EP31: The .draw Format — PNG with Superpowers

### 🎯 Goal: Understand the native DRW project format

### PNG file with embedded drAw chunk — viewable anywhere!

### Preserves Everything

- All layers + blend modes + opacity
- Palette state and [DOCUMENT] palette
- Tool states, grid settings, snap
- Reference image configuration
- Text layer data (re-editable!)
- Extract images settings
- Character mode state

### Flattened preview visible in any image viewer

### Version tracking for forward compatibility

## EP32: Export As — 9 Image Formats

### 🎯 Goal: Export artwork in various formats

### PNG Native — with embedded drAw chunk

### PNG Plain — standard PNG (no metadata)

### GIF — animated or static

### JPEG — lossy compression

### TGA — Truevision (game dev friendly)

### BMP — Windows Bitmap

### HDR — High Dynamic Range

### ICO — Windows Icon format

### QOI — Quite OK Image (modern lossless)

### QB64 Source Code Export — artwork as BASIC code!

## EP33: Extract Images — Sprite Sheet Decomposition

### 🎯 Goal: Extract sprites from sheets or compositions

### Extraction Methods

- Flood-fill connected regions (auto-detect sprites)
- Per-layer extraction (each layer = one image)
- Merged extraction (visible layers)

### Background Options

- Transparent
- FG color
- BG color

### Output as separate PNG files

### Settings persisted in .draw files

---

# 11 - 🖥️ Canvas & View Controls

## EP34: Zoom, Pan & Navigation

### 🎯 Goal: Navigate canvases of any size efficiently

### Zoom Controls

- Ctrl+Mouse wheel
- Ctrl+= (in) / Ctrl+- (out)
- Ctrl+0 = reset to 100%
- Zoom tool (Z): click in, Alt+click out, drag region
- Snap levels: 25% through 800%

### Pan Controls

- Middle mouse drag (any tool!)
- Spacebar + drag (any tool!)
- Arrow keys for keyboard panning
- Double-middle-click = reset pan+zoom

### Scrollbars for large canvases

### Canvas border toggle (# key)

## EP35: Preview Window, Tile Mode & View Options

### 🎯 Goal: Use preview and tiling for workflow efficiency

### Preview Window (F4)

- Follow Mode — magnified cursor follower
- Floating Image Mode — reference display
- Bin Quick Look — hover drawer slots
- Color Picking (Alt+Click in preview)
- Recent preview images (up to 10)
- Independent zoom/pan
- Resizable and repositionable

### Pattern Tile Mode (Shift+Tab) — 3×3 tiled, up to 512×512

### Grayscale Preview (Ctrl+Alt+Shift+G)

### Reference Image (Ctrl+R) — trace with adjustable opacity

### Canvas Fill & Clear

- Delete = Edit > Clear (clears active selection, or whole layer if no selection; no prompt)

- Backspace = fill with foreground color (instant, no prompt)

- Shift+Backspace = fill with background color (instant)

### Canvas crop — interactive with handles

### Canvas resize dialog (Image menu)

---

# 12 - ⚙️ UI Customization & Settings

## EP36: Settings Dialog — All 8 Tabs Explained

### 🎯 Goal: Configure DRAW to your preferences

### Open: Ctrl+Comma or Edit → Settings

### Tab 1: General — display scale, fullscreen, FPS, UI scaling

### Tab 2: Grid — size, geometry, alignment, snap, crosshair

### Tab 3: Palette — defaults, recent, Lospec visibility

### Tab 4: Panels — default visibility for all panels

### Tab 5: Audio — SFX/music enable, volume, mute

### Tab 6: Fonts — default font, size, TTF/OTF directories

### Tab 7: Appearance — theme selection, color scheme

### Tab 8: Directories — template/palette/music folders

### DRAW.cfg — plain text config, hand-editable

### OS-specific configs: DRAW.linux.cfg, .macOS.cfg, .windows.cfg

### --config flag for custom config file path

### --config-upgrade to reconcile with new defaults

## EP37: Theming — Icons, Colors & Sounds

### 🎯 Goal: Customize DRAW's look and feel

### All UI colors fully themeable

### PNG icons replaceable per theme

### Sound files customizable per theme

### Music folder per theme

### THEME.CFG — no recompile needed

### Layer panel, transform overlay, smart guides — all themeable

### Display Scale (1x-8x) and Toolbar Scale (1x-4x)

## EP38: Panel Layout & Docking

### 🎯 Goal: Arrange panels for your workflow

### Dockable Panels

- Toolbox — left/right (Tab toggle)
- Layer Panel — left/right (Ctrl+L toggle)
- Edit Bar — left/right (F5)
- Advanced Bar — left/right (Shift+F5)
- Character Map — left/right (Ctrl+M)

### Ctrl+Shift+Click = toggle dock side

### F11 = toggle all UI / Ctrl+F11 = menu only

### Quick Side-Panel Hide Shortcuts

- Ctrl+Shift+Left = hide/show left-side panels (edit bar, layer panel)

- Ctrl+Shift+Right = hide/show right-side panels (toolbar, organizer, drawer)

- Ctrl+Shift+Up = hide/show menu bar

- Ctrl+Shift+Down = hide/show status bar and color strip

### Auto-hide panels while drawing

### Cursor system: OS native for UI, custom for tools

---

# 13 - 🔊 Audio — Music & Sound Effects

## EP39: Audio System — SFX, Music & Customization

### 🎯 Goal: Configure the creative audio experience

### Sound Effects (21 categorized slots)

- Menus, tools, selection, fill, clipboard
- Layer ops, text entry, sliders, drag-drop
- Per-theme replaceable WAV/OGG files
- Enable/disable + volume + mute

### Background Music

- Tracker formats: .mod .xm .it .s3m .rad
- Auto-shuffle — random track on song end
- Next ( } ) / Prev ( { ) / Random track
- Volume up/down (±10%), independent of SFX
- NOW PLAYING display in Audio menu
- Explore Music Folder (open in file manager)

### Audio menu — rightmost in menu bar

### All settings persist in DRAW.cfg

---

# 14 - 🔍 Pixel Art Analyzer

## EP40: Pixel Art Analyzer — Find & Fix Common Issues

### 🎯 Goal: Improve pixel art quality with automated analysis

### Detection Categories

- Orphan Pixels — isolated single-pixel noise
- Jagged Lines — uneven stepped edges
- Banding — unwanted color gradient striping
- Pillow Shading — unrealistic "pillow" 3D effect
- Doubles — redundant pixel repetition

### Precompute engine for fast analysis

### Visual feedback highlighting problem areas

### Interactive dialog with detailed results

### 🎨 Demo: Before/After cleanup

- Analyze a rough sprite
- Identify issues in overlay
- Fix each category, re-analyze

---

# 15 - 🖼️ Reference Image & Import

## EP41: Reference Image — Tracing Made Easy

### 🎯 Goal: Use reference images for tracing/study

### Toggle reference: Ctrl+R

### Ctrl+Shift+Wheel = adjust opacity (5-100%)

### Reposition mode: drag, zoom, nudge

### Renders behind all layers (non-destructive)

### Persisted in .draw files

### 🎨 Demo: Pixel art from photo reference

- Load photo as reference
- Set ~50% opacity for tracing
- Create pixel art interpretation on layers above

## EP42: Image Import — Oversized Placement & Transform

### 🎯 Goal: Import and position external images

### Import places image for interactive positioning

### Zoom + pan within imported image

### Rotate 90° CW/CCW within import

### Flip horizontal/vertical

### Resize destination box with handles

### Live preview of all transforms

### Aseprite (.ase/.aseprite) import

### Photoshop (.psd) import

---

# 16 - ⌨️ Keyboard Shortcuts & Command Palette

## EP43: Command Palette — 200+ Commands at Your Fingertips

### 🎯 Goal: Access any command instantly

### ? key = open Command Palette

### Fuzzy search matching on command names

### Hotkey display for every command

### Alt+? = Quick Reference Mode (all commands listed)

### Categories

- Tools, File, Edit, View, Color, Brush
- Layer, Canvas, Assist, Grid, Symmetry
- Select, Help, Image, Audio

## EP44: Keyboard Shortcuts Cheat Sheet

### 🎯 Goal: Memorize the essential shortcuts

### Tool Selection (single key)

- B=Brush, D=Dot, L=Line, R=Rect, C=Ellipse
- P=Polygon, F=Fill, K=Spray, I=Picker
- E=Eraser, M=Marquee, W=Wand, V=Move
- Z=Zoom, T=Text

### Essential Combos

- Ctrl+S/O/N/Z/Y — Save/Open/New/Undo/Redo
- Ctrl+C/X/V — Copy/Cut/Paste
- Ctrl+A/D/E — Select All/Deselect/Clear
- Ctrl+L — Toggle Layer Panel
- [ ] — Brush Size  /  \ — Brush Shape
- X — Swap FG/BG  /  0-9 — Paint Opacity
- ' ; . , — Grid controls
- F4-F9, F11 — Panel and mode toggles
- Tab — Toggle Toolbar
- ? — Command Palette

### See CHEATSHEET.md for the complete list

---

# 17 - ↩️ Undo, Redo & History

## EP45: History System — Fearless Experimentation

### 🎯 Goal: Understand the unified undo/redo system

### Ctrl+Z = Undo / Ctrl+Y = Redo

### Unified history — one timeline for everything

### Auto-record on mouse release (no manual save)

### Multi-layer undo for operations affecting multiple layers

### Text-local undo — separate 128-state history while typing

### Smart erase has per-layer history tracking

### History labels describe each action

### Experiment freely — you can always go back!

---

# 18 - 🎓 Real-World Pixel Art Workflows

## EP46: Workflow — Game Sprite (16×16 Character)

### 🎯 Goal: Create a complete game character sprite

### Step-by-Step

- 1. New canvas: 16×16, grid=1, snap on
- 2. Choose a limited palette (NES or PICO-8)
- 3. Layer 1: Silhouette outline (dark color)
- 4. Layer 2: Base colors (opacity lock for clean fills)
- 5. Layer 3: Shading (Multiply blend mode)
- 6. Layer 4: Highlights (Screen blend mode)
- 7. Run Pixel Art Analyzer — fix issues
- 8. Export as PNG for your game engine

## EP47: Workflow — Seamless Tile Texture

### 🎯 Goal: Create a tileable background pattern

### Step-by-Step

- 1. New canvas: 32×32 or 64×64
- 2. Enable Pattern Tile Mode (Shift+Tab)
- 3. Draw base pattern (see 3×3 repeat live)
- 4. Fix seams at edges using tile preview
- 5. Custom brush from tile → tiled fill test
- 6. Export as PNG tile

## EP48: Workflow — Isometric Pixel Art

### 🎯 Goal: Create isometric buildings/objects

### Step-by-Step

- 1. Set grid to Isometric mode (Ctrl+')
- 2. Enable snap-to-grid (;)
- 3. Grid guides ensure perfect 2:1 ratio
- 4. Use Polygon for angled surfaces
- 5. Separate layers for top/left/right faces
- 6. Blend modes for light/shadow
- 7. Group layers per object

## EP49: Workflow — Symmetrical Mandala / Pattern

### 🎯 Goal: Create complex symmetrical artwork

### Step-by-Step

- 1. Enable 8-way symmetry (F7 × 3 = asterisk)
- 2. Center symmetry point (Ctrl+Click canvas center)
- 3. Draw one slice — instant 8-fold reflection
- 4. Multiple layers with different blend modes
- 5. Opacity variations for depth
- 6. Custom brush stamps for detail

## EP50: Workflow — ANSI/Text Art with Character Mode

### 🎯 Goal: Create text-mode art using block characters

### Step-by-Step

- 1. Switch to VGA font (T key)
- 2. Enable Character Mode
- 3. Open Character Map (Ctrl+M)
- 4. Use F1-F12 for ANSI block chars (░▒▓█▀▄)
- 5. Navigate with virtual cursor
- 6. Alt+U to pick colors from existing chars
- 7. DOT/RECT tools fill cells with glyphs
- 8. CP437 mode for classic DOS art feel

## EP51: Workflow — Sprite Sheet Assembly & Export

### 🎯 Goal: Assemble sprites into a sheet and extract

### Step-by-Step

- 1. Create individual sprites on separate layers
- 2. Use grid + snap for consistent spacing
- 3. Layer groups per animation frame
- 4. Align & Distribute for perfect layout
- 5. Export full sheet as PNG
- 6. Use Extract Images to decompose into individual PNGs
- 7. Save as .draw to preserve layers for future edits

## EP52: Workflow — Photo to Pixel Art

### 🎯 Goal: Convert a photograph into pixel art

### Step-by-Step

- 1. Load photo as Reference Image (Ctrl+R)
- 2. Choose a limited palette (e.g., Endesga 32)
- 3. Set reference opacity to ~60%
- 4. Trace key shapes with lines/polygons
- 5. Fill regions with flood fill
- 6. Add detail with brush/dot tools
- 7. Image Adjustments for color tweaking
- 8. Posterize for pixel-art-friendly values
- 9. Hide reference to evaluate result

---

# 19 - 💡 Tips, Tricks & Advanced Techniques

## EP53: 10 Time-Saving Tips You Need to Know

### 🎯 Goal: Boost productivity with pro tips

### Tip 1: ALT+Click = instant color picker from any tool

### Tip 2: Middle-click = pan without switching tools

### Tip 3: Hold E = temporary eraser (release to return)

### Tip 4: Shift+RClick = connecting line (join distant points)

### Tip 5: Command Palette (?) = faster than menu diving

### Tip 6: Opacity Lock + big brush = instant recolor

### Tip 7: Custom brush tiled fill = instant pattern fills

### Tip 8: Ctrl+Shift+C = Copy Merged (flatten to clipboard)

### Tip 9: Double-middle-click = instant zoom/pan reset

### Tip 10: .draw format = PNG you can open in any viewer

## EP54: Advanced Layer Techniques

### 🎯 Goal: Push the layer system to its limits

### Non-destructive color adjustment layers (workflow)

### Group opacity for complex transparency effects

### Pass Through mode — groups that blend naturally

### Alt+Drag with Move = clone stamping across layers

### Solo mode for isolated editing (Alt+Click eye)

### Multi-layer selection + bulk transform

### Layer alignment for sprite sheet layout

## EP55: Series Wrap-Up — What's Next?

### 🎯 Goal: Recap and look ahead

### Series recap — all 54 episodes summarized

### DRAW is open source — contribute on GitHub!

### Join the community — share your pixel art

### QB64 source code export — unique to DRAW

### Upcoming features and roadmap

### Thank you for watching — go create something amazing!

---

# 20 - 📋 Appendix — Quick Reference

## All Keyboard Shortcuts (CHEATSHEET.md)

### Tool Keys

- B=Brush D=Dot L=Line R=Rect C=Ellipse
- P=Polygon F=Fill K=Spray I=Picker
- E=Eraser M=Marquee W=Wand V=Move
- Z=Zoom T=Text

### Modifier Keys

- Shift = Constrain / Add to selection
- Ctrl = Perfect shape / Command key
- Alt = Subtract / Temp picker / Clone
- Ctrl+Shift = Angle snap / Bypass grid

### Panel Toggles

- Tab=Toolbar F4=Preview F5=EditBar
- Shift+F5=AdvBar Ctrl+L=Layers Ctrl+M=CharMap
- F11=All UI Ctrl+F11=Menu Only F10=Status

## All 56 Bundled Palettes

### NES, PICO-8, Commodore 64, Game Boy

### Endesga 32/64, DawnBringer 16/32

### AAP-64, Sweetie 16, Resurrect 64

### CGA, EGA, VGA, Amiga, MSX

### ... and 40+ more (see ASSETS/PALETTES/)

## All 19 Blend Modes

### Normal, Multiply, Screen, Overlay

### Add, Subtract, Difference

### Darken, Lighten

### Color Dodge, Color Burn

### Hard Light, Soft Light

### Exclusion, Vivid Light, Linear Light, Pin Light

### Color, Luminosity

### + Pass Through (groups only)

## All 9 Export Formats

### PNG Native (.draw), PNG Plain

### GIF, JPEG, TGA, BMP

### HDR, ICO, QOI

### + QB64 Source Code (.bas)

## Useful Links

### GitHub: github.com/grymmjack/DRAW

### QB64-PE: qb64phoenix.com

### Lospec Palettes: lospec.com/palette-list
