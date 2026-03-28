'$INCLUDEONCE

' ============================================================================
' TI-TYPES.BI — Type definitions and constants for QB64_GJ_TEXT_INPUT
'
' Reusable single-line text input widget for QB64-PE.
' No external dependencies — fully self-contained.
'
' (c) 2026 grymmjack — MIT License
' ============================================================================

' --- Constants ---------------------------------------------------------------

CONST TI_MAX_INPUTS = 16             ' Max simultaneous text inputs
CONST TI_MAX_TEXT_LEN = 4096         ' Max text length per input
CONST TI_CURSOR_BLINK_MS = 0.5      ' Cursor blink interval in seconds
CONST TI_SCROLL_PADDING = 8         ' Pixels of padding for text scroll

' --- Default theme colors (can be overridden per-instance) -------------------

CONST TI_DEFAULT_BG~& = &HFF3C3C3C          ' Background
CONST TI_DEFAULT_FOCUS_BG~& = &HFF1E1E1E    ' Focused background
CONST TI_DEFAULT_BORDER~& = &HFF555555       ' Border
CONST TI_DEFAULT_FOCUS_BORDER~& = &HFF007ACC ' Focused border
CONST TI_DEFAULT_TEXT~& = &HFFCCCCCC         ' Text color
CONST TI_DEFAULT_PLACEHOLDER~& = &HFF808080  ' Placeholder text color
CONST TI_DEFAULT_CURSOR~& = &HFFAEAFAD       ' Cursor color
CONST TI_DEFAULT_SELECTION~& = &HFF264F78    ' Selection highlight
CONST TI_DEFAULT_READONLY_BG~& = &HFF2D2D2D  ' Read-only background

' --- Clipboard buffer (shared) -----------------------------------------------

DIM SHARED TI_clipboard AS STRING

' --- Per-instance theme overrides --------------------------------------------

TYPE TI_THEME_OBJ
    bgColor         AS _UNSIGNED LONG  ' Background (0 = use default)
    focusBgColor    AS _UNSIGNED LONG  ' Focused background
    borderColor     AS _UNSIGNED LONG  ' Border
    focusBorderColor AS _UNSIGNED LONG ' Focused border
    textColor       AS _UNSIGNED LONG  ' Text
    placeholderColor AS _UNSIGNED LONG ' Placeholder text
    cursorColor     AS _UNSIGNED LONG  ' Cursor
    selectionColor  AS _UNSIGNED LONG  ' Selection highlight
    readonlyBgColor AS _UNSIGNED LONG  ' Read-only background
END TYPE

' --- Text Input State --------------------------------------------------------

TYPE TI_INPUT_OBJ
    ' Identity
    id              AS INTEGER         ' Unique ID (1..TI_MAX_INPUTS)
    active          AS INTEGER         ' TRUE if this slot is in use

    ' Geometry (screen coordinates, set by caller)
    x               AS INTEGER         ' Left edge X
    y               AS INTEGER         ' Top edge Y
    w               AS INTEGER         ' Width in pixels
    h               AS INTEGER         ' Height in pixels

    ' Content
    text            AS STRING * 4096   ' Text buffer (fixed for TYPE compatibility)
    textLen         AS INTEGER         ' Actual text length (avoids repeated RTRIM$)
    placeholder     AS STRING * 128    ' Placeholder text when empty
    maxLen          AS INTEGER         ' Max allowed text length (0 = TI_MAX_TEXT_LEN)

    ' Cursor and selection
    cursorPos       AS INTEGER         ' Cursor position (0 = before first char)
    selStart        AS INTEGER         ' Selection start (-1 = no selection)
    selEnd          AS INTEGER         ' Selection end

    ' Scroll
    scrollX         AS INTEGER         ' Horizontal scroll offset in pixels
    scrollY         AS INTEGER         ' Vertical scroll offset in pixels (multiline)

    ' Multiline
    multiline       AS INTEGER         ' TRUE = multiline text area
    wordWrap        AS INTEGER         ' TRUE = soft-wrap lines to widget width (multiline)
    desiredCol      AS INTEGER         ' Remembered column for Up/Down navigation

    ' Display state
    focused         AS INTEGER         ' TRUE if this input has focus
    readOnly        AS INTEGER         ' TRUE if read-only
    password        AS INTEGER         ' TRUE to mask with *
    cursorBlink     AS INTEGER         ' Current blink state
    cursorTimer     AS DOUBLE          ' Last blink toggle time
    dirty           AS INTEGER         ' TRUE if needs redraw

    ' Theme overrides (0 = use defaults)
    theme           AS TI_THEME_OBJ

    ' Callback hints (caller can check these after TI_process_key)
    submitted       AS INTEGER         ' TRUE if Enter was pressed
    escaped         AS INTEGER         ' TRUE if Escape was pressed
    tabbed          AS INTEGER         ' +1 = Tab, -1 = Shift+Tab, 0 = none
    changed         AS INTEGER         ' TRUE if text was modified this call
END TYPE

' --- Global array of text input instances ------------------------------------

DIM SHARED TI_inputs(1 TO TI_MAX_INPUTS) AS TI_INPUT_OBJ
DIM SHARED TI_focusedId AS INTEGER       ' Currently focused input ID (0 = none)

' --- Multi-click detection state (shared) ------------------------------------

CONST TI_MULTI_CLICK_MS = 0.35          ' Max seconds between clicks for multi-click
DIM SHARED TI_clickCount AS INTEGER      ' 1=single, 2=double, 3=triple, 4=quad
DIM SHARED TI_lastClickTime AS DOUBLE   ' TIMER of last click
DIM SHARED TI_lastClickId AS INTEGER    ' Which input was last clicked
DIM SHARED TI_lastClickX AS INTEGER     ' Last click X (screen coords)
DIM SHARED TI_lastClickY AS INTEGER     ' Last click Y (screen coords)

' --- Undo/Redo system --------------------------------------------------------

CONST TI_UNDO_MAX = 32                  ' Max undo states per input (ring buffer)
CONST TI_UNDO_GROUP_MS = 0.4            ' Seconds before a new undo group starts
CONST TI_UNDO_NONE = 0                  ' No previous action
CONST TI_UNDO_INSERT = 1                ' Last action was character insert
CONST TI_UNDO_DELETE = 2                ' Last action was character delete
CONST TI_UNDO_BULK = 3                  ' Last action was paste/cut/bulk (always new group)

TYPE TI_UNDO_STATE
    text            AS STRING * 4096    ' Snapshot of text buffer
    textLen         AS INTEGER          ' Length at snapshot time
    cursorPos       AS INTEGER          ' Cursor position at snapshot time
END TYPE

DIM SHARED TI_undoStack(1 TO TI_MAX_INPUTS, 0 TO TI_UNDO_MAX - 1) AS TI_UNDO_STATE
DIM SHARED TI_undoPos(1 TO TI_MAX_INPUTS) AS INTEGER    ' Next write slot (ring)
DIM SHARED TI_undoCount(1 TO TI_MAX_INPUTS) AS INTEGER   ' Available undo states
DIM SHARED TI_redoCount(1 TO TI_MAX_INPUTS) AS INTEGER   ' Available redo states
DIM SHARED TI_undoLastTime(1 TO TI_MAX_INPUTS) AS DOUBLE ' Timer of last undo push
DIM SHARED TI_undoLastType(1 TO TI_MAX_INPUTS) AS INTEGER ' Action type of last push
