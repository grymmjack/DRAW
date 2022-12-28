''
' DRAW - GUI/BRUSHES.BI
' =============================================================================
' Header file for brushes functions.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'

TYPE DRAW_BRUSH
    IMG AS LONG
    W   AS INTEGER
    H   AS INTEGER
END TYPE

TYPE DRAW_BRUSHES
    IDX   AS INTEGER
    BRUSH AS DRAW_BRUSH
END TYPE

DIM SHARED BRUSHES(1 TO CFG.NUM_CUSTOM_BRUSHES%) AS DRAW_BRUSHES

BRUSHES_init
