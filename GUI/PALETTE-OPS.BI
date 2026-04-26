''
' DRAW - GUI/PALETTE-OPS.BI
' =============================================================================
' Palette Ops mode - transforms palette strip into a palette management tool.
' Toggle via the organizer Palette Ops button.
'
' When active:
'   L-CLICK strip color       → 500ms delayed magic-wand select all matching pixels
'   Double L-CLICK strip color → OS color dialog, replace old color across canvas
'   R-CLICK strip color       → Toggle mark indicator on color
'   M-CLICK strip color       → Delete color (remap to nearest neighbor)
'   SHIFT+M-CLICK strip color → Insert blank color at position
'   DRAG strip color           → Rearrange palette order
'
' On activation: auto-remaps canvas to current palette (no dialog).
' Deactivates on any tool switch or menu action.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE PALETTE_OPS_OBJ
    ACTIVE           AS INTEGER ' TRUE when palette ops mode is on
    DRAG_ACTIVE      AS INTEGER ' TRUE during color drag-reorder
    DRAG_SRC_IDX     AS INTEGER ' Source palette index being dragged
    DRAG_DST_IDX     AS INTEGER ' Current destination index during drag
    DRAG_START_X     AS INTEGER ' Screen X where drag started
    DRAG_START_Y     AS INTEGER ' Screen Y where drag started
    WAND_PENDING_IDX AS INTEGER ' Palette index awaiting wand selection (-1 = none)
    WAND_TIMER       AS DOUBLE  ' TIMER value when L-click started (for 500ms delay)
    WAND_SHOWING     AS INTEGER ' TRUE if wand selection is currently displayed
    DBLCLICK_TIME    AS DOUBLE  ' Last L-click time for double-click detection
    DBLCLICK_IDX     AS INTEGER ' Last clicked palette index for double-click
END TYPE

DIM SHARED PALETTE_OPS AS PALETTE_OPS_OBJ
DIM SHARED PALETTE_OPS_MARKED(0 TO 255) AS INTEGER        ' Per-color mark flags

' Document palette state - snapshot of modified palette for switching back
DIM SHARED PALETTE_DOC_EXISTS AS INTEGER                  ' TRUE when document palette has been created
DIM SHARED PALETTE_DOC_COLORS(0 TO 255) AS _UNSIGNED LONG ' Snapshot of PAL() colors
DIM SHARED PALETTE_DOC_COUNT  AS INTEGER                  ' Color count in document palette
PALETTE_DOC_EXISTS% = FALSE
PALETTE_DOC_COUNT%  = 0

PALETTE_OPS.ACTIVE%           = FALSE
PALETTE_OPS.DRAG_ACTIVE%      = FALSE
PALETTE_OPS.WAND_PENDING_IDX% = -1
PALETTE_OPS.WAND_SHOWING%     = FALSE
PALETTE_OPS.DBLCLICK_TIME#    = 0
PALETTE_OPS.DBLCLICK_IDX%     = -1

' Declarations
