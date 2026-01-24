''
' DRAW - INPUT/KEYBOARD.BI
' =============================================================================
' UDT for keyboard input handling.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' MOVE tool arrow key state tracking (for single-press detection)
DIM SHARED MOVE_KEY_UP_LAST AS INTEGER
DIM SHARED MOVE_KEY_DOWN_LAST AS INTEGER
DIM SHARED MOVE_KEY_LEFT_LAST AS INTEGER
DIM SHARED MOVE_KEY_RIGHT_LAST AS INTEGER
