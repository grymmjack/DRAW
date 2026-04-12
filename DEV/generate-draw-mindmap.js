/**
 * DRAW Feature Mind Map Generator (.xmind format) — Multi-Sheet Edition
 * 
 * Creates an overview sheet with 19 clickable top-level nodes,
 * each linking to its own detail sheet with full sub-trees.
 * 
 * Usage: node generate-draw-mindmap.js [output-dir]
 * Default output: ../PLANS/diagrams/DRAW-feature-mindmap.xmind
 */
const { Workbook, Topic, Zipper } = require('xmind');
const path = require('path');

const OUTPUT_DIR = process.argv[2] || path.join(__dirname, '..', 'PLANS', 'diagrams');
const FILENAME = 'DRAW-feature-mindmap';

// =============================================================================
// FULL FEATURE TREE — 19 major branches, 658 nodes
// =============================================================================

const featureTree = [
    {
        title: '\u{1F58C}\uFE0F Drawing Tools',
        id: 'tools',
        children: [
            {
                title: 'Brush (B)',
                children: [
                    {title: 'Freehand Painting (drag to paint)'},
                    {title: 'Size 1-50px ([ ] keys)'},
                    {title: 'Circle / Square shape (\\\\ key)'},
                    {title: 'Preview Mode (` key)'},
                    {title: 'Pixel Perfect Mode (F6)'},
                    {title: 'Shift = Axis Constrain'},
                    {title: 'Shift+RClick = Connecting Line'},
                    {title: 'L-Click FG / R-Click BG'},
                    {title: '4 Size Presets (Organizer)'},
                ]
            },
            {
                title: 'Dot / Stamp (D)',
                children: [
                    {title: 'Single-pixel stamp (click, no drag)'},
                    {title: 'Shift+RClick = Connecting Line'},
                    {title: 'Uses Brush Size & Shape'},
                ]
            },
            {
                title: 'Line (L)',
                children: [
                    {title: 'Brush-sized thick preview'},
                    {title: 'Shift = H/V Constrain'},
                    {title: 'Ctrl+Shift = Angle Snap'},
                    {title: 'Symmetry support'},
                ]
            },
            {
                title: 'Rectangle (R / Shift+R)',
                children: [
                    {title: 'Outlined (R)'},
                    {title: 'Filled (Shift+R)'},
                    {title: 'Ctrl = Perfect Square'},
                    {title: 'Shift = Draw from Center'},
                    {
                        title: 'Fill Adjust (F8) \u2014 Tiled Fill',
                        children: [
                            {title: 'Drag = Reposition Tile Origin'},
                            {title: 'Wheel = Uniform Scale'},
                            {title: 'L-Handle = Independent X/Y'},
                            {title: 'Rotation Handle'},
                            {title: 'Enter Apply / Esc Cancel'},
                        ]
                    },
                ]
            },
            {
                title: 'Ellipse (C / Shift+C)',
                children: [
                    {title: 'Outlined (C)'},
                    {title: 'Filled (Shift+C)'},
                    {title: 'Ctrl = Perfect Circle'},
                    {title: 'Shift = Draw from Center'},
                    {title: 'Fill Adjust (F8) \u2014 Tiled Fill'},
                ]
            },
            {
                title: 'Polygon (P / Shift+P)',
                children: [
                    {title: 'Outlined (P)'},
                    {title: 'Filled (Shift+P)'},
                    {title: 'Click = Add Point, Enter = Close'},
                    {title: 'Ctrl+Shift = Angle Snap'},
                    {title: 'Fill Adjust (F8) \u2014 Tiled Fill'},
                ]
            },
            {
                title: 'Fill / Flood Fill (F)',
                children: [
                    {title: 'Standard Flood Fill'},
                    {title: 'Shift = Sample from Merged Visible'},
                    {title: 'Custom Brush Tiled Fill'},
                    {title: 'Pattern / Gradient Paint Mode'},
                    {
                        title: 'Fill Adjustment Overlay (F8)',
                        children: [
                            {title: 'Drag = Reposition Tile Origin'},
                            {title: 'Mouse Wheel = Uniform Scale'},
                            {title: 'L-Handle: Independent X/Y Scale'},
                            {title: 'Rotation Handle (Arc Drag)'},
                            {title: 'Enter = Apply / Esc = Cancel'},
                        ]
                    },
                ]
            },
            {
                title: 'Spray (K)',
                children: [
                    {title: 'Brush-shaped Nozzle Tips'},
                    {title: 'Radius doubles per brush size level'},
                    {title: 'Density scales with radius'},
                    {title: 'Custom Brush Stamp Support'},
                    {title: 'Shift = Axis Constrain'},
                    {title: 'Circle + Dot Preview'},
                ]
            },
            {
                title: 'Picker / Eyedropper (I)',
                children: [
                    {title: 'Cursor-adjacent Loupe Overlay'},
                    {title: 'Shows RGB + Hex Values'},
                    {title: 'ALT+Click = Temp Picker (any tool)'},
                    {title: 'Alt+L = Pick FG / Alt+R = Pick BG'},
                ]
            },
            {
                title: 'Eraser (E)',
                children: [
                    {title: 'Paints Transparent Pixels'},
                    {title: 'Hold E = Temporary Eraser'},
                    {title: 'Shift = Smart Erase (all visible layers)'},
                    {title: 'Uses Current Brush Size & Shape'},
                    {title: 'Custom Brush Support'},
                    {title: 'Status: FG:TRN indicator'},
                ]
            },
            {
                title: 'Zoom (Z)',
                children: [
                    {title: 'Click = Zoom In'},
                    {title: 'Alt+Click = Zoom Out'},
                    {title: 'Drag = Zoom to Region'},
                    {title: 'Snap Levels: 25%\u2013800%'},
                ]
            },
            {
                title: 'Pan / Hand Tool',
                children: [
                    {title: 'Dedicated Pan Mode (L-Click drag)'},
                    {title: 'Middle Mouse = Pan (any tool)'},
                    {title: 'Spacebar + Drag = Pan (any tool)'},
                    {title: 'Double-Click = Reset Zoom+Pan'},
                ]
            },
            {
                title: 'Crop',
                children: [
                    {title: 'Marquee-based Crop Region'},
                    {title: 'Resize Handles + Drag Move'},
                    {title: 'Dark Overlay Outside Region'},
                    {title: 'Size Label Display'},
                    {title: 'Canvas Resize Dialog'},
                ]
            },
            {
                title: 'Image Import',
                children: [
                    {title: 'Oversized Image Placement'},
                    {title: 'Zoom + Pan Within Image'},
                    {title: 'Rotate 90\u00B0 CW/CCW'},
                    {title: 'Flip Horizontal / Vertical'},
                    {title: 'Resize Destination Box'},
                    {title: 'Live Preview All Transforms'},
                ]
            },
            {
                title: 'Custom Brush',
                children: [
                    {title: 'Capture Selection as Brush'},
                    {title: 'Non-rectangular via Alpha Channel'},
                    {title: 'Flip H (Home) / V (End)'},
                    {title: 'Scale Up (PgUp) / Down (PgDn)'},
                    {title: 'Reset Scale ( / key)'},
                    {title: 'Recolor Mode (F9)'},
                    {title: 'Outline Mode (Shift+O)'},
                    {title: 'Export as PNG (F12)'},
                    {title: 'Works with Line/Rect/Ellipse/Poly'},
                ]
            },
            {
                title: 'Reference Image',
                children: [
                    {title: 'Toggle Ctrl+R'},
                    {title: 'Ctrl+Shift+Wheel = Opacity (5-100%)'},
                    {title: 'Reposition Mode (Drag/Zoom/Nudge)'},
                    {title: 'Renders Behind All Layers'},
                    {title: 'Persisted in .draw Files'},
                ]
            },
            {
                title: 'Symmetry Drawing (F7)',
                children: [
                    {title: 'Vertical | (2 copies)'},
                    {title: 'Cross + (4 copies)'},
                    {title: 'Asterisk * (8 copies)'},
                    {title: 'Ctrl+Click = Reposition Center'},
                    {title: 'Visual Guide Lines & Crosshair'},
                    {title: 'Works with All Drawing Tools'},
                    {title: 'F8 = Disable / Fill Adjust'},
                ]
            },
            {
                title: 'Angle Snap (Ctrl+Shift)',
                children: [
                    {title: 'Degree Mode (15\u00B0/30\u00B0/45\u00B0/90\u00B0)'},
                    {title: 'Pixel Art Mode (integer ratios)'},
                    {title: 'Ctrl+Shift Bypasses Grid Snap'},
                    {title: 'Works: Line, Polygon, Brush, Dot'},
                ]
            },
            {
                title: 'Pixel Art Analyzer (Tools menu)',
                children: [
                    {title: 'Orphan Pixels Detection'},
                    {title: 'Jagged Lines Detection'},
                    {title: 'Banding Detection'},
                    {title: 'Pillow Shading Detection'},
                    {title: 'Doubles Detection'},
                    {title: 'Precompute Engine (fast)'},
                ]
            },
        ]
    },

    {
        title: '\u2702\uFE0F Selection & Clipboard',
        id: 'selection',
        children: [
            {
                title: 'Marquee (M) \u2014 Rectangular',
                children: [
                    {title: 'Drag = Create Selection'},
                    {title: 'Shift+Drag = Add (Union)'},
                    {title: 'Alt+Drag = Subtract'},
                    {title: 'Resize Handles'},
                    {title: 'Drag Inside = Move'},
                    {title: 'Arrow Keys (1px / Shift 10px)'},
                    {title: 'Ctrl+Arrows = Resize'},
                ]
            },
            {title: 'Freehand Select (toolbar/palette)'},
            {title: 'Polygon Select (toolbar/palette)'},
            {title: 'Ellipse Select (toolbar/palette)'},
            {
                title: 'Magic Wand (W)',
                children: [
                    {title: 'Contiguous Same-Color Selection'},
                    {title: 'Shift+Click = Add to Selection'},
                    {title: 'Alt+Click = Subtract'},
                    {title: 'Hold F+Click = Flood Fill FG'},
                    {title: 'Hold E+Click = Flood Erase'},
                    {title: 'Hold W+Click = Select from Merged'},
                ]
            },
            {
                title: 'Selection Actions',
                children: [
                    {title: 'Select All (Ctrl+A)'},
                    {title: 'Invert Selection (Ctrl+Shift+I)'},
                    {title: 'Deselect (Ctrl+D / Escape)'},
                    {title: 'From Current Layer'},
                    {title: 'From Selected Layers (2+)'},
                    {title: 'Expand / Contract Selection'},
                ]
            },
            {
                title: 'Selection = Clipping Mask',
                children: [
                    {title: 'Clips all drawing tools'},
                    {title: 'Brush/Dot/Line/Rect/Ellipse/Poly/Fill'},
                    {title: 'Marching Ants visual feedback'},
                ]
            },
            {
                title: 'Clipboard Operations',
                children: [
                    {title: 'Copy (Ctrl+C)'},
                    {title: 'Cut (Ctrl+X)'},
                    {title: 'Paste at Cursor (Ctrl+V)'},
                    {title: 'Copy Merged (Ctrl+Shift+C)'},
                    {title: 'Clear Selection (Ctrl+E)'},
                    {title: 'Copy to New Layer (Ctrl+Alt+C)'},
                    {title: 'Cut to New Layer (Ctrl+Alt+X)'},
                    {title: 'Paste from OS (Ctrl+Shift+V)'},
                ]
            },
            {
                title: 'Stroke Selection (Edit menu)',
                children: [
                    {title: 'Configurable Width (px)'},
                    {title: 'FG or Custom Color'},
                    {title: 'Inside / Outside / Center'},
                ]
            },
        ]
    },

    {
        title: '\uD83D\uDCDA Layer System',
        id: 'layers',
        children: [
            {title: 'Up to 64 Layers (128 slots)'},
            {
                title: 'Per-Layer Properties',
                children: [
                    {title: 'Opacity (0-255, % display)'},
                    {title: 'Visibility Toggle'},
                    {title: 'Opacity Lock (no draw on transparent)'},
                    {title: 'Rename (R-Click)'},
                ]
            },
            {
                title: 'Blend Modes (19 + Pass Through)',
                children: [
                    {title: 'Normal (default)'},
                    {title: 'Multiply'},
                    {title: 'Screen'},
                    {title: 'Overlay'},
                    {title: 'Add (Linear Dodge)'},
                    {title: 'Subtract'},
                    {title: 'Difference'},
                    {title: 'Darken'},
                    {title: 'Lighten'},
                    {title: 'Color Dodge'},
                    {title: 'Color Burn'},
                    {title: 'Hard Light'},
                    {title: 'Soft Light'},
                    {title: 'Exclusion'},
                    {title: 'Vivid Light'},
                    {title: 'Linear Light'},
                    {title: 'Pin Light'},
                    {title: 'Color (Blend Mode)'},
                    {title: 'Luminosity'},
                    {title: 'Pass Through (Groups)'},
                ]
            },
            {
                title: 'Layer Groups',
                children: [
                    {title: 'New Group (Ctrl+G)'},
                    {title: 'Group from Selection (Ctrl+Shift+G)'},
                    {title: 'Ungroup (Ctrl+Shift+U)'},
                    {title: 'Collapsible (Triangle Toggle)'},
                    {title: 'Arbitrary Nesting Depth'},
                    {title: 'Drag Layer Into Group'},
                    {title: 'Merge Group to One Layer'},
                    {title: 'Select All in Group'},
                    {title: 'Selection from Group Pixels'},
                ]
            },
            {
                title: 'Layer Operations',
                children: [
                    {title: 'New Layer (Ctrl+Shift+N)'},
                    {title: 'Delete (Ctrl+Shift+Delete)'},
                    {title: 'Duplicate (Ctrl+Shift+D)'},
                    {title: 'Merge Down (Ctrl+Alt+E)'},
                    {title: 'Merge Visible (Ctrl+Alt+Shift+E)'},
                    {title: 'Merge Selected'},
                    {title: 'Move Up/Down (Ctrl+PgUp/PgDn)'},
                    {title: 'Arrange Top/Bottom (Ctrl+Home/End)'},
                    {title: 'Align (L/C/R/T/M/B)'},
                    {title: 'Distribute (H/V)'},
                ]
            },
            {
                title: 'Multi-Layer Select',
                children: [
                    {title: 'Ctrl+Click / Shift+Click rows'},
                    {title: 'Clear/Fill/Flip/Scale/Rotate all selected'},
                ]
            },
            {
                title: 'Layer Panel UI',
                children: [
                    {title: 'Eye Icon \u2014 Visibility Toggle'},
                    {title: 'Lock Icon \u2014 Opacity Lock'},
                    {title: 'Opacity Bar (drag/wheel)'},
                    {title: 'Alt+Click Eye = Solo Layer'},
                    {title: 'Drag Across Eyes = Swipe Vis'},
                    {title: 'Shift+R-Click = Cycle Blend Mode'},
                    {title: 'R-Click = Context Menu'},
                    {title: 'Drag & Drop Reordering'},
                    {title: 'Auto-scroll when dragging'},
                ]
            },
        ]
    },

    {
        title: '\uD83C\uDFA8 Color & Palette System',
        id: 'color',
        children: [
            {
                title: 'Palette Strip',
                children: [
                    {title: 'L-Click = Select FG Color'},
                    {title: 'R-Click = Select BG Color'},
                    {title: 'Wheel = Scroll / Shift+Wheel = Fast (32)'},
                    {title: '\u25C4 \u25BA Arrow Buttons'},
                ]
            },
            {
                title: 'Palette Dropdown',
                children: [
                    {title: 'Click Name = Switch Palettes'},
                    {title: '56 Bundled .GPL Files'},
                    {title: 'Letter keys jump to palette name'},
                ]
            },
            {
                title: 'Palette Ops Mode',
                children: [
                    {title: 'Dbl-Click = Change Color (replaces on canvas)'},
                    {title: 'R-Click = Mark Color'},
                    {title: 'M-Click = Delete Color (remap neighbor)'},
                    {title: 'Shift+M-Click = Insert Color'},
                    {title: 'Drag = Rearrange Order'},
                    {title: 'L-Click = Magic Wand Select'},
                    {title: 'Auto [DOCUMENT] Palette Creation'},
                ]
            },
            {
                title: 'Color Picker (RGB)',
                children: [
                    {title: 'Click Status Bar FG/BG Swatches'},
                    {title: 'True RGB Color Selection'},
                ]
            },
            {
                title: 'FG / BG Color Controls',
                children: [
                    {title: 'X = Swap FG/BG'},
                    {title: 'Ctrl+D = Reset (White/Black)'},
                    {title: 'Shift+Del = BG Transparent'},
                ]
            },
            {
                title: 'Paint Opacity (1-0 keys)',
                children: [
                    {title: 'Keys 1-9 = 10%-90%'},
                    {title: 'Key 0 = 100% (fully opaque)'},
                    {title: 'Per-stroke compositing (no compounding)'},
                ]
            },
            {
                title: 'Palette Workflows',
                children: [
                    {title: 'Download from Lospec'},
                    {title: 'Create Palette from Image'},
                    {title: 'Remap Artwork to Active Palette'},
                    {title: 'Import/Export .GPL files'},
                ]
            },
        ]
    },

    {
        title: '\uD83D\uDCDD Text System',
        id: 'text',
        children: [
            {
                title: 'Text Entry & Navigation',
                children: [
                    {title: 'Arrow keys / Home / End'},
                    {title: 'Ctrl+Left/Right = Word Nav'},
                    {title: 'Ctrl+Home/End = Start/End'},
                    {title: 'Backspace / Delete chars'},
                    {title: 'Enter = New Line'},
                    {title: 'Escape = Apply/Finish'},
                ]
            },
            {
                title: 'Text Selection',
                children: [
                    {title: 'Shift+Arrow = Select chars'},
                    {title: 'Double-click = Word'},
                    {title: 'Triple-click = Line'},
                    {title: 'Quad-click = All'},
                    {title: 'Ctrl+A = Select All'},
                ]
            },
            {
                title: 'Font System',
                children: [
                    {title: 'VGA (Default) \u2014 T key'},
                    {title: 'Tiny5 Small \u2014 Shift+T'},
                    {title: 'Custom TTF/OTF \u2014 Ctrl+T (M-Click load)'},
                    {title: 'Bitmap Fonts (Fontaption/PSF/BDF)'},
                    {
                        title: 'Color Bitmap Fonts (CBF)',
                        children: [
                            {title: '24 Bundled DPaint-style .bmp fonts'},
                            {title: 'Preserve original pixel colors'},
                            {title: 'Fixed native glyph height'},
                        ]
                    },
                ]
            },
            {
                title: 'Rich Per-Character Formatting',
                children: [
                    {title: 'Bold'},
                    {title: 'Italic'},
                    {title: 'Underline'},
                    {title: 'Strikethrough'},
                    {title: 'Outline (Color + Size)'},
                    {title: 'Shadow (Color + X/Y Offset 1-10px)'},
                    {title: 'Per-character FG/BG Colors'},
                    {title: 'Letter Spacing / Line Height'},
                    {title: 'Auto-Wrap'},
                ]
            },
            {
                title: 'Text Layers (Persistent)',
                children: [
                    {title: 'Click existing to re-edit'},
                    {title: 'Persisted in DRW files'},
                    {title: 'Full undo/redo support'},
                    {title: 'Rasterize Text Layer'},
                    {title: 'New Text Layer (Layer menu)'},
                ]
            },
            {
                title: 'Text-Local Undo/Redo',
                children: [
                    {title: 'Ctrl+Z / Ctrl+Y within text mode'},
                    {title: 'Up to 128 states'},
                    {title: 'Separate from canvas undo'},
                ]
            },
            {
                title: 'Style Presets',
                children: [
                    {title: 'Save [S] / Load / Update [U] / Delete [X]'},
                    {title: 'Stores: B/I/U/S, Outline, Shadow, Align, AA'},
                ]
            },
            {
                title: 'Character Map (Ctrl+M)',
                children: [
                    {title: '16x16 Glyph Grid (256 chars)'},
                    {title: 'Click glyph = Insert / Custom Brush'},
                    {title: 'Dockable Left/Right'},
                    {title: 'Dynamic cell count (4-16 per row)'},
                    {title: 'Bitmap Font Rendering'},
                ]
            },
            {
                title: 'Character Mode (CHAR)',
                children: [
                    {title: 'Virtual Cursor \u2014 Free Grid Navigation'},
                    {title: 'F1-F12 = ANSI Block Characters'},
                    {title: 'Font Stickiness'},
                    {title: 'DOT/RECT drawing on Text Layers'},
                    {title: 'Alt+U = Color Pickup'},
                    {title: 'Character Grid Overlay + Snap'},
                    {title: 'Persisted per-document (DRW v19+)'},
                ]
            },
            {
                title: 'Text Property Bar (GUI)',
                children: [
                    {title: 'Font Dropdown'},
                    {title: 'Size Dropdown'},
                    {title: 'B / I / U / S Toggle Buttons'},
                    {title: 'Outline Toggle + Color + Size'},
                    {title: 'Shadow Toggle + Color + X/Y'},
                    {title: 'FG/BG Color Swatches'},
                    {title: 'Style Preset Controls'},
                ]
            },
        ]
    },

    {
        title: '\uD83D\uDDBC\uFE0F Canvas & View',
        id: 'canvas',
        children: [
            {title: 'Configurable Canvas Size (up to 4096x4096)'},
            {
                title: 'Zoom Controls',
                children: [
                    {title: 'Mouse Wheel / Ctrl +/-'},
                    {title: 'Snap Levels: 25%-800%'},
                    {title: 'Reset Ctrl+0 / Double-Middle'},
                ]
            },
            {
                title: 'Pan Controls',
                children: [
                    {title: 'Middle Mouse Drag'},
                    {title: 'Spacebar + Drag'},
                    {title: 'Arrow Keys (Keyboard)'},
                ]
            },
            {title: 'Scrollbars (large canvases)'},
            {
                title: 'Preview Window (F4)',
                children: [
                    {title: 'Follow Mode (Magnifier)'},
                    {title: 'Floating Image Mode'},
                    {title: 'Bin Quick Look (hover drawer)'},
                    {title: 'Color Picking (Alt+Click)'},
                    {title: 'Recent Images (up to 10)'},
                    {title: 'Independent Zoom/Pan'},
                    {title: 'Move & Resize Controls'},
                ]
            },
            {title: 'Pattern Tile Mode (Shift+Tab, up to 512x512)'},
            {title: 'Grayscale Preview (Ctrl+Alt+Shift+G)'},
            {title: 'Canvas Border Toggle (# key)'},
            {title: 'Clear Canvas \u2014 Del (prompt) / Backspace (instant)'},
        ]
    },

    {
        title: '\uD83D\uDCD0 Grid System',
        id: 'grid',
        children: [
            {title: "Grid Toggle (' key)"},
            {title: "Pixel Grid (Shift+', 400%+ zoom)"},
            {title: 'Snap-to-Grid Toggle (; key)'},
            {title: 'Size Adjust ( . , keys, 2-50px)'},
            {
                title: "Grid Geometry Modes (Ctrl+')",
                children: [
                    {title: 'Square (default)'},
                    {title: 'Diagonal (45\u00B0 diamond)'},
                    {title: 'Isometric (2:1 pixel art)'},
                    {title: 'Hexagonal (flat-top)'},
                ]
            },
            {title: 'Alignment: Corner / Center (View menu)'},
            {
                title: 'Grid Cell Fill Mode',
                children: [
                    {title: 'Fills Squares (Square mode)'},
                    {title: 'Fills Diamonds (Diagonal)'},
                    {title: 'Fills Triangles (Isometric)'},
                    {title: 'Fills Hexagons (Hex mode)'},
                ]
            },
            {
                title: 'Crosshair Assistant',
                children: [
                    {title: 'Show with Shift (held)'},
                    {title: 'Configurable outline stroke'},
                    {title: 'Color / Opacity / Width'},
                ]
            },
            {
                title: 'Smart Guides',
                children: [
                    {title: 'Align to Edges / Centers / Canvas'},
                    {title: 'Snap Enable (Ctrl+;)'},
                    {title: 'Visibility (Ctrl+Shift+;)'},
                    {title: 'Themeable Colors & Opacity'},
                ]
            },
            {title: 'Ctrl+Shift bypasses grid snap'},
            {title: 'Both grids shown simultaneously at high zoom'},
            {title: 'Grid state persisted in .draw files'},
        ]
    },

    {
        title: '\uD83D\uDD8A\uFE0F Brush System',
        id: 'brush-sys',
        children: [
            {title: 'Size 1-50px ([ ] keys)'},
            {title: 'Shape: Circle / Square (\\\\ key)'},
            {title: 'Preview Mode (` key)'},
            {title: 'Pixel Perfect Mode (F6)'},
            {title: '4 Size Presets (Organizer)'},
            {title: 'Visual Cursor w/ Current Color'},
            {title: 'Affects all drawing tools'},
            {
                title: 'Paint Modes',
                children: [
                    {title: 'Normal (solid color)'},
                    {title: 'Pattern (from Drawer)'},
                    {title: 'Gradient (from Drawer)'},
                    {title: '1-Bit Pattern (opaque BG)'},
                ]
            },
            {
                title: 'Dithering Algorithms',
                children: [
                    {title: 'Ordered (Bayer 2x2, 4x4, 8x8)'},
                    {title: 'Floyd-Steinberg'},
                    {title: 'Atkinson'},
                    {title: 'Stucki'},
                    {title: 'Blue Noise'},
                ]
            },
        ]
    },

    {
        title: '\uD83D\uDD04 Transform Operations',
        id: 'transform',
        children: [
            {title: 'Flip Horizontal (H key)'},
            {title: 'Flip Vertical (Ctrl+Shift+H)'},
            {title: 'Rotate 90\u00B0 CW (> key)'},
            {title: 'Rotate 90\u00B0 CCW (< key)'},
            {title: 'Scale Up 50% (Ctrl+Shift+=)'},
            {title: 'Scale Down 50% (Ctrl+Shift+-)'},
            {
                title: 'Transform Overlay (Edit \u2192 TRANSFORM)',
                children: [
                    {title: 'Scale (Shift = Lock Aspect)'},
                    {title: 'Rotate (Shift = 15\u00B0 Snap)'},
                    {title: 'Shear'},
                    {title: 'Distort (Independent Corners)'},
                    {title: 'Perspective (Shift = Mirror)'},
                    {title: 'Themeable Frame & Handles'},
                    {title: 'Enter = Apply / Esc = Cancel'},
                ]
            },
            {
                title: 'Move Tool (V)',
                children: [
                    {title: 'Arrow Keys (1px / Shift 10px)'},
                    {title: 'Alt+Drag = Clone Stamp'},
                    {title: 'Ctrl+Arrows = Resize'},
                    {title: 'Shift+Click = Auto-Select Layer'},
                ]
            },
            {title: 'Works on Layer / Selection / Float'},
        ]
    },

    {
        title: '\uD83C\uDF9B\uFE0F Image Adjustments',
        id: 'imgadj',
        children: [
            {
                title: 'Dialogs (Live Preview)',
                children: [
                    {title: 'Brightness / Contrast'},
                    {title: 'Hue / Saturation'},
                    {title: 'Levels (B/W/Gamma)'},
                    {title: 'Color Balance (Shadows/Mid/Highlights)'},
                    {title: 'Blur (Gaussian, adjustable radius)'},
                    {title: 'Sharpen (adjustable intensity)'},
                ]
            },
            {
                title: 'One-Shot Adjustments',
                children: [
                    {title: 'Invert (RGB negative)'},
                    {title: 'Desaturate (luminosity grayscale)'},
                    {title: 'Posterize (N levels + dithering)'},
                    {title: 'Pixelate (block cell size)'},
                ]
            },
            {title: 'Flip Canvas H / V (Image menu)'},
            {
                title: 'Common Features',
                children: [
                    {title: 'Live Preview while dialog open'},
                    {title: 'Mouse Wheel on sliders'},
                    {title: 'Alpha Channel preserved'},
                    {title: 'Per-layer operation'},
                    {title: 'Saves undo state (Ctrl+Z)'},
                ]
            },
        ]
    },

    {
        title: '\uD83D\uDCBE File I/O',
        id: 'fileio',
        children: [
            {
                title: 'Open / Load',
                children: [
                    {title: 'Open Image (Ctrl+O) \u2014 PNG/BMP/JPG/GIF'},
                    {title: 'Open Project (.draw) \u2014 Alt+O'},
                    {title: 'Open Aseprite (.ase/.aseprite)'},
                    {title: 'Open PSD (.psd)'},
                    {title: 'Import Image (oversized placement)'},
                    {title: 'Windows Drag & Drop'},
                    {title: 'Command Line File Argument'},
                ]
            },
            {
                title: 'Save',
                children: [
                    {title: 'Save (Ctrl+S) \u2014 silent if saved before'},
                    {title: 'Save As (Ctrl+Shift+S) \u2014 prompt'},
                    {title: 'Export Selection (Ctrl+Alt+Shift+S)'},
                    {title: 'Export Layer as PNG'},
                    {title: 'Export Brush as PNG (F12)'},
                ]
            },
            {
                title: 'Export As (9 Formats)',
                children: [
                    {title: 'PNG Native (with alpha)'},
                    {title: 'PNG Plain'},
                    {title: 'GIF'},
                    {title: 'JPEG'},
                    {title: 'TGA'},
                    {title: 'BMP'},
                    {title: 'HDR'},
                    {title: 'ICO'},
                    {title: 'QOI'},
                ]
            },
            {
                title: 'DRW Project Format',
                children: [
                    {title: 'PNG with embedded drAw chunk'},
                    {title: 'All layers + blend modes + opacity'},
                    {title: 'Palette state'},
                    {title: 'Tool states + grid + snap'},
                    {title: 'Reference image config'},
                    {title: 'Extract images settings'},
                    {title: 'Text layer data'},
                    {title: 'Viewable in any image viewer'},
                ]
            },
            {title: 'Recent Files (up to 10, Alt+1-0)'},
            {title: 'New from Template'},
            {
                title: 'Extract Images (File menu)',
                children: [
                    {title: 'Flood-fill connected regions'},
                    {title: 'Per-layer extraction'},
                    {title: 'Merged extraction'},
                    {title: 'Transparent / FG / BG background'},
                    {title: 'Output as separate PNGs'},
                ]
            },
            {title: 'QB64 Source Code Export'},
        ]
    },

    {
        title: '\uD83D\uDDA5\uFE0F User Interface',
        id: 'ui',
        children: [
            {
                title: 'Menu Bar (11 Menus)',
                children: [
                    {title: 'File'},
                    {title: 'Edit'},
                    {title: 'View'},
                    {title: 'Select'},
                    {title: 'Tools'},
                    {title: 'Brush'},
                    {title: 'Layer'},
                    {title: 'Palette'},
                    {title: 'Image'},
                    {title: 'Help'},
                    {title: 'Audio'},
                    {title: 'Alt key keyboard navigation'},
                    {title: 'Hotkey hints on items'},
                    {title: 'Cascading submenus'},
                    {title: 'Toggle checkmarks'},
                ]
            },
            {
                title: 'Toolbar (4x7 Grid, 28 Buttons)',
                children: [
                    {title: 'Themeable PNG Icons'},
                    {title: 'Active tool indicator'},
                    {title: 'Toggle with Tab'},
                ]
            },
            {
                title: 'Organizer Widget',
                children: [
                    {title: '4x3 Layout'},
                    {title: 'Brush Presets'},
                    {title: 'Palette Ops Toggle'},
                ]
            },
            {
                title: 'Drawer Panel (30 Slots)',
                children: [
                    {title: 'Brush Mode (F1)'},
                    {title: 'Gradient Mode (F2)'},
                    {title: 'Pattern Mode (F3)'},
                    {title: '1-Bit Patterns (opaque BG)'},
                    {title: 'Shift+L-Click = Store'},
                    {title: 'R-Click = Context Menu'},
                    {title: 'Load Images (batch import)'},
                    {title: 'Drag & Drop Reorder'},
                    {title: '.dset Import/Export'},
                    {title: 'Mini Palette'},
                ]
            },
            {
                title: 'Edit Bar (F5)',
                children: [
                    {title: 'Undo / Redo Icons'},
                    {title: 'Smart Guides Toggle'},
                    {title: 'Pixel Perfect Toggle'},
                    {title: 'Flip Canvas H/V'},
                    {title: 'Dockable Left/Right'},
                ]
            },
            {
                title: 'Advanced Bar (Shift+F5)',
                children: [
                    {title: '26+ Quick Toggle Buttons'},
                    {title: 'Char Map / Grid / Snap Toggles'},
                    {title: 'Preview / Edit Bar Toggles'},
                    {title: 'Tile / Grid / Fill Toggles'},
                    {title: 'Reference Image Controls'},
                    {title: 'Dockable Left/Right'},
                ]
            },
            {
                title: 'Status Bar (F10)',
                children: [
                    {title: 'Current Tool Name'},
                    {title: 'X,Y Coordinates'},
                    {title: 'Zoom Level %'},
                    {title: 'Grid State (G:n S/Mode)'},
                    {title: 'FG/BG Color Swatches'},
                    {title: 'Paint Opacity OP:nn%'},
                    {title: 'Symmetry SYM:n'},
                    {title: 'Custom Brush CB/CB+RECOLOR'},
                ]
            },
            {title: 'Command Palette (? / Help)'},
            {title: 'Tooltips (toggleable)'},
            {
                title: 'Layout Docking',
                children: [
                    {title: 'Toolbox Left/Right'},
                    {title: 'Layer Panel Left/Right'},
                    {title: 'Edit Bar Left/Right'},
                    {title: 'Advanced Bar Left/Right'},
                    {title: 'Char Map Left/Right'},
                    {title: 'Ctrl+Shift+Click = Toggle Side'},
                ]
            },
            {
                title: 'Cursor System',
                children: [
                    {title: 'OS Native for UI Areas'},
                    {title: 'Crosshair for Drawing'},
                    {title: 'I-Beam for Text'},
                    {title: 'Custom PNG for Special Tools'},
                    {title: 'Configurable in DRAW.cfg'},
                ]
            },
            {title: 'Auto-Hide During Drawing'},
            {
                title: 'Settings Dialog (Ctrl+,)',
                children: [
                    {title: 'General'},
                    {title: 'Grid'},
                    {title: 'Palette'},
                    {title: 'Panels'},
                    {title: 'Audio'},
                    {title: 'Fonts'},
                    {title: 'Appearance'},
                    {title: 'Directories'},
                ]
            },
            {title: 'About Screen (animated logo + version)'},
        ]
    },

    {
        title: '\uD83D\uDD0A Audio System',
        id: 'audio',
        children: [
            {
                title: 'Sound Effects (21 Slots)',
                children: [
                    {title: 'Menus / Tools / Selection / Fill'},
                    {title: 'Clipboard / Layers / Text / Sliders'},
                    {title: 'Drag-Drop / Point / Organizer'},
                    {title: 'Per-theme replaceable'},
                    {title: 'Enable / Disable / Volume / Mute'},
                ]
            },
            {
                title: 'Background Music',
                children: [
                    {title: 'Auto-Shuffle (random tracks)'},
                    {title: 'Formats: .mod .xm .it .s3m .rad'},
                    {title: 'Next/Prev/Random (} { * keys)'},
                    {title: 'Volume / Mute (independent of SFX)'},
                    {title: 'Explore Music Folder'},
                    {title: 'NOW PLAYING in Audio Menu'},
                ]
            },
        ]
    },

    {
        title: '\uD83C\uDFA8 Theming System',
        id: 'theming',
        children: [
            {title: 'All Colors Themeable'},
            {title: 'PNG Icons Replaceable'},
            {title: 'Sound Files Per Theme'},
            {title: 'Music Folder Per Theme'},
            {title: 'THEME.CFG (no recompile needed)'},
            {title: 'Layer Panel fully themeable'},
            {title: 'Transform overlay frame themeable'},
            {title: 'Smart guide colors themeable'},
        ]
    },

    {
        title: '\u2699\uFE0F Configuration',
        id: 'config',
        children: [
            {
                title: 'DRAW.cfg Config File',
                children: [
                    {title: 'FPS Limits (Idle / Active)'},
                    {title: 'Grid Color / Opacity / Angle'},
                    {title: 'Transparency Checkerboard'},
                    {title: 'SFX / Music Enable / Vol / Mute'},
                    {title: 'SYSTEM_CURSORS Toggle'},
                    {title: 'ANGLE_SNAP_DEGREES'},
                    {title: 'Font Include Directories'},
                    {title: '--config-upgrade (reconcile)'},
                ]
            },
            {
                title: 'OS-Specific Config Files',
                children: [
                    {title: 'DRAW.macOS.cfg'},
                    {title: 'DRAW.linux.cfg'},
                    {title: 'DRAW.windows.cfg'},
                    {title: '--config / -c flag override'},
                ]
            },
            {
                title: 'Auto-Detection (First Launch)',
                children: [
                    {title: 'Display Scale (targets 90% desktop)'},
                    {title: 'Toolbar Scale (from viewport height)'},
                    {title: 'Screen Dimensions (rounded even)'},
                ]
            },
            {title: 'Display Scale (1x-8x)'},
            {title: 'Toolbar Scale (1x-4x)'},
            {title: 'Keyboard Bindings'},
            {title: 'Mouse Bindings'},
            {title: 'Joystick Bindings'},
        ]
    },

    {
        title: '\u21A9\uFE0F Undo / Redo System',
        id: 'undo',
        children: [
            {title: 'Unified History (Ctrl+Z / Ctrl+Y)'},
            {title: 'Auto-record on mouse release'},
            {title: 'Double-save prevention'},
            {title: 'Multi-layer undo support'},
            {title: 'Text-local undo (128 states)'},
        ]
    },

    {
        title: '\uD83C\uDFAE Input System',
        id: 'input',
        children: [
            {
                title: 'Mouse Input',
                children: [
                    {title: 'Raw / Canvas / Unsnapped coordinates'},
                    {title: 'Press / Release transition detect'},
                    {title: 'Deferred actions'},
                    {title: 'UI Chrome skip logic'},
                ]
            },
            {
                title: 'Keyboard Shortcuts',
                children: [
                    {title: 'Tool selection (B/D/F/I/K/L/P/R/C/E/Z/T/M/W/V)'},
                    {title: 'Modifier combos (Ctrl/Shift/Alt)'},
                    {title: 'KEYDOWN for Ctrl+ combos (not KEYHIT)'},
                ]
            },
            {title: 'Joystick / Stick Support'},
            {title: 'Modifier Tracking (Ctrl/Shift/Alt)'},
        ]
    },

    {
        title: '\uD83D\uDCBB Platform Support',
        id: 'platform',
        children: [
            {title: 'Windows'},
            {title: 'Linux'},
            {title: 'macOS'},
            {
                title: 'Installers & File Association',
                children: [
                    {title: 'Linux: .desktop + MIME type'},
                    {title: 'Windows: Registry + Start Menu'},
                    {title: 'macOS: install-mac.command'},
                ]
            },
            {title: 'Built with QB64-PE v4.x+'},
        ]
    },

    {
        title: '\uD83D\uDDB5 Rendering Pipeline',
        id: 'rendering',
        children: [
            {title: 'Scene Cache + Dirty Tracking'},
            {title: 'Layer Compositing (blend modes)'},
            {title: '_MEM per-pixel blend processing'},
            {title: 'Idle Detection (15 FPS throttle)'},
            {title: 'Configurable FPS Limit'},
            {title: '_LIMIT after SCREEN_render (no lag)'},
        ]
    },
];

