''
' DRAW - GUI/PALETTE-OPS.BI
' =============================================================================
' Palette Ops mode - transforms palette strip into a palette management tool.
' Toggle via the organizer Palette Ops button.
'
' When active (palette index semantics: a chip IS its pixels — editing a chip
' recolors every pixel of that color, the basis for indexed color / cycling):
'   L-CLICK chip              → Select it (yellow frame) and make it FG. While
'                               selected, ANY FG change (mixer, ACP, 3D panel,
'                               picker, hex...) edits the chip live and recolors
'                               its pixels; one undo step per edit (mouse up).
'                               500ms later the chip's pixels are wand-selected.
'   L-CLICK selected chip      → Deselect it
'   L-CLICK blank strip area   → Deselect chip + clear all marks + wand
'   SHIFT+L-CLICK chip         → Ramp: chips between the selected chip and this
'                               one become an interpolated ramp (Gradient Blend
'                               space), pixels follow; this chip becomes selected
'   Double L-CLICK chip        → OS color dialog for that chip
'   L-DRAG chip                → Move it (a marked chip moves ALL marked chips)
'   R-CLICK / R-DRAG chips     → Mark / unmark (drag paints the first chip's new state)
'   M-CLICK chip               → Delete it (a marked chip deletes ALL marked)
'   M-DRAG across chips        → Delete the whole range (red preview until release)
'   SHIFT+M-CLICK chip         → Insert the current FG color after it
'   Color cycling (GUI/PALETTE-CYCLE.BM), Ctrl + :
'     CTRL+L-DRAG chips        → New cycle range over the dragged span
'     CTRL+L-CLICK range chip  → Direction FWD → REV → PING
'     CTRL+R-CLICK range chip  → Pause / resume the range
'     CTRL+M-CLICK range chip  → Delete the range
'     CTRL+WHEEL over range    → Speed (table step); CTRL+SHIFT+WHEEL = fine 5%
'   R-CLICK Color Ops button / ESC → leave Color Ops mode
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
    TOGGLE_PENDING   AS INTEGER ' L-press landed on the selected chip: deselect on release unless dragged

    ' Selected chip (L-click): FG edits recolor it + its pixels (-1 = none)
    SEL_IDX          AS INTEGER
    SEL_LAST         AS _UNSIGNED LONG ' FG value last synced with the selected chip
    EDIT_ACTIVE      AS INTEGER        ' TRUE while a live chip edit is uncommitted
    EDIT_ORIG        AS _UNSIGNED LONG ' chip color when the live edit began
    EDIT_COUNT       AS LONG           ' pixels recorded in PALETTE_OPS_EDIT_OFF()

    ' R-drag marking
    MARK_DRAG        AS INTEGER ' TRUE while B2 is held after a strip press
    MARK_VALUE       AS INTEGER ' mark state the drag paints (TRUE / FALSE)

    ' M-drag range delete
    DEL_DRAG         AS INTEGER ' TRUE while B3 is held after a strip press
    DEL_START        AS INTEGER ' palette index where the press landed
    DEL_END          AS INTEGER ' palette index under the pointer now
    DEL_SHIFT        AS INTEGER ' Shift was held at the press (insert instead)
END TYPE

DIM SHARED PALETTE_OPS       AS PALETTE_OPS_OBJ
DIM SHARED PALETTE_OPS_MARKED(0 TO 255) AS INTEGER        ' Per-color mark flags
' BUG-31: TRUE while a batch delete (PALETTE_OPS_delete_marked) is running, so the
' per-color PALETTE_OPS_delete_color skips its own undo group + palette snapshot and lets
' the batch wrap the whole thing in ONE undo record instead.
DIM SHARED PALETTE_OPS_BATCH AS INTEGER

' Live chip edit (PALETTE_OPS_edit_*): every pixel that had the chip's color
' when the edit began, recorded once so later updates rewrite exactly those
' pixels (dragging the color through another chip's color never merges them).
' Per layer slot: before-image for undo (0 = layer has none of the color) and
' the [first, first+count) span of its pixel byte offsets in EDIT_OFF().
DIM SHARED PALETTE_OPS_EDIT_BEFORE$
DIM SHARED PALETTE_OPS_EDIT_IMG(1 TO MAX_LAYERS) AS LONG
DIM SHARED PALETTE_OPS_EDIT_FIRST(1 TO MAX_LAYERS) AS LONG
DIM SHARED PALETTE_OPS_EDIT_N(1 TO MAX_LAYERS) AS LONG
REDIM SHARED PALETTE_OPS_EDIT_OFF(0) AS LONG

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
PALETTE_OPS.SEL_IDX%          = -1
PALETTE_OPS.DEL_START%        = -1
PALETTE_OPS.DEL_END%          = -1

' Declarations
