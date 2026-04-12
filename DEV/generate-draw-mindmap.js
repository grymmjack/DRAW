/**
 * DRAW Feature Mind Map Generator (.xmind format)
 * 
 * Usage: node generate-draw-mindmap.js [output-dir]
 * Default output: ../PLANS/diagrams/DRAW-feature-mindmap.xmind
 */
const { Workbook, Topic, Zipper } = require('xmind');
const path = require('path');

const OUTPUT_DIR = process.argv[2] || path.join(__dirname, '..', 'PLANS', 'diagrams');
const FILENAME = 'DRAW-feature-mindmap';

const wb = new Workbook();
const sheet = wb.createSheet('DRAW Features', 'DRAW — Pixel Art Editor v0.31.0');
const t = new Topic({sheet});
const ids = {}; // map custom keys → SDK UUIDs

/**
 * Recursively add children to the mind map.
 * Uses t.on(parentUUID).add({title}) then t.cid() to capture the UUID.
 */
function addChildren(parentUUID, children) {
    for (const child of children) {
        if (parentUUID) {
            t.on(parentUUID);
        } else {
            t.on(); // root
        }
        t.add({title: child.title});
        const uuid = t.cid();
        if (child.id) {
            ids[child.id] = uuid;
        }
        if (child.children && child.children.length > 0) {
            addChildren(uuid, child.children);
        }
    }
}

// =============================================================================
// FULL FEATURE TREE — 19 major branches, 400+ nodes, up to 10 levels deep
// =============================================================================

