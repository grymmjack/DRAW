''
' DRAW - COMMON.BI
' =============================================================================
' Common header include.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

'$DYNAMIC
$CONSOLE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

$IF FALSE = UNDEFINED AND TRUE = UNDEFINED THEN
    $LET TRUE = TRUE
    CONST FALSE = 0 : CONST TRUE = NOT FALSE
$END IF

CONST KEY_CAPSLOCK& = 100301 ' Not supported on Linux/macOS
CONST KEY_LSHIFT&   = 100304
CONST KEY_RSHIFT&   = 100303 
CONST KEY_LCTRL&    = 100305
CONST KEY_RCTRL&    = 100306
CONST KEY_RALT&     = 100307
CONST KEY_LALT&     = 100308
CONST KEY_DELETE&   = 21248  ' DELETE key
CONST KEY_BACKSPACE& = 8     ' BACKSPACE key

' Last directory for file dialogs (save/load)
DIM SHARED LAST_DIRECTORY$
LAST_DIRECTORY$ = ""

' Tool modes - basic drawing tools (1-20)
CONST TOOL_NULL    = 0  ' Internal null tool - does nothing, no toolbar button
CONST TOOL_BRUSH   = 1
CONST TOOL_FILL    = 2
CONST TOOL_DOT     = 3
CONST TOOL_LINE    = 4
CONST TOOL_MARQUEE = 5
CONST TOOL_POLYGON = 6
CONST TOOL_RECT    = 7
CONST TOOL_ELLIPSE = 8
CONST TOOL_RECT_FILLED = 9
CONST TOOL_ELLIPSE_FILLED = 10
CONST TOOL_PICKER  = 11
CONST TOOL_POLYGON_FILLED = 12
' Note: TOOL_MOVE, TOOL_TEXT, TOOL_SAVE, TOOL_OPEN, TOOL_CODE defined in GUI/GUI.BI (30-39)

DIM SHARED AS INTEGER WHEEL_COLOR, KEY_COLOR
DIM SHARED AS _UNSIGNED LONG PAINT_COLOR
DIM SHARED AS _UNSIGNED LONG PAINT_BG_COLOR
DIM SHARED AS _UNSIGNED LONG DRAW_COLOR ' Current drawing color (FG or BG based on mouse button)
DIM SHARED AS INTEGER CONSTRAIN_X, CONSTRAIN_Y
DIM SHARED AS INTEGER CURRENT_TOOL
DIM SHARED AS INTEGER PREVIOUS_TOOL  ' Tool to return to after temporary picker
DIM SHARED AS INTEGER CANVAS_DIRTY  ' Track if canvas has unsaved changes
DIM SHARED TEXT_BUFFER(0 TO 99) AS STRING  ' Text tool buffer for 100 lines
CONSTRAIN_X% = FALSE : CONSTRAIN_Y% = FALSE
WHEEL_COLOR% = FALSE : KEY_COLOR% = FALSE
PAINT_COLOR~& = 0  ' Will be set from palette after init
PAINT_BG_COLOR~& = _RGB32(0, 0, 0)  ' Background color defaults to black
CURRENT_TOOL% = TOOL_NULL  ' Default to null tool - user must select a tool
PREVIOUS_TOOL% = TOOL_NULL  ' Initialize to same as current
CANVAS_DIRTY% = FALSE  ' Start with clean canvas
