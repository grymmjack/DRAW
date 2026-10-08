''
' DRAW - GUI/BUTTON-LIST.BI
' =============================================================================
' Button lists: what the toolbox, the edit bar and the advanced bar show, in
' order (plan: PLANS/_/TOOLBAR-EDITOR-PLAN.md). Each panel is an ordered list
' of entries:
'   BL_TOOL  a toolbox tool (id = TB_*)        BL_DIV  a divider (bars: a new row)
'   BL_CMD   any command (id = its action id)  BL_GAP  an empty cell
' The default lists come from today's fixed tables (EDITBAR_init / ADVBAR_init
' / TOOLBAR_DEF_ORDER), so nothing looks different until a list is changed.
' Command icons come from the bars' tables, looked up by action id (BL_cmd_icon&).
' In workspace files an entry is a name: the panel names (move, undo, preview,
' ...), cmd:<action id> for any other command, | for a divider, - for a gap.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST BL_TOOLBOX = 1
CONST BL_EDITBAR = 2
CONST BL_ADVBAR  = 3
CONST BL_PANELS  = 3

CONST BL_TOOL = 1
CONST BL_CMD  = 2
CONST BL_DIV  = 3
CONST BL_GAP  = 4

CONST BL_MAX = 96 ' entries per panel

TYPE BL_ENTRY_OBJ
    kind AS INTEGER ' BL_TOOL / BL_CMD / BL_DIV / BL_GAP
    id   AS INTEGER ' TB_* (tool) or action id (command)
    ' where it was drawn this frame (0 size = not drawn: scrolled away / a divider)
    x    AS INTEGER
    y    AS INTEGER
    w    AS INTEGER
    h    AS INTEGER
END TYPE

DIM SHARED BL(1 TO BL_PANELS, 0 TO BL_MAX - 1) AS BL_ENTRY_OBJ
DIM SHARED BL_N(1 TO BL_PANELS) AS INTEGER
DIM SHARED BL_READY(1 TO BL_PANELS) AS INTEGER ' the list has been built (else BL_ensure builds the default)
