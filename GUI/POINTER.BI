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
    S  AS STRING    ' DRAW string used to render pointer (fallback)
    C  AS _UNSIGNED LONG ' Pointer color chip (RGB color value)
    O  AS INTEGER   ' Pointer outline
    OC AS _UNSIGNED LONG ' Old pointer color chip
    CURSOR_ID AS INTEGER ' Active cursor index (CURSOR_NULL, CURSOR_BRUSH, etc.)
    CURSOR_FLIP AS INTEGER ' 0=none, 1=flip horiz, 2=flip vert, 3=flip both
END TYPE

DIM SHARED POINTER AS POINTER_OBJ

POINTER_init
