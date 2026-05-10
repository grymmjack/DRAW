''
' DRAW - TOOLS/SS-PILL.BI
' =============================================================================
' Pill / Stadium shape: rectangle capped with semicircles. ROUNDNESS_PCT
' (0..100) controls how round the caps are (0 = plain rect, 100 = full pill).
' SEGMENTS (1..16) divides the pill body into N equal segments with vertical
' separators (useful for tab-bars, segmented controls).
' ↑↓ = ROUNDNESS_PCT ±5; ←→ = SEGMENTS ±1.
'
$INCLUDEONCE

CONST SS_PILL_MAX_SEGMENTS = 16

TYPE SS_PILL_TYPE
    DRAGGING      AS INTEGER
    X0            AS INTEGER
    Y0            AS INTEGER
    X1            AS INTEGER
    Y1            AS INTEGER
    ROUNDNESS_PCT AS INTEGER ' 0..100
    SEGMENTS      AS INTEGER ' 1..16
    FILLED        AS INTEGER
END TYPE
DIM SHARED SS_PILL AS SS_PILL_TYPE
SS_PILL.ROUNDNESS_PCT = 100
SS_PILL.SEGMENTS      = 1
