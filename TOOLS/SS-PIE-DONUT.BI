''
' DRAW - TOOLS/SS-PIE-DONUT.BI
' =============================================================================
' Pie / Donut smart-shape: outer ellipse + optional concentric inner ellipse
' (donut hole) + optional radial spokes dividing it into equal slices.
'
' LMB drag = outline; RMB drag = filled.
' SHIFT during drag = circle constrain.
' UP/DOWN  = SLICES   (0..30)
' LEFT/RIGHT = HOLE_PCT (0..90)
'
$INCLUDEONCE

CONST SS_PIE_MAX_SLICES = 30

TYPE SS_PIE_DONUT_TYPE
    DRAGGING   AS INTEGER
    START_X    AS INTEGER
    START_Y    AS INTEGER
    END_X      AS INTEGER
    END_Y      AS INTEGER
    CENTER_X   AS INTEGER
    CENTER_Y   AS INTEGER
    RX         AS INTEGER
    RY         AS INTEGER
    SLICES     AS INTEGER ' 0..30
    HOLE_PCT   AS INTEGER ' 0..90
    FILLED     AS INTEGER
END TYPE

DIM SHARED SS_PIE_DONUT AS SS_PIE_DONUT_TYPE
SS_PIE_DONUT.DRAGGING = FALSE
SS_PIE_DONUT.SLICES   = 4
SS_PIE_DONUT.HOLE_PCT = 0
