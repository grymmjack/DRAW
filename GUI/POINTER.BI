''
' DRAW - GUI/POINTER.BI
' =============================================================================
' UDT for pointer.
'
' @author Rick Christy <grymmjack@gmail.com>
'

TYPE POINTER_OBJ
    W  AS INTEGER   ' Width of pointer
    H  AS INTEGER   ' Height of pointer
    S  AS STRING    ' DRAW string used to render pointer
    C  AS LONG      ' Pointer color chip
    O  AS LONG      ' Pointer outline
    OC AS LONG      ' Old pointer color chip
    LC AS LONG      ' Left click pointer color
    RC AS LONG      ' Right click pointer color
    MC AS LONG      ' Middle click pointer color
END TYPE

DIM SHARED POINTER AS POINTER_OBJ

POINTER_init
