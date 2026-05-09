''
' DRAW - TOOLS/SS-ROUNDED-RECT.BI
' =============================================================================
' Rounded Rectangle. Drag-out box, ↑↓ adjusts corner RADIUS (1..30).
' SHIFT during drag = square constrain. RMB = filled.
'
$INCLUDEONCE

CONST SS_RR_MIN_RADIUS = 1
CONST SS_RR_MAX_RADIUS = 30

TYPE SS_RR_TYPE
    DRAGGING AS INTEGER
    X0 AS INTEGER
    Y0 AS INTEGER
    X1 AS INTEGER
    Y1 AS INTEGER
    RADIUS AS INTEGER
    FILLED AS INTEGER
END TYPE
DIM SHARED SS_RR AS SS_RR_TYPE
SS_RR.RADIUS = 5
