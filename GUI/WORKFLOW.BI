''
' DRAW - GUI/WORKFLOW.BI
' =============================================================================
' Workflow buttons: a strip at the top of the toolbox, one button per
' workspace in CFG.WORKFLOW_BUTTONS (PLANS/PERSONAS.md). A click switches to
' that workspace; a click on the lit one goes back to Default. Right-click a
' button: the dock's handle menu in workflow mode (DOCK_UI.menuWf) picks its
' workspace / adds / removes / hides.
'
' Geometry: DOCK_apply_rect puts the strip at the top of the toolbox's rect
' (WF_place) and moves TB_RECT_Y down by its height, so the tool buttons and
' every hit test that reads TB_SLOT_Y are unchanged.
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

' where the layout put the strip (WF_place): 0 height = none
DIM SHARED WF_X AS INTEGER, WF_Y AS INTEGER, WF_W AS INTEGER, WF_H AS INTEGER
' each button's rect as last drawn (0 width = not drawn)
DIM SHARED WF_BX(1 TO WF_MAX) AS INTEGER
DIM SHARED WF_BY(1 TO WF_MAX) AS INTEGER
DIM SHARED WF_BW(1 TO WF_MAX) AS INTEGER
DIM SHARED WF_BH(1 TO WF_MAX) AS INTEGER
DIM SHARED WF_HOVER AS INTEGER                 ' button under the pointer (0 = none)
DIM SHARED WF_MENU_NEXT AS INTEGER             ' the next DOCK_menu_open is button n's menu (0 = the handle menu)
