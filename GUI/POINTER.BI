''
' DRAW - GUI/POINTER.BI
' =============================================================================
' UDT for pointer.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE POINTER_OBJ
    W  AS INTEGER   ' Width of pointer
    H  AS INTEGER   ' Height of pointer
    S  AS STRING    ' DRAW string used to render pointer
    C  AS INTEGER   ' Pointer color chip
    O  AS INTEGER   ' Pointer outline
    OC AS INTEGER   ' Old pointer color chip
END TYPE

DIM SHARED POINTER AS POINTER_OBJ

POINTER_init
