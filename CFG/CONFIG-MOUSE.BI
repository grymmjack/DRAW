''
' DRAW - CFG/MOUSE.BI
' =============================================================================
' UDT for mouse bindings.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE DRAW_MOUSE_BINDINGS
    PAN            AS STRING ' Hold to pan canvas (middle click)
    PAL_PICK_COLOR AS STRING ' Pick color from canvas
    PAL_NEXT       AS STRING ' Select next palette color
    PAL_PREV       AS STRING ' Select previous palette color
    PAL_SET_FG     AS STRING ' Set foreground color from palette
    PAL_SET_BG     AS STRING ' Set background color from palette
    ZOOM_IN        AS STRING ' Zoom in (scroll wheel)
    ZOOM_OUT       AS STRING ' Zoom out (scroll wheel)
    ZOOM_RESET     AS STRING ' Reset zoom to 1:1
    BRUSH_SIZE_INC AS STRING ' Increase brush size (Ctrl+wheel)
    BRUSH_SIZE_DEC AS STRING ' Decrease brush size (Ctrl+wheel)
END TYPE

DIM SHARED MB AS DRAW_MOUSE_BINDINGS ' Global mouse binding configuration
