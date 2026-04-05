''
' DRAW - GUI/SMART-GUIDES.BI
' =============================================================================
' Smart Guides — automatic alignment guide lines that snap to layer bounds
' when moving selections or hovering near neighboring layer edges.
'
' Guide lines appear as dashed/solid lines at X/Y positions matching layer
' bounds (left, right, top, bottom, center-H, center-V) of non-active layers.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Maximum number of simultaneous guide lines to track per axis
CONST SG_MAX_GUIDES = 128

' Snap result indices
CONST SG_EDGE_LEFT   = 0
CONST SG_EDGE_RIGHT  = 1
CONST SG_EDGE_TOP    = 2
CONST SG_EDGE_BOTTOM = 3
CONST SG_EDGE_CTR_H  = 4
CONST SG_EDGE_CTR_V  = 5

' Layer bounding box (cached non-transparent bounds)
TYPE SG_BBOX
    valid  AS INTEGER  ' TRUE if bounds are computed and non-empty
    x1     AS INTEGER  ' Left edge (canvas pixels)
    y1     AS INTEGER  ' Top edge
    x2     AS INTEGER  ' Right edge (inclusive)
    y2     AS INTEGER  ' Bottom edge (inclusive)
    cx     AS INTEGER  ' Center X = (x1+x2)\2
    cy     AS INTEGER  ' Center Y = (y1+y2)\2
END TYPE

' A single active guide line to render
TYPE SG_GUIDE_LINE
    pos    AS INTEGER  ' Canvas-pixel position of the guide line
    active AS INTEGER  ' TRUE if this guide is active this frame
END TYPE

' Smart guides state
TYPE SMART_GUIDES_OBJ
    ENABLED     AS INTEGER  ' Master toggle (persisted in CFG)
    SNAP        AS INTEGER  ' Snap-to-guides toggle (persisted in CFG)
    DISTANCE    AS INTEGER  ' Detection/snap distance in canvas pixels (default 4)
    ' Active guide lines this frame
    hCount      AS INTEGER  ' Number of active horizontal guide lines
    vCount      AS INTEGER  ' Number of active vertical guide lines
    ' Snap result: the canvas pixel to snap to (-1 = no snap)
    snapX       AS INTEGER
    snapY       AS INTEGER
    ' Snap deltas applied this frame
    snapDX      AS INTEGER
    snapDY      AS INTEGER
    ' Cached opaque bbox of the moving content (relative to selection image origin)
    moveBBoxValid AS INTEGER ' TRUE if moving content bbox computed this drag session
    moveBBoxX1  AS INTEGER   ' Left edge of opaque content in selection image
    moveBBoxY1  AS INTEGER   ' Top edge
    moveBBoxX2  AS INTEGER   ' Right edge (inclusive)
    moveBBoxY2  AS INTEGER   ' Bottom edge (inclusive)
END TYPE

DIM SHARED SMART_GUIDES AS SMART_GUIDES_OBJ
' Active guide line arrays (H = horizontal = constant Y, V = vertical = constant X)
DIM SHARED SG_H_GUIDES(0 TO SG_MAX_GUIDES - 1) AS SG_GUIDE_LINE
DIM SHARED SG_V_GUIDES(0 TO SG_MAX_GUIDES - 1) AS SG_GUIDE_LINE
' Bounding boxes for each layer (recomputed on demand)
DIM SHARED SG_BBOXES(1 TO 64) AS SG_BBOX

DECLARE SUB SMART_GUIDES_init ()
DECLARE SUB SMART_GUIDES_compute_bbox (layerIdx AS INTEGER)
DECLARE SUB SMART_GUIDES_compute_moving_bbox (img AS LONG)
DECLARE SUB SMART_GUIDES_invalidate_all ()
DECLARE SUB SMART_GUIDES_update (moveX AS INTEGER, moveY AS INTEGER, moveW AS INTEGER, moveH AS INTEGER)
DECLARE SUB SMART_GUIDES_apply_snap (moveX AS INTEGER, moveY AS INTEGER)
DECLARE SUB SMART_GUIDES_render (dest AS LONG, dx AS INTEGER, dy AS INTEGER, zoom AS SINGLE)
DECLARE SUB SMART_GUIDES_clear ()
