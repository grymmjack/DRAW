''
' DRAW - TOOLS/SS-BEVEL-RECT.BI
' =============================================================================
' Beveled rectangle (button-style chamfer). BEVEL_SIZE (1..30) cuts the corners.
' BORDER_SIZE (0..10) draws an inner outline at offset.
' STYLE: 0 = inner bevel, 1 = outer bevel (line only).
' ↑↓ = BEVEL_SIZE ±1; ←→ = BORDER_SIZE ±1.
'
$INCLUDEONCE

CONST SS_BEVEL_MAX = 30

TYPE SS_BEVEL_TYPE
    DRAGGING    AS INTEGER
    X0          AS INTEGER
    Y0          AS INTEGER
    X1          AS INTEGER
    Y1          AS INTEGER
    BEVEL_SIZE  AS INTEGER ' 1..30
    BORDER_SIZE AS INTEGER ' 0..10
    FILLED      AS INTEGER
    STYLE       AS INTEGER ' 0 = inner bevel (default), 1 = outer bevel (border drawn outside)
END TYPE
DIM SHARED SS_BEVEL AS SS_BEVEL_TYPE
SS_BEVEL.BEVEL_SIZE  = 4
SS_BEVEL.BORDER_SIZE = 0
SS_BEVEL.STYLE       = 0