// =============================================================================
// BUILD MULTI-SHEET WORKBOOK
// =============================================================================

// Step 1: Prepare sheet definitions — overview + one per branch
const sheetDefs = [
    { s: 'Overview', t: 'DRAW \u2014 Pixel Art Editor v0.31.0' },
];
for (const branch of featureTree) {
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
const overviewTopic = new Topic({sheet: overviewSheet});

// Collect root topic IDs from each sub-sheet (link target must be the topic, not the sheet)
const rootTopicIds = {};
for (const branch of featureTree) {
    const sheet = wb.getSheet(sheetIds[branch.title]);
    const rootTopic = sheet.getRootTopic();
    rootTopicIds[branch.title] = rootTopic.getId();
}

for (const branch of featureTree) {
    overviewTopic.on().add({title: branch.title});
    // Add cross-sheet link targeting the root topic in the sub-sheet
    const childUUID = overviewTopic.cid();
    const childComponent = overviewSheet.findComponentById(childUUID);
    if (childComponent && childComponent.addHref) {
        childComponent.addHref('xmind:#' + rootTopicIds[branch.title]);
    }
}

// Step 3: Build each sub-sheet with its full tree
function addChildrenToTopic(topic, parentUUID, children) {
    for (const child of children) {
        if (parentUUID) {
            topic.on(parentUUID);
        } else {
            topic.on(); // root
        }
        topic.add({title: child.title});
        const uuid = topic.cid();
        if (child.children && child.children.length > 0) {
            addChildrenToTopic(topic, uuid, child.children);
        }
    }
}

// Get the Overview root topic ID for back-links
const overviewRootTopicId = overviewSheet.getRootTopic().getId();

for (const branch of featureTree) {
    const sheetId = sheetIds[branch.title];
    const sheet = wb.getSheet(sheetId);
    const topic = new Topic({sheet});

    // Add back-link on the root topic targeting the Overview's root topic
    const rootComponent = sheet.getRootTopic();
    if (rootComponent && rootComponent.addHref) {
        rootComponent.addHref('xmind:#' + overviewRootTopicId);
    }

    // Build the sub-tree
    if (branch.children) {
        addChildrenToTopic(topic, null, branch.children);
    }
}

// Step 4: Apply snowbrush theme to every sheet
// wb.theme() only works with createSheet (sets this.sheet).
// For createSheets, apply theme directly via xmind-model sheet.changeTheme().
const { Theme } = require(require.resolve('xmind/dist/core/theme'));
function applyTheme(sheetId) {
    const sheet = wb.getSheet(sheetId);
    if (sheet && sheet.changeTheme) {
        const themeInstance = new Theme({themeName: 'snowbrush'});
        sheet.changeTheme(themeInstance.data);
    }
}
applyTheme(sheetIds['Overview']);
for (const branch of featureTree) {
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
countNodes(featureTree);
console.log('Total nodes: ' + nodeCount + ', Sheets: ' + created.length);

// Step 5: Save
const zipper = new Zipper({path: OUTPUT_DIR, workbook: wb, filename: FILENAME});
zipper.save().then(function(status) {
    if (status) {
        console.log('SUCCESS: ' + OUTPUT_DIR + '/' + FILENAME + '.xmind');
    } else {
        console.error('FAILED to save xmind file');
        process.exit(1);
    }
});
