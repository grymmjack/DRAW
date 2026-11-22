''
' DRAW - GUI/HISTORY-PANEL.BI
' =============================================================================
' The History palette (Rick 2026-11-22: "and a history palette for undo" / "the palettes
' need scale, resize, dock, etc." / "common red x to close, and recall support for
' workspaces, universal controls/adjustments"): Photoshop's History panel over DRAW's
' unified history (TOOLS/HISTORY). A dock panel (DP_HISTORY, View > History,
' CFG.HISTORY_PANEL; plan PLANS/HISTORY-ACTIONS-PALETTES.md):
'   row 0         the document as opened / created
'   a row a step  the records of one undo step (one sequence: a HISTORY_begin_group
'                 group is one row), named by the record's label, else by its kind
'   the current state highlighted, the redo states after it dimmed; a click goes to
'   that state (undo / redo until there); the wheel scrolls (Shift: 10 rows); the
'   list follows the current state. Buttons: UNDO / REDO / CLEAR (asks). Right-click:
'   the same as a menu.
' Colours: the [PANEL] list keys (PANEL_LIST_*, PANEL_DISABLED_FG, PANEL_SCROLLBAR_*,
' PANEL_BUTTON_*).
'
$INCLUDEONCE

CONST HISTP_MIN_W = 90   ' narrowest (its units)
CONST HISTP_COL_W = 170  ' the width it asks of a column
CONST HISTP_SB_W = 4     ' the scroll strip at the right

' controls (HISTP.hover / hit ids; rows are HISTPB_ROW0 + the step, 0 = the document)
CONST HISTPB_UNDO = 1
CONST HISTPB_REDO = 2
CONST HISTPB_CLEAR = 3
CONST HISTPB_SCROLL = 9
CONST HISTPB_ROW0 = 100

CONST HISTP_ACT_PANEL = 2700 ' View > History (GUI/COMMAND.BM; free range 2700-2729 checked 2026-11-22)
CONST HISTP_ACT_CLEAR = 2701 ' Edit > Clear History (asks)

' its right-click menu's rows (DOCK_UI.menuHist; values above the dock menu's own)
CONST HISTP_MV_UNDO = 9001
CONST HISTP_MV_REDO = 9002
CONST HISTP_MV_CLEAR = 9003

TYPE HISTP_OBJ
    x       AS INTEGER ' the rect it was given (its units)
    y       AS INTEGER
    w       AS INTEGER
    h       AS INTEGER
    visible AS INTEGER
    hover   AS INTEGER ' the control / row under the pointer (HISTPB_*)
    drag    AS INTEGER ' the scroll strip held
    scroll  AS INTEGER ' first row shown
    rowH    AS INTEGER ' last laid out: a row's height, rows that fit, rows in all
    rowsFit AS INTEGER
    rowsAll AS INTEGER
    listY   AS INTEGER ' the list's top, its height
    listH   AS INTEGER
    btnY    AS INTEGER ' the button row's top
    cur     AS INTEGER ' the row of the current state
    seen    AS STRING  ' the history as last listed (count, current, next sequence): a change relists it
END TYPE
DIM SHARED HISTP AS HISTP_OBJ
DIM SHARED HISTP_LAST(0 TO HISTORY_MAX_RECORDS) AS INTEGER ' a row's last record (row 0: 0)
DIM SHARED HISTP_NAME(0 TO HISTORY_MAX_RECORDS) AS STRING  ' a row's name (stored case: upper-cased where drawn)
DIM SHARED HISTP_BX(1 TO 3) AS INTEGER, HISTP_BW(1 TO 3) AS INTEGER ' the buttons (its units)
DIM SHARED HISTP_MENU_NEXT AS INTEGER ' DOCK_menu_open: the right-click menu, not the dock's (GUI/DOCK)
