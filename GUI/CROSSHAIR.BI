''
' DRAW - GUI/CROSSHAIR.BI
' =============================================================================
' UDT for crosshair assistant.
'
' @todo
' @depends ../CFG/CONFIG-THEME.BI
' @author Rick Christy <grymmjack@gmail.com>
'

$IF CROSSHAIR_BI = UNDEFINED THEN
    $LET CROSSHAIR_BI = 1
$END IF
$IF CONFIG_THEME_BI = UNDEFINED THEN 
'$INCLUDE:'../CFG/CONFIG-THEME.BI'
$END IF

' TYPE DRAW_CROSSHAIR_ASSISTANT

' END TYPE
