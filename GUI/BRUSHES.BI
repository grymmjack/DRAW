''
' DRAW - GUI/BRUSHES.BI
' =============================================================================
' Header file for brushes functions.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'

$IF BRUSHES_BI = UNDEFINED THEN
    $LET BRUSHES_BI = 1
$END IF


TYPE DRAW_BRUSH
    IMG AS LONG
    W   AS INTEGER
    H   AS INTEGER
END TYPE


TYPE DRAW_BRUSHES
    IDX   AS INTEGER
    BRUSH AS DRAW_BRUSH
END TYPE
