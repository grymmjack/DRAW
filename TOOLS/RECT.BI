''
' DRAW - TOOLS/RECT.BI
' =============================================================================
' UDT for rect (LINE B|BF) tool.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE RECT_TYPE
    DRAGGING AS INTEGER    ' TRUE when dragging to create rectangle
    START_X AS INTEGER     ' Rectangle start X
    START_Y AS INTEGER     ' Rectangle start Y
    END_X AS INTEGER       ' Rectangle end X (current mouse position)
    END_Y AS INTEGER       ' Rectangle end Y (current mouse position)
    CENTER_X AS INTEGER    ' Original center X (for CTRL mode)
    CENTER_Y AS INTEGER    ' Original center Y (for CTRL mode)
    FILLED AS INTEGER      ' TRUE for filled rectangle (BF), FALSE for outline (B)
END TYPE

DIM SHARED RECT_TOOL AS RECT_TYPE
RECT_TOOL.DRAGGING = FALSE
RECT_TOOL.START_X = 0
RECT_TOOL.START_Y = 0
RECT_TOOL.END_X = 0
RECT_TOOL.END_Y = 0
RECT_TOOL.CENTER_X = 0
RECT_TOOL.CENTER_Y = 0
RECT_TOOL.FILLED = FALSE
