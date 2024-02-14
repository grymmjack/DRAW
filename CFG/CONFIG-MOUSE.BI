''
' DRAW - CFG/MOUSE.BI
' =============================================================================
' UDT for mouse bindings.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE DRAW_MOUSE_BINDINGS
    PAN            AS STRING
    PAL_PICK_COLOR AS STRING
    PAL_NEXT       AS STRING
    PAL_PREV       AS STRING
    PAL_SET_FG     AS STRING
    PAL_SET_BG     AS STRING
    ZOOM_IN        AS STRING
    ZOOM_OUT       AS STRING
    ZOOM_RESET     AS STRING
    BRUSH_SIZE_INC AS STRING
    BRUSH_SIZE_DEC AS STRING
END TYPE

DIM SHARED MB AS DRAW_MOUSE_BINDINGS
