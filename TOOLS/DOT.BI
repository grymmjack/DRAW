''
' DRAW - TOOLS/DOT.BI
' =============================================================================
' UDT for dot (PSET) tool.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE DOT_TYPE
    LAST_X AS INTEGER    ' Last dot X position for SHIFT+RightClick line
    LAST_Y AS INTEGER    ' Last dot Y position for SHIFT+RightClick line
    HAS_LAST AS INTEGER  ' TRUE if we have a last position
END TYPE

TYPE PIXEL_PERFECT_STROKE_TYPE
    X AS INTEGER
    Y AS INTEGER
    ORIGINAL_COLOR AS _UNSIGNED LONG  ' Store original pixel color for restore
END TYPE

DIM SHARED DOT AS DOT_TYPE
DIM SHARED PP_STROKE(0 TO 10000) AS PIXEL_PERFECT_STROKE_TYPE
DIM SHARED PP_STROKE_COUNT AS INTEGER

DOT.LAST_X = 0
DOT.LAST_Y = 0
DOT.HAS_LAST = FALSE
PP_STROKE_COUNT% = 0