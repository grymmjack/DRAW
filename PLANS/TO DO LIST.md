# TOOLBOX ORGANIZER

Toolbox organizer contains widgets that are used to complement the existing Toolbox buttons, including at a glance options and modes for quick access.

All images are located in THEMES/{THEME_NAME}/ directory.
Where {THEME_NAME} is the configured theme, or DEFAULT if not configured.

- Should render directly beneath the toolbox
  - Starting on X left most toolbox edge start
  - Starting on Y bottom most toolbox edge start
- Should render exactly as annotated image
- Should be considered part of the Toolbox for auto-hide on drag over while drawing
- Should be considered part of the Toolbox when hiding the Toolbox
- Should render any time the Toolbox is rendered
- Should be on the same compositing layer in the GUI as Toolbox

From Image Annotation:

RENDERING ORDER:
```
1 2 3
4 2 5
6 7 8
```

1. CANVAS OPS
2. BRUSH SIZE
3. PATTERN MODE
4. TRANSFORM OPS
5. COLOR MODE
6. SYMMETRY MODE
7. GRID TYPE / VISIBILITY (GRID TYPE / GRID VISIBLE)
8. GRID SNAP (GRID SNAP - TOGGLE)


## CANVAS OPS (stub no-op for now)

IMAGE: `canvas-ops.png`
SIZE:  11 x 10

OPTIONS:
- Left Click    = Spare Page
- Right Click   = Resize Canvas
- Middle Click  = Crop

EVENT BASED RENDERING:
- Spare Page OFF = No Rect Outline
- Spare Page ON  = Rect Outline Inner Stroke
- KEEP existing tool from toolbox chosen


## BRUSH SIZE

IMAGE: `brush-size.png`
SIZE:  11 x 21

OPTIONS:
- Left Click First - Brush Size 1 (F1)
- Left Click Again - Brush Size 2 (F2)
- Left Click Again - Brush Size 3 (F3)
- Left Click Again - Brush Size 4 (F4)
- Left Click Again ... cycle to First
- KEEP existing tool from toolbox chosen

EVENT BASED RENDERING:
- White brackets around each brush preview line in image:
e.g. below (brackets are literal brackets)
 ...
[---]
 ===
 ###


## PATTERN MODE (stub - no-op for now)

IMAGE: `pattern-mode-off.png`
SIZE:  11 x 11

OPTIONS:
- Left Click - Turn ON Pattern Mode
- Left Click While ON - Turn Off Pattern Mode, Turn ON Color Mode

EVENT BASED RENDERING:
- When ON swap image to `pattern-mode-on.png`
- When OFF swap image to `pattern-mode-off.png`
- KEEP existing tool from toolbox chosen


## COLOR MODE

IMAGE: `color-mode-off.png`
SIZE: 11 x 11

OPTIONS:
- Left Click - Turn ON Color Mode
- Left Click While ON - Turn Off Color Mode, Turn ON Pattern Mode
- KEEP existing tool from toolbox chosen

EVENT BASED RENDERING:
- When ON swap image to `color-mode-on.png`
- When OFF swap image to `color-mode-off.png`
- KEEP existing tool from toolbox chosen


## TRANSFORM OPS

IMAGE: `transform-ops.png`
SIZE:  11 x 10

OPTIONS:
- Left Click Left Side of Image - Flip Horizontal 
- Left Click Right Side of Image - Flip Vertical
- Operate on selection, or layer if no selection
- KEEP existing tool from toolbox chosen

EVENT BASED RENDERING:
- When Click Left Side - Swap image to `assistant-flip-horizontal.png` temporarily while mouse is DOWN
- When Click Right Side - Swap image to `assistant-flip-vertical.png` temporarily while mouse is DOWN
- When Mouse is UP swap image back to `transform-ops.png`


## SYMMETRY MODE

IMAGE: `symmetry-mode-off.png`
SIZE:  11 x 10

OPTIONS:
- Left Click First Time - Turn ON Symmetry Mode 1
- Left Click Again - Turn ON Symmetry Mode 2
- Left Click Again - Turn ON Symmetry Mode 3
- Left Click Again ... cycle to OFF

EVENT BASED RENDERING:
- When OFF swap to image `symmetry-mode-off.png`
- When Mode 1 swap to image `symmetry-mode-1.png`
- When Mode 2 swap to image `symmetry-mode-2.png`
- When Mode 3 swap to image `symmetry-mode-3.png`


## GRID TYPE / VISIBILITY

IMAGE: `grid-invisible.png`
SIZE:  11 x 10

OPTIONS:
- Left Click - Make Grid Visible
- Left Click Again - Make Grid Invisible

EVENT BASED RENDERING:
- When grid is invisible swap to image `grid-invisible.png`
- When grid is visible swap to image `grid-visible.png`


## GRID SNAP

IMAGE: `grid-snap-off.png`
SIZE:  11 x 10

OPTIONS:
- Left Click - Turn ON Snap to Grid
- Left Click Again - Turn OFF Snap to Grid

EVENT BASED RENDERING:
- When snap is OFF swap to image `grid-snap-off.png`
- When snap is ON swap to image `grid-snap-on.png`




