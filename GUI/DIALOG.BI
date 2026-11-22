''
' DRAW - GUI/DIALOG.BI
' =============================================================================
' Shared modal dialog infrastructure - TYPE, init/poll/draw/cleanup helpers.
' Used by STROKE-SEL and IMAGE-ADJ dialogs to avoid boilerplate duplication.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Dialog context - carries all per-dialog state needed by helpers
' Set when a dialog absorbs a window-close request; DRAW.BAS acts on it once
' the modal loop has unwound.
DIM SHARED DIALOG_EXIT_PENDING%

TYPE DIALOG_CTX
    imgHandle    AS LONG    ' Offscreen buffer (_NEWIMAGE)
    x            AS INTEGER ' Dialog screen position (logical pixels)
    y            AS INTEGER
    w            AS INTEGER ' Buffer dimensions
    h            AS INTEGER
    scale        AS INTEGER ' Copy of SCRN.displayScale%
    fontH        AS LONG    ' Loaded font handle
    mx           AS INTEGER ' Mouse X relative to dialog top-left
    my           AS INTEGER ' Mouse Y relative to dialog top-left
    mb1          AS INTEGER ' Current left button state (consumable: widgets/swallows may zero it)
    omb1         AS INTEGER ' Previous RAW left button state (for edge detection)
    mb1raw       AS INTEGER ' Current RAW physical button, immune to swallows — feeds omb1 next frame
    justClicked  AS INTEGER ' mb1 transitioned 0->1 this frame
    mwheel       AS INTEGER ' Accumulated vertical mouse wheel delta this frame
    mtilt        AS INTEGER ' Accumulated horizontal wheel TILT this frame (_MOUSEWHEEL(MOUSE_TILT_AXIS))
    done         AS INTEGER ' TRUE when loop should exit
    result       AS INTEGER ' TRUE = OK, FALSE = Cancel
    ' ---- Live preview / split view ----
    origThumb    AS LONG    ' Thumbnail of layer at open (created by IMAGE_ADJ_setup_preview)
    previewThumb AS LONG    ' Thumbnail of current adjusted result
    prevH        AS INTEGER ' Preview pane height; 0 = no preview
    splitX       AS INTEGER ' Split bar X position in dialog pixels
    previewDirty AS INTEGER ' TRUE = > recompute previewThumb this frame
    loupeDirty   AS INTEGER ' TRUE = > dialog moved, re-capture loupe region
    ' ---- Movable dialog ----
    moveDrag     AS INTEGER ' TRUE while user is dragging dialog via title bar
    moveDragOX   AS INTEGER ' Mouse-to-dialog-left offset at drag start
    moveDragOY   AS INTEGER ' Mouse-to-dialog-top offset at drag start
    splitDrag    AS INTEGER ' TRUE while user is dragging the split bar
    screenShot   AS LONG    ' Copy of screen at dialog open — restored each frame as bg
    inputArmed   AS INTEGER ' FALSE until mb1 is seen released once — swallows a button
                            ' still held from the menu click that opened the dialog, so
                            ' it can't drag a control the dialog opened underneath it
    ' ---- Universal value input (Rick 2026-11-18: wheel +/-1, Shift +/-10, middle-click
    '      = reset, double-click on a slider = reset, on a value box = type it) ----
    mb3raw       AS INTEGER ' middle button now (raw)
    omb3         AS INTEGER ' middle button last frame
    justMid      AS INTEGER ' middle button went down this frame
    dblClick     AS INTEGER ' this frame's justClicked is the second click of a double-click
    lastClickT   AS DOUBLE  ' TIMER of the last click (0 = none pending)
    lastClickX   AS INTEGER
    lastClickY   AS INTEGER
END TYPE

