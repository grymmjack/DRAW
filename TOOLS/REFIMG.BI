''
' DRAW - TOOLS/REFIMG.BI
' =============================================================================
' Reference Image - loads a high-resolution image behind the canvas at
' adjustable opacity for tracing / pixel art reference.
'
' The reference image is non-destructive: it is never part of any layer,
' cannot be drawn on, and renders behind the grid and all layers but above
' the transparency checkerboard.  Its filename, position, scale, opacity,
' and visibility are persisted in the .draw project file (DRW v4+).
'
' Controls:
'   Ctrl+R              Toggle reference image on/off
'   Ctrl+Shift+Wheel    Adjust reference image opacity
'   View -> Reference Image -> Load / Clear / Reposition / Toggle
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Reference image constants
CONST REFIMG_OPACITY_MIN% = 5       ' Minimum opacity (%)
CONST REFIMG_OPACITY_MAX% = 100     ' Maximum opacity (%)
CONST REFIMG_OPACITY_STEP% = 5      ' Opacity change per wheel tick
CONST REFIMG_OPACITY_DEFAULT% = 30  ' Default opacity (%)

TYPE REFIMG_OBJ
    IMAGE       AS LONG     ' Loaded image handle (< -1 when valid)
    IMAGE_W     AS INTEGER  ' Original image width
    IMAGE_H     AS INTEGER  ' Original image height
    FILENAME    AS STRING   ' Source filename

    ' Position on canvas (in canvas pixel coordinates)
    POS_X       AS SINGLE   ' X position (can be fractional for sub-pixel placement)
    POS_Y       AS SINGLE   ' Y position
    SCALE_W     AS SINGLE   ' Display width in canvas pixels
    SCALE_H     AS SINGLE   ' Display height in canvas pixels

    ' Display state
    VISIBLE     AS INTEGER  ' Whether to render
    OPACITY     AS INTEGER  ' Opacity percentage (5-100)

    ' Interaction state (for repositioning)
    DRAGGING    AS INTEGER  ' Whether user is dragging to reposition
    DRAG_OFS_X  AS SINGLE   ' Offset from image origin to drag start
    DRAG_OFS_Y  AS SINGLE   ' Offset from image origin to drag start
    REPOSITION  AS INTEGER  ' TRUE when in reposition mode
    PREV_TOOL   AS INTEGER  ' Tool to restore after reposition
END TYPE

DIM SHARED REFIMG AS REFIMG_OBJ

' Initialise defaults
REFIMG.IMAGE = 0
REFIMG.VISIBLE = FALSE
REFIMG.OPACITY = REFIMG_OPACITY_DEFAULT%
REFIMG.REPOSITION = FALSE
REFIMG.DRAGGING = FALSE
