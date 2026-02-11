''
' DRAW - INPUT/MODIFIERS.BI
' =============================================================================
' Modifier key state system - centralized tracking of CTRL, SHIFT, ALT keys.
' Updated once per frame at the start of the main loop.
'
' PURPOSE:
' - Reduces 50+ scattered _KEYDOWN() calls to a single update
' - Handles macOS Option key workaround internally
' - Precomputes common modifier combinations to reduce nesting
' - Provides consistent modifier state across all input handlers
'
' USAGE:
'   Call MODIFIERS_update() once at the start of each frame
'   Then use MOD.ctrl%, MOD.shift%, MOD.alt%, or combinations like MOD.ctrlShift%
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' NOTE: Key codes (KEY_LCTRL&, KEY_RCTRL&, KEY_LSHIFT&, KEY_RSHIFT&, KEY_LALT&, KEY_RALT&)
' are already defined in _COMMON.BI - do not redefine them here

' Modifier state object - updated once per frame
TYPE MODIFIERS_OBJ
    ctrl AS INTEGER         ' TRUE if any Ctrl key is held
    shift AS INTEGER        ' TRUE if any Shift key is held
    alt AS INTEGER          ' TRUE if any Alt key is held
    ctrlOnly AS INTEGER     ' TRUE if ONLY Ctrl (no Shift or Alt)
    shiftOnly AS INTEGER    ' TRUE if ONLY Shift (no Ctrl or Alt)
    altOnly AS INTEGER      ' TRUE if ONLY Alt (no Ctrl or Shift)
    ctrlShift AS INTEGER    ' TRUE if Ctrl+Shift (no Alt)
    ctrlAlt AS INTEGER      ' TRUE if Ctrl+Alt (no Shift)
    shiftAlt AS INTEGER     ' TRUE if Shift+Alt (no Ctrl)
    ctrlShiftAlt AS INTEGER ' TRUE if all three modifiers
    none AS INTEGER         ' TRUE if no modifiers held
END TYPE

DIM SHARED MODIFIERS AS MODIFIERS_OBJ

$IF MAC THEN
    ' macOS: Track ALT key state via _KEYHIT (more reliable than _KEYDOWN for Option key)
    ' This is updated in MODIFIERS_track_alt_keyhit() called from main loop when k& is captured
    DIM SHARED AS INTEGER MAC_ALT_HELD  ' TRUE when ALT/Option key is held
$END IF

' Declare SUBs
DECLARE SUB MODIFIERS_init ()
DECLARE SUB MODIFIERS_update ()
DECLARE SUB MODIFIERS_track_alt_keyhit (k&)
