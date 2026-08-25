''
' DRAW - GUI/POINTER.BI
' =============================================================================
' UDT for pointer.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE POINTER_OBJ
    W                    AS INTEGER        ' Width of pointer
    H                    AS INTEGER        ' Height of pointer
    S                    AS STRING         ' DRAW string used to render pointer (fallback)
    C                    AS _UNSIGNED LONG ' Pointer color chip (RGB color value)
    O                    AS INTEGER        ' Pointer outline
    OC                   AS _UNSIGNED LONG ' Old pointer color chip
    CURSOR_ID            AS INTEGER        ' Active cursor index (CURSOR_NULL, CURSOR_BRUSH, etc.)
    CURSOR_FLIP          AS INTEGER        ' 0 = none, 1 = flip horiz, 2 = flip vert, 3 = flip both
    HIDDEN               AS INTEGER        ' TRUE when pointer is hidden for native dialogs
    PREV_DRAW_X          AS INTEGER        ' Previous frame pointer X (canvas coords) for dirty-rect
    PREV_DRAW_Y          AS INTEGER        ' Previous frame pointer Y (canvas coords) for dirty-rect
    DENIED_OVERLAY       AS INTEGER        ' TRUE = stamp CURSOR_DENIED_SMALL over the tool cursor this frame
    USING_SYSTEM_CURSOR  AS INTEGER        ' TRUE when OS system cursor is active this frame
    PREV_SYS_CURSOR      AS STRING * 24    ' Previous _MOUSESHOW string to skip redundant SDL calls
    PREV_HW_CURSOR_ID    AS INTEGER        ' Last cursor index set as an OS hardware cursor (-999 = none)
    PREV_HW_CURSOR_SCALE AS INTEGER        ' displayScale the last hardware cursor was built at
    HW_ICON_ACTIVE       AS INTEGER        ' TRUE this frame: HW icon cursor over canvas, no per-frame software feedback -> a bare mouse move needs NO render
END TYPE

DIM SHARED POINTER AS POINTER_OBJ

POINTER_init
