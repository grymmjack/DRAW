''
' DRAW - GUI/ORGANIZER.BI
' =============================================================================
' Toolbox Organizer - compact widget grid that sits directly beneath the Toolbar.
' Provides quick-access buttons for brush size, symmetry, grid, pattern/color
' mode, canvas ops, and transform ops.
'
' Layout (3 columns x 3 rows):
'   Row 0: [CANVAS OPS]    [BRUSH SIZE top]   [PATTERN MODE]
'   Row 1: [TRANSFORM OPS] [BRUSH SIZE bot]   [COLOR MODE]
'   Row 2: [SYMMETRY MODE] [GRID VISIBILITY]  [GRID SNAP]
'
' Brush Size spans rows 0+1 in the center column (11x21 image).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Widget indices
CONST ORG_CANVAS_OPS    = 0
CONST ORG_BRUSH_SIZE    = 1
CONST ORG_PATTERN_MODE  = 2
CONST ORG_TRANSFORM_OPS = 3
CONST ORG_COLOR_MODE    = 4
CONST ORG_SYMMETRY_MODE = 5
CONST ORG_GRID_VIS      = 6
CONST ORG_GRID_SNAP     = 7
CONST ORG_WIDGET_COUNT  = 8

' Widget cell dimensions (unscaled, native pixel sizes)
CONST ORG_COL_W         = 11    ' Column width (all columns)
CONST ORG_ROW0_H        = 10    ' Row 0 height
CONST ORG_ROW1_H        = 10    ' Row 1 height (row 0 + gap + row 1 = 21 for brush-size)
CONST ORG_ROW2_H        = 10    ' Row 2 height
CONST ORG_BRUSH_H       = 21    ' Brush size image height (spans rows 0+1)
CONST ORG_PADDING       = 1     ' Padding between cells

TYPE ORGANIZER_WIDGET
    imgHandles AS LONG          ' Array of image handles (up to 4 states) - primary
    imgHandle2 AS LONG          ' Secondary state image handle
    imgHandle3 AS LONG          ' Third state image handle
    imgHandle4 AS LONG          ' Fourth state image handle
    imgSrc     AS STRING        ' Primary image filename
    imgSrc2    AS STRING        ' Secondary image filename
    imgSrc3    AS STRING        ' Third image filename
    imgSrc4    AS STRING        ' Fourth image filename
    x          AS INTEGER       ' Calculated screen X position
    y          AS INTEGER       ' Calculated screen Y position
    w          AS INTEGER       ' Calculated scaled width
    h          AS INTEGER       ' Calculated scaled height
    srcW       AS INTEGER       ' Source image width (unscaled)
    srcH       AS INTEGER       ' Source image height (unscaled)
    tip        AS STRING        ' Tooltip text
END TYPE

TYPE ORGANIZER_STATE
    visible      AS INTEGER     ' Whether organizer is visible
    panelX1      AS INTEGER     ' Panel bounds (for hit testing)
    panelY1      AS INTEGER
    panelX2      AS INTEGER
    panelY2      AS INTEGER
    topY         AS INTEGER     ' Top Y position (below toolbar)
END TYPE

DIM SHARED ORG_WIDGETS(0 TO 7) AS ORGANIZER_WIDGET
DIM SHARED ORGANIZER AS ORGANIZER_STATE

' Initialize widget image sources and dimensions
' Canvas Ops
ORG_WIDGETS(ORG_CANVAS_OPS).imgSrc$   = "canvas-ops.png"
ORG_WIDGETS(ORG_CANVAS_OPS).srcW%     = 11
ORG_WIDGETS(ORG_CANVAS_OPS).srcH%     = 10
ORG_WIDGETS(ORG_CANVAS_OPS).tip$      = "Canvas: L=Spare R=Resize M=Crop"

' Brush Size (4 state images: one per preset)
ORG_WIDGETS(ORG_BRUSH_SIZE).imgSrc$   = "brush-size-1.png"
ORG_WIDGETS(ORG_BRUSH_SIZE).imgSrc2$  = "brush-size-2.png"
ORG_WIDGETS(ORG_BRUSH_SIZE).imgSrc3$  = "brush-size-3.png"
ORG_WIDGETS(ORG_BRUSH_SIZE).imgSrc4$  = "brush-size-4.png"
ORG_WIDGETS(ORG_BRUSH_SIZE).srcW%     = 11
ORG_WIDGETS(ORG_BRUSH_SIZE).srcH%     = 21
ORG_WIDGETS(ORG_BRUSH_SIZE).tip$      = "Brush Size (click to cycle F1-F4)"

