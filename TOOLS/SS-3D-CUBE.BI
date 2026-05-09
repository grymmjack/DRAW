''
' DRAW - TOOLS/SS-3D-CUBE.BI
' =============================================================================
' Isometric / oblique 3D cube with adjustable depth and rotation.
' Z_DEPTH (10..100), ROT_X / ROT_Y in degrees.
' ↑↓ = Z_DEPTH ±2; ←→ = ROT_Y ±5.
'
$INCLUDEONCE

TYPE SS_CUBE_TYPE
    DRAGGING AS INTEGER
    X0 AS INTEGER
    Y0 AS INTEGER
    X1 AS INTEGER
    Y1 AS INTEGER
    Z_DEPTH AS INTEGER ' 10..100 (% of min(w,h))
    ROT_X AS INTEGER   ' degrees
    ROT_Y AS INTEGER   ' degrees
END TYPE
DIM SHARED SS_CUBE AS SS_CUBE_TYPE
SS_CUBE.Z_DEPTH = 30
SS_CUBE.ROT_X = 25
SS_CUBE.ROT_Y = -25
