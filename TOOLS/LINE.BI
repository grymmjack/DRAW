''
' DRAW - TOOLS/LINE.BI
' =============================================================================
' UDT for line tool.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
TYPE LINE_TYPE
    DRAGGING AS INTEGER    ' TRUE when dragging to create line
    START_X AS INTEGER     ' Line start X
    START_Y AS INTEGER     ' Line start Y
    END_X AS INTEGER       ' Line end X (current mouse position)
    END_Y AS INTEGER       ' Line end Y (current mouse position)
END TYPE

DIM SHARED LINE_TOOL AS LINE_TYPE
LINE_TOOL.DRAGGING = FALSE
LINE_TOOL.START_X = 0
LINE_TOOL.START_Y = 0
LINE_TOOL.END_X = 0
LINE_TOOL.END_Y = 0