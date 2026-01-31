''
' DRAW - TOOLS/UNDO.BI
' =============================================================================
' Undo/Redo system header
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE UNDO_STATE
    img AS LONG  ' Image handle for this state
END TYPE

TYPE UNDO_SYSTEM
    states AS LONG        ' Array of UNDO_STATE (dynamically allocated)
    current AS INTEGER    ' Current position in undo history
    count AS INTEGER      ' Number of states stored
    max_states AS INTEGER ' Maximum number of undo states
END TYPE

DIM SHARED UNDO AS UNDO_SYSTEM
DIM SHARED UNDO_STATES(100) AS UNDO_STATE  ' Support up to 100 undo levels
DIM SHARED UNDO_saved_this_frame AS INTEGER ' Prevent double-saves in same frame

UNDO_init
