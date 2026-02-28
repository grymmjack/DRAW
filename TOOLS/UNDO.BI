''
' DRAW - TOOLS/UNDO.BI
' =============================================================================
' Undo/Redo system header
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE UNDO_STATE
    img AS LONG          ' Image handle for this state
    layer_index AS INTEGER ' Which layer this state belongs to
    timestamp AS DOUBLE  ' TIMER value when state was saved (for intelligent undo)
END TYPE

TYPE UNDO_SYSTEM
    states AS LONG        ' Array of UNDO_STATE (dynamically allocated)
    current AS INTEGER    ' Current position in undo history
    count AS INTEGER      ' Number of states stored
    max_states AS INTEGER ' Maximum number of undo states
END TYPE

DIM SHARED UNDO AS UNDO_SYSTEM
CONST UNDO_STATES_MAX% = 200
' Force UNDO_STATES to be a static array regardless of '$DYNAMIC context.
' With '$DYNAMIC in scope (from _COMMON.BI), dynamic arrays get reset to UBOUND=0
' before UNDO_init runs. '$STATIC guarantees proper allocation at compile time.
'$STATIC
DIM SHARED UNDO_STATES(0 TO UNDO_STATES_MAX%) AS UNDO_STATE  ' 201 elements: indices 0..UNDO_STATES_MAX%
'$DYNAMIC
DIM SHARED UNDO_saved_this_frame AS INTEGER ' Prevent double-saves in same frame
' NOTE: UNDO_init must be called AFTER LAYERS_init (from SCREEN_init)
' DO NOT call UNDO_init here -- layers don't exist yet at include time
