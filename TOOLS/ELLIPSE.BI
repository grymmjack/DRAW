''
' DRAW - TOOLS/ELLIPSE.BI
' =============================================================================
' UDT for ellipse (CIRCLE) tool.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE ELLIPSE_TYPE
    DRAGGING AS INTEGER    ' TRUE when dragging to create ellipse
    START_X AS INTEGER     ' Ellipse start X (center will be calculated)
    START_Y AS INTEGER     ' Ellipse start Y (center will be calculated)
    END_X AS INTEGER       ' Ellipse end X (current mouse position)
    END_Y AS INTEGER       ' Ellipse end Y (current mouse position)
    CENTER_X AS INTEGER    ' Original center X (for CTRL mode)
    CENTER_Y AS INTEGER    ' Original center Y (for CTRL mode)
    FILLED AS INTEGER      ' TRUE for filled ellipse, FALSE for outline
END TYPE

DIM SHARED ELLIPSE_TOOL AS ELLIPSE_TYPE
ELLIPSE_TOOL.DRAGGING = FALSE
ELLIPSE_TOOL.START_X = 0
ELLIPSE_TOOL.START_Y = 0
ELLIPSE_TOOL.END_X = 0
ELLIPSE_TOOL.END_Y = 0
ELLIPSE_TOOL.CENTER_X = 0
ELLIPSE_TOOL.CENTER_Y = 0
ELLIPSE_TOOL.FILLED = FALSE
