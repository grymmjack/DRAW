''
' DRAW - TOOLS/SS-PACMAN.BI
' =============================================================================
' Pac-Man / Wedge: ellipse minus a pie-wedge mouth. MOUTH_DEG (0..170) is the
' angular size of the cut. HOLE_PCT (0..90) carves a concentric hole (donut wedge).
' ↑↓ = MOUTH_DEG ±5; ←→ = HOLE_PCT ±5. Mouth opens to the right by default;
' the mouth direction is set automatically from drag vector relative to center.
'
$INCLUDEONCE

TYPE SS_PACMAN_TYPE
    DRAGGING AS INTEGER
    START_X AS INTEGER
    START_Y AS INTEGER
    END_X AS INTEGER
    END_Y AS INTEGER
    CENTER_X AS INTEGER
    CENTER_Y AS INTEGER
    RX AS INTEGER
    RY AS INTEGER
    MOUTH_DEG AS INTEGER ' 0..170
    HOLE_PCT AS INTEGER  ' 0..90
    MOUTH_DIR AS SINGLE  ' radians, direction the mouth points
    FILLED AS INTEGER
END TYPE
DIM SHARED SS_PACMAN AS SS_PACMAN_TYPE
SS_PACMAN.MOUTH_DEG = 60
SS_PACMAN.HOLE_PCT = 0
SS_PACMAN.MOUTH_DIR = 0
