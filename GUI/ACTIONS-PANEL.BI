''
' DRAW - GUI/ACTIONS-PANEL.BI
' =============================================================================
' The Actions palette (Rick 2026-11-22: "need a new macro palette" / "like photoshop actions
' has" / "the palettes need scale, resize, dock, etc."): Photoshop's Actions panel over
' TOOLS/ACTIONS. A dock panel (DP_ACTIONS, View > Actions, CFG.ACTIONS_PANEL):
'   the tree   sets > actions > steps, a row each; a set / action folds open and shut
'              (its triangle). Per row an ENABLED box (off = skipped on play); per step a
'              DIALOG box (on = its dialog shows on play). A click selects, a double-click
'              renames (a set / action), right-click = its menu.
'   buttons    STOP / RECORD / PLAY, NEW SET / NEW ACTION / DELETE
' RECORD records into the selected action (after the selected step); NEW ACTION asks a
' name and records into it. PLAY plays the selection: a set, an action, an action from a
' step. Colours: the [PANEL] list / checkbox / button keys; PANEL_WARNING_FG = recording.
'
$INCLUDEONCE

CONST ACTP_MIN_W = 110   ' narrowest (its units)
CONST ACTP_COL_W = 190   ' the width it asks of a column
CONST ACTP_SB_W = 4      ' the scroll strip at the right
CONST ACTP_BOX = 9       ' a row's check boxes
CONST ACTP_INDENT = 10   ' a tree level

' controls (ACTP.hover / hit ids)
CONST ACTPB_STOP = 1
CONST ACTPB_REC = 2
CONST ACTPB_PLAY = 3
CONST ACTPB_NEWSET = 4
CONST ACTPB_NEWACT = 5
CONST ACTPB_DEL = 6
CONST ACTPB_SCROLL = 9
CONST ACTPB_ROW = 1000   ' + node * 4 + part (ACTPP_*)
CONST ACTPP_NAME = 0
CONST ACTPP_ON = 1
CONST ACTPP_DLG = 2
CONST ACTPP_FOLD = 3

' commands (GUI/COMMAND.BM; free range 2700-2729 checked 2026-11-22 - 2700 / 2701 are History's)
CONST ACTP_ACT_FIRST = 2702 ' (none of these is recorded as a step)
CONST ACTP_ACT_PANEL = 2702 ' View > Actions
CONST ACTP_ACT_RECORD = 2703
CONST ACTP_ACT_STOP = 2704
CONST ACTP_ACT_PLAY = 2705  ' the selection
CONST ACTP_ACT_NEWSET = 2706
CONST ACTP_ACT_NEWACT = 2707
CONST ACTP_ACT_DELETE = 2708
CONST ACTP_ACT_LAST = 2729

' its right-click menu's rows (DOCK_UI.menuActs; 9101+, apart from the History's 9001+ in QA dumps)
CONST ACTP_MV_PLAY = 9101
CONST ACTP_MV_RECORD = 9102
CONST ACTP_MV_STOP = 9103
CONST ACTP_MV_NEWSET = 9104
CONST ACTP_MV_NEWACT = 9105
CONST ACTP_MV_RENAME = 9106
CONST ACTP_MV_DUP = 9107
CONST ACTP_MV_DELETE = 9108
CONST ACTP_MV_RELOAD = 9109

TYPE ACTP_OBJ
    x       AS INTEGER ' the rect it was given (its units)
    y       AS INTEGER
    w       AS INTEGER
    h       AS INTEGER
    visible AS INTEGER
    hover   AS INTEGER ' the control / row part under the pointer (ACTPB_*)
    drag    AS INTEGER ' the scroll strip held
    scroll  AS INTEGER ' first row shown
    sel     AS INTEGER ' the selected node (0 = none; TOOLS/ACTIONS keeps it in step)
    rowH    AS INTEGER ' last laid out
    rowsFit AS INTEGER
    rowsAll AS INTEGER
    listY   AS INTEGER
    listH   AS INTEGER
    btnY    AS INTEGER ' the first button row's top (two rows)
END TYPE
DIM SHARED ACTP AS ACTP_OBJ
DIM SHARED ACTP_VIS(1 TO ACTS_MAX) AS INTEGER ' the rows: their nodes (folded children left out)
DIM SHARED ACTP_BX(1 TO 6) AS INTEGER, ACTP_BY(1 TO 6) AS INTEGER, ACTP_BW(1 TO 6) AS INTEGER ' the buttons
DIM SHARED ACTP_MENU_NEXT AS INTEGER ' DOCK_menu_open: its right-click menu, not the dock's
