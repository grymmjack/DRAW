''
' DRAW - CFG/BINDINGS.BI
' =============================================================================
' Custom control bindings type and shared state declarations.
' Provides a runtime-override layer on top of all hardcoded keyboard,
' mouse-button, and mouse-wheel shortcuts.
'
' INCLUDE ORDER: Must come after GUI/COMMAND.BI (needs CMD_MAX_COMMANDS).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' --- File constant -----------------------------------------------------------

CONST BINDINGS_FILE_DEFAULT$ = "DRAW.bindings"

' --- Modifier bitmask constants ----------------------------------------------

CONST BINDINGS_MOD_CTRL  = 1
CONST BINDINGS_MOD_SHIFT = 2
CONST BINDINGS_MOD_ALT   = 4

' --- Mouse button constants --------------------------------------------------

CONST BINDINGS_BTN_NONE   = 0
CONST BINDINGS_BTN_LEFT   = 1
CONST BINDINGS_BTN_RIGHT  = 2
CONST BINDINGS_BTN_MIDDLE = 3

' --- Wheel direction constants -----------------------------------------------

CONST BINDINGS_WHEEL_NONE = 0
CONST BINDINGS_WHEEL_UP   = 1
CONST BINDINGS_WHEEL_DOWN = 2
CONST BINDINGS_WHEEL_BOTH = 3

' --- Per-action binding record -----------------------------------------------
'
' One entry per CMD_LIST slot (parallel array indexed 0..CMD_COUNT-1).
'
' pressKey  : ABS(_KEYHIT) code for the key that triggers the action.
'             Use 0 for "no key binding".
' pressMods : Bitmask of modifier keys that must be held with pressKey
'             (BINDINGS_MOD_CTRL, BINDINGS_MOD_SHIFT, BINDINGS_MOD_ALT).
' holdKey   : _KEYDOWN physical code for an additional non-modifier key
'             that must be held as a gate before pressKey fires (0 = none).
' mouseBtn  : Mouse button that triggers the action (BINDINGS_BTN_*).
' wheelDir  : Wheel direction that triggers the action (BINDINGS_WHEEL_*).
' hasCustom : TRUE = this entry is a user override; FALSE = default/inactive.

TYPE DRAW_BINDING
    pressKey  AS LONG    ' ABS(_KEYHIT) trigger key code (0 = none)
    pressMods AS INTEGER ' Modifier bitmask (BINDINGS_MOD_*)
    holdKey   AS LONG    ' _KEYDOWN code for held gate key (0 = none)
    mouseBtn  AS INTEGER ' Mouse button trigger (BINDINGS_BTN_*)
    wheelDir  AS INTEGER ' Wheel direction trigger (BINDINGS_WHEEL_*)
    hasCustom AS INTEGER ' TRUE = user override written to DRAW.bindings
END TYPE

' --- Shared state ------------------------------------------------------------

DIM SHARED BINDINGS(CMD_MAX_COMMANDS) AS DRAW_BINDING
DIM SHARED BINDINGS_FILE_PATH         AS STRING

' --- Function Declarations ---------------------------------------------------

DECLARE SUB      BINDINGS_init ()
DECLARE SUB      BINDINGS_load (filePath AS STRING)
DECLARE SUB      BINDINGS_save ()
DECLARE SUB      BINDINGS_reset ()
DECLARE FUNCTION BINDINGS_key_name$ (keyCode AS LONG)
DECLARE FUNCTION BINDINGS_mods_str$ (mods AS INTEGER)
DECLARE FUNCTION BINDINGS_format_key$ (keyCode AS LONG, mods AS INTEGER)
DECLARE FUNCTION BINDINGS_find_conflict% (skipIdx AS INTEGER, b AS DRAW_BINDING)
DECLARE FUNCTION BINDINGS_check_char_binding% (keyCode AS LONG, mods AS INTEGER)
DECLARE FUNCTION BINDINGS_check_mouse_binding% (btn AS INTEGER)
DECLARE FUNCTION BINDINGS_check_wheel_binding% (dir AS INTEGER)
