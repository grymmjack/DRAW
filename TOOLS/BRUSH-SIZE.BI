''
' DRAW - TOOLS/BRUSH-SIZE.BI
' =============================================================================
' Brush size state management for circular brushes
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE BRUSH_SIZE_TYPE
    CURRENT AS INTEGER    ' Current brush size index (1-25)
    MIN     AS INTEGER    ' Minimum index (1)
    MAX     AS INTEGER    ' Maximum index (25)
    PRESET1 AS INTEGER    ' F1 preset index
    PRESET2 AS INTEGER    ' F2 preset index
    PRESET3 AS INTEGER    ' F3 preset index
    PRESET4 AS INTEGER    ' F4 preset index
    PREVIEW AS INTEGER    ' Show brush preview (0=off, -1=on)
    SHAPE   AS INTEGER    ' Brush shape (0=circle, -1=square)
END TYPE

DIM SHARED BRUSH_SIZE AS BRUSH_SIZE_TYPE
DIM SHARED BRUSH_PIXEL_SIZES(1 TO 25) AS INTEGER

BRUSH_SIZE_init