const featureTree = [
    // =========================================================================
    // 1. DRAWING TOOLS
    // =========================================================================
    {
        title: '🖌️ Drawing Tools',
        id: 'tools',
        children: [
            {
                title: 'Brush (B)',
                id: 'tool-brush',
                children: [
                    {title: 'Freehand Painting (drag to paint)', id: 'brush-freehand'},
                    {title: 'Size 1-50px ([ ] keys)', id: 'brush-size'},
                    {title: 'Circle / Square shape (\\ key)', id: 'brush-shape'},
                    {title: 'Preview Mode (` key)', id: 'brush-preview'},
                    {title: 'Pixel Perfect Mode (F6)', id: 'brush-pixperf'},
                    {title: 'Shift = Axis Constrain', id: 'brush-axis'},
                    {title: 'Shift+RClick = Connecting Line', id: 'brush-connect'},
                    {title: 'L-Click FG / R-Click BG', id: 'brush-lr'},
                    {title: '4 Size Presets (Organizer)', id: 'brush-presets'},
                ]
            },
            {
                title: 'Dot / Stamp (D)',
                id: 'tool-dot',
                children: [
                    {title: 'Single-pixel stamp (click, no drag)', id: 'dot-stamp'},
                    {title: 'Shift+RClick = Connecting Line', id: 'dot-connect'},
                    {title: 'Uses Brush Size & Shape', id: 'dot-brush'},
                ]
            },
            {
                title: 'Line (L)',
                id: 'tool-line',
                children: [
                    {title: 'Brush-sized thick preview', id: 'line-thick'},
                    {title: 'Shift = H/V Constrain', id: 'line-shift'},
                    {title: 'Ctrl+Shift = Angle Snap', id: 'line-snap'},
                    {title: 'Symmetry support', id: 'line-sym'},
                ]
            },
            {
                title: 'Rectangle (R / Shift+R)',
                id: 'tool-rect',
                children: [
                    {title: 'Outlined (R)', id: 'rect-outline'},
                    {title: 'Filled (Shift+R)', id: 'rect-filled'},
                    {title: 'Ctrl = Perfect Square', id: 'rect-square'},
                    {title: 'Shift = Draw from Center', id: 'rect-center'},
                    {
                        title: 'Fill Adjust (F8) — Tiled Fill',
                        id: 'rect-filladj',
                        children: [
                            {title: 'Drag = Reposition Tile Origin', id: 'rect-fa-drag'},
                            {title: 'Wheel = Uniform Scale', id: 'rect-fa-wheel'},
                            {title: 'L-Handle = Independent X/Y', id: 'rect-fa-lhandle'},
                            {title: 'Rotation Handle', id: 'rect-fa-rotate'},
                            {title: 'Enter Apply / Esc Cancel', id: 'rect-fa-apply'},
                        ]
                    },
                ]
            },
            {
                title: 'Ellipse (C / Shift+C)',
                id: 'tool-ellipse',
                children: [
                    {title: 'Outlined (C)', id: 'ell-outline'},
                    {title: 'Filled (Shift+C)', id: 'ell-filled'},
                    {title: 'Ctrl = Perfect Circle', id: 'ell-circle'},
                    {title: 'Shift = Draw from Center', id: 'ell-center'},
                    {title: 'Fill Adjust (F8) — Tiled Fill', id: 'ell-filladj'},
                ]
            },
            {
                title: 'Polygon (P / Shift+P)',
                id: 'tool-polygon',
                children: [
                    {title: 'Outlined (P)', id: 'poly-outline'},
                    {title: 'Filled (Shift+P)', id: 'poly-filled'},
                    {title: 'Click = Add Point, Enter = Close', id: 'poly-points'},
                    {title: 'Ctrl+Shift = Angle Snap', id: 'poly-snap'},
                    {title: 'Fill Adjust (F8) — Tiled Fill', id: 'poly-filladj'},
                ]
            },
            {
                title: 'Fill / Flood Fill (F)',
                id: 'tool-fill',
                children: [
                    {title: 'Standard Flood Fill', id: 'fill-flood'},
                    {title: 'Shift = Sample from Merged Visible', id: 'fill-merged'},
                    {title: 'Custom Brush Tiled Fill', id: 'fill-custom'},
                    {title: 'Pattern / Gradient Paint Mode', id: 'fill-pattern'},
                    {
                        title: 'Fill Adjustment Overlay (F8)',
                        id: 'fill-adjust',
                        children: [
                            {title: 'Drag = Reposition Tile Origin', id: 'fa-drag'},
                            {title: 'Mouse Wheel = Uniform Scale', id: 'fa-wheel'},
                            {title: 'L-Handle: Independent X/Y Scale', id: 'fa-lhandle'},
                            {title: 'Rotation Handle (Arc Drag)', id: 'fa-rotate'},
                            {title: 'Enter = Apply / Esc = Cancel', id: 'fa-apply'},
                        ]
                    },
                ]
            },
            {
                title: 'Spray (K)',
                id: 'tool-spray',
                children: [
                    {title: 'Brush-shaped Nozzle Tips', id: 'spray-nozzle'},
                    {title: 'Radius doubles per brush size level', id: 'spray-radius'},
                    {title: 'Density scales with radius', id: 'spray-density'},
                    {title: 'Custom Brush Stamp Support', id: 'spray-custom'},
                    {title: 'Shift = Axis Constrain', id: 'spray-axis'},
                    {title: 'Circle + Dot Preview', id: 'spray-preview'},
                ]
            },
            {
                title: 'Picker / Eyedropper (I)',
                id: 'tool-picker',
                children: [
                    {title: 'Cursor-adjacent Loupe Overlay', id: 'picker-loupe'},
                    {title: 'Shows RGB + Hex Values', id: 'picker-rgb'},
                    {title: 'ALT+Click = Temp Picker (any tool)', id: 'picker-alt'},
                    {title: 'Alt+L = Pick FG / Alt+R = Pick BG', id: 'picker-fgbg'},
                ]
            },
            {
                title: 'Eraser (E)',
                id: 'tool-eraser',
                children: [
                    {title: 'Paints Transparent Pixels', id: 'eraser-trans'},
                    {title: 'Hold E = Temporary Eraser', id: 'eraser-hold'},
                    {title: 'Shift = Smart Erase (all visible layers)', id: 'eraser-smart'},
                    {title: 'Uses Current Brush Size & Shape', id: 'eraser-brush'},
                    {title: 'Custom Brush Support', id: 'eraser-custom'},
                    {title: 'Status: FG:TRN indicator', id: 'eraser-status'},
                ]
            },
            {
                title: 'Zoom (Z)',
                id: 'tool-zoom',
                children: [
                    {title: 'Click = Zoom In', id: 'zoom-in'},
                    {title: 'Alt+Click = Zoom Out', id: 'zoom-out'},
                    {title: 'Drag = Zoom to Region', id: 'zoom-rect'},
                    {title: 'Snap Levels: 25%–800%', id: 'zoom-levels'},
                ]
            },
            {
                title: 'Pan / Hand Tool',
                id: 'tool-pan',
                children: [
                    {title: 'Dedicated Pan Mode (L-Click drag)', id: 'pan-dedicated'},
                    {title: 'Middle Mouse = Pan (any tool)', id: 'pan-middle'},
                    {title: 'Spacebar + Drag = Pan (any tool)', id: 'pan-space'},
                    {title: 'Double-Click = Reset Zoom+Pan', id: 'pan-reset'},
                ]
            },
            {
                title: 'Crop',
                id: 'tool-crop',
                children: [
                    {title: 'Marquee-based Crop Region', id: 'crop-marquee'},
                    {title: 'Resize Handles + Drag Move', id: 'crop-handles'},
                    {title: 'Dark Overlay Outside Region', id: 'crop-overlay'},
                    {title: 'Size Label Display', id: 'crop-label'},
                    {title: 'Canvas Resize Dialog', id: 'crop-resize'},
                ]
            },
            {
                title: 'Image Import',
                id: 'tool-import',
                children: [
                    {title: 'Oversized Image Placement', id: 'import-oversize'},
                    {title: 'Zoom + Pan Within Image', id: 'import-zoom'},
                    {title: 'Rotate 90° CW/CCW', id: 'import-rotate'},
                    {title: 'Flip Horizontal / Vertical', id: 'import-flip'},
                    {title: 'Resize Destination Box', id: 'import-resize'},
                    {title: 'Live Preview All Transforms', id: 'import-live'},
                ]
            },
            {
                title: 'Custom Brush',
                id: 'tool-cbrush',
                children: [
                    {title: 'Capture Selection as Brush', id: 'cb-capture'},
                    {title: 'Non-rectangular via Alpha Channel', id: 'cb-alpha'},
                    {title: 'Flip H (Home) / V (End)', id: 'cb-flip'},
                    {title: 'Scale Up (PgUp) / Down (PgDn)', id: 'cb-scale'},
                    {title: 'Reset Scale ( / key)', id: 'cb-reset'},
                    {title: 'Recolor Mode (F9)', id: 'cb-recolor'},
                    {title: 'Outline Mode (Shift+O)', id: 'cb-outline'},
                    {title: 'Export as PNG (F12)', id: 'cb-export'},
                    {title: 'Works with Line/Rect/Ellipse/Poly', id: 'cb-shapes'},
                ]
            },
            {
                title: 'Reference Image',
                id: 'tool-refimg',
                children: [
                    {title: 'Toggle Ctrl+R', id: 'ref-toggle'},
                    {title: 'Ctrl+Shift+Wheel = Opacity (5-100%)', id: 'ref-opacity'},
                    {title: 'Reposition Mode (Drag/Zoom/Nudge)', id: 'ref-repos'},
                    {title: 'Renders Behind All Layers', id: 'ref-behind'},
                    {title: 'Persisted in .draw Files', id: 'ref-persist'},
                ]
            },
            {
                title: 'Symmetry Drawing (F7)',
                id: 'tool-symmetry',
                children: [
                    {title: 'Vertical | (2 copies)', id: 'sym-vert'},
                    {title: 'Cross + (4 copies)', id: 'sym-cross'},
                    {title: 'Asterisk * (8 copies)', id: 'sym-asterisk'},
                    {title: 'Ctrl+Click = Reposition Center', id: 'sym-center'},
                    {title: 'Visual Guide Lines & Crosshair', id: 'sym-guides'},
                    {title: 'Works with All Drawing Tools', id: 'sym-all'},
                    {title: 'F8 = Disable / Fill Adjust', id: 'sym-f8'},
                ]
            },
            {
                title: 'Angle Snap (Ctrl+Shift)',
                id: 'tool-anglesnap',
                children: [
                    {title: 'Degree Mode (15°/30°/45°/90°)', id: 'asnap-deg'},
                    {title: 'Pixel Art Mode (integer ratios)', id: 'asnap-pixel'},
                    {title: 'Ctrl+Shift Bypasses Grid Snap', id: 'asnap-bypass'},
                    {title: 'Works: Line, Polygon, Brush, Dot', id: 'asnap-tools'},
                ]
            },
            {
                title: 'Pixel Art Analyzer (Tools menu)',
                id: 'tool-pixcoach',
                children: [
                    {title: 'Orphan Pixels Detection', id: 'pc-orphan'},
                    {title: 'Jagged Lines Detection', id: 'pc-jagged'},
                    {title: 'Banding Detection', id: 'pc-banding'},
                    {title: 'Pillow Shading Detection', id: 'pc-pillow'},
                    {title: 'Doubles Detection', id: 'pc-doubles'},
                    {title: 'Precompute Engine (fast)', id: 'pc-precomp'},
                ]
            },
        ]
    },

    // =========================================================================
    // 2. SELECTION & CLIPBOARD
    // =========================================================================
    {
        title: '✂️ Selection & Clipboard',
        id: 'selection',
        children: [
            {
                title: 'Marquee (M) — Rectangular',
                id: 'sel-marquee',
                children: [
                    {title: 'Drag = Create Selection', id: 'marq-drag'},
                    {title: 'Shift+Drag = Add (Union)', id: 'marq-add'},
                    {title: 'Alt+Drag = Subtract', id: 'marq-sub'},
                    {title: 'Resize Handles', id: 'marq-handles'},
                    {title: 'Drag Inside = Move', id: 'marq-move'},
                    {title: 'Arrow Keys (1px / Shift 10px)', id: 'marq-arrows'},
                    {title: 'Ctrl+Arrows = Resize', id: 'marq-resize'},
                ]
            },
            {title: 'Freehand Select (toolbar/palette)', id: 'sel-freehand'},
            {title: 'Polygon Select (toolbar/palette)', id: 'sel-polysel'},
            {title: 'Ellipse Select (toolbar/palette)', id: 'sel-ellsel'},
            {
                title: 'Magic Wand (W)',
                id: 'sel-wand',
                children: [
                    {title: 'Contiguous Same-Color Selection', id: 'wand-contig'},
                    {title: 'Shift+Click = Add to Selection', id: 'wand-add'},
                    {title: 'Alt+Click = Subtract', id: 'wand-sub'},
                    {title: 'Hold F+Click = Flood Fill FG', id: 'wand-fill'},
                    {title: 'Hold E+Click = Flood Erase', id: 'wand-erase'},
                    {title: 'Hold W+Click = Select from Merged', id: 'wand-merged'},
                ]
            },
            {
                title: 'Selection Actions',
                id: 'sel-actions',
                children: [
                    {title: 'Select All (Ctrl+A)', id: 'sel-all'},
                    {title: 'Invert Selection (Ctrl+Shift+I)', id: 'sel-invert'},
                    {title: 'Deselect (Ctrl+D / Escape)', id: 'sel-desel'},
                    {title: 'From Current Layer', id: 'sel-fromlayer'},
                    {title: 'From Selected Layers (2+)', id: 'sel-frommulti'},
                    {title: 'Expand / Contract Selection', id: 'sel-expandcontract'},
                ]
            },
            {
                title: 'Selection = Clipping Mask',
                id: 'sel-mask',
                children: [
                    {title: 'Clips all drawing tools', id: 'mask-tools'},
                    {title: 'Brush/Dot/Line/Rect/Ellipse/Poly/Fill', id: 'mask-list'},
                    {title: 'Marching Ants visual feedback', id: 'mask-ants'},
                ]
            },
            {
                title: 'Clipboard Operations',
                id: 'sel-clipboard',
                children: [
                    {title: 'Copy (Ctrl+C)', id: 'clip-copy'},
                    {title: 'Cut (Ctrl+X)', id: 'clip-cut'},
                    {title: 'Paste at Cursor (Ctrl+V)', id: 'clip-paste'},
                    {title: 'Copy Merged (Ctrl+Shift+C)', id: 'clip-merged'},
                    {title: 'Clear Selection (Ctrl+E)', id: 'clip-clear'},
                    {title: 'Copy to New Layer (Ctrl+Alt+C)', id: 'clip-copylayer'},
                    {title: 'Cut to New Layer (Ctrl+Alt+X)', id: 'clip-cutlayer'},
                    {title: 'Paste from OS (Ctrl+Shift+V)', id: 'clip-pasteos'},
                ]
            },
            {
                title: 'Stroke Selection (Edit menu)',
                id: 'sel-stroke',
                children: [
                    {title: 'Configurable Width (px)', id: 'stroke-width'},
                    {title: 'FG or Custom Color', id: 'stroke-color'},
                    {title: 'Inside / Outside / Center', id: 'stroke-pos'},
                ]
            },
        ]
    },

    // =========================================================================
    // 3. LAYER SYSTEM
    // =========================================================================
    {
        title: '📚 Layer System',
        id: 'layers',
        children: [
            {title: 'Up to 64 Layers (128 slots)', id: 'layer-max'},
            {
                title: 'Per-Layer Properties',
                id: 'layer-props',
                children: [
                    {title: 'Opacity (0-255, % display)', id: 'layer-opacity'},
                    {title: 'Visibility Toggle', id: 'layer-vis'},
                    {title: 'Opacity Lock (no draw on transparent)', id: 'layer-lock'},
                    {title: 'Rename (R-Click)', id: 'layer-rename'},
                ]
            },
            {
                title: 'Blend Modes (19 + Pass Through)',
                id: 'layer-blend',
                children: [
                    {title: 'Normal (default)', id: 'bl-normal'},
                    {title: 'Multiply', id: 'bl-multiply'},
                    {title: 'Screen', id: 'bl-screen'},
                    {title: 'Overlay', id: 'bl-overlay'},
                    {title: 'Add (Linear Dodge)', id: 'bl-add'},
                    {title: 'Subtract', id: 'bl-subtract'},
                    {title: 'Difference', id: 'bl-difference'},
                    {title: 'Darken', id: 'bl-darken'},
                    {title: 'Lighten', id: 'bl-lighten'},
                    {title: 'Color Dodge', id: 'bl-cdodge'},
                    {title: 'Color Burn', id: 'bl-cburn'},
                    {title: 'Hard Light', id: 'bl-hardl'},
                    {title: 'Soft Light', id: 'bl-softl'},
                    {title: 'Exclusion', id: 'bl-exclusion'},
                    {title: 'Vivid Light', id: 'bl-vividl'},
                    {title: 'Linear Light', id: 'bl-linearl'},
                    {title: 'Pin Light', id: 'bl-pinl'},
                    {title: 'Color (Blend Mode)', id: 'bl-color'},
                    {title: 'Luminosity', id: 'bl-luminosity'},
                    {title: 'Pass Through (Groups)', id: 'bl-passthru'},
                ]
            },
            {
                title: 'Layer Groups',
                id: 'layer-groups',
                children: [
                    {title: 'New Group (Ctrl+G)', id: 'grp-new'},
                    {title: 'Group from Selection (Ctrl+Shift+G)', id: 'grp-fromsel'},
                    {title: 'Ungroup (Ctrl+Shift+U)', id: 'grp-ungroup'},
                    {title: 'Collapsible (Triangle Toggle)', id: 'grp-collapse'},
                    {title: 'Arbitrary Nesting Depth', id: 'grp-nest'},
                    {title: 'Drag Layer Into Group', id: 'grp-dnd'},
                    {title: 'Merge Group to One Layer', id: 'grp-merge'},
                    {title: 'Select All in Group', id: 'grp-selectall'},
                    {title: 'Selection from Group Pixels', id: 'grp-selmask'},
                ]
            },
            {
                title: 'Layer Operations',
                id: 'layer-ops',
                children: [
                    {title: 'New Layer (Ctrl+Shift+N)', id: 'lop-new'},
                    {title: 'Delete (Ctrl+Shift+Delete)', id: 'lop-delete'},
                    {title: 'Duplicate (Ctrl+Shift+D)', id: 'lop-dup'},
                    {title: 'Merge Down (Ctrl+Alt+E)', id: 'lop-mergedn'},
                    {title: 'Merge Visible (Ctrl+Alt+Shift+E)', id: 'lop-mergevis'},
                    {title: 'Merge Selected', id: 'lop-mergesel'},
                    {title: 'Move Up/Down (Ctrl+PgUp/PgDn)', id: 'lop-move'},
                    {title: 'Arrange Top/Bottom (Ctrl+Home/End)', id: 'lop-arrange'},
                    {title: 'Align (L/C/R/T/M/B)', id: 'lop-align'},
                    {title: 'Distribute (H/V)', id: 'lop-distribute'},
                ]
            },
            {
                title: 'Multi-Layer Select',
                id: 'layer-multi',
                children: [
                    {title: 'Ctrl+Click / Shift+Click rows', id: 'multi-select'},
                    {title: 'Clear/Fill/Flip/Scale/Rotate all selected', id: 'multi-ops'},
                ]
            },
            {
                title: 'Layer Panel UI',
                id: 'layer-panel',
                children: [
                    {title: 'Eye Icon — Visibility Toggle', id: 'lpanel-eye'},
                    {title: 'Lock Icon — Opacity Lock', id: 'lpanel-lock'},
                    {title: 'Opacity Bar (drag/wheel)', id: 'lpanel-opacity'},
                    {title: 'Alt+Click Eye = Solo Layer', id: 'lpanel-solo'},
                    {title: 'Drag Across Eyes = Swipe Vis', id: 'lpanel-swipe'},
                    {title: 'Shift+R-Click = Cycle Blend Mode', id: 'lpanel-blend'},
                    {title: 'R-Click = Context Menu', id: 'lpanel-context'},
                    {title: 'Drag & Drop Reordering', id: 'lpanel-dnd'},
                    {title: 'Auto-scroll when dragging', id: 'lpanel-scroll'},
                ]
            },
        ]
    },

    // =========================================================================
    // 4. COLOR & PALETTE SYSTEM
    // =========================================================================
    {
        title: '🎨 Color & Palette System',
        id: 'color',
        children: [
            {
                title: 'Palette Strip',
                id: 'pal-strip',
                children: [
                    {title: 'L-Click = Select FG Color', id: 'ps-fg'},
                    {title: 'R-Click = Select BG Color', id: 'ps-bg'},
                    {title: 'Wheel = Scroll / Shift+Wheel = Fast (32)', id: 'ps-scroll'},
                    {title: '◄ ► Arrow Buttons', id: 'ps-arrows'},
                ]
            },
            {
                title: 'Palette Dropdown',
                id: 'pal-dropdown',
                children: [
                    {title: 'Click Name = Switch Palettes', id: 'pd-switch'},
                    {title: '56 Bundled .GPL Files', id: 'pd-bundled'},
                    {title: 'Letter keys jump to palette name', id: 'pd-letter'},
                ]
            },
            {
                title: 'Palette Ops Mode',
                id: 'pal-ops',
                children: [
                    {title: 'Dbl-Click = Change Color (replaces on canvas)', id: 'po-change'},
                    {title: 'R-Click = Mark Color', id: 'po-mark'},
                    {title: 'M-Click = Delete Color (remap neighbor)', id: 'po-delete'},
                    {title: 'Shift+M-Click = Insert Color', id: 'po-insert'},
                    {title: 'Drag = Rearrange Order', id: 'po-drag'},
                    {title: 'L-Click = Magic Wand Select', id: 'po-wand'},
                    {title: 'Auto [DOCUMENT] Palette Creation', id: 'po-document'},
                ]
            },
            {
                title: 'Color Picker (RGB)',
                id: 'pal-picker',
                children: [
                    {title: 'Click Status Bar FG/BG Swatches', id: 'cp-status'},
                    {title: 'True RGB Color Selection', id: 'cp-rgb'},
                ]
            },
            {
                title: 'FG / BG Color Controls',
                id: 'pal-fgbg',
                children: [
                    {title: 'X = Swap FG/BG', id: 'fgbg-swap'},
                    {title: 'Ctrl+D = Reset (White/Black)', id: 'fgbg-reset'},
                    {title: 'Shift+Del = BG Transparent', id: 'fgbg-trans'},
                ]
            },
            {
                title: 'Paint Opacity (1-0 keys)',
                id: 'pal-opacity',
                children: [
                    {title: 'Keys 1-9 = 10%-90%', id: 'op-keys'},
                    {title: 'Key 0 = 100% (fully opaque)', id: 'op-100'},
                    {title: 'Per-stroke compositing (no compounding)', id: 'op-stroke'},
                ]
            },
            {
                title: 'Palette Workflows',
                id: 'pal-workflows',
                children: [
                    {title: 'Download from Lospec', id: 'pw-lospec'},
                    {title: 'Create Palette from Image', id: 'pw-fromimg'},
                    {title: 'Remap Artwork to Active Palette', id: 'pw-remap'},
                    {title: 'Import/Export .GPL files', id: 'pw-gpl'},
                ]
            },
        ]
    },

    // =========================================================================
    // 5. TEXT SYSTEM
    // =========================================================================
    {
        title: '📝 Text System',
        id: 'text',
        children: [
            {
                title: 'Text Entry & Navigation',
                id: 'text-entry',
                children: [
                    {title: 'Arrow keys / Home / End', id: 'te-arrows'},
                    {title: 'Ctrl+Left/Right = Word Nav', id: 'te-word'},
                    {title: 'Ctrl+Home/End = Start/End', id: 'te-startend'},
                    {title: 'Backspace / Delete chars', id: 'te-delete'},
                    {title: 'Enter = New Line', id: 'te-newline'},
                    {title: 'Escape = Apply/Finish', id: 'te-escape'},
                ]
            },
            {
                title: 'Text Selection',
                id: 'text-select',
                children: [
                    {title: 'Shift+Arrow = Select chars', id: 'ts-char'},
                    {title: 'Double-click = Word', id: 'ts-dblclick'},
                    {title: 'Triple-click = Line', id: 'ts-triple'},
                    {title: 'Quad-click = All', id: 'ts-quad'},
                    {title: 'Ctrl+A = Select All', id: 'ts-all'},
                ]
            },
            {
                title: 'Font System',
                id: 'text-fonts',
                children: [
                    {title: 'VGA (Default) — T key', id: 'tf-vga'},
                    {title: 'Tiny5 Small — Shift+T', id: 'tf-tiny5'},
                    {title: 'Custom TTF/OTF — Ctrl+T (M-Click load)', id: 'tf-custom'},
                    {title: 'Bitmap Fonts (Fontaption/PSF/BDF)', id: 'tf-bitmap'},
                    {
                        title: 'Color Bitmap Fonts (CBF)',
                        id: 'tf-cbf',
                        children: [
                            {title: '24 Bundled DPaint-style .bmp fonts', id: 'cbf-bundled'},
                            {title: 'Preserve original pixel colors', id: 'cbf-colors'},
                            {title: 'Fixed native glyph height', id: 'cbf-size'},
                        ]
                    },
                ]
            },
            {
                title: 'Rich Per-Character Formatting',
                id: 'text-format',
                children: [
                    {title: 'Bold', id: 'fmt-bold'},
                    {title: 'Italic', id: 'fmt-italic'},
                    {title: 'Underline', id: 'fmt-under'},
                    {title: 'Strikethrough', id: 'fmt-strike'},
                    {title: 'Outline (Color + Size)', id: 'fmt-outline'},
                    {title: 'Shadow (Color + X/Y Offset 1-10px)', id: 'fmt-shadow'},
                    {title: 'Per-character FG/BG Colors', id: 'fmt-perchar'},
                    {title: 'Letter Spacing / Line Height', id: 'fmt-spacing'},
                    {title: 'Auto-Wrap', id: 'fmt-wrap'},
                ]
            },
            {
                title: 'Text Layers (Persistent)',
                id: 'text-layers',
                children: [
                    {title: 'Click existing to re-edit', id: 'tl-reedit'},
                    {title: 'Persisted in DRW files', id: 'tl-persist'},
                    {title: 'Full undo/redo support', id: 'tl-undo'},
                    {title: 'Rasterize Text Layer', id: 'tl-rasterize'},
                    {title: 'New Text Layer (Layer menu)', id: 'tl-new'},
                ]
            },
            {
                title: 'Text-Local Undo/Redo',
                id: 'text-undo',
                children: [
                    {title: 'Ctrl+Z / Ctrl+Y within text mode', id: 'tu-keys'},
                    {title: 'Up to 128 states', id: 'tu-states'},
                    {title: 'Separate from canvas undo', id: 'tu-separate'},
                ]
            },
            {
                title: 'Style Presets',
                id: 'text-presets',
                children: [
                    {title: 'Save [S] / Load / Update [U] / Delete [X]', id: 'tp-crud'},
                    {title: 'Stores: B/I/U/S, Outline, Shadow, Align, AA', id: 'tp-stores'},
                ]
            },
            {
                title: 'Character Map (Ctrl+M)',
                id: 'text-charmap',
                children: [
                    {title: '16×16 Glyph Grid (256 chars)', id: 'cm-grid'},
                    {title: 'Click glyph = Insert / Custom Brush', id: 'cm-click'},
                    {title: 'Dockable Left/Right', id: 'cm-dock'},
                    {title: 'Dynamic cell count (4-16 per row)', id: 'cm-dynamic'},
                    {title: 'Bitmap Font Rendering', id: 'cm-bitmap'},
                ]
            },
            {
                title: 'Character Mode (CHAR)',
                id: 'text-charmode',
                children: [
                    {title: 'Virtual Cursor — Free Grid Navigation', id: 'chm-virtual'},
                    {title: 'F1-F12 = ANSI Block Characters', id: 'chm-fkeys'},
                    {title: 'Font Stickiness', id: 'chm-sticky'},
                    {title: 'DOT/RECT drawing on Text Layers', id: 'chm-draw'},
                    {title: 'Alt+U = Color Pickup', id: 'chm-colorpu'},
                    {title: 'Character Grid Overlay + Snap', id: 'chm-chargrid'},
                    {title: 'Persisted per-document (DRW v19+)', id: 'chm-persist'},
                ]
            },
            {
                title: 'Text Property Bar (GUI)',
                id: 'text-bar',
                children: [
                    {title: 'Font Dropdown', id: 'tb-font'},
                    {title: 'Size Dropdown', id: 'tb-size'},
                    {title: 'B / I / U / S Toggle Buttons', id: 'tb-bius'},
                    {title: 'Outline Toggle + Color + Size', id: 'tb-outline'},
                    {title: 'Shadow Toggle + Color + X/Y', id: 'tb-shadow'},
                    {title: 'FG/BG Color Swatches', id: 'tb-colors'},
                    {title: 'Style Preset Controls', id: 'tb-presets'},
                ]
            },
        ]
    },

    // =========================================================================
    // 6. CANVAS & VIEW
    // =========================================================================
    {
        title: '🖼️ Canvas & View',
        id: 'canvas',
        children: [
            {title: 'Configurable Canvas Size (up to 4096×4096)', id: 'cv-size'},
            {
                title: 'Zoom Controls',
                id: 'cv-zoom',
                children: [
                    {title: 'Mouse Wheel / Ctrl +/-', id: 'cvz-wheel'},
                    {title: 'Snap Levels: 25%-800%', id: 'cvz-levels'},
                    {title: 'Reset Ctrl+0 / Double-Middle', id: 'cvz-reset'},
                ]
            },
            {
                title: 'Pan Controls',
                id: 'cv-pan',
                children: [
                    {title: 'Middle Mouse Drag', id: 'cvp-middle'},
                    {title: 'Spacebar + Drag', id: 'cvp-space'},
                    {title: 'Arrow Keys (Keyboard)', id: 'cvp-keys'},
                ]
            },
            {title: 'Scrollbars (large canvases)', id: 'cv-scroll'},
            {
                title: 'Preview Window (F4)',
                id: 'cv-preview',
                children: [
                    {title: 'Follow Mode (Magnifier)', id: 'prev-follow'},
                    {title: 'Floating Image Mode', id: 'prev-float'},
                    {title: 'Bin Quick Look (hover drawer)', id: 'prev-binql'},
                    {title: 'Color Picking (Alt+Click)', id: 'prev-colorpick'},
                    {title: 'Recent Images (up to 10)', id: 'prev-recent'},
                    {title: 'Independent Zoom/Pan', id: 'prev-zoom'},
                    {title: 'Move & Resize Controls', id: 'prev-resize'},
                ]
            },
            {title: 'Pattern Tile Mode (Shift+Tab, up to 512×512)', id: 'cv-tile'},
            {title: 'Grayscale Preview (Ctrl+Alt+Shift+G)', id: 'cv-gray'},
            {title: 'Canvas Border Toggle (# key)', id: 'cv-border'},
            {title: 'Clear Canvas — Del (prompt) / Backspace (instant)', id: 'cv-clear'},
        ]
    },

    // =========================================================================
    // 7. GRID SYSTEM
    // =========================================================================
    {
        title: '📐 Grid System',
        id: 'grid',
        children: [
            {title: 'Grid Toggle (\' key)', id: 'grid-show'},
            {title: 'Pixel Grid (Shift+\', 400%+ zoom)', id: 'grid-pixel'},
            {title: 'Snap-to-Grid Toggle (; key)', id: 'grid-snap'},
            {title: 'Size Adjust ( . , keys, 2-50px)', id: 'grid-size'},
            {
                title: 'Grid Geometry Modes (Ctrl+\')',
                id: 'grid-modes',
                children: [
                    {title: 'Square (default)', id: 'gm-square'},
                    {title: 'Diagonal (45° diamond)', id: 'gm-diag'},
                    {title: 'Isometric (2:1 pixel art)', id: 'gm-iso'},
                    {title: 'Hexagonal (flat-top)', id: 'gm-hex'},
                ]
            },
            {title: 'Alignment: Corner / Center (View menu)', id: 'grid-align'},
            {
                title: 'Grid Cell Fill Mode',
                id: 'grid-cellfill',
                children: [
                    {title: 'Fills Squares (Square mode)', id: 'gcf-square'},
                    {title: 'Fills Diamonds (Diagonal)', id: 'gcf-diamond'},
                    {title: 'Fills Triangles (Isometric)', id: 'gcf-tri'},
                    {title: 'Fills Hexagons (Hex mode)', id: 'gcf-hex'},
                ]
            },
            {
                title: 'Crosshair Assistant',
                id: 'grid-cross',
                children: [
                    {title: 'Show with Shift (held)', id: 'gc-shift'},
                    {title: 'Configurable outline stroke', id: 'gc-outline'},
                    {title: 'Color / Opacity / Width', id: 'gc-color'},
                ]
            },
            {
                title: 'Smart Guides',
                id: 'grid-smartguides',
                children: [
                    {title: 'Align to Edges / Centers / Canvas', id: 'sg-align'},
                    {title: 'Snap Enable (Ctrl+;)', id: 'sg-snap'},
                    {title: 'Visibility (Ctrl+Shift+;)', id: 'sg-vis'},
                    {title: 'Themeable Colors & Opacity', id: 'sg-theme'},
                ]
            },
            {title: 'Ctrl+Shift bypasses grid snap', id: 'grid-bypass'},
            {title: 'Both grids shown simultaneously at high zoom', id: 'grid-both'},
            {title: 'Grid state persisted in .draw files', id: 'grid-persist'},
        ]
    },

    // =========================================================================
    // 8. BRUSH SYSTEM
    // =========================================================================
    {
        title: '🖊️ Brush System',
        id: 'brush-sys',
        children: [
            {title: 'Size 1-50px ([ ] keys)', id: 'bs-size'},
            {title: 'Shape: Circle / Square (\\ key)', id: 'bs-shape'},
            {title: 'Preview Mode (` key)', id: 'bs-preview'},
            {title: 'Pixel Perfect Mode (F6)', id: 'bs-pixperf'},
            {title: '4 Size Presets (Organizer)', id: 'bs-presets'},
            {title: 'Visual Cursor w/ Current Color', id: 'bs-cursor'},
            {title: 'Affects all drawing tools', id: 'bs-affects'},
            {
                title: 'Paint Modes',
                id: 'bs-modes',
                children: [
                    {title: 'Normal (solid color)', id: 'pm-normal'},
                    {title: 'Pattern (from Drawer)', id: 'pm-pattern'},
                    {title: 'Gradient (from Drawer)', id: 'pm-gradient'},
                    {title: '1-Bit Pattern (opaque BG)', id: 'pm-1bit'},
                ]
            },
            {
                title: 'Dithering Algorithms',
                id: 'bs-dither',
                children: [
                    {title: 'Ordered (Bayer 2×2, 4×4, 8×8)', id: 'di-ordered'},
                    {title: 'Floyd-Steinberg', id: 'di-floyd'},
                    {title: 'Atkinson', id: 'di-atkinson'},
                    {title: 'Stucki', id: 'di-stucki'},
                    {title: 'Blue Noise', id: 'di-bluenoise'},
                ]
            },
        ]
    },

    // =========================================================================
    // 9. TRANSFORM OPERATIONS
    // =========================================================================
    {
        title: '🔄 Transform Operations',
        id: 'transform',
        children: [
            {title: 'Flip Horizontal (H key)', id: 'xf-fliph'},
            {title: 'Flip Vertical (Ctrl+Shift+H)', id: 'xf-flipv'},
            {title: 'Rotate 90° CW (> key)', id: 'xf-rotcw'},
            {title: 'Rotate 90° CCW (< key)', id: 'xf-rotccw'},
            {title: 'Scale Up 50% (Ctrl+Shift+=)', id: 'xf-scaleup'},
            {title: 'Scale Down 50% (Ctrl+Shift+-)', id: 'xf-scaledn'},
            {
                title: 'Transform Overlay (Edit → TRANSFORM)',
                id: 'xf-overlay',
                children: [
                    {title: 'Scale (Shift = Lock Aspect)', id: 'xo-scale'},
                    {title: 'Rotate (Shift = 15° Snap)', id: 'xo-rotate'},
                    {title: 'Shear', id: 'xo-shear'},
                    {title: 'Distort (Independent Corners)', id: 'xo-distort'},
                    {title: 'Perspective (Shift = Mirror)', id: 'xo-persp'},
                    {title: 'Themeable Frame & Handles', id: 'xo-theme'},
                    {title: 'Enter = Apply / Esc = Cancel', id: 'xo-apply'},
                ]
            },
            {
                title: 'Move Tool (V)',
                id: 'xf-move',
                children: [
                    {title: 'Arrow Keys (1px / Shift 10px)', id: 'mv-arrows'},
                    {title: 'Alt+Drag = Clone Stamp', id: 'mv-clone'},
                    {title: 'Ctrl+Arrows = Resize', id: 'mv-resize'},
                    {title: 'Shift+Click = Auto-Select Layer', id: 'mv-autosel'},
                ]
            },
            {title: 'Works on Layer / Selection / Float', id: 'xf-targets'},
        ]
    },

    // =========================================================================
    // 10. IMAGE ADJUSTMENTS
    // =========================================================================
    {
        title: '🎛️ Image Adjustments',
        id: 'imgadj',
        children: [
            {
                title: 'Dialogs (Live Preview)',
                id: 'adj-dialogs',
                children: [
                    {title: 'Brightness / Contrast', id: 'adj-bright'},
                    {title: 'Hue / Saturation', id: 'adj-hue'},
                    {title: 'Levels (B/W/Gamma)', id: 'adj-levels'},
                    {title: 'Color Balance (Shadows/Mid/Highlights)', id: 'adj-colbal'},
                    {title: 'Blur (Gaussian, adjustable radius)', id: 'adj-blur'},
                    {title: 'Sharpen (adjustable intensity)', id: 'adj-sharpen'},
                ]
            },
            {
                title: 'One-Shot Adjustments',
                id: 'adj-oneshot',
                children: [
                    {title: 'Invert (RGB negative)', id: 'adj-invert'},
                    {title: 'Desaturate (luminosity grayscale)', id: 'adj-desat'},
                    {title: 'Posterize (N levels + dithering)', id: 'adj-poster'},
                    {title: 'Pixelate (block cell size)', id: 'adj-pixel'},
                ]
            },
            {title: 'Flip Canvas H / V (Image menu)', id: 'adj-flipcv'},
            {
                title: 'Common Features',
                id: 'adj-common',
                children: [
                    {title: 'Live Preview while dialog open', id: 'ac-liveprev'},
                    {title: 'Mouse Wheel on sliders', id: 'ac-wheel'},
                    {title: 'Alpha Channel preserved', id: 'ac-alpha'},
                    {title: 'Per-layer operation', id: 'ac-perlayer'},
                    {title: 'Saves undo state (Ctrl+Z)', id: 'ac-undo'},
                ]
            },
        ]
    },

    // =========================================================================
    // 11. FILE I/O
    // =========================================================================
    {
        title: '💾 File I/O',
        id: 'fileio',
        children: [
            {
                title: 'Open / Load',
                id: 'fio-open',
                children: [
                    {title: 'Open Image (Ctrl+O) — PNG/BMP/JPG/GIF', id: 'fo-image'},
                    {title: 'Open Project (.draw) — Alt+O', id: 'fo-project'},
                    {title: 'Open Aseprite (.ase/.aseprite)', id: 'fo-aseprite'},
                    {title: 'Open PSD (.psd)', id: 'fo-psd'},
                    {title: 'Import Image (oversized placement)', id: 'fo-import'},
                    {title: 'Windows Drag & Drop', id: 'fo-dnd'},
                    {title: 'Command Line File Argument', id: 'fo-cmdline'},
                ]
            },
            {
                title: 'Save',
                id: 'fio-save',
                children: [
                    {title: 'Save (Ctrl+S) — silent if saved before', id: 'fs-save'},
                    {title: 'Save As (Ctrl+Shift+S) — prompt', id: 'fs-saveas'},
                    {title: 'Export Selection (Ctrl+Alt+Shift+S)', id: 'fs-exsel'},
                    {title: 'Export Layer as PNG', id: 'fs-layer'},
                    {title: 'Export Brush as PNG (F12)', id: 'fs-brush'},
                ]
            },
            {
                title: 'Export As (9 Formats)',
                id: 'fio-export',
                children: [
                    {title: 'PNG Native (with alpha)', id: 'ex-pngnative'},
                    {title: 'PNG Plain', id: 'ex-pngplain'},
                    {title: 'GIF', id: 'ex-gif'},
                    {title: 'JPEG', id: 'ex-jpeg'},
                    {title: 'TGA', id: 'ex-tga'},
                    {title: 'BMP', id: 'ex-bmp'},
                    {title: 'HDR', id: 'ex-hdr'},
                    {title: 'ICO', id: 'ex-ico'},
                    {title: 'QOI', id: 'ex-qoi'},
                ]
            },
            {
                title: 'DRW Project Format',
                id: 'fio-drw',
                children: [
                    {title: 'PNG with embedded drAw chunk', id: 'drw-chunk'},
                    {title: 'All layers + blend modes + opacity', id: 'drw-layers'},
                    {title: 'Palette state', id: 'drw-palette'},
                    {title: 'Tool states + grid + snap', id: 'drw-tools'},
                    {title: 'Reference image config', id: 'drw-refimg'},
                    {title: 'Extract images settings', id: 'drw-extract'},
                    {title: 'Text layer data', id: 'drw-text'},
                    {title: 'Viewable in any image viewer', id: 'drw-viewable'},
                ]
            },
            {title: 'Recent Files (up to 10, Alt+1-0)', id: 'fio-recent'},
            {title: 'New from Template', id: 'fio-template'},
            {
                title: 'Extract Images (File menu)',
                id: 'fio-extractimg',
                children: [
                    {title: 'Flood-fill connected regions', id: 'ei-flood'},
                    {title: 'Per-layer extraction', id: 'ei-perlayer'},
                    {title: 'Merged extraction', id: 'ei-merged'},
                    {title: 'Transparent / FG / BG background', id: 'ei-bg'},
                    {title: 'Output as separate PNGs', id: 'ei-output'},
                ]
            },
            {title: 'QB64 Source Code Export', id: 'fio-qb64'},
        ]
    },

    // =========================================================================
    // 12. USER INTERFACE
    // =========================================================================
    {
        title: '🖥️ User Interface',
        id: 'ui',
        children: [
            {
                title: 'Menu Bar (11 Menus)',
                id: 'ui-menubar',
                children: [
                    {title: 'File', id: 'menu-file'},
                    {title: 'Edit', id: 'menu-edit'},
                    {title: 'View', id: 'menu-view'},
                    {title: 'Select', id: 'menu-select'},
                    {title: 'Tools', id: 'menu-tools'},
                    {title: 'Brush', id: 'menu-brush'},
                    {title: 'Layer', id: 'menu-layer'},
                    {title: 'Palette', id: 'menu-palette'},
                    {title: 'Image', id: 'menu-image'},
                    {title: 'Help', id: 'menu-help'},
                    {title: 'Audio', id: 'menu-audio'},
                    {title: 'Alt key keyboard navigation', id: 'menu-altnav'},
                    {title: 'Hotkey hints on items', id: 'menu-hotkeys'},
                    {title: 'Cascading submenus', id: 'menu-cascade'},
                    {title: 'Toggle checkmarks', id: 'menu-checks'},
                ]
            },
            {
                title: 'Toolbar (4×7 Grid, 28 Buttons)',
                id: 'ui-toolbar',
                children: [
                    {title: 'Themeable PNG Icons', id: 'tbar-icons'},
                    {title: 'Active tool indicator', id: 'tbar-active'},
                    {title: 'Toggle with Tab', id: 'tbar-toggle'},
                ]
            },
            {
                title: 'Organizer Widget',
                id: 'ui-organizer',
                children: [
                    {title: '4×3 Layout', id: 'org-layout'},
                    {title: 'Brush Presets', id: 'org-presets'},
                    {title: 'Palette Ops Toggle', id: 'org-palops'},
                ]
            },
            {
                title: 'Drawer Panel (30 Slots)',
                id: 'ui-drawer',
                children: [
                    {title: 'Brush Mode (F1)', id: 'drw-brushm'},
                    {title: 'Gradient Mode (F2)', id: 'drw-grad'},
                    {title: 'Pattern Mode (F3)', id: 'drw-pattern'},
                    {title: '1-Bit Patterns (opaque BG)', id: 'drw-1bit'},
                    {title: 'Shift+L-Click = Store', id: 'drw-store'},
                    {title: 'R-Click = Context Menu', id: 'drw-context'},
                    {title: 'Load Images (batch import)', id: 'drw-loadimg'},
                    {title: 'Drag & Drop Reorder', id: 'drw-dnd'},
                    {title: '.dset Import/Export', id: 'drw-dset'},
                    {title: 'Mini Palette', id: 'drw-minipal'},
                ]
            },
            {
                title: 'Edit Bar (F5)',
                id: 'ui-editbar',
                children: [
                    {title: 'Undo / Redo Icons', id: 'eb-undo'},
                    {title: 'Smart Guides Toggle', id: 'eb-smartg'},
                    {title: 'Pixel Perfect Toggle', id: 'eb-pixperf'},
                    {title: 'Flip Canvas H/V', id: 'eb-flip'},
                    {title: 'Dockable Left/Right', id: 'eb-dock'},
                ]
            },
            {
                title: 'Advanced Bar (Shift+F5)',
                id: 'ui-advbar',
                children: [
                    {title: '26+ Quick Toggle Buttons', id: 'ab-buttons'},
                    {title: 'Char Map / Grid / Snap Toggles', id: 'ab-chartgl'},
                    {title: 'Preview / Edit Bar Toggles', id: 'ab-preview'},
                    {title: 'Tile / Grid / Fill Toggles', id: 'ab-tile'},
                    {title: 'Reference Image Controls', id: 'ab-refimg'},
                    {title: 'Dockable Left/Right', id: 'ab-dock'},
                ]
            },
            {
                title: 'Status Bar (F10)',
                id: 'ui-statusbar',
                children: [
                    {title: 'Current Tool Name', id: 'sb-tool'},
                    {title: 'X,Y Coordinates', id: 'sb-coords'},
                    {title: 'Zoom Level %', id: 'sb-zoom'},
                    {title: 'Grid State (G:n S/Mode)', id: 'sb-grid'},
                    {title: 'FG/BG Color Swatches', id: 'sb-colors'},
                    {title: 'Paint Opacity OP:nn%', id: 'sb-opacity'},
                    {title: 'Symmetry SYM:n', id: 'sb-sym'},
                    {title: 'Custom Brush CB/CB+RECOLOR', id: 'sb-cb'},
                ]
            },
            {title: 'Command Palette (? / Help)', id: 'ui-cmdpal'},
            {title: 'Tooltips (toggleable)', id: 'ui-tooltips'},
            {
                title: 'Layout Docking',
                id: 'ui-docking',
                children: [
                    {title: 'Toolbox Left/Right', id: 'dk-toolbox'},
                    {title: 'Layer Panel Left/Right', id: 'dk-layers'},
                    {title: 'Edit Bar Left/Right', id: 'dk-editbar'},
                    {title: 'Advanced Bar Left/Right', id: 'dk-advbar'},
                    {title: 'Char Map Left/Right', id: 'dk-charmap'},
                    {title: 'Ctrl+Shift+Click = Toggle Side', id: 'dk-toggle'},
                ]
            },
            {
                title: 'Cursor System',
                id: 'ui-cursors',
                children: [
                    {title: 'OS Native for UI Areas', id: 'cur-native'},
                    {title: 'Crosshair for Drawing', id: 'cur-cross'},
                    {title: 'I-Beam for Text', id: 'cur-ibeam'},
                    {title: 'Custom PNG for Special Tools', id: 'cur-custom'},
                    {title: 'Configurable in DRAW.cfg', id: 'cur-config'},
                ]
            },
            {title: 'Auto-Hide During Drawing', id: 'ui-autohide'},
            {
                title: 'Settings Dialog (Ctrl+,)',
                id: 'ui-settings',
                children: [
                    {title: 'General', id: 'set-general'},
                    {title: 'Grid', id: 'set-grid'},
                    {title: 'Palette', id: 'set-palette'},
                    {title: 'Panels', id: 'set-panels'},
                    {title: 'Audio', id: 'set-audio'},
                    {title: 'Fonts', id: 'set-fonts'},
                    {title: 'Appearance', id: 'set-appear'},
                    {title: 'Directories', id: 'set-dirs'},
                ]
            },
            {title: 'About Screen (animated logo + version)', id: 'ui-about'},
        ]
    },

    // =========================================================================
    // 13. AUDIO SYSTEM
    // =========================================================================
    {
        title: '🔊 Audio System',
        id: 'audio',
        children: [
            {
                title: 'Sound Effects (21 Slots)',
                id: 'audio-sfx',
                children: [
                    {title: 'Menus / Tools / Selection / Fill', id: 'sfx-cat1'},
                    {title: 'Clipboard / Layers / Text / Sliders', id: 'sfx-cat2'},
                    {title: 'Drag-Drop / Point / Organizer', id: 'sfx-cat3'},
                    {title: 'Per-theme replaceable', id: 'sfx-theme'},
                    {title: 'Enable / Disable / Volume / Mute', id: 'sfx-ctrl'},
                ]
            },
            {
                title: 'Background Music',
                id: 'audio-music',
                children: [
                    {title: 'Auto-Shuffle (random tracks)', id: 'mus-shuffle'},
                    {title: 'Formats: .mod .xm .it .s3m .rad', id: 'mus-formats'},
                    {title: 'Next/Prev/Random (} { * keys)', id: 'mus-controls'},
                    {title: 'Volume / Mute (independent of SFX)', id: 'mus-volume'},
                    {title: 'Explore Music Folder', id: 'mus-explore'},
                    {title: 'NOW PLAYING in Audio Menu', id: 'mus-now'},
                ]
            },
        ]
    },

    // =========================================================================
    // 14. THEMING
    // =========================================================================
    {
        title: '🎨 Theming System',
        id: 'theming',
        children: [
            {title: 'All Colors Themeable', id: 'thm-colors'},
            {title: 'PNG Icons Replaceable', id: 'thm-icons'},
            {title: 'Sound Files Per Theme', id: 'thm-sounds'},
            {title: 'Music Folder Per Theme', id: 'thm-music'},
            {title: 'THEME.CFG (no recompile needed)', id: 'thm-cfg'},
            {title: 'Layer Panel fully themeable', id: 'thm-layers'},
            {title: 'Transform overlay frame themeable', id: 'thm-transform'},
            {title: 'Smart guide colors themeable', id: 'thm-guides'},
        ]
    },

    // =========================================================================
    // 15. CONFIGURATION
    // =========================================================================
    {
        title: '⚙️ Configuration',
        id: 'config',
        children: [
            {
                title: 'DRAW.cfg Config File',
                id: 'cfg-file',
                children: [
                    {title: 'FPS Limits (Idle / Active)', id: 'cfg-fps'},
                    {title: 'Grid Color / Opacity / Angle', id: 'cfg-grid'},
                    {title: 'Transparency Checkerboard', id: 'cfg-transp'},
                    {title: 'SFX / Music Enable / Vol / Mute', id: 'cfg-audio'},
                    {title: 'SYSTEM_CURSORS Toggle', id: 'cfg-cursors'},
                    {title: 'ANGLE_SNAP_DEGREES', id: 'cfg-angle'},
                    {title: 'Font Include Directories', id: 'cfg-fonts'},
                    {title: '--config-upgrade (reconcile)', id: 'cfg-upgrade'},
                ]
            },
            {
                title: 'OS-Specific Config Files',
                id: 'cfg-os',
                children: [
                    {title: 'DRAW.macOS.cfg', id: 'cfg-mac'},
                    {title: 'DRAW.linux.cfg', id: 'cfg-linux'},
                    {title: 'DRAW.windows.cfg', id: 'cfg-win'},
                    {title: '--config / -c flag override', id: 'cfg-flag'},
                ]
            },
            {
                title: 'Auto-Detection (First Launch)',
                id: 'cfg-auto',
                children: [
                    {title: 'Display Scale (targets 90% desktop)', id: 'auto-display'},
                    {title: 'Toolbar Scale (from viewport height)', id: 'auto-toolbar'},
                    {title: 'Screen Dimensions (rounded even)', id: 'auto-screen'},
                ]
            },
            {title: 'Display Scale (1x-8x)', id: 'cfg-displayscale'},
            {title: 'Toolbar Scale (1x-4x)', id: 'cfg-toolbarscale'},
            {title: 'Keyboard Bindings', id: 'cfg-keys'},
            {title: 'Mouse Bindings', id: 'cfg-mouse'},
            {title: 'Joystick Bindings', id: 'cfg-stick'},
        ]
    },

    // =========================================================================
    // 16. HISTORY / UNDO SYSTEM
    // =========================================================================
    {
        title: '↩️ Undo / Redo System',
        id: 'undo',
        children: [
            {title: 'Unified History (Ctrl+Z / Ctrl+Y)', id: 'undo-unified'},
            {title: 'Auto-record on mouse release', id: 'undo-record'},
            {title: 'Double-save prevention', id: 'undo-guard'},
            {title: 'Multi-layer undo support', id: 'undo-multi'},
            {title: 'Text-local undo (128 states)', id: 'undo-text'},
        ]
    },

    // =========================================================================
    // 17. INPUT SYSTEM
    // =========================================================================
    {
        title: '🎮 Input System',
        id: 'input',
        children: [
            {
                title: 'Mouse Input',
                id: 'inp-mouse',
                children: [
                    {title: 'Raw / Canvas / Unsnapped coordinates', id: 'im-coords'},
                    {title: 'Press / Release transition detect', id: 'im-buttons'},
                    {title: 'Deferred actions', id: 'im-deferred'},
                    {title: 'UI Chrome skip logic', id: 'im-chrome'},
                ]
            },
            {
                title: 'Keyboard Shortcuts',
                id: 'inp-keyboard',
                children: [
                    {title: 'Tool selection (B/D/F/I/K/L/P/R/C/E/Z/T/M/W/V)', id: 'ik-tools'},
                    {title: 'Modifier combos (Ctrl/Shift/Alt)', id: 'ik-mods'},
                    {title: 'KEYDOWN for Ctrl+ combos (not KEYHIT)', id: 'ik-keydown'},
                ]
            },
            {title: 'Joystick / Stick Support', id: 'inp-stick'},
            {title: 'Modifier Tracking (Ctrl/Shift/Alt)', id: 'inp-modifiers'},
        ]
    },

    // =========================================================================
    // 18. PLATFORM SUPPORT
    // =========================================================================
    {
        title: '💻 Platform Support',
        id: 'platform',
        children: [
            {title: 'Windows', id: 'plat-win'},
            {title: 'Linux', id: 'plat-linux'},
            {title: 'macOS', id: 'plat-macos'},
            {
                title: 'Installers & File Association',
                id: 'plat-install',
                children: [
                    {title: 'Linux: .desktop + MIME type', id: 'inst-linux'},
                    {title: 'Windows: Registry + Start Menu', id: 'inst-win'},
                    {title: 'macOS: install-mac.command', id: 'inst-mac'},
                ]
            },
            {title: 'Built with QB64-PE v4.x+', id: 'plat-qb64'},
        ]
    },

    // =========================================================================
    // 19. RENDERING PIPELINE
    // =========================================================================
    {
        title: '🖵 Rendering Pipeline',
        id: 'rendering',
        children: [
            {title: 'Scene Cache + Dirty Tracking', id: 'rnd-cache'},
            {title: 'Layer Compositing (blend modes)', id: 'rnd-composite'},
            {title: '_MEM per-pixel blend processing', id: 'rnd-blend'},
            {title: 'Idle Detection (15 FPS throttle)', id: 'rnd-idle'},
            {title: 'Configurable FPS Limit', id: 'rnd-fps'},
            {title: '_LIMIT after SCREEN_render (no lag)', id: 'rnd-limit'},
        ]
    },
];

// =============================================================================
// BUILD THE TREE
// =============================================================================

addChildren(null, featureTree);

// Count nodes for report
let nodeCount = 0;
function countNodes(arr) {
    for (const n of arr) {
        nodeCount++;
        if (n.children) countNodes(n.children);
    }
}
countNodes(featureTree);
console.log(`Total nodes: ${nodeCount}`);

// =============================================================================
// SAVE
// =============================================================================

const zipper = new Zipper({path: OUTPUT_DIR, workbook: wb, filename: FILENAME});
zipper.save().then(status => {
    if (status) {
        console.log(`SUCCESS: ${OUTPUT_DIR}/${FILENAME}.xmind`);
    } else {
        console.error('FAILED to save xmind file');
        process.exit(1);
    }
});
