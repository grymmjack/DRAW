''
' DRAW - TOOLS/SS-POLYGON.BI
' =============================================================================
' Polygon / star sub-tool of the Smart Shapes group.
'
' Drag (LMB)  draws polygon outline; drag (RMB) draws filled polygon.
' Arrow keys while dragging:
'     UP/DOWN    -> sides   (3..30)
'     LEFT/RIGHT -> point depth (0..200; 100 = regular polygon, <100 inner star, >100 burst)
' Moving the mouse in a circular motion around the polygon center accumulates
' rotation (in addition to the radial size change).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST SS_POLY_MAX_SIDES = 30
CONST SS_POLY_MIN_SIDES = 3

TYPE SS_POLYGON_TYPE
    DRAGGING       AS INTEGER
    START_X        AS INTEGER ' Initial press point (canvas px)
    START_Y        AS INTEGER
    END_X          AS INTEGER ' Current cursor (canvas px)
    END_Y          AS INTEGER
    CENTER_X       AS INTEGER ' Polygon center (= START while default; SHIFT/CTRL alters)
    CENTER_Y       AS INTEGER
    RX             AS INTEGER ' Outer x-radius (pixels)
    RY             AS INTEGER ' Outer y-radius (pixels)
    SIDES          AS INTEGER
    POINT_DEPTH    AS INTEGER ' 0..200, 100 = regular polygon
    ROTATION       AS SINGLE  ' Radians, accumulated from circular mouse motion
    LAST_ANGLE     AS SINGLE  ' Last cursor angle from center (for delta tracking)
    HAS_LAST_ANGLE AS INTEGER
    FILLED         AS INTEGER ' TRUE = filled (right-button drag)
    SNAP_VERTS     AS INTEGER ' TRUE = snap each computed vertex to grid (toggle: `)
    SHIFT_PREV     AS INTEGER ' Previous-frame shift state (for release re-anchor)
    HISTORY_BEFORE AS LONG    ' _COPYIMAGE of layer before stamp
END TYPE

DIM SHARED SS_POLYGON AS SS_POLYGON_TYPE

SS_POLYGON.DRAGGING       = FALSE
SS_POLYGON.SIDES          = 5
SS_POLYGON.POINT_DEPTH    = 100
SS_POLYGON.ROTATION       = 0
SS_POLYGON.HAS_LAST_ANGLE = FALSE
SS_POLYGON.SNAP_VERTS     = FALSE
SS_POLYGON.SHIFT_PREV     = FALSE
SS_POLYGON.HISTORY_BEFORE = 0