' The value a dialog's slider / spinner had the first time it was seen this dialog
' (keyed by its position): its reset value when it is not a DRAW.cfg field.
' Reset by DIALOG_init. (DIALOG_value_default%)
CONST DLG_VAL_MAX = 96
CONST VAL_OP_NUDGE = 1 ' VAL_apply%: add d
CONST VAL_OP_RESET = 2 ' VAL_apply%: the factory default
DIM SHARED DLG_VAL_N AS INTEGER
DIM SHARED DLG_VAL_KX(1 TO DLG_VAL_MAX) AS INTEGER, DLG_VAL_KY(1 TO DLG_VAL_MAX) AS INTEGER
DIM SHARED DLG_VAL_V(1 TO DLG_VAL_MAX) AS INTEGER
DIM SHARED DLG_DEF_CFG AS DRAW_CONFIG ' factory defaults (DIALOG_cfg_default%; built on first use)
DIM SHARED DLG_DEF_READY AS INTEGER

' The main loop's value controls (dock panels, floating windows, bars): the
' double-click tracker (VAL_dbl%) - the last press: its control id, time, place.
DIM SHARED VAL_LAST_ID AS LONG, VAL_LAST_T AS DOUBLE, VAL_LAST_X AS INTEGER, VAL_LAST_Y AS INTEGER

' ---- Dropdown (popup select) shared state -----------------------------------
' Immediate-mode single-open-at-a-time dropdown. Only one modal dialog runs at a
' time, so module globals are safe. DIALOG_init clears DIALOG_DD_OPEN.
DIM SHARED DIALOG_DD_OPEN%             ' id of the currently-open dropdown (0 = none)
DIM SHARED DIALOG_DD_UP%               ' TRUE = open list ABOVE the box (no room below); decided at open time
DIM SHARED DIALOG_DD_X%, DIALOG_DD_Y%, DIALOG_DD_W%, DIALOG_DD_COUNT%
DIM SHARED DIALOG_DD_SEL%              ' live selection while open (round-tripped to caller)
DIM SHARED DIALOG_DD_SCROLL%           ' first visible row when list is taller than MAXVIS
DIM SHARED DIALOG_DD_RESULT_ID%        ' dropdown id that was picked THIS frame (0 = none)
DIM SHARED DIALOG_DD_RESULT_VAL%       ' value picked for DIALOG_DD_RESULT_ID
REDIM SHARED DIALOG_DD_LABELS$(0 TO 0) ' labels of the open dropdown (snapshot at open)
' Button roles (DIALOG_draw_button_role): each has its theme keys DIALOG_BUTTON[_<ROLE>]_BG /
' _HOVER_BG / _BORDER / _FG. A button that shows a colour of the user's (not a role) keeps
' DIALOG_draw_button with its own colours.
CONST DLG_BTN_PLAIN = 0   ' DIALOG_BUTTON_*         - most buttons, steppers
CONST DLG_BTN_PRIMARY = 1 ' DIALOG_BUTTON_PRIMARY_* - OK / Import / Install ...
CONST DLG_BTN_CANCEL = 2  ' DIALOG_BUTTON_CANCEL_*
CONST DLG_BTN_DANGER = 3  ' DIALOG_BUTTON_DANGER_*  - delete
CONST DLG_BTN_WARN = 4    ' DIALOG_BUTTON_WARN_*    - reset / overwrite
CONST DLG_BTN_ACCENT = 5  ' DIALOG_BUTTON_ACCENT_*  - pick / browse / open / done

CONST DIALOG_DD_BOXH%   = 14           ' closed-box height (matches slider row height)
CONST DIALOG_DD_ROWH%   = 12           ' open-list row height
CONST DIALOG_DD_MAXVIS% = 8            ' rows shown before the list scrolls

' ---- Lifecycle ---------------------------------------------------------------

' ---- Input -------------------------------------------------------------------

' ---- Drawing -----------------------------------------------------------------

' ---- Hit-testing / input helpers --------------------------------------------

''
' Returns TRUE (and clears justClicked) when the dialog was clicked inside a rect.
' Must be called during the input-dispatch phase, NOT the draw phase.

''
' Draw the live split-preview pane. Call _DEST ctx.imgHandle before invoking.
' Does nothing when ctx.prevH = 0. Expects origThumb and previewThumb to be valid.

''
' Returns updated slider value when mb1 is held over the slider track.
' Pass current value; returns new value (clamped to minV..maxV).

''
' Returns updated slider value when mouse wheel scrolled over the slider row.
' Scroll up increases, scroll down decreases by 1 per detent.
' Hit zone: full slider width, 20px above track top to 4px below bottom.
