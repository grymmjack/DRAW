/**
 * DRAW YouTube Tutorial Playlist Mind Map Generator (.xmind format)
 *
 * Creates a multi-sheet mind map organizing a complete YouTube tutorial series
 * for DRAW — the QB64-PE pixel art editor by grymmjack.
 *
 * Usage: node generate-youtube-playlist-mindmap.js [output-dir]
 * Default output: ../PLANS/diagrams/DRAW-youtube-playlist.xmind
 */
const { Workbook, Topic, Zipper } = require('xmind');
const path = require('path');

const OUTPUT_DIR = process.argv[2] || path.join(__dirname, '..', 'PLANS', 'diagrams');
const FILENAME = 'DRAW-youtube-playlist';

// =============================================================================
// YOUTUBE TUTORIAL PLAYLIST — 20 sections, structured as episodes
// =============================================================================

const playlistTree = [
    // =========================================================================
    // SECTION 1: INTRODUCTION & SETUP
    // =========================================================================
    {
        title: '🎬 Section 1: Introduction & Setup',
        id: 'intro',
        children: [
            {
                title: 'EP01: What Is DRAW? — Overview & Philosophy',
                children: [
                    { title: '🎯 Goal: Understand what DRAW is and why it exists' },
                    { title: 'Pixel art editor written in QB64-PE (BASIC!)' },
                    { title: 'Unique feature: exports artwork as QB64 source code' },
                    { title: 'Open source — GitHub repo walkthrough' },
                    { title: 'Inspired by classic DPaint / ProMotion / Deluxe Paint' },
                    { title: 'Cross-platform: Windows, Linux, macOS' },
                    { title: 'Feature highlights reel — quick demo of capabilities' },
                    { title: '64 layers, 19 blend modes, full text system' },
                    { title: 'Theming, audio, custom brushes, symmetry drawing' },
                    { title: 'Native .draw format (PNG with embedded project data)' },
                ]
            },
            {
                title: 'EP02: Getting DRAW — Download, Build & Install',
                children: [
                    { title: '🎯 Goal: Get DRAW running on your machine' },
                    {
                        title: 'Option A: Download Pre-Built Release',
                        children: [
                            { title: 'GitHub Releases page walkthrough' },
                            { title: 'Choose your platform (Win/Linux/Mac)' },
                            { title: 'Extract and run — zero dependencies' },
                        ]
                    },
                    {
                        title: 'Option B: Build From Source',
                        children: [
                            { title: 'Install QB64-PE compiler' },
                            { title: 'Clone the DRAW repo' },
                            { title: 'Build command: qb64pe -w -x DRAW.BAS -o DRAW.run' },
                            { title: 'Makefile targets explained' },
                        ]
                    },
                    {
                        title: 'Platform-Specific Setup',
                        children: [
                            { title: 'Linux: .desktop file + MIME type registration' },
                            { title: 'Windows: Registry + Start Menu installer' },
                            { title: 'macOS: install-mac.command walkthrough' },
                        ]
                    },
                    { title: 'First launch — auto-detection of display & scale' },
                    { title: 'DRAW.cfg — where settings live' },
                ]
            },
            {
                title: 'EP03: Your First 5 Minutes — UI Tour',
                children: [
                    { title: '🎯 Goal: Navigate the interface confidently' },
                    {
                        title: 'Screen Layout Overview',
                        children: [
                            { title: 'Menu Bar (11 menus: File → Audio)' },
                            { title: 'Toolbar (4×7 grid, 28 tool buttons)' },
                            { title: 'Canvas (center — your drawing area)' },
                            { title: 'Palette Strip (bottom — color swatches)' },
                            { title: 'Status Bar (info: coords, zoom, tool, grid)' },
                            { title: 'Layer Panel (right side)' },
                        ]
                    },
                    {
                        title: 'Hidden Panels (toggle on/off)',
                        children: [
                            { title: 'Organizer Widget — brush presets & toggles' },
                            { title: 'Drawer Panel — 30 reusable brush/pattern slots' },
                            { title: 'Edit Bar (F5) — quick edit actions' },
                            { title: 'Advanced Bar (Shift+F5) — 26+ toggles' },
                            { title: 'Preview Window (F4) — magnifier or floating' },
                            { title: 'Character Map (Ctrl+M) — glyph grid' },
                        ]
                    },
                    { title: 'Docking system — Ctrl+Shift+Click to swap sides' },
                    { title: 'F11 = Toggle ALL UI / Ctrl+F11 = Menu only' },
                    { title: 'Tab = Toggle Toolbar visibility' },
                    { title: 'Command Palette ( ? key) — searchable command list' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 2: CORE DRAWING FUNDAMENTALS
    // =========================================================================
    {
        title: '🖌️ Section 2: Core Drawing Fundamentals',
        id: 'drawing-basics',
        children: [
            {
                title: 'EP04: Brush, Dot & Freehand Drawing',
                children: [
                    { title: '🎯 Goal: Master basic freehand pixel drawing' },
                    { title: 'Brush tool (B) — drag to paint freehand strokes' },
                    { title: 'Dot tool (D) — precision single-pixel stamps' },
                    { title: 'Brush size: [ and ] keys (1–50px)' },
                    { title: 'Brush shape: \\ key (circle ↔ square)' },
                    { title: 'Brush preview: ` key (outline + color)' },
                    { title: 'Left-click = FG color / Right-click = BG color' },
                    { title: 'Shift = constrain to horizontal/vertical axis' },
                    { title: 'Shift+Right-Click = connecting line (last to current)' },
                    { title: 'Pixel Perfect mode (F6) — removes L-shaped corners' },
                    { title: '4 size presets in the Organizer widget' },
                    {
                        title: '🎨 Exercise: Draw a simple sprite',
                        children: [
                            { title: 'Start small: 16×16 character' },
                            { title: 'Use Dot for placement, Brush for fills' },
                            { title: 'Try different brush sizes for outlines vs fill' },
                        ]
                    },
                ]
            },
            {
                title: 'EP05: Lines, Rectangles & Ellipses',
                children: [
                    { title: '🎯 Goal: Draw clean geometric shapes' },
                    {
                        title: 'Line Tool (L)',
                        children: [
                            { title: 'Click-drag = draw line preview' },
                            { title: 'Uses current brush size for thickness' },
                            { title: 'Shift = constrain H/V' },
                            { title: 'Ctrl+Shift = angle snap (15°/30°/45°)' },
                        ]
                    },
                    {
                        title: 'Rectangle Tool (R / Shift+R)',
                        children: [
                            { title: 'R = outlined rectangle' },
                            { title: 'Shift+R = filled rectangle' },
                            { title: 'Ctrl = perfect square' },
                            { title: 'Shift (while drawing) = from center' },
                        ]
                    },
                    {
                        title: 'Ellipse Tool (C / Shift+C)',
                        children: [
                            { title: 'C = outlined ellipse/circle' },
                            { title: 'Shift+C = filled ellipse' },
                            { title: 'Ctrl = perfect circle' },
                            { title: 'Shift (while drawing) = from center' },
                        ]
                    },
                    { title: 'All shapes respect brush size & color' },
                    { title: 'All shapes support symmetry drawing' },
                    {
                        title: '🎨 Exercise: Build a scene with shapes',
                        children: [
                            { title: 'House: rectangles + triangle roof' },
                            { title: 'Sun: filled circle + lines for rays' },
                            { title: 'Ground: filled rectangle' },
                        ]
                    },
                ]
            },
            {
                title: 'EP06: Polygons & Fill Tool',
                children: [
                    { title: '🎯 Goal: Draw complex shapes and fill regions' },
                    {
                        title: 'Polygon Tool (P / Shift+P)',
                        children: [
                            { title: 'P = outlined polygon' },
                            { title: 'Shift+P = filled polygon' },
                            { title: 'Click = add vertex point' },
                            { title: 'Enter = close and finish' },
                            { title: 'Ctrl+Shift = angle snap between points' },
                        ]
                    },
                    {
                        title: 'Flood Fill Tool (F)',
                        children: [
                            { title: 'Click to fill contiguous same-color region' },
                            { title: 'Shift = sample from all visible layers (merged)' },
                            { title: 'Works with custom brushes (tiled fill!)' },
                            { title: 'Supports pattern and gradient paint modes' },
                        ]
                    },
                    {
                        title: 'Fill Adjustment Overlay (F8)',
                        children: [
                            { title: 'Activate after filling with custom brush' },
                            { title: 'Drag canvas = reposition tile origin' },
                            { title: 'Mouse wheel = uniform scale' },
                            { title: 'L-handle = independent X/Y scale' },
                            { title: 'Rotation handle (arc drag)' },
                            { title: 'Enter = apply / Esc = cancel' },
                        ]
                    },
                    {
                        title: '🎨 Exercise: Create a tileable pattern',
                        children: [
                            { title: 'Draw a small tile (8×8 or 16×16)' },
                            { title: 'Capture as custom brush' },
                            { title: 'Fill a large area with tiled fill' },
                            { title: 'Adjust with F8 overlay' },
                        ]
                    },
                ]
            },
            {
                title: 'EP07: Spray Tool & Eraser',
                children: [
                    { title: '🎯 Goal: Use spray can effects and clean up mistakes' },
                    {
                        title: 'Spray Tool (K)',
                        children: [
                            { title: 'Spray paint with randomized dot placement' },
                            { title: 'Nozzle radius doubles per brush size level' },
                            { title: 'Density scales with radius' },
                            { title: 'Supports custom brush stamping' },
                            { title: 'Shift = constrain to axis' },
                        ]
                    },
                    {
                        title: 'Eraser Tool (E)',
                        children: [
                            { title: 'Paints transparent pixels (reveals bg)' },
                            { title: 'Hold E = temporary eraser (any tool)' },
                            { title: 'Uses current brush size & shape' },
                            { title: 'Shift = Smart Erase (all visible layers!)' },
                            { title: 'Custom brush support for shaped erasing' },
                            { title: 'Status bar shows FG:TRN indicator' },
                        ]
                    },
                    { title: 'Tip: Eraser + opacity lock = paint only on existing pixels' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 3: COLOR & PALETTE MASTERY
    // =========================================================================
    {
        title: '🎨 Section 3: Color & Palette Mastery',
        id: 'color',
        children: [
            {
                title: 'EP08: Color Basics — FG, BG & Palette Strip',
                children: [
                    { title: '🎯 Goal: Select, swap, and manage colors' },
                    { title: 'Left-click palette swatch = set FG color' },
                    { title: 'Right-click palette swatch = set BG color' },
                    { title: 'X key = swap FG ↔ BG colors' },
                    { title: 'Ctrl+D = reset to white FG / black BG' },
                    { title: 'Shift+Delete = set BG to transparent' },
                    { title: 'Mouse wheel on strip = scroll palette' },
                    { title: 'Shift+wheel = fast scroll (32 colors)' },
                    { title: 'ALT+Left-click = temp FG eyedropper (any tool)' },
                    { title: 'ALT+Right-click = temp BG eyedropper (any tool)' },
                    { title: 'Paint Opacity: keys 1-9 = 10-90%, 0 = 100%' },
                    { title: 'Per-stroke compositing (no compounding!)' },
                ]
            },
            {
                title: 'EP09: Color Picker, Color Mixer & Custom RGB',
                children: [
                    { title: '🎯 Goal: Use the full RGB color picker and live Color Mixer' },
                    { title: 'Click FG/BG swatches in status bar → open picker' },
                    { title: 'Picker tool (I) — eyedropper with loupe overlay' },
                    { title: 'Loupe shows RGB + hex values on hover' },
                    { title: 'True 24-bit RGB color selection' },
                    { title: 'Hex input support' },
                    { title: 'Invert colors command (toolbar)' },
                    {
                        title: 'Color Mixer Panel (View → Color Mixer)',
                        children: [
                            { title: 'Floating panel for live RGB/HSV color editing' },
                            { title: 'RGB sliders — adjust Red, Green, Blue independently' },
                            { title: 'HSV sliders — adjust Hue, Saturation, Value (brightness)' },
                            { title: 'Hex input field — type any hex color value directly' },
                            { title: 'FG/BG swatches — click to apply mixed color' },
                            { title: 'Stays open while drawing — tweak colors without interrupting flow' },
                            { title: 'Visibility persisted in DRAW.cfg' },
                        ]
                    },
                ]
            },
            {
                title: 'EP10: Palette Management — 56 Built-In Palettes',
                children: [
                    { title: '🎯 Goal: Switch, browse, and manage palettes' },
                    { title: 'Palette dropdown — click name to switch' },
                    { title: '56 bundled .GPL palettes (GIMP format)' },
                    { title: 'Classic palettes: NES, PICO-8, Commodore 64, Game Boy' },
                    { title: 'Letter keys jump to palette name in dropdown' },
                    {
                        title: 'Palette Workflows',
                        children: [
                            { title: 'Download from Lospec (online palette database)' },
                            { title: 'Create palette from existing image' },
                            { title: 'Import/Export .GPL files' },
                            { title: 'Remap existing artwork to new palette' },
                        ]
                    },
                ]
            },
            {
                title: 'EP11: Palette Ops — Edit Colors Directly',
                children: [
                    { title: '🎯 Goal: Modify palette colors and remap on canvas' },
                    { title: 'Enable Palette Ops mode (Organizer toggle)' },
                    { title: 'Double-click = change color (replaces on canvas!)' },
                    { title: 'Right-click = mark color with indicator' },
                    { title: 'Middle-click = delete color (remap to nearest)' },
                    { title: 'Shift+Middle-click = insert transparent color' },
                    { title: 'Drag = rearrange palette order' },
                    { title: 'Left-click = magic wand select matching pixels' },
                    { title: 'Auto [DOCUMENT] palette creation' },
                    { title: 'Snapshot/restore for safe experimentation' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 4: LAYER SYSTEM
    // =========================================================================
    {
        title: '📚 Section 4: Layer System Deep Dive',
        id: 'layers',
        children: [
            {
                title: 'EP12: Layer Basics — Create, Delete & Reorder',
                children: [
                    { title: '🎯 Goal: Work with multiple layers' },
                    { title: 'Up to 64 layers — enormous creative flexibility' },
                    { title: 'New Layer (Ctrl+Shift+N)' },
                    { title: 'Delete Layer (Ctrl+Shift+Delete)' },
                    { title: 'Duplicate Layer (Ctrl+Shift+D)' },
                    { title: 'Drag & drop to reorder in layer panel' },
                    { title: 'Move Up/Down (Ctrl+PgUp/PgDn)' },
                    { title: 'Arrange to Top/Bottom (Ctrl+Home/End)' },
                    { title: 'Right-click layer = context menu' },
                    { title: 'Rename layers (right-click → Rename)' },
                    {
                        title: '🎨 Exercise: Multi-layer sprite',
                        children: [
                            { title: 'Layer 1: Background/scene' },
                            { title: 'Layer 2: Character outline' },
                            { title: 'Layer 3: Character colors' },
                            { title: 'Layer 4: Highlights/effects' },
                        ]
                    },
                ]
            },
            {
                title: 'EP13: Opacity, Visibility & Opacity Lock',
                children: [
                    { title: '🎯 Goal: Control layer transparency and protection' },
                    { title: 'Opacity bar — drag or mouse wheel (0–100%)' },
                    { title: 'Eye icon = toggle visibility' },
                    { title: 'Alt+click eye = Solo mode (hide all others)' },
                    { title: 'Drag across eye icons = swipe visibility' },
                    { title: 'Lock icon = Opacity Lock (draw only on existing pixels)' },
                    { title: 'Great for recoloring without changing shape' },
                    {
                        title: '🎨 Demo: Opacity lock workflow',
                        children: [
                            { title: 'Draw character on one layer' },
                            { title: 'Enable opacity lock' },
                            { title: 'Paint new colors — stays within outline!' },
                        ]
                    },
                ]
            },
            {
                title: 'EP14: Blend Modes — 19 Modes Explained',
                children: [
                    { title: '🎯 Goal: Understand and use blend modes creatively' },
                    {
                        title: 'Basic Modes',
                        children: [
                            { title: 'Normal — standard opaque overlay' },
                            { title: 'Multiply — darken (shadows, ambient occlusion)' },
                            { title: 'Screen — lighten (glow, highlights)' },
                            { title: 'Overlay — contrast boost' },
                        ]
                    },
                    {
                        title: 'Math Modes',
                        children: [
                            { title: 'Add (Linear Dodge) — bright glow effects' },
                            { title: 'Subtract — remove light' },
                            { title: 'Difference — psychedelic color inversion' },
                        ]
                    },
                    {
                        title: 'Comparison Modes',
                        children: [
                            { title: 'Darken — keep darker of two pixels' },
                            { title: 'Lighten — keep lighter of two pixels' },
                        ]
                    },
                    {
                        title: 'Dodge/Burn & Light Modes',
                        children: [
                            { title: 'Color Dodge / Color Burn' },
                            { title: 'Hard Light / Soft Light' },
                            { title: 'Vivid Light / Linear Light / Pin Light' },
                        ]
                    },
                    {
                        title: 'Color Modes',
                        children: [
                            { title: 'Exclusion — soft difference' },
                            { title: 'Color — apply hue+saturation, keep luminance' },
                            { title: 'Luminosity — apply brightness, keep color' },
                        ]
                    },
                    { title: 'Shift+Right-Click layer row = cycle blend mode' },
                    {
                        title: '🎨 Exercise: Lighting with blend modes',
                        children: [
                            { title: 'Base sprite on layer 1' },
                            { title: 'Shadows layer: Multiply mode' },
                            { title: 'Highlights layer: Screen or Add mode' },
                            { title: 'Color wash layer: Color mode' },
                        ]
                    },
                ]
            },
            {
                title: 'EP15: Layer Groups & Advanced Operations',
                children: [
                    { title: '🎯 Goal: Organize complex artwork with groups' },
                    {
                        title: 'Layer Groups',
                        children: [
                            { title: 'Create group (Ctrl+G)' },
                            { title: 'Group from selected layers (Ctrl+Shift+G)' },
                            { title: 'Ungroup (Ctrl+Shift+U)' },
                            { title: 'Collapse/expand with triangle toggle' },
                            { title: 'Drag layers into/out of groups' },
                            { title: 'Arbitrary nesting depth' },
                            { title: 'Pass Through blend mode for groups' },
                        ]
                    },
                    {
                        title: 'Merge Operations',
                        children: [
                            { title: 'Merge Down (Ctrl+Alt+E)' },
                            { title: 'Merge Visible (Ctrl+Alt+Shift+E)' },
                            { title: 'Merge Selected layers' },
                            { title: 'Merge Group to single layer' },
                        ]
                    },
                    {
                        title: 'Multi-Layer Select',
                        children: [
                            { title: 'Ctrl+Click = toggle individual selection' },
                            { title: 'Shift+Click = range selection' },
                            { title: 'Bulk ops: clear, fill, flip, scale, rotate' },
                            { title: 'Select All in Group' },
                        ]
                    },
                    {
                        title: 'Layer Alignment & Distribution',
                        children: [
                            { title: 'Align Left / Center / Right' },
                            { title: 'Align Top / Middle / Bottom' },
                            { title: 'Distribute Horizontally / Vertically' },
                        ]
                    },
                    {
                        title: 'Symbol Layers',
                        children: [
                            { title: 'Symbol Parent + one or more Symbol Children' },
                            { title: 'Draw on the parent → all children auto-sync' },
                            { title: 'Children can be independently scaled and repositioned' },
                            { title: 'Rasterize: bake a symbol child into a normal pixel layer' },
                            { title: 'Detach: break the sync link — child becomes independent' },
                            { title: 'Useful for repeated elements (coins, enemies, tiles, UI)' },
                            { title: 'Created via Layer menu → New Symbol Layer / Convert to Symbol' },
                        ]
                    },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 5: SELECTION & CLIPBOARD
    // =========================================================================
    {
        title: '✂️ Section 5: Selection & Clipboard',
        id: 'selection',
        children: [
            {
                title: 'EP16: Selection Tools — Marquee, Freehand & Wand',
                children: [
                    { title: '🎯 Goal: Select regions for editing and manipulation' },
                    {
                        title: 'Marquee Tool (M)',
                        children: [
                            { title: 'Drag = create rectangular selection' },
                            { title: 'Shift+Drag = add to selection (union)' },
                            { title: 'Alt+Drag = subtract from selection' },
                            { title: 'Resize handles on selection edges' },
                            { title: 'Drag inside = move selection' },
                            { title: 'Arrow keys = nudge (1px, Shift=10px)' },
                        ]
                    },
                    { title: 'Freehand Select — draw selection boundary' },
                    { title: 'Polygon Select — click-to-point boundary' },
                    { title: 'Ellipse Select — oval selection area' },
                    {
                        title: 'Magic Wand (W)',
                        children: [
                            { title: 'Click = select contiguous same-color pixels' },
                            { title: 'Shift+Click = add to selection' },
                            { title: 'Alt+Click = subtract from selection' },
                            { title: 'Hold F+Click = instant flood fill with FG' },
                            { title: 'Hold E+Click = instant erase to transparent' },
                            { title: 'Hold W+Click = select from merged canvas' },
                        ]
                    },
                    { title: 'Select All (Ctrl+A) / Deselect (Ctrl+D)' },
                    { title: 'Invert Selection (Ctrl+Shift+I)' },
                    { title: 'Expand / Contract selection' },
                    { title: 'Selection from current layer (non-transparent pixels)' },
                    { title: 'Selection from selected layers (union mask)' },
                    { title: 'Selections clip ALL drawing tools (marching ants)' },
                ]
            },
            {
                title: 'EP17: Copy, Cut, Paste & Clipboard Power',
                children: [
                    { title: '🎯 Goal: Master clipboard operations' },
                    { title: 'Copy (Ctrl+C) — selection to clipboard' },
                    { title: 'Cut (Ctrl+X) — copy + clear' },
                    { title: 'Paste (Ctrl+V) — at cursor, auto-engages Move tool' },
                    { title: 'Paste in Place (Ctrl+Alt+Shift+V) — same position' },
                    { title: 'Copy Merged (Ctrl+Shift+C) — all visible layers' },
                    { title: 'Copy to New Layer (Ctrl+Alt+C)' },
                    { title: 'Cut to New Layer (Ctrl+Alt+X)' },
                    { title: 'Paste from OS Clipboard (Ctrl+Shift+V)' },
                    { title: 'Clear/Erase (Ctrl+E or Delete)' },
                    {
                        title: 'Stroke Selection (Edit menu)',
                        children: [
                            { title: 'Add stroke around selection boundary' },
                            { title: 'Configurable width (px)' },
                            { title: 'Position: inside / outside / center' },
                            { title: 'FG or custom color' },
                        ]
                    },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 6: TRANSFORM & IMAGE ADJUSTMENTS
    // =========================================================================
    {
        title: '🔄 Section 6: Transforms & Image Adjustments',
        id: 'transforms',
        children: [
            {
                title: 'EP18: Quick Transforms — Flip, Rotate & Scale',
                children: [
                    { title: '🎯 Goal: Transform layers and selections quickly' },
                    { title: 'Flip Horizontal (H key)' },
                    { title: 'Flip Vertical (Ctrl+Shift+H)' },
                    { title: 'Rotate 90° CW (> key)' },
                    { title: 'Rotate 90° CCW (< key)' },
                    { title: 'Scale Up 50% (Ctrl+Shift+=)' },
                    { title: 'Scale Down 50% (Ctrl+Shift+-)' },
                    { title: 'All work on single or multi-selected layers' },
                    { title: 'Canvas-level flip in Image menu (affects ALL layers)' },
                ]
            },
            {
                title: 'EP19: Transform Overlay — Scale, Rotate, Distort',
                children: [
                    { title: '🎯 Goal: Use the interactive on-canvas transform tool' },
                    { title: 'Activate: Edit → TRANSFORM (or command palette)' },
                    {
                        title: '5 Transform Modes',
                        children: [
                            { title: 'Scale — drag handles, Shift = lock aspect ratio' },
                            { title: 'Rotate — drag outside box, Shift = 15° snap' },
                            { title: 'Shear — drag edges to skew' },
                            { title: 'Distort — move corners independently' },
                            { title: 'Perspective — Shift = wall projection' },
                        ]
                    },
                    { title: 'Themeable frame and handles' },
                    { title: 'Enter = apply / Esc = cancel' },
                    { title: 'Full undo support after applying' },
                ]
            },
            {
                title: 'EP20: Move Tool & Smart Guides',
                children: [
                    { title: '🎯 Goal: Reposition content precisely' },
                    {
                        title: 'Move Tool (V)',
                        children: [
                            { title: 'Drag to reposition layer content' },
                            { title: 'Arrow keys = nudge 1px (Shift = 10px)' },
                            { title: 'Alt+Drag = clone stamp (duplicate while moving)' },
                            { title: 'Ctrl+Arrows = resize' },
                            { title: 'Shift+Click = auto-select topmost layer' },
                        ]
                    },
                    {
                        title: 'Smart Guides',
                        children: [
                            { title: 'Alignment lines when moving layers' },
                            { title: 'Snap to canvas edges and centers' },
                            { title: 'Snap to other layer edges' },
                            { title: 'Toggle visibility: Ctrl+Shift+;' },
                            { title: 'Toggle snap: Ctrl+;' },
                            { title: 'Themeable colors and opacity' },
                        ]
                    },
                ]
            },
            {
                title: 'EP21: Image Adjustments — Color Correction & Effects',
                children: [
                    { title: '🎯 Goal: Apply per-layer color adjustments' },
                    {
                        title: 'Dialog-Based (Live Preview)',
                        children: [
                            { title: 'Brightness / Contrast' },
                            { title: 'Hue / Saturation' },
                            { title: 'Levels (Black/White/Gamma)' },
                            { title: 'Color Balance (Shadows/Mid/Highlights)' },
                            { title: 'Blur (Gaussian, adjustable radius)' },
                            { title: 'Sharpen (adjustable intensity)' },
                        ]
                    },
                    {
                        title: 'One-Shot Adjustments',
                        children: [
                            { title: 'Invert (RGB negative)' },
                            { title: 'Desaturate (luminosity grayscale)' },
                            { title: 'Posterize (N levels + dithering options)' },
                            { title: 'Pixelate (block cell size)' },
                            { title: 'Remove Background' },
                        ]
                    },
                    { title: 'Mouse wheel on sliders for fine control' },
                    { title: 'Alpha channel always preserved' },
                    { title: 'Ctrl+Z = undo any adjustment' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 7: TEXT SYSTEM
    // =========================================================================
    {
        title: '📝 Section 7: Text System',
        id: 'text',
        children: [
            {
                title: 'EP22: Text Tool Basics — Fonts & Entry',
                children: [
                    { title: '🎯 Goal: Add text to your pixel art' },
                    { title: 'Text tool (T) — click to place text cursor' },
                    { title: 'Type to enter text, Enter for new line' },
                    { title: 'Escape = apply and finish' },
                    {
                        title: 'Built-in Fonts',
                        children: [
                            { title: 'VGA (T key) — classic 8×8 monospace' },
                            { title: 'Tiny5 (Shift+T) — minimal 5×5' },
                            { title: 'Custom TTF/OTF (Ctrl+T, Middle-click to load)' },
                        ]
                    },
                    {
                        title: 'Color Bitmap Fonts (24 bundled)',
                        children: [
                            { title: 'DPaint-style .bmp spritesheet fonts' },
                            { title: 'Preserve original pixel colors' },
                            { title: 'Fixed native glyph height' },
                            { title: 'PSF, BDF, Fontaption formats supported' },
                        ]
                    },
                    { title: 'Text Property Bar — font dropdown, size, toggles' },
                ]
            },
            {
                title: 'EP23: Rich Text — Per-Character Formatting',
                children: [
                    { title: '🎯 Goal: Apply advanced text formatting' },
                    {
                        title: 'Selection Methods',
                        children: [
                            { title: 'Shift+Arrow = select characters' },
                            { title: 'Double-click = select word' },
                            { title: 'Triple-click = select line' },
                            { title: 'Quad-click = select all' },
                            { title: 'Ctrl+A = select all' },
                        ]
                    },
                    {
                        title: 'Per-Character Properties',
                        children: [
                            { title: 'Bold / Italic / Underline / Strikethrough' },
                            { title: 'Outline (color + size)' },
                            { title: 'Shadow (color + X/Y offset 1-10px)' },
                            { title: 'Per-character FG/BG colors' },
                            { title: 'Letter spacing / line height' },
                        ]
                    },
                    { title: 'Auto-wrap mode' },
                    { title: 'Style Presets — Save/Load/Update/Delete' },
                    { title: 'Text-local undo/redo (Ctrl+Z/Y, 128 states)' },
                    { title: 'Sound feedback on keystroke' },
                ]
            },
            {
                title: 'EP24: Text Layers & Character Mode',
                children: [
                    { title: '🎯 Goal: Master persistent text and ANSI-style art' },
                    {
                        title: 'Text Layers',
                        children: [
                            { title: 'Click existing text layer to re-edit' },
                            { title: 'Persisted in .draw files' },
                            { title: 'Full undo/redo support' },
                            { title: 'Rasterize single or all text layers' },
                            { title: 'New Text Layer from Layer menu' },
                        ]
                    },
                    {
                        title: 'Character Mode (useChars)',
                        children: [
                            { title: 'Virtual cursor — free grid navigation' },
                            { title: 'F1-F12 = ANSI block characters (░▒▓█▀▄▌▐)' },
                            { title: 'Font stickiness while navigating' },
                            { title: 'DOT/RECT drawing fills cells with glyphs' },
                            { title: 'Alt+U = pick colors from character at cursor' },
                            { title: 'Character grid overlay with snap' },
                        ]
                    },
                    {
                        title: 'Character Map Panel (Ctrl+M)',
                        children: [
                            { title: '16×16 glyph grid (256 characters)' },
                            { title: 'Click glyph = insert or use as custom brush' },
                            { title: 'Dockable left/right' },
                            { title: 'Unicode/CP437 mode toggle (Ctrl+Shift+U)' },
                        ]
                    },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 8: GRID, SYMMETRY & DRAWING AIDS
    // =========================================================================
    {
        title: '📐 Section 8: Grid, Symmetry & Drawing Aids',
        id: 'grid-sym',
        children: [
            {
                title: 'EP25: Grid System — 4 Geometry Modes',
                children: [
                    { title: '🎯 Goal: Use grids for precise pixel art layout' },
                    { title: "Grid toggle: ' (apostrophe)" },
                    { title: "Pixel grid: Shift+' (shows at 400%+ zoom)" },
                    { title: 'Snap-to-grid: ; (semicolon)' },
                    { title: 'Grid size: . (increase) , (decrease) — 2 to 50px' },
                    {
                        title: "4 Geometry Modes (Ctrl+')",
                        children: [
                            { title: 'Square (default) — standard tile grid' },
                            { title: 'Diagonal — 45° rotated diamonds' },
                            { title: 'Isometric — 2:1 pixel art standard' },
                            { title: 'Hexagonal — flat-top hexagons' },
                        ]
                    },
                    { title: 'Alignment: Corner (intersections) vs Center (cells)' },
                    {
                        title: 'Grid Cell Fill Mode',
                        children: [
                            { title: 'Fills squares, diamonds, triangles, or hexagons' },
                            { title: 'Depends on current geometry mode' },
                        ]
                    },
                    { title: 'Ctrl+Shift = bypass grid snap for freehand' },
                    { title: 'Grid state saved in .draw files' },
                    {
                        title: '🎨 Demo: Isometric pixel art with grid',
                        children: [
                            { title: 'Set isometric mode + snap' },
                            { title: 'Draw iso cube / building' },
                            { title: 'Grid guides perfect 2:1 angles' },
                        ]
                    },
                ]
            },
            {
                title: 'EP26: Symmetry Drawing — Mirror & Kaleidoscope',
                children: [
                    { title: '🎯 Goal: Create symmetrical art effortlessly' },
                    { title: 'Cycle modes with F7: Off → | → + → *' },
                    {
                        title: 'Symmetry Modes',
                        children: [
                            { title: 'Vertical | — 2 copies (bilateral symmetry)' },
                            { title: 'Cross + — 4 copies (quad symmetry)' },
                            { title: 'Asterisk * — 8 copies (kaleidoscope)' },
                        ]
                    },
                    { title: 'Ctrl+Click = reposition symmetry center' },
                    { title: 'Visual guide lines and crosshair' },
                    { title: 'Works with ALL drawing tools' },
                    { title: 'F8 = disable symmetry (or open fill adjust)' },
                    { title: 'Status bar shows SYM:0/1/2/3' },
                    {
                        title: '🎨 Demo: Mandala creation',
                        children: [
                            { title: 'Set asterisk mode (8-way)' },
                            { title: 'Center on canvas' },
                            { title: 'Draw one slice — 8 copies appear instantly' },
                            { title: 'Layer blend modes for complexity' },
                        ]
                    },
                ]
            },
            {
                title: 'EP27: Drawing Aids — Angle Snap, Crosshair & Assists',
                children: [
                    { title: '🎯 Goal: Use helpers for clean, precise artwork' },
                    {
                        title: 'Angle Snap (Ctrl+Shift while drawing)',
                        children: [
                            { title: 'Degree mode: 15°/30°/45°/90° snapping' },
                            { title: 'Pixel Art mode: integer ratio angles (clean lines)' },
                            { title: 'Works: Line, Polygon, Brush, Dot connecting lines' },
                            { title: 'Configurable in DRAW.cfg' },
                        ]
                    },
                    {
                        title: 'Crosshair Assistant',
                        children: [
                            { title: 'Hold Shift to display' },
                            { title: 'Configurable: color, opacity, width' },
                            { title: 'Outline stroke for visibility on any bg' },
                        ]
                    },
                    { title: 'Pixel Perfect mode (F6) — cleanest edges' },
                    { title: 'Grayscale Preview (Ctrl+Alt+Shift+G) — check values' },
                    { title: 'Pattern Tile Mode (Shift+Tab) — seamless texture preview' },
                    { title: 'Canvas border toggle (# key)' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 9: CUSTOM BRUSH & DRAWER
    // =========================================================================
    {
        title: '🪄 Section 9: Custom Brushes & Drawer Panel',
        id: 'custom-brush',
        children: [
            {
                title: 'EP28: Custom Brushes — Capture, Transform & Paint',
                children: [
                    { title: '🎯 Goal: Create and use custom brushes' },
                    {
                        title: 'Creating Custom Brushes',
                        children: [
                            { title: 'Make a selection → capture as brush' },
                            { title: 'Select from Current Layer (non-transparent pixels)' },
                            { title: 'Select from Selected Layers (union)' },
                            { title: 'Non-rectangular shapes via alpha channel' },
                        ]
                    },
                    {
                        title: 'Brush Transform Controls',
                        children: [
                            { title: 'Flip H (Home) / Flip V (End)' },
                            { title: 'Scale Up (PgUp) / Scale Down (PgDn)' },
                            { title: 'Reset Scale ( / key)' },
                        ]
                    },
                    { title: 'Recolor Mode (F9) — paint brush in FG color' },
                    { title: 'Outline Mode (Shift+O) — add BG-colored outline' },
                    { title: 'Export as PNG (F12)' },
                    { title: 'Works with Line, Rect, Ellipse, Poly, Fill, Spray' },
                    { title: 'Custom brush + tiled fill = powerful patterns' },
                ]
            },
            {
                title: 'EP29: Drawer Panel — 30 Reusable Slots',
                children: [
                    { title: '🎯 Goal: Organize and reuse brushes and patterns' },
                    {
                        title: '3 Drawer Modes',
                        children: [
                            { title: 'Brush Mode (F1) — stamp and paint' },
                            { title: 'Gradient Mode (F2) — color transitions' },
                            { title: 'Pattern Mode (F3) — tiled fill patterns' },
                        ]
                    },
                    { title: 'Shift+Left-Click = store current brush to slot' },
                    { title: 'Right-Click = context menu (load, save, clear)' },
                    { title: 'Load Images — batch import to slots' },
                    { title: 'Drag & Drop to reorder slots' },
                    { title: '.dset Import/Export — share brush sets' },
                    { title: 'Mini Palette in drawer' },
                    { title: '1-Bit Patterns (opaque background)' },
                    {
                        title: 'Paint Modes',
                        children: [
                            { title: 'Normal (solid color)' },
                            { title: 'Pattern (from drawer slot)' },
                            { title: 'Gradient (from drawer slot)' },
                        ]
                    },
                    {
                        title: 'Dithering Algorithms',
                        children: [
                            { title: 'Ordered (Bayer 2×2, 4×4, 8×8)' },
                            { title: 'Floyd-Steinberg error diffusion' },
                            { title: 'Atkinson / Stucki / Blue Noise' },
                        ]
                    },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 10: FILE I/O & EXPORT
    // =========================================================================
    {
        title: '💾 Section 10: File I/O & Export',
        id: 'fileio',
        children: [
            {
                title: 'EP30: Opening & Saving — Formats Explained',
                children: [
                    { title: '🎯 Goal: Understand all file format options' },
                    {
                        title: 'Open/Import',
                        children: [
                            { title: 'Open Image (Ctrl+O) — PNG/BMP/JPG/GIF' },
                            { title: 'Open Project (Alt+O) — .draw format' },
                            { title: 'Open Aseprite (.ase/.aseprite)' },
                            { title: 'Open Photoshop (.psd)' },
                            { title: 'Import Image — oversized interactive placement' },
                            { title: 'Drag & Drop files onto window (Windows)' },
                            { title: 'Command line argument' },
                        ]
                    },
                    {
                        title: 'Save Options',
                        children: [
                            { title: 'Save (Ctrl+S) — silent resave' },
                            { title: 'Save As (Ctrl+Shift+S) — prompt new name' },
                            { title: 'Export Selection (Ctrl+Alt+Shift+S)' },
                            { title: 'Export Layer as PNG' },
                            { title: 'Export Brush as PNG (F12)' },
                        ]
                    },
                    { title: 'Recent Files — up to 10, Alt+1-0 quick access' },
                    { title: 'New from Template' },
                ]
            },
            {
                title: 'EP31: The .draw Format — PNG with Superpowers',
                children: [
                    { title: '🎯 Goal: Understand the native DRW project format' },
                    { title: 'PNG file with embedded drAw chunk — viewable anywhere!' },
                    {
                        title: 'Preserves Everything',
                        children: [
                            { title: 'All layers + blend modes + opacity' },
                            { title: 'Palette state and [DOCUMENT] palette' },
                            { title: 'Tool states, grid settings, snap' },
                            { title: 'Reference image configuration' },
                            { title: 'Text layer data (re-editable!)' },
                            { title: 'Extract images settings' },
                            { title: 'Character mode state' },
                        ]
                    },
                    { title: 'Flattened preview visible in any image viewer' },
                    { title: 'Version tracking for forward compatibility' },
                ]
            },
            {
                title: 'EP32: Export As — 9 Image Formats',
                children: [
                    { title: '🎯 Goal: Export artwork in various formats' },
                    { title: 'PNG Native — with embedded drAw chunk' },
                    { title: 'PNG Plain — standard PNG (no metadata)' },
                    { title: 'GIF — animated or static' },
                    { title: 'JPEG — lossy compression' },
                    { title: 'TGA — Truevision (game dev friendly)' },
                    { title: 'BMP — Windows Bitmap' },
                    { title: 'HDR — High Dynamic Range' },
                    { title: 'ICO — Windows Icon format' },
                    { title: 'QOI — Quite OK Image (modern lossless)' },
                    { title: 'QB64 Source Code Export — artwork as BASIC code!' },
                ]
            },
            {
                title: 'EP33: Extract Images — Sprite Sheet Decomposition',
                children: [
                    { title: '🎯 Goal: Extract sprites from sheets or compositions' },
                    {
                        title: 'Extraction Methods',
                        children: [
                            { title: 'Flood-fill connected regions (auto-detect sprites)' },
                            { title: 'Per-layer extraction (each layer = one image)' },
                            { title: 'Merged extraction (visible layers)' },
                        ]
                    },
                    {
                        title: 'Background Options',
                        children: [
                            { title: 'Transparent' },
                            { title: 'FG color' },
                            { title: 'BG color' },
                        ]
                    },
                    { title: 'Output as separate PNG files' },
                    { title: 'Settings persisted in .draw files' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 11: CANVAS & VIEW FEATURES
    // =========================================================================
    {
        title: '🖥️ Section 11: Canvas & View Controls',
        id: 'canvas',
        children: [
            {
                title: 'EP34: Zoom, Pan & Navigation',
                children: [
                    { title: '🎯 Goal: Navigate canvases of any size efficiently' },
                    {
                        title: 'Zoom Controls',
                        children: [
                            { title: 'Ctrl+Mouse wheel' },
                            { title: 'Ctrl+= (in) / Ctrl+- (out)' },
                            { title: 'Ctrl+0 = reset to 100%' },
                            { title: 'Zoom tool (Z): click in, Alt+click out, drag region' },
                            { title: 'Snap levels: 25% through 800%' },
                        ]
                    },
                    {
                        title: 'Pan Controls',
                        children: [
                            { title: 'Middle mouse drag (any tool!)' },
                            { title: 'Spacebar + drag (any tool!)' },
                            { title: 'Arrow keys for keyboard panning' },
                            { title: 'Double-middle-click = reset pan+zoom' },
                        ]
                    },
                    { title: 'Scrollbars for large canvases' },
                    { title: 'Canvas border toggle (# key)' },
                ]
            },
            {
                title: 'EP35: Preview Window, Tile Mode & View Options',
                children: [
                    { title: '🎯 Goal: Use preview and tiling for workflow efficiency' },
                    {
                        title: 'Preview Window (F4)',
                        children: [
                            { title: 'Follow Mode — magnified cursor follower' },
                            { title: 'Floating Image Mode — reference display' },
                            { title: 'Bin Quick Look — hover drawer slots' },
                            { title: 'Color Picking (Alt+Click in preview)' },
                            { title: 'Recent preview images (up to 10)' },
                            { title: 'Independent zoom/pan' },
                            { title: 'Resizable and repositionable' },
                        ]
                    },
                    { title: 'Pattern Tile Mode (Shift+Tab) — 3×3 tiled, up to 512×512' },
                    { title: 'Grayscale Preview (Ctrl+Alt+Shift+G)' },
                    { title: 'Reference Image (Ctrl+R) — trace with adjustable opacity' },
                    {
                        title: 'Canvas Fill & Clear',
                        children: [
                            { title: 'Delete = Edit > Clear (clears selection, or whole layer if none; no prompt)' },
                            { title: 'Backspace = fill with foreground color (instant)' },
                            { title: 'Shift+Backspace = fill with background color (instant)' },
                        ]
                    },
                    { title: 'Canvas crop — interactive with handles' },
                    { title: 'Canvas resize dialog (Image menu)' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 12: UI & CUSTOMIZATION
    // =========================================================================
    {
        title: '⚙️ Section 12: UI Customization & Settings',
        id: 'settings',
        children: [
            {
                title: 'EP36: Settings Dialog — All 8 Tabs Explained',
                children: [
                    { title: '🎯 Goal: Configure DRAW to your preferences' },
                    { title: 'Open: Ctrl+Comma or Edit → Settings' },
                    { title: 'Tab 1: General — display scale, fullscreen, FPS, UI scaling' },
                    { title: 'Tab 2: Grid — size, geometry, alignment, snap, crosshair' },
                    { title: 'Tab 3: Palette — defaults, recent, Lospec visibility' },
                    { title: 'Tab 4: Panels — default visibility for all panels' },
                    { title: 'Tab 5: Audio — SFX/music enable, volume, mute' },
                    { title: 'Tab 6: Fonts — default font, size, TTF/OTF directories' },
                    { title: 'Tab 7: Appearance — theme selection, color scheme' },
                    { title: 'Tab 8: Directories — template/palette/music folders' },
                    { title: 'DRAW.cfg — plain text config, hand-editable' },
                    { title: 'OS-specific configs: DRAW.linux.cfg, .macOS.cfg, .windows.cfg' },
                    { title: '--config flag for custom config file path' },
                    { title: '--config-upgrade to reconcile with new defaults' },
                ]
            },
            {
                title: 'EP37: Theming — Icons, Colors & Sounds',
                children: [
                    { title: '🎯 Goal: Customize DRAW\'s look and feel' },
                    { title: 'All UI colors fully themeable' },
                    { title: 'PNG icons replaceable per theme' },
                    { title: 'Sound files customizable per theme' },
                    { title: 'Music folder per theme' },
                    { title: 'THEME.CFG — no recompile needed' },
                    { title: 'Layer panel, transform overlay, smart guides — all themeable' },
                    { title: 'Display Scale (1x-8x) and Toolbar Scale (1x-4x)' },
                ]
            },
            {
                title: 'EP38: Panel Layout & Docking',
                children: [
                    { title: '🎯 Goal: Arrange panels for your workflow' },
                    {
                        title: 'Dockable Panels',
                        children: [
                            { title: 'Toolbox — left/right (Tab toggle)' },
                            { title: 'Layer Panel — left/right (Ctrl+L toggle)' },
                            { title: 'Edit Bar — left/right (F5)' },
                            { title: 'Advanced Bar — left/right (Shift+F5)' },
                            { title: 'Character Map — left/right (Ctrl+M)' },
                        ]
                    },
                    { title: 'Ctrl+Shift+Click = toggle dock side' },
                    { title: 'F11 = toggle all UI / Ctrl+F11 = menu only' },
                    {
                        title: 'Quick Side-Panel Hide Shortcuts',
                        children: [
                            { title: 'Ctrl+Shift+Left = hide/show left-side panels (edit bar, layer panel)' },
                            { title: 'Ctrl+Shift+Right = hide/show right-side panels (toolbar, organizer, drawer)' },
                            { title: 'Ctrl+Shift+Up = hide/show menu bar' },
                            { title: 'Ctrl+Shift+Down = hide/show status bar and color strip' },
                        ]
                    },
                    { title: 'Auto-hide panels while drawing' },
                    { title: 'Cursor system: OS native for UI, custom for tools' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 13: AUDIO
    // =========================================================================
    {
        title: '🔊 Section 13: Audio — Music & Sound Effects',
        id: 'audio',
        children: [
            {
                title: 'EP39: Audio System — SFX, Music & Customization',
                children: [
                    { title: '🎯 Goal: Configure the creative audio experience' },
                    {
                        title: 'Sound Effects (21 categorized slots)',
                        children: [
                            { title: 'Menus, tools, selection, fill, clipboard' },
                            { title: 'Layer ops, text entry, sliders, drag-drop' },
                            { title: 'Per-theme replaceable WAV/OGG files' },
                            { title: 'Enable/disable + volume + mute' },
                        ]
                    },
                    {
                        title: 'Background Music',
                        children: [
                            { title: 'Tracker formats: .mod .xm .it .s3m .rad' },
                            { title: 'Auto-shuffle — random track on song end' },
                            { title: 'Next ( } ) / Prev ( { ) / Random track' },
                            { title: 'Volume up/down (±10%), independent of SFX' },
                            { title: 'NOW PLAYING display in Audio menu' },
                            { title: 'Explore Music Folder (open in file manager)' },
                        ]
                    },
                    { title: 'Audio menu — rightmost in menu bar' },
                    { title: 'All settings persist in DRAW.cfg' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 14: PIXEL ART ANALYZER
    // =========================================================================
    {
        title: '🔍 Section 14: Pixel Art Analyzer',
        id: 'analyzer',
        children: [
            {
                title: 'EP40: Pixel Art Analyzer — Find & Fix Common Issues',
                children: [
                    { title: '🎯 Goal: Improve pixel art quality with automated analysis' },
                    {
                        title: 'Detection Categories',
                        children: [
                            { title: 'Orphan Pixels — isolated single-pixel noise' },
                            { title: 'Jagged Lines — uneven stepped edges' },
                            { title: 'Banding — unwanted color gradient striping' },
                            { title: 'Pillow Shading — unrealistic "pillow" 3D effect' },
                            { title: 'Doubles — redundant pixel repetition' },
                        ]
                    },
                    { title: 'Precompute engine for fast analysis' },
                    { title: 'Visual feedback highlighting problem areas' },
                    { title: 'Interactive dialog with detailed results' },
                    {
                        title: '🎨 Demo: Before/After cleanup',
                        children: [
                            { title: 'Analyze a rough sprite' },
                            { title: 'Identify issues in overlay' },
                            { title: 'Fix each category, re-analyze' },
                        ]
                    },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 15: REFERENCE IMAGE & IMAGE IMPORT
    // =========================================================================
    {
        title: '🖼️ Section 15: Reference Image & Import',
        id: 'reference',
        children: [
            {
                title: 'EP41: Reference Image — Tracing Made Easy',
                children: [
                    { title: '🎯 Goal: Use reference images for tracing/study' },
                    { title: 'Toggle reference: Ctrl+R' },
                    { title: 'Ctrl+Shift+Wheel = adjust opacity (5-100%)' },
                    { title: 'Reposition mode: drag, zoom, nudge' },
                    { title: 'Renders behind all layers (non-destructive)' },
                    { title: 'Persisted in .draw files' },
                    {
                        title: '🎨 Demo: Pixel art from photo reference',
                        children: [
                            { title: 'Load photo as reference' },
                            { title: 'Set ~50% opacity for tracing' },
                            { title: 'Create pixel art interpretation on layers above' },
                        ]
                    },
                ]
            },
            {
                title: 'EP42: Image Import — Oversized Placement & Transform',
                children: [
                    { title: '🎯 Goal: Import and position external images' },
                    { title: 'Import places image for interactive positioning' },
                    { title: 'Zoom + pan within imported image' },
                    { title: 'Rotate 90° CW/CCW within import' },
                    { title: 'Flip horizontal/vertical' },
                    { title: 'Resize destination box with handles' },
                    { title: 'Live preview of all transforms' },
                    { title: 'Aseprite (.ase/.aseprite) import' },
                    { title: 'Photoshop (.psd) import' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 16: COMMAND PALETTE & KEYBOARD MASTERY
    // =========================================================================
    {
        title: '⌨️ Section 16: Keyboard Shortcuts & Command Palette',
        id: 'keyboard',
        children: [
            {
                title: 'EP43: Command Palette — 200+ Commands at Your Fingertips',
                children: [
                    { title: '🎯 Goal: Access any command instantly' },
                    { title: '? key = open Command Palette' },
                    { title: 'Fuzzy search matching on command names' },
                    { title: 'Hotkey display for every command' },
                    { title: 'Alt+? = Quick Reference Mode (all commands listed)' },
                    {
                        title: 'Categories',
                        children: [
                            { title: 'Tools, File, Edit, View, Color, Brush' },
                            { title: 'Layer, Canvas, Assist, Grid, Symmetry' },
                            { title: 'Select, Help, Image, Audio' },
                        ]
                    },
                ]
            },
            {
                title: 'EP44: Keyboard Shortcuts Cheat Sheet',
                children: [
                    { title: '🎯 Goal: Memorize the essential shortcuts' },
                    {
                        title: 'Tool Selection (single key)',
                        children: [
                            { title: 'B=Brush, D=Dot, L=Line, R=Rect, C=Ellipse' },
                            { title: 'P=Polygon, F=Fill, K=Spray, I=Picker' },
                            { title: 'E=Eraser, M=Marquee, W=Wand, V=Move' },
                            { title: 'Z=Zoom, T=Text' },
                        ]
                    },
                    {
                        title: 'Essential Combos',
                        children: [
                            { title: 'Ctrl+S/O/N/Z/Y — Save/Open/New/Undo/Redo' },
                            { title: 'Ctrl+C/X/V — Copy/Cut/Paste' },
                            { title: 'Ctrl+A/D/E — Select All/Deselect/Clear' },
                            { title: 'Ctrl+L — Toggle Layer Panel' },
                            { title: '[ ] — Brush Size  /  \\ — Brush Shape' },
                            { title: 'X — Swap FG/BG  /  0-9 — Paint Opacity' },
                            { title: "' ; . , — Grid controls" },
                            { title: 'F4-F9, F11 — Panel and mode toggles' },
                            { title: 'Tab — Toggle Toolbar' },
                            { title: '? — Command Palette' },
                        ]
                    },
                    { title: 'See CHEATSHEET.md for the complete list' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 17: UNDO/REDO & HISTORY
    // =========================================================================
    {
        title: '↩️ Section 17: Undo, Redo & History',
        id: 'history',
        children: [
            {
                title: 'EP45: History System — Fearless Experimentation',
                children: [
                    { title: '🎯 Goal: Understand the unified undo/redo system' },
                    { title: 'Ctrl+Z = Undo / Ctrl+Y = Redo' },
                    { title: 'Unified history — one timeline for everything' },
                    { title: 'Auto-record on mouse release (no manual save)' },
                    { title: 'Multi-layer undo for operations affecting multiple layers' },
                    { title: 'Text-local undo — separate 128-state history while typing' },
                    { title: 'Smart erase has per-layer history tracking' },
                    { title: 'History labels describe each action' },
                    { title: 'Experiment freely — you can always go back!' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 18: REAL-WORLD WORKFLOWS
    // =========================================================================
    {
        title: '🎓 Section 18: Real-World Pixel Art Workflows',
        id: 'workflows',
        children: [
            {
                title: 'EP46: Workflow — Game Sprite (16×16 Character)',
                children: [
                    { title: '🎯 Goal: Create a complete game character sprite' },
                    {
                        title: 'Step-by-Step',
                        children: [
                            { title: '1. New canvas: 16×16, grid=1, snap on' },
                            { title: '2. Choose a limited palette (NES or PICO-8)' },
                            { title: '3. Layer 1: Silhouette outline (dark color)' },
                            { title: '4. Layer 2: Base colors (opacity lock for clean fills)' },
                            { title: '5. Layer 3: Shading (Multiply blend mode)' },
                            { title: '6. Layer 4: Highlights (Screen blend mode)' },
                            { title: '7. Run Pixel Art Analyzer — fix issues' },
                            { title: '8. Export as PNG for your game engine' },
                        ]
                    },
                ]
            },
            {
                title: 'EP47: Workflow — Seamless Tile Texture',
                children: [
                    { title: '🎯 Goal: Create a tileable background pattern' },
                    {
                        title: 'Step-by-Step',
                        children: [
                            { title: '1. New canvas: 32×32 or 64×64' },
                            { title: '2. Enable Pattern Tile Mode (Shift+Tab)' },
                            { title: '3. Draw base pattern (see 3×3 repeat live)' },
                            { title: '4. Fix seams at edges using tile preview' },
                            { title: '5. Custom brush from tile → tiled fill test' },
                            { title: '6. Export as PNG tile' },
                        ]
                    },
                ]
            },
            {
                title: 'EP48: Workflow — Isometric Pixel Art',
                children: [
                    { title: '🎯 Goal: Create isometric buildings/objects' },
                    {
                        title: 'Step-by-Step',
                        children: [
                            { title: "1. Set grid to Isometric mode (Ctrl+')" },
                            { title: '2. Enable snap-to-grid (;)' },
                            { title: '3. Grid guides ensure perfect 2:1 ratio' },
                            { title: '4. Use Polygon for angled surfaces' },
                            { title: '5. Separate layers for top/left/right faces' },
                            { title: '6. Blend modes for light/shadow' },
                            { title: '7. Group layers per object' },
                        ]
                    },
                ]
            },
            {
                title: 'EP49: Workflow — Symmetrical Mandala / Pattern',
                children: [
                    { title: '🎯 Goal: Create complex symmetrical artwork' },
                    {
                        title: 'Step-by-Step',
                        children: [
                            { title: '1. Enable 8-way symmetry (F7 × 3 = asterisk)' },
                            { title: '2. Center symmetry point (Ctrl+Click canvas center)' },
                            { title: '3. Draw one slice — instant 8-fold reflection' },
                            { title: '4. Multiple layers with different blend modes' },
                            { title: '5. Opacity variations for depth' },
                            { title: '6. Custom brush stamps for detail' },
                        ]
                    },
                ]
            },
            {
                title: 'EP50: Workflow — ANSI/Text Art with Character Mode',
                children: [
                    { title: '🎯 Goal: Create text-mode art using block characters' },
                    {
                        title: 'Step-by-Step',
                        children: [
                            { title: '1. Switch to VGA font (T key)' },
                            { title: '2. Enable Character Mode' },
                            { title: '3. Open Character Map (Ctrl+M)' },
                            { title: '4. Use F1-F12 for ANSI block chars (░▒▓█▀▄)' },
                            { title: '5. Navigate with virtual cursor' },
                            { title: '6. Alt+U to pick colors from existing chars' },
                            { title: '7. DOT/RECT tools fill cells with glyphs' },
                            { title: '8. CP437 mode for classic DOS art feel' },
                        ]
                    },
                ]
            },
            {
                title: 'EP51: Workflow — Sprite Sheet Assembly & Export',
                children: [
                    { title: '🎯 Goal: Assemble sprites into a sheet and extract' },
                    {
                        title: 'Step-by-Step',
                        children: [
                            { title: '1. Create individual sprites on separate layers' },
                            { title: '2. Use grid + snap for consistent spacing' },
                            { title: '3. Layer groups per animation frame' },
                            { title: '4. Align & Distribute for perfect layout' },
                            { title: '5. Export full sheet as PNG' },
                            { title: '6. Use Extract Images to decompose into individual PNGs' },
                            { title: '7. Save as .draw to preserve layers for future edits' },
                        ]
                    },
                ]
            },
            {
                title: 'EP52: Workflow — Photo to Pixel Art',
                children: [
                    { title: '🎯 Goal: Convert a photograph into pixel art' },
                    {
                        title: 'Step-by-Step',
                        children: [
                            { title: '1. Load photo as Reference Image (Ctrl+R)' },
                            { title: '2. Choose a limited palette (e.g., Endesga 32)' },
                            { title: '3. Set reference opacity to ~60%' },
                            { title: '4. Trace key shapes with lines/polygons' },
                            { title: '5. Fill regions with flood fill' },
                            { title: '6. Add detail with brush/dot tools' },
                            { title: '7. Image Adjustments for color tweaking' },
                            { title: '8. Posterize for pixel-art-friendly values' },
                            { title: '9. Hide reference to evaluate result' },
                        ]
                    },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 19: TIPS, TRICKS & ADVANCED TECHNIQUES
    // =========================================================================
    {
        title: '💡 Section 19: Tips, Tricks & Advanced Techniques',
        id: 'tips',
        children: [
            {
                title: 'EP53: 10 Time-Saving Tips You Need to Know',
                children: [
                    { title: '🎯 Goal: Boost productivity with pro tips' },
                    { title: 'Tip 1: ALT+Click = instant color picker from any tool' },
                    { title: 'Tip 2: Middle-click = pan without switching tools' },
                    { title: 'Tip 3: Hold E = temporary eraser (release to return)' },
                    { title: 'Tip 4: Shift+RClick = connecting line (join distant points)' },
                    { title: 'Tip 5: Command Palette (?) = faster than menu diving' },
                    { title: 'Tip 6: Opacity Lock + big brush = instant recolor' },
                    { title: 'Tip 7: Custom brush tiled fill = instant pattern fills' },
                    { title: 'Tip 8: Ctrl+Shift+C = Copy Merged (flatten to clipboard)' },
                    { title: 'Tip 9: Double-middle-click = instant zoom/pan reset' },
                    { title: 'Tip 10: .draw format = PNG you can open in any viewer' },
                ]
            },
            {
                title: 'EP54: Advanced Layer Techniques',
                children: [
                    { title: '🎯 Goal: Push the layer system to its limits' },
                    { title: 'Non-destructive color adjustment layers (workflow)' },
                    { title: 'Group opacity for complex transparency effects' },
                    { title: 'Pass Through mode — groups that blend naturally' },
                    { title: 'Alt+Drag with Move = clone stamping across layers' },
                    { title: 'Solo mode for isolated editing (Alt+Click eye)' },
                    { title: 'Multi-layer selection + bulk transform' },
                    { title: 'Layer alignment for sprite sheet layout' },
                ]
            },
            {
                title: 'EP55: Series Wrap-Up — What\'s Next?',
                children: [
                    { title: '🎯 Goal: Recap and look ahead' },
                    { title: 'Series recap — all 54 episodes summarized' },
                    { title: 'DRAW is open source — contribute on GitHub!' },
                    { title: 'Join the community — share your pixel art' },
                    { title: 'QB64 source code export — unique to DRAW' },
                    { title: 'Upcoming features and roadmap' },
                    { title: 'Thank you for watching — go create something amazing!' },
                ]
            },
        ]
    },

    // =========================================================================
    // SECTION 20: APPENDIX — QUICK REFERENCE
    // =========================================================================
    {
        title: '📋 Section 20: Appendix — Quick Reference',
        id: 'appendix',
        children: [
            {
                title: 'All Keyboard Shortcuts (CHEATSHEET.md)',
                children: [
                    {
                        title: 'Tool Keys',
                        children: [
                            { title: 'B=Brush D=Dot L=Line R=Rect C=Ellipse' },
                            { title: 'P=Polygon F=Fill K=Spray I=Picker' },
                            { title: 'E=Eraser M=Marquee W=Wand V=Move' },
                            { title: 'Z=Zoom T=Text' },
                        ]
                    },
                    {
                        title: 'Modifier Keys',
                        children: [
                            { title: 'Shift = Constrain / Add to selection' },
                            { title: 'Ctrl = Perfect shape / Command key' },
                            { title: 'Alt = Subtract / Temp picker / Clone' },
                            { title: 'Ctrl+Shift = Angle snap / Bypass grid' },
                        ]
                    },
                    {
                        title: 'Panel Toggles',
                        children: [
                            { title: 'Tab=Toolbar F4=Preview F5=EditBar' },
                            { title: 'Shift+F5=AdvBar Ctrl+L=Layers Ctrl+M=CharMap' },
                            { title: 'F11=All UI Ctrl+F11=Menu Only F10=Status' },
                        ]
                    },
                ]
            },
            {
                title: 'All 56 Bundled Palettes',
                children: [
                    { title: 'NES, PICO-8, Commodore 64, Game Boy' },
                    { title: 'Endesga 32/64, DawnBringer 16/32' },
                    { title: 'AAP-64, Sweetie 16, Resurrect 64' },
                    { title: 'CGA, EGA, VGA, Amiga, MSX' },
                    { title: '... and 40+ more (see ASSETS/PALETTES/)' },
                ]
            },
            {
                title: 'All 19 Blend Modes',
                children: [
                    { title: 'Normal, Multiply, Screen, Overlay' },
                    { title: 'Add, Subtract, Difference' },
                    { title: 'Darken, Lighten' },
                    { title: 'Color Dodge, Color Burn' },
                    { title: 'Hard Light, Soft Light' },
                    { title: 'Exclusion, Vivid Light, Linear Light, Pin Light' },
                    { title: 'Color, Luminosity' },
                    { title: '+ Pass Through (groups only)' },
                ]
            },
            {
                title: 'All 9 Export Formats',
                children: [
                    { title: 'PNG Native (.draw), PNG Plain' },
                    { title: 'GIF, JPEG, TGA, BMP' },
                    { title: 'HDR, ICO, QOI' },
                    { title: '+ QB64 Source Code (.bas)' },
                ]
            },
            {
                title: 'Useful Links',
                children: [
                    { title: 'GitHub: github.com/grymmjack/DRAW' },
                    { title: 'QB64-PE: qb64phoenix.com' },
                    { title: 'Lospec Palettes: lospec.com/palette-list' },
                ]
            },
        ]
    },
];

// =============================================================================
// BUILD MULTI-SHEET WORKBOOK
// =============================================================================

// Step 1: Prepare sheet definitions — overview + one per branch
const sheetDefs = [
    { s: 'Overview', t: '🎬 DRAW YouTube Tutorial Playlist — 55 Episodes' },
];
for (const branch of playlistTree) {
    sheetDefs.push({ s: branch.title, t: branch.title });
}

const wb = new Workbook();
const created = wb.createSheets(sheetDefs);

// Map sheet titles to their IDs
const sheetIds = {};
for (const c of created) {
    sheetIds[c.title] = c.id;
}

// Step 2: Build the overview sheet with links to sub-sheets
const overviewSheet = wb.getSheet(sheetIds['Overview']);
const overviewTopic = new Topic({ sheet: overviewSheet });

// Collect root topic IDs from each sub-sheet
const rootTopicIds = {};
for (const branch of playlistTree) {
    const sheet = wb.getSheet(sheetIds[branch.title]);
    const rootTopic = sheet.getRootTopic();
    rootTopicIds[branch.title] = rootTopic.getId();
}

for (const branch of playlistTree) {
    overviewTopic.on().add({ title: branch.title });
    const childUUID = overviewTopic.cid();
    const childComponent = overviewSheet.findComponentById(childUUID);
    if (childComponent && childComponent.addHref) {
        childComponent.addHref('xmind:#' + rootTopicIds[branch.title]);
    }
}

// Step 3: Build each sub-sheet with full tree + back-link to overview
function addChildrenToTopic(topic, parentUUID, children) {
    for (const child of children) {
        if (parentUUID) {
            topic.on(parentUUID);
        } else {
            topic.on();
        }
        topic.add({ title: child.title });
        const uuid = topic.cid();
        if (child.children && child.children.length > 0) {
            addChildrenToTopic(topic, uuid, child.children);
        }
    }
}

const overviewRootTopicId = overviewSheet.getRootTopic().getId();

for (const branch of playlistTree) {
    const sheetId = sheetIds[branch.title];
    const sheet = wb.getSheet(sheetId);
    const topic = new Topic({ sheet });

    // Back-link to overview
    const rootComponent = sheet.getRootTopic();
    if (rootComponent && rootComponent.addHref) {
        rootComponent.addHref('xmind:#' + overviewRootTopicId);
    }

    if (branch.children) {
        addChildrenToTopic(topic, null, branch.children);
    }
}

// Step 4: Apply snowbrush theme to every sheet
const { Theme } = require(require.resolve('xmind/dist/core/theme'));
function applyTheme(sheetId) {
    const sheet = wb.getSheet(sheetId);
    if (sheet && sheet.changeTheme) {
        const themeInstance = new Theme({ themeName: 'robust' });
        sheet.changeTheme(themeInstance.data);
    }
}
applyTheme(sheetIds['Overview']);
for (const branch of playlistTree) {
    applyTheme(sheetIds[branch.title]);
}

// Count nodes
let nodeCount = 0;
function countNodes(arr) {
    for (const n of arr) {
        nodeCount++;
        if (n.children) countNodes(n.children);
    }
}
countNodes(playlistTree);
console.log('Total nodes: ' + nodeCount + ', Sheets: ' + created.length);

// Step 5: Save
const zipper = new Zipper({ path: OUTPUT_DIR, workbook: wb, filename: FILENAME });
zipper.save().then(function (status) {
    if (status) {
        console.log('SUCCESS: ' + OUTPUT_DIR + '/' + FILENAME + '.xmind');
    } else {
        console.error('FAILED to save xmind file');
        process.exit(1);
    }
});
