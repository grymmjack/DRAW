'$INCLUDEONCE

' ============================================================================
' MB-TYPES.BI — Type definitions for QB64_GJ_MSG_BOX
'
' Unified message box / input box library for QB64-PE.
' No dependency on DRAW project types.
'
' (c) 2026 grymmjack — MIT License
' ============================================================================

' --- Button Presets ----------------------------------------------------------

CONST MB_BTN_OK = 0
CONST MB_BTN_OK_CANCEL = 1
CONST MB_BTN_YES_NO = 2
CONST MB_BTN_YES_NO_CANCEL = 3
CONST MB_BTN_RETRY_CANCEL = 4
CONST MB_BTN_CUSTOM = 5                 ' Use MB_set_buttons() for labels

' --- Icon Types --------------------------------------------------------------

CONST MB_ICON_NONE = 0
CONST MB_ICON_INFO = 1
CONST MB_ICON_WARNING = 2
CONST MB_ICON_ERROR = 3
CONST MB_ICON_QUESTION = 4

' --- Result Codes ------------------------------------------------------------

CONST MB_RESULT_NONE = -1               ' No result yet / cancelled with X
CONST MB_RESULT_1 = 0                   ' First button (OK / Yes / Retry)
CONST MB_RESULT_2 = 1                   ' Second button (Cancel / No)
CONST MB_RESULT_3 = 2                   ' Third button (Cancel in 3-button)

' --- Mode Constants ----------------------------------------------------------

CONST MB_MODE_MESSAGE = 0               ' Plain message box
CONST MB_MODE_INPUT = 1                 ' Message + text input field

' --- Limits ------------------------------------------------------------------

CONST MB_MAX_BUTTONS = 3                ' Max buttons per dialog
CONST MB_MAX_MESSAGE_LINES = 32         ' Max wrapped message lines
CONST MB_MAX_LINE_LEN = 256             ' Max characters per wrapped line

' --- Type Definitions --------------------------------------------------------

TYPE MB_BUTTON_OBJ
    label AS STRING * 32                ' Button label text
    hotkey AS INTEGER                   ' ASCII code for keyboard shortcut (0=none)
    isDefault AS INTEGER                ' TRUE = Enter activates
    isCancel AS INTEGER                 ' TRUE = Escape activates
END TYPE

TYPE MB_STATE_OBJ
    ' Mode and configuration
    mode AS INTEGER                     ' MB_MODE_*
    title AS STRING * 128               ' Title bar text
    icon AS INTEGER                     ' MB_ICON_*
    buttonPreset AS INTEGER             ' MB_BTN_*

    ' Message content
    message AS STRING * 2048            ' Full message text
    messageLineCount AS INTEGER         ' Number of wrapped lines
    maxLineWidth AS INTEGER             ' Width of widest line (in pixels)

    ' Buttons
    buttonCount AS INTEGER              ' Number of buttons (1-3)
    focusedButton AS INTEGER            ' Currently focused button (0-based)

    ' Input field
    tiInputId AS INTEGER                ' TI widget ID for input field (MB_MODE_INPUT)
    inputPlaceholder AS STRING * 128    ' Placeholder text for input

    ' Dialog geometry (in dialog-local coordinates)
    dialogX AS INTEGER                  ' Dialog X on screen
    dialogY AS INTEGER                  ' Dialog Y on screen
    dialogW AS INTEGER                  ' Dialog width
    dialogH AS INTEGER                  ' Dialog height

    ' Calculated layout zones
    iconX AS INTEGER                    ' Icon area X
    iconY AS INTEGER                    ' Icon area Y
    messageX AS INTEGER                 ' Message text X
    messageY AS INTEGER                 ' Message text Y
    inputX AS INTEGER                   ' Input field X
    inputY AS INTEGER                   ' Input field Y
    inputW AS INTEGER                   ' Input field width
    inputH AS INTEGER                   ' Input field height
    buttonBarY AS INTEGER               ' Button bar Y

    ' Interaction
    dragging AS INTEGER                 ' TRUE = dragging title bar
    dragStartX AS INTEGER               ' Mouse X when drag started
    dragStartY AS INTEGER               ' Mouse Y when drag started
    dragOrigX AS INTEGER                ' Dialog X when drag started
    dragOrigY AS INTEGER                ' Dialog Y when drag started
    hoverButton AS INTEGER              ' Button mouse is over (-1 = none)
    lastCursor AS STRING * 24           ' Last cursor set (avoid redundant calls)

    ' Mouse state (raw screen coords)
    mouseX AS INTEGER
    mouseY AS INTEGER
    mouseB1 AS INTEGER
    oldMouseB1 AS INTEGER

    ' Result
    done AS INTEGER                     ' TRUE = dialog should close
    result AS INTEGER                   ' MB_RESULT_* constant

    ' Rendering
    imgHandle AS LONG                   ' Offscreen dialog buffer
    screenShot AS LONG                  ' Background screen capture
    dirty AS INTEGER                    ' TRUE = needs redraw
    scale AS INTEGER                    ' Display scale factor
END TYPE

' --- Shared State ------------------------------------------------------------

DIM SHARED MB_STATE AS MB_STATE_OBJ
DIM SHARED MB_buttons(MB_MAX_BUTTONS - 1) AS MB_BUTTON_OBJ
DIM SHARED MB_messageLines(MB_MAX_MESSAGE_LINES - 1) AS STRING * 256
