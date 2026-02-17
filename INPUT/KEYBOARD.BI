'' DRAW - INPUT/KEYBOARD.BI
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

' File hotkey state tracking (for single-press detection)
DIM SHARED FILE_KEY_O_LAST AS INTEGER   ' Open
DIM SHARED FILE_KEY_S_LAST AS INTEGER   ' Save
DIM SHARED FILE_KEY_N_LAST AS INTEGER   ' New

' Clipboard hotkey state tracking (for single-press detection)
DIM SHARED CLIPBOARD_KEY_C_LAST AS INTEGER   ' Copy
DIM SHARED CLIPBOARD_KEY_X_LAST AS INTEGER   ' Cut
DIM SHARED CLIPBOARD_KEY_V_LAST AS INTEGER   ' Paste
DIM SHARED CLIPBOARD_KEY_E_LAST AS INTEGER   ' Clear selection
DIM SHARED CLIPBOARD_KEY_T_LAST AS INTEGER   ' Custom font text tool

' Undo/Redo hotkey state tracking (for single-press detection)
DIM SHARED UNDO_KEY_Z_LAST AS INTEGER   ' Undo (Ctrl+Z)
DIM SHARED UNDO_KEY_Y_LAST AS INTEGER   ' Redo (Ctrl+Y)
