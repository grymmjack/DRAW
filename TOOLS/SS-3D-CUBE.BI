''
' DRAW - TOOLS/SS-3D-CUBE.BI
' =============================================================================
' Isometric / oblique 3D polyhedron with adjustable depth and rotation.
' Z_DEPTH (10..100), ROT_X / ROT_Y in degrees.
' DICE_TYPE: 4=D4 (tetra), 6=D6 (cube), 8=D8 (octa), 10=D10 (trapezo),
'            12=D12 (dodeca), 20=D20 (icosa), 30=D30 (rhombic triaconta).
' Number keys while drawing: 4/6/8/0/1/2/3 -> D4/D6/D8/D10/D12/D20/D30.
' ↑↓ = Z_DEPTH ±2; ←→ = ROT_Y ±5; Wheel = ROT_X.
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
    DICE_TYPE AS INTEGER ' 4,6,8,10,12,20,30
    FILLED AS INTEGER  ' TRUE = right-click solid flat-shaded; FALSE = wireframe
END TYPE
DIM SHARED SS_CUBE AS SS_CUBE_TYPE
SS_CUBE.Z_DEPTH = 30
SS_CUBE.ROT_X = 25
SS_CUBE.ROT_Y = -25
SS_CUBE.DICE_TYPE = 6
SS_CUBE.FILLED = FALSE

''
' Adjustable directional light for solid 3D shapes.
' AZIMUTH:    degrees, 0 = light from camera-front, +90 = from right, -90 = from left.
' ELEVATION:  degrees, 0 = horizon (light along screen plane), 90 = zenith (overhead).
' INTENSITY:  diffuse multiplier (0.0 .. 2.0). Specular tracks intensity.
'
TYPE SS_LIGHT_TYPE
    AZIMUTH   AS SINGLE
    ELEVATION AS SINGLE
    INTENSITY AS SINGLE
END TYPE
DIM SHARED SS_LIGHT AS SS_LIGHT_TYPE
SS_LIGHT.AZIMUTH   = -35
SS_LIGHT.ELEVATION =  45
SS_LIGHT.INTENSITY =   1.0
