''
' DRAW - GUI/SUBTOOL-FLYOUT.BI
' =============================================================================
' Reusable toolbar sub-tool flyout. A toolbar button can register a "group" of
' child sub-tools; on press of that button the flyout opens as a horizontal
' strip beside the toolbar (clamped + wraps to a 2nd row if needed). The user
' drags-while-held over the strip; on release the hovered child becomes the
' active tool. Release off-strip cancels with no tool change.
'
' Designed to be reused for any toolbar button that needs a sub-tool picker
' (Smart Shapes is the first consumer).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST SUBTOOL_MAX_GROUPS   = 8
CONST SUBTOOL_MAX_CHILDREN = 16

TYPE SUBTOOL_ENTRY_TYPE
    toolConst  AS INTEGER     ' TOOL_* constant assigned to this child
    iSrc       AS STRING * 64 ' Icon filename (loaded from theme TOOLBOX dir)
    iconHnd    AS LONG        ' Cached icon handle (lazy load)
    statusName AS STRING * 32 ' Short name for status bar
END TYPE

TYPE SUBTOOL_GROUP_TYPE
    parentTb     AS INTEGER ' TB_* constant of the parent toolbar button
    childCount   AS INTEGER
    lastChildIdx AS INTEGER ' -1 = none chosen yet, else 0..childCount-1
END TYPE

TYPE SUBTOOL_FLYOUT_OBJ
    ACTIVE          AS INTEGER ' TRUE while flyout is open
    GROUP_IDX       AS INTEGER ' Active group index
    HOVER_CHILD_IDX AS INTEGER ' -1 = none, else index into group.children
    ANCHOR_X        AS INTEGER ' Top-left X of strip (screen px)
    ANCHOR_Y        AS INTEGER ' Top-left Y of strip (screen px)
    BTN_W           AS INTEGER ' Scaled button width
    BTN_H           AS INTEGER ' Scaled button height
    PAD             AS INTEGER ' Scaled padding between buttons
    ROW1_COUNT      AS INTEGER ' How many children fit in row 1 (rest wrap to row 2)
    EXPAND_RIGHT    AS INTEGER ' TRUE = expand to the right of parent; FALSE = left
END TYPE

DIM SHARED SUBTOOL_GROUPS(SUBTOOL_MAX_GROUPS - 1) AS SUBTOOL_GROUP_TYPE
DIM SHARED SUBTOOL_GROUP_CHILDREN(SUBTOOL_MAX_GROUPS - 1, SUBTOOL_MAX_CHILDREN - 1) AS SUBTOOL_ENTRY_TYPE
DIM SHARED SUBTOOL_GROUP_COUNT AS INTEGER
DIM SHARED SUBTOOL_FLYOUT      AS SUBTOOL_FLYOUT_OBJ

SUBTOOL_GROUP_COUNT            = 0
SUBTOOL_FLYOUT.ACTIVE          = FALSE
SUBTOOL_FLYOUT.GROUP_IDX       = -1
SUBTOOL_FLYOUT.HOVER_CHILD_IDX = -1
