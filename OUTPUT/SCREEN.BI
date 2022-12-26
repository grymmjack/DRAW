''
' DRAW - OUTPUT/SCREEN.BI
' =============================================================================
' UDT for screen output.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'

$IF SCREEN_BI = UNDEFINED THEN
    $LET SCREEN_BI = 1
$END IF

TYPE SCREEN_OBJ
    w        AS LONG
    h        AS LONG
    bpp      AS INTEGER
    CANVAS   AS LONG
    PAINTING AS LONG
    GUI      AS LONG
END TYPE

DIM SHARED SCRN AS SCREEN_OBJ