' Pattern Mode
ORG_WIDGETS(ORG_PATTERN_MODE).imgSrc$  = "pattern-mode-off.png"
ORG_WIDGETS(ORG_PATTERN_MODE).imgSrc2$ = "pattern-mode-on.png"
ORG_WIDGETS(ORG_PATTERN_MODE).srcW%    = 11
ORG_WIDGETS(ORG_PATTERN_MODE).srcH%    = 11
ORG_WIDGETS(ORG_PATTERN_MODE).tip$     = "Pattern Mode (stub)"

' Transform Ops
ORG_WIDGETS(ORG_TRANSFORM_OPS).imgSrc$  = "transform-ops.png"
ORG_WIDGETS(ORG_TRANSFORM_OPS).imgSrc2$ = "assistant-flip-horizontal.png"
ORG_WIDGETS(ORG_TRANSFORM_OPS).imgSrc3$ = "assistant-flip-vertical.png"
ORG_WIDGETS(ORG_TRANSFORM_OPS).srcW%    = 11
ORG_WIDGETS(ORG_TRANSFORM_OPS).srcH%    = 10
ORG_WIDGETS(ORG_TRANSFORM_OPS).tip$     = "Transform: L=Flip H R=Flip V"

' Color Mode
ORG_WIDGETS(ORG_COLOR_MODE).imgSrc$  = "color-mode-on.png"
ORG_WIDGETS(ORG_COLOR_MODE).imgSrc2$ = "color-mode-off.png"
ORG_WIDGETS(ORG_COLOR_MODE).srcW%    = 11
ORG_WIDGETS(ORG_COLOR_MODE).srcH%    = 11
ORG_WIDGETS(ORG_COLOR_MODE).tip$     = "Color Mode (stub)"

' Symmetry Mode (4 states: off, mode 1, mode 2, mode 3)
ORG_WIDGETS(ORG_SYMMETRY_MODE).imgSrc$  = "symmetry-mode-off.png"
ORG_WIDGETS(ORG_SYMMETRY_MODE).imgSrc2$ = "symmetry-mode-1.png"
ORG_WIDGETS(ORG_SYMMETRY_MODE).imgSrc3$ = "symmetry-mode-2.png"
ORG_WIDGETS(ORG_SYMMETRY_MODE).imgSrc4$ = "symmetry-mode-3.png"
ORG_WIDGETS(ORG_SYMMETRY_MODE).srcW%    = 11
ORG_WIDGETS(ORG_SYMMETRY_MODE).srcH%    = 10
ORG_WIDGETS(ORG_SYMMETRY_MODE).tip$     = "Symmetry Mode (click to cycle)"

' Grid Visibility
ORG_WIDGETS(ORG_GRID_VIS).imgSrc$  = "grid-invisible.png"
ORG_WIDGETS(ORG_GRID_VIS).imgSrc2$ = "grid-visible.png"
ORG_WIDGETS(ORG_GRID_VIS).srcW%    = 11
ORG_WIDGETS(ORG_GRID_VIS).srcH%    = 10
ORG_WIDGETS(ORG_GRID_VIS).tip$     = "Grid Visibility"

' Grid Snap
ORG_WIDGETS(ORG_GRID_SNAP).imgSrc$  = "grid-snap-off.png"
ORG_WIDGETS(ORG_GRID_SNAP).imgSrc2$ = "grid-snap-on.png"
ORG_WIDGETS(ORG_GRID_SNAP).srcW%    = 11
ORG_WIDGETS(ORG_GRID_SNAP).srcH%    = 10
ORG_WIDGETS(ORG_GRID_SNAP).tip$     = "Grid Snap"

ORGANIZER.visible% = TRUE

DECLARE SUB ORGANIZER_render (tbPanelY2 AS INTEGER)
DECLARE FUNCTION ORGANIZER_handle_click% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE FUNCTION ORGANIZER_is_over_area% (mouseX AS INTEGER, mouseY AS INTEGER)
DECLARE SUB ORGANIZER_load_images ()
