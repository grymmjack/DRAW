''
' DRAW - OUTPUT/SCREEN.BI
' =============================================================================
' UDT for screen output.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE SCREEN_OBJ
    w        AS LONG
    h        AS LONG
    bpp      AS INTEGER
    CANVAS   AS LONG
    PAINTING AS LONG
    CURSOR   AS LONG
    GUI      AS LONG
    zoom     AS SINGLE   ' Current zoom level
    zoomMin  AS SINGLE   ' Minimum zoom
    zoomMax  AS SINGLE   ' Maximum zoom
    offsetX  AS INTEGER  ' Pan offset X
    offsetY  AS INTEGER  ' Pan offset Y
END TYPE

DIM SHARED SCRN AS SCREEN_OBJ

SCREEN_init
