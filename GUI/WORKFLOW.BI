''
' DRAW - GUI/WORKFLOW.BI
' =============================================================================
' Workflow buttons: a dock panel of their own (DP_WORKFLOW; Rick, 2026-11-14:
' "ungang from the toolbox into their own panel"), one button per workspace in
' CFG.WORKFLOW_BUTTONS (PLANS/PERSONAS.md). A click switches to that
' workspace; a click on the lit one goes back to Default. Right-click a
' button: the dock's handle menu in workflow mode (DOCK_UI.menuWf) picks its
' workspace / adds / removes / hides, plus the panel's Float and Scale.
'
' Like the organizer it docks anywhere (by default above the toolbox, in its
' column, at the toolbox's width), floats, and has its own Scale
' (WORKFLOW_PANEL_SCALE; GUI/PANEL-SURFACE: it lays out and hit-tests in its
' units). The buttons reflow into the width: as many labelled columns as fit
' (24 units each), rows balanced; one column shows only each workspace's
' first letter. It shows while CFG.WORKFLOW_BAR is on and there are buttons,
' and hides with the toolbox (Tab / a stroke's auto-hide), as it always did.
' =============================================================================
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

CONST WF_MAX = 8

' actions (GUI/COMMAND: View > Workflow Buttons, palette Workflow Button 1..8)
CONST WF_ACT_TOGGLE = 2660
CONST WF_ACT_BTN0   = 2660 ' + n = click button n (2661-2668)

' handle-menu values in workflow mode (DOCK_UI.menuWf)
CONST WF_MV_ADD    = 3901
CONST WF_MV_REMOVE = 3902
CONST WF_MV_HIDE   = 3903
CONST WF_MV_LEFT   = 3904
CONST WF_MV_RIGHT  = 3905
CONST WF_MV_WS     = 4000 ' + WS_LIST index: set the button to that workspace

DIM SHARED WF_N AS INTEGER                     ' buttons
DIM SHARED WF_ID(1 TO WF_MAX) AS STRING        ' their workspace ids
DIM SHARED WF_PARSED AS STRING                 ' the CFG list WF_ID came from
DIM SHARED WF_PARSED_OK AS INTEGER

CONST WF_LBL_W = 24 ' narrowest button with a label (units); narrower = one column of first letters
CONST WF_LBL_MAX = 48 ' widest a button grows (DOCK_panel_max_w%: every button in one row)

' the panel's rect from the dock (WF_place), in its units: 0 width = not laid out
DIM SHARED WF_X AS INTEGER, WF_Y AS INTEGER, WF_W AS INTEGER, WF_H AS INTEGER
' each button's rect as last drawn, in the panel's units (0 width = not drawn)
DIM SHARED WF_BX(1 TO WF_MAX) AS INTEGER
DIM SHARED WF_BY(1 TO WF_MAX) AS INTEGER
DIM SHARED WF_BW(1 TO WF_MAX) AS INTEGER
DIM SHARED WF_BH(1 TO WF_MAX) AS INTEGER
DIM SHARED WF_HOVER AS INTEGER                 ' button under the pointer (0 = none)
DIM SHARED WF_MENU_NEXT AS INTEGER             ' the next DOCK_menu_open is button n's menu (0 = the handle menu)
