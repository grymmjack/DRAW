''
' DRAW - GUI/SEL-BAR.BI
' =============================================================================
' The Selection Bar: the selection tools' options, a dock panel (DP_SELBAR) laid
' out like the text bar - its controls wrap into lines across the width it gets.
' Shown with a selection tool (marquee / ellipse / lasso / polygon / wand) while
' View > Selection Bar is on (CFG.SELECTION_BAR). PLANS/AA-SELECTIONS.md part B.
'
' Groups (each only where it applies):
'   MODE    REPLACE / ADD / SUBTRACT / INTERSECT - the mode with no modifier held
'   FEATHER slider (each new selection) + APPLY (the current one)
'   WAND    TOLERANCE slider, CONTIGUOUS, SAMPLE MERGED, AA EDGE
'   SHAPE   FREE / RATIO / SIZE, W / H sliders, FROM CENTER (rectangle, ellipse)
'   PATH    SMOOTH PATH slider (lasso, polygon)
'   MODIFY  AMOUNT slider, GROW, SHRINK, SMOOTH, INVERT, DESELECT
' Every value is a CFG key (DRAW.cfg [SELECTION]); the buttons run actions
' 1420-1428 (GUI/COMMAND.BM) so the menus and the command palette have them too.
'
$INCLUDEONCE

' widths in its units (as the text bar's: DOCK_panel_box / DOCK_row_panel_box)
CONST SELBAR_MIN_W       = 120 ' narrowest: the controls wrap into lines
CONST SELBAR_COL_W       = 220 ' the width it asks of a column
CONST SELBAR_ROW_BASIS_W = 640 ' the width it asks of a row
CONST SELBAR_TRACK_W     = 44  ' a slider's track

' controls
CONST SBC_REPLACE    = 1
CONST SBC_ADD        = 2
CONST SBC_SUBTRACT   = 3
CONST SBC_INTERSECT  = 4
CONST SBC_FEATHER    = 5  ' slider: CFG.SELECTION_FEATHER
CONST SBC_FEATHER_GO = 6  ' button: feather the current selection (action 1421)
CONST SBC_TOLERANCE  = 7  ' slider: CFG.WAND_TOLERANCE
CONST SBC_CONTIGUOUS = 8
CONST SBC_MERGED     = 9
CONST SBC_AAEDGE     = 10
CONST SBC_FREE       = 11
CONST SBC_RATIO      = 12
CONST SBC_SIZE       = 13
CONST SBC_SHAPE_W    = 14 ' slider
CONST SBC_SHAPE_H    = 15 ' slider
CONST SBC_CENTER     = 16
CONST SBC_PATHSMOOTH = 17 ' slider: CFG.SELECTION_SMOOTH
CONST SBC_AMOUNT     = 18 ' slider: CFG.SELECTION_GROW
CONST SBC_GROW       = 19
CONST SBC_SHRINK     = 20
CONST SBC_SMOOTH     = 21
CONST SBC_INVERT     = 22
CONST SBC_DESELECT   = 23
CONST SBC_LAST       = 23

' its actions (GUI/COMMAND.BM; free range checked 2026-11-18)
CONST SELBAR_ACT_TOGGLE  = 1420 ' View > Selection Bar
CONST SELBAR_ACT_FEATHER = 1421 ' Select > Feather Selection (by SELECTION_FEATHER, at least 1)
CONST SELBAR_ACT_GROW    = 1422 ' Select > Grow Selection (by SELECTION_GROW)
CONST SELBAR_ACT_SHRINK  = 1423
CONST SELBAR_ACT_SMOOTH  = 1424 ' Select > Smooth Selection (round its corners by SELECTION_GROW)
CONST SELBAR_ACT_MODE0   = 1425 ' + SEL_MODE_*: the mode chips (1425-1428)

TYPE SELBAR_OBJ
    visible AS INTEGER ' shown this frame (SCREEN_compute_layout: SELBAR_wanted% and live in the dock)
    x       AS INTEGER ' its rect from the dock (its units)
    y       AS INTEGER
    w       AS INTEGER
    h       AS INTEGER
    lines   AS INTEGER ' lines its controls took at the last render
    hover   AS INTEGER ' control under the pointer (SBC_*, 0 = none)
    drag    AS INTEGER ' slider being dragged (0 = none)
END TYPE
DIM SHARED SELBAR AS SELBAR_OBJ

' the controls as last laid out by a render (its units): SELBAR_layout
DIM SHARED SB_N AS INTEGER
DIM SHARED SB_ID(1 TO 32) AS INTEGER
DIM SHARED SB_X(1 TO 32) AS INTEGER, SB_Y(1 TO 32) AS INTEGER, SB_W(1 TO 32) AS INTEGER
DIM SHARED SB_TX(1 TO 32) AS INTEGER ' a slider's track x
