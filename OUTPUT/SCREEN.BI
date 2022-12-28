''
' DRAW - OUTPUT/SCREEN.BI
' =============================================================================
' UDT for screen output.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'

TYPE SCREEN_OBJ
    w        AS LONG
    h        AS LONG
    bpp      AS INTEGER
    CANVAS   AS LONG
    PAINTING AS LONG
    CURSOR   AS LONG
    GUI      AS LONG
END TYPE

DIM SHARED SCRN AS SCREEN_OBJ

SCREEN_init
