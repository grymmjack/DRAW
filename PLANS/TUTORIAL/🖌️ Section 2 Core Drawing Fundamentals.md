# 🖌️ Section 2: Core Drawing Fundamentals

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

