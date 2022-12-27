''
' DRAW - COMMON.BI
' =============================================================================
' Common header include.
'
' @author Rick Christy <grymmjack@gmail.com>
'

$IF COMMON_BI = UNDEFINED THEN
    $LET COMMON_BI = 1
$END IF

$IF FALSE = UNDEFINED AND TRUE = UNDEFINED THEN
    $LET TRUE = TRUE
    CONST FALSE = 0 : CONST TRUE = NOT FALSE
$END IF
