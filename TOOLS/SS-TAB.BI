''
' DRAW - TOOLS/SS-TAB.BI
' =============================================================================
' Tab shape: rectangle with one straight (flat) side and three rounded corners
' on the opposite side. FLAT_SIDE: 0=top, 1=right, 2=bottom, 3=left.
' ↑↓ = RADIUS (1..30); ←→ = cycle FLAT_SIDE.
'
$INCLUDEONCE

CONST SS_TAB_MIN_RADIUS = 1
CONST SS_TAB_MAX_RADIUS = 30

TYPE SS_TAB_TYPE
    DRAGGING AS INTEGER
    X0 AS INTEGER
    Y0 AS INTEGER
    X1 AS INTEGER
    Y1 AS INTEGER
    RADIUS AS INTEGER
    FLAT_SIDE AS INTEGER ' 0..3
    FILLED AS INTEGER
END TYPE
DIM SHARED SS_TAB AS SS_TAB_TYPE
SS_TAB.RADIUS = 5
SS_TAB.FLAT_SIDE = 2 ' bottom flat by default (file-folder tab)
