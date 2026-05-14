''
' DRAW - GUI/CONTROLS.BI
' =============================================================================
' Customize Controls dialog — TYPE and constant declarations.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ACTION_CUSTOMIZE_CONTROLS = 2300 is defined in GUI/COMMAND.BI

' --- Dialog dimensions (unscaled logical pixels) ----------------------------

CONST CTRL_W          = 700 ' Dialog width
CONST CTRL_H          = 440 ' Dialog height
CONST CTRL_TITLE_H    = 16  ' Title bar height
CONST CTRL_FIND_H     = 26  ' FIND row height (below title)
CONST CTRL_HDR_H      = 30  ' Two-row column header height (2 x 15)
CONST CTRL_BTN_BAR_H  = 28  ' Bottom button bar height
CONST CTRL_ROW_H      = 18  ' Content row height per command
CONST CTRL_CAT_H      = 14  ' Category separator row height
CONST CTRL_SCROLL_W   = 10  ' Scrollbar track width

' Viewport top/bottom within dialog
CONST CTRL_CONTENT_Y  = CTRL_TITLE_H + CTRL_FIND_H + CTRL_HDR_H  ' 72
CONST CTRL_CONTENT_H  = CTRL_H - CTRL_CONTENT_Y - CTRL_BTN_BAR_H ' 440-72-28=340

' --- Column X positions and widths (0 = left edge of dialog) ----------------

CONST CTRL_COL_PAD       = 4   ' Left padding

CONST CTRL_COL_ICON_X    = 4   ' Icon column
CONST CTRL_COL_ICON_W    = 18

CONST CTRL_COL_NAME_X    = 24  ' Function name column (4+18+2)
CONST CTRL_COL_NAME_W    = 218

CONST CTRL_COL_HCUR_X    = 244 ' Current HOLD  (24+218+2)
CONST CTRL_COL_HCUR_W    = 50

CONST CTRL_COL_PCUR_X    = 296 ' Current PRESS (244+50+2)
CONST CTRL_COL_PCUR_W    = 60

CONST CTRL_COL_CCUR_X    = 358 ' Current CLICK (296+60+2)
CONST CTRL_COL_CCUR_W    = 46

CONST CTRL_COL_WCUR_X    = 406 ' Current WHEEL (358+46+2)
CONST CTRL_COL_WCUR_W    = 46

CONST CTRL_COL_SEP_X     = 454 ' Visual separator dashes (406+46+2)
CONST CTRL_COL_SEP_W     = 6

CONST CTRL_COL_HNEW_X    = 462 ' New HOLD button (454+8)
CONST CTRL_COL_HNEW_W    = 54

CONST CTRL_COL_PNEW_X    = 518 ' New PRESS button (462+54+2)
CONST CTRL_COL_PNEW_W    = 54

CONST CTRL_COL_CNEW_X    = 574 ' New CLICK button (518+54+2)
CONST CTRL_COL_CNEW_W    = 50

CONST CTRL_COL_WNEW_X    = 626 ' New WHEEL button (574+50+2)
CONST CTRL_COL_WNEW_W    = 54

CONST CTRL_COL_SCROLL_X  = 682 ' Scrollbar track (626+54+2) → 682+10=692<700✓
CONST CTRL_COL_SCROLL_W  = 10

' --- Assign-dialog assign-type constants ------------------------------------

CONST CTRL_ASSIGN_HOLD  = 0
CONST CTRL_ASSIGN_PRESS = 1
CONST CTRL_ASSIGN_CLICK = 2
CONST CTRL_ASSIGN_WHEEL = 3

' --- Controls Dialog Context -------------------------------------------------

TYPE CONTROLS_CTX
    ctx           AS DIALOG_CTX              ' Wrapped DIALOG_CTX
    filter        AS STRING * 64             ' FIND text
    filterLen     AS INTEGER                 ' Length of filter string
    filterFocus   AS INTEGER                 ' TRUE = FIND input has focus
    visItems      AS STRING                  ' Packed list of visible CMD indices (4 bytes per entry)
    visCount      AS INTEGER                 ' Number of entries in visItems
    totalH        AS INTEGER                 ' Total scrollable content height
    scrollY       AS INTEGER                 ' Current vertical scroll offset (pixels)
    scrollDrag    AS INTEGER                 ' TRUE while dragging scroll thumb
    scrollDragY   AS INTEGER                 ' Mouse Y at drag start
    scrollDragOfs AS INTEGER                 ' scrollY at drag start
    needsRebuild  AS INTEGER                 ' TRUE = visItems list must be rebuilt
    needsRedraw   AS INTEGER                 ' TRUE = repaint required
    hasChanges    AS INTEGER                 ' TRUE = pending != saved
    hovRow        AS INTEGER                 ' Hovered row index in visItems (-1=none)
END TYPE

DIM SHARED CTRL AS CONTROLS_CTX

' Shadow bindings edited in the dialog; applied to BINDINGS() on OK/Save
DIM SHARED CTRL_PENDING(CMD_MAX_COMMANDS) AS DRAW_BINDING

' --- Function Declarations ---------------------------------------------------

DECLARE SUB      CONTROLS_open ()
DECLARE SUB      CTRL_rebuild_vis ()
DECLARE SUB      CTRL_draw_content ()
DECLARE SUB      CTRL_draw_headers ()
DECLARE SUB      CTRL_draw_find_row ()
DECLARE SUB      CTRL_draw_button_bar ()
DECLARE SUB      CTRL_handle_scroll ()
DECLARE SUB      CTRL_handle_content_click ()
DECLARE SUB      CTRL_handle_find_input ()
DECLARE SUB      CTRL_apply_pending ()
DECLARE SUB      CTRL_print_to_file ()
DECLARE SUB      CTRL_get_vis_item (visPos AS INTEGER, cmdIdx AS INTEGER, isCatHeader AS INTEGER)
DECLARE FUNCTION CTRL_action_icon& (actionId AS INTEGER)
DECLARE FUNCTION CTRL_conflict_label$ (skipIdx AS INTEGER, b AS DRAW_BINDING)
DECLARE FUNCTION CTRL_assign_key_dialog% (cmdIdx AS INTEGER, assignType AS INTEGER)
DECLARE FUNCTION CTRL_assign_mouse_dialog% (cmdIdx AS INTEGER)
DECLARE FUNCTION CTRL_assign_wheel_dialog% (cmdIdx AS INTEGER)
