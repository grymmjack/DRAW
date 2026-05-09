''
' DRAW - TOOLS/BEZIER.BI
' =============================================================================
' UDT and state for the Bezier Curve pen tool.
'
' Interaction model:
'   - L-CLICK: place anchor point
'   - L-CLICK + DRAG: place anchor and set smooth control handles (mirrored)
'   - Click near first anchor (within 5px, requires >=2 anchors): close path and commit
'   - Enter: commit and keep tool active for next curve
'   - ESC: cancel and restore canvas to pre-draw state
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Bezier tool state constants
CONST BEZIER_STATE_IDLE        = 0  ' No path in progress
CONST BEZIER_STATE_ANCHORING   = 1  ' Mouse button held - dragging handle of new anchor
CONST BEZIER_STATE_PLACED      = 2  ' At least one anchor placed, waiting for next click
CONST BEZIER_STATE_DRAG_ANCHOR = 3  ' Dragging an already-placed anchor point
CONST BEZIER_STATE_DRAG_HANDLE = 4  ' Dragging a control handle of an already-placed point
CONST BEZIER_STATE_PENDING_DRAG= 5  ' Press near handle - waiting to see if drag or click

' Which handle is being dragged (BEZIER.DRAG_HANDLE field)
CONST BEZIER_DRAG_ANCHOR = 0  ' Dragging the anchor itself
CONST BEZIER_DRAG_C1     = 1  ' Dragging the in-handle (toward previous anchor)
CONST BEZIER_DRAG_C2     = 2  ' Dragging the out-handle (toward next anchor)

CONST BEZIER_MAX_POINTS       = 200 ' Maximum anchor points per path

' Per-anchor point: anchor position + in/out control handles
TYPE BEZIER_POINT_TYPE
    AX        AS INTEGER  ' Anchor X (canvas coords)
    AY        AS INTEGER  ' Anchor Y (canvas coords)
    C1X       AS INTEGER  ' In-handle X  (toward previous anchor)
    C1Y       AS INTEGER  ' In-handle Y
    C2X       AS INTEGER  ' Out-handle X (toward next anchor)
    C2Y       AS INTEGER  ' Out-handle Y
    IS_CORNER AS INTEGER  ' TRUE = sharp corner (no handles), FALSE = smooth
END TYPE

' Overall tool state
TYPE BEZIER_TYPE
    STATE              AS INTEGER  ' BEZIER_STATE_*
    POINT_COUNT        AS INTEGER  ' Number of finalized anchors in BEZIER_PTS
    CLOSE_PATH         AS INTEGER  ' TRUE when last click was detected as close-path
    HISTORY_BEFORE_IMG AS LONG     ' Snapshot of layer before any drawing (for undo)
    DRAG_IDX           AS INTEGER  ' Index of point being dragged (DRAG_ANCHOR/HANDLE states)
    DRAG_HANDLE        AS INTEGER  ' BEZIER_DRAG_ANCHOR / BEZIER_DRAG_C1 / BEZIER_DRAG_C2
    DRAG_PREV_X        AS INTEGER  ' Mouse X at last drag frame (for delta computation)
    DRAG_PREV_Y        AS INTEGER  ' Mouse Y at last drag frame (for delta computation)
    PENDING_DRAG_IDX   AS INTEGER  ' Candidate handle drag idx (-1 = none)
    PENDING_DRAG_HANDLE AS INTEGER ' BEZIER_DRAG_C1/C2 of candidate
    PENDING_PRESS_X    AS INTEGER  ' Canvas X where the pending press occurred
    PENDING_PRESS_Y    AS INTEGER  ' Canvas Y where the pending press occurred
END TYPE

DIM SHARED BEZIER AS BEZIER_TYPE
DIM SHARED BEZIER_PTS(BEZIER_MAX_POINTS) AS BEZIER_POINT_TYPE

' Initialize all fields
BEZIER.STATE               = BEZIER_STATE_IDLE
BEZIER.POINT_COUNT         = 0
BEZIER.CLOSE_PATH          = FALSE
BEZIER.HISTORY_BEFORE_IMG  = 0
BEZIER.DRAG_IDX            = 0
BEZIER.DRAG_HANDLE         = 0
BEZIER.DRAG_PREV_X         = 0
BEZIER.DRAG_PREV_Y         = 0
BEZIER.PENDING_DRAG_IDX    = -1
BEZIER.PENDING_DRAG_HANDLE = 0
BEZIER.PENDING_PRESS_X     = 0
BEZIER.PENDING_PRESS_Y     = 0
