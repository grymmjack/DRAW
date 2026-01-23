''
' DRAW - GUI/GUI.BI
' =============================================================================
' UDT for GUI controls
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE GUI_CONTROL
    iHnd AS LONG
    iHndAlt AS LONG   ' Alternate icon handle (for buttons with multiple states)
    iSrc AS STRING
    iSrcAlt AS STRING ' Alternate icon source (for buttons with multiple states)
    tip  AS STRING
    w    AS INTEGER
    h    AS INTEGER
    x    AS INTEGER
    y    AS INTEGER
    evt  AS STRING
END TYPE

DIM SHARED GUI_TB(13) AS GUI_CONTROL

DIM SHARED GUI_CONTEXT    AS INTEGER
DIM SHARED ACTION_CONTEXT AS INTEGER
DIM SHARED TOOL_CONTEXT   AS INTEGER
DIM SHARED PROGRAM_PHASE  AS INTEGER

' GUI CONTEXTS ----------------------------------------------------------------

' WIDGET (1 - 10)
CONST WIDGET_CANVAS       = 1
CONST WIDGET_PALETTE      = 2
CONST WIDGET_PATTERN      = 3
CONST WIDGET_WIDTH        = 4
CONST WIDGET_MENUBAR      = 5
CONST WIDGET_LAYERS       = 6
CONST WIDGET_BRUSHES      = 7
CONST WIDGET_STATUBAR     = 8
CONST WIDGET_TOOLBOX      = 9

' DRAW (10 - 29)
CONST DRAW_PAINT          = 10
CONST DRAW_PAINT_FILL     = 11
CONST DRAW_ERASE          = 12
CONST DRAW_BRUSH          = 13
CONST DRAW_LINE           = 14
CONST DRAW_POLY           = 15
CONST DRAW_POLY_FILL      = 16
CONST DRAW_RAY            = 17
CONST DRAW_ELLIPSE        = 18
CONST DRAW_ELLIPSE_FILL   = 19
CONST DRAW_RECT           = 20
CONST DRAW_RECT_FILL      = 21
CONST DRAW_FLOOD_FILL     = 22

' TOOL (30 - 39)
CONST TOOL_SELECT_RECT    = 30
CONST TOOL_SELECT_POLY    = 31
CONST TOOL_SELECT_ELLIPSE = 32
CONST TOOL_SELECT_FREE    = 33
CONST TOOL_MOVE           = 34
CONST TOOL_TEXT           = 35
CONST TOOL_SAVE           = 36
CONST TOOL_OPEN           = 37
CONST TOOL_CODE           = 38

' ASSISTANT (40 - 49)
CONST ASSISTANT_CROSSHAIR = 40
CONST ASSISTANT_GRID      = 41
CONST ASSISTANT_PICKER    = 42
CONST ASSISTANT_PAN       = 43
CONST ASSISTANT_ZOOM      = 44

' EDITOR (50 - 59)
CONST EDITOR_PALETTE      = 50
CONST EDITOR_COLOR        = 51
CONST EDITOR_PATTERN      = 52
CONST EDITOR_BRUSH        = 53
CONST EDITOR_TEXT         = 54
CONST EDITOR_CODE         = 55

' GUI ACTIONS (60 - 69) -------------------------------------------------------
CONST ACTION_IDLE         = 60
CONST ACTION_IN_MENU      = 61
CONST ACTION_IN_EDITOR    = 62
CONST ACTION_DRAWING      = 63
CONST ACTION_TYPING       = 64

' GUI PHASES (70 - 79) --------------------------------------------------------
CONST PHASE_READY         = 70
CONST PHASE_START         = 71
CONST PHASE_ACTIVE        = 72
CONST PHASE_STOP          = 73
CONST PHASE_WAIT          = 74
CONST PHASE_BUSY          = 75

' CONTROL STATES (80 - 89) ----------------------------------------------------
CONST CONTROL_DISABLED    = 80
CONST CONTROL_ENABLED     = 81
CONST CONTROL_VISIBLE     = 82
CONST CONTROL_HIDDEN      = 83
