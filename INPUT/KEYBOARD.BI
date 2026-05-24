'' DRAW - INPUT/KEYBOARD.BI
' =============================================================================
' UDT for keyboard input handling.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' MOVE tool arrow key state tracking (for single-press detection)
DIM SHARED MOVE_KEY_UP_LAST    AS INTEGER
DIM SHARED MOVE_KEY_DOWN_LAST  AS INTEGER
DIM SHARED MOVE_KEY_LEFT_LAST  AS INTEGER
DIM SHARED MOVE_KEY_RIGHT_LAST AS INTEGER

' (FILE_KEY_*_LAST removed in Phase 6d batch 5 — Ctrl+N/O/S/Shift+S/
'  Alt+Shift+S are now dispatched=TRUE bindings; the central dispatcher
'  tracks per-binding KEY_DOWN_LAST in INPUT.BI for these chords now.)

' (CLIPBOARD_KEY_*_LAST and UNDO_KEY_Z/Y_LAST removed in Phase 6d batch 4 —
'  KEYBOARD_handle_clipboard_operations is gone; the central dispatcher
'  tracks per-binding KEY_DOWN_LAST in INPUT.BI for these chords now.)
