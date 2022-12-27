''
' DRAW - GUI/POINTER.BI
' =============================================================================
' UDT for pointer.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'

$IF POINTER_BI = UNDEFINED THEN
    $LET POINTER_BI = 1
$END IF

TYPE POINTER_OBJ
    W  AS INTEGER
    H  AS INTEGER
    S  AS STRING
    C  AS INTEGER
    O  AS INTEGER 'outline
    OC AS INTEGER
    LC AS INTEGER
    RC AS INTEGER
    MC AS INTEGER
END TYPE
