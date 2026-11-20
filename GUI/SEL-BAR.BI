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
' the shared painting set (Tool Options phase 1b: PLANS/TOOL-OPTIONS-BAR.md) - brush, dot,
' eraser, spray, line and the shapes; each drives the same state its keys / panels do
CONST SBC_P_SIZE      = 24 ' slider: BRUSH_SIZE.CURRENT (an index - it shows its px)
CONST SBC_L_SHAPE     = 25 ' a label
CONST SBC_P_ROUND     = 26 ' chips: BRUSH_SIZE.SHAPE (BRUSH_SIZE_set_shape)
CONST SBC_P_SQUARE    = 27
CONST SBC_P_SLASH     = 28
CONST SBC_P_BACKSLASH = 29
CONST SBC_P_SOFT      = 30 ' slider: BRUSH_SIZE.SOFT (round and slant shapes)
CONST SBC_P_OPACITY   = 31 ' slider: PAINT_OPACITY (keys 1-0)
CONST SBC_P_PIXPERF   = 32 ' toggle: action 609 (F6)
CONST SBC_P_AA        = 33 ' toggle: action 958
CONST SBC_L_SYM       = 34 ' a label
CONST SBC_P_SYM0      = 35 ' chips: SYMMETRY.MODE 0-3 (F7 cycles them)
CONST SBC_P_SYM3      = 38
' the line (phase 3): what each new line starts with - LINE_TOOL.BAR_* (s / e / arrows
' while dragging change only that line)
CONST SBC_L_START     = 39 ' a label
CONST SBC_LN_SC0      = 40 ' chips: start cap LINE_CAP_NONE .. LINE_CAP_DOT (40-43)
CONST SBC_L_END       = 44 ' a label
CONST SBC_LN_EC0      = 45 ' chips: end cap (45-48)
CONST SBC_LN_SPOKES   = 49 ' slider 0-16
CONST SBC_L_SNAP      = 50 ' a label: the angle Ctrl+Shift snaps to
CONST SBC_LN_SNAP15   = 51 ' chips: CFG.ANGLE_SNAP_DEGREES 15 / 30 / 45 / 90 (51-54)
CONST SBC_LN_SNAPPX   = 55 ' chip: CFG.ANGLE_SNAP_PIXEL_ART
' the rectangle and the ellipse: RECT_TOOL.BAR_* / ELLIPSE_TOOL.BAR_*
CONST SBC_RC_HDIV     = 56 ' slider 0-32: vertical divider lines
CONST SBC_RC_VDIV     = 57 ' slider 0-32: horizontal divider lines
CONST SBC_EL_SLICES   = 58 ' slider 0-16
CONST SBC_EL_RINGS    = 59 ' slider 0-16
' the polygon (+ the SNAP chips) and the bezier: what Enter / Esc / ` do
CONST SBC_PL_FINISH   = 60 ' button: as Enter
CONST SBC_PL_CANCEL   = 61 ' button: as Esc
CONST SBC_BZ_HANDLES  = 62 ' toggle: BEZIER.SHOW_HANDLES (` while a path is open)
CONST SBC_BZ_COMMIT   = 63 ' button: as Enter
CONST SBC_BZ_CANCEL   = 64 ' button: as Esc
' the smart shapes (PLANS/TOOL-OPTIONS-BAR.md phase 3: every option of every kind). The
' values are the SS_* fields the keys / wheel change while dragging; they already carry
' over from one shape to the next.
CONST SBC_L_KIND      = 65 ' a label
CONST SBC_SS_K0       = 66 ' chips: the kind, TOOL_SS_POLYGON + 0 .. 9 (66-75)
CONST SBC_SS_K9       = 75
CONST SBC_SS_OUTLINE  = 76 ' chips: what a left-drag draws (SS_BAR_FILLED); a right-drag the other
CONST SBC_SS_FILLED   = 77
CONST SBC_SS_SIDES    = 78 ' polygon: SIDES 3-30
CONST SBC_SS_PDEPTH   = 79 ' polygon: POINT_DEPTH 0-200 (100 = regular)
CONST SBC_SS_SNAPV    = 80 ' toggle: SNAP_VERTS (`)
CONST SBC_SS_LOCKROT  = 81 ' toggle: LOCK_ROTATION (~)
CONST SBC_SS_SLICES   = 82 ' pie / donut: SLICES 0-30
CONST SBC_SS_PIEHOLE  = 83 ' pie / donut: HOLE_PCT 0-90
CONST SBC_SS_RADIUS   = 84 ' rounded rect / tab: RADIUS 1-30
CONST SBC_L_FLAT      = 85 ' a label
CONST SBC_SS_FLAT0    = 86 ' chips: tab FLAT_SIDE 0-3 = top / right / bottom / left (86-89)
CONST SBC_SS_ROUND    = 90 ' pill: ROUNDNESS_PCT 0-100
CONST SBC_SS_SEGS     = 91 ' pill: SEGMENTS 1-16
CONST SBC_SS_MOUTH    = 92 ' pac-man: MOUTH_DEG 0-170
CONST SBC_SS_PACHOLE  = 93 ' pac-man: HOLE_PCT 0-90
CONST SBC_L_DICE      = 94 ' a label
CONST SBC_SS_D0       = 95 ' chips: DICE_TYPE 4 / 6 / 8 / 10 / 12 / 20 / 30 (95-101)
CONST SBC_SS_ZDEPTH   = 102 ' 3D cube / text: Z_DEPTH (cube 10-300, text 5-200)
CONST SBC_SS_TILT     = 103 ' 3D cube / text: ROT_X (the wheel while dragging)
CONST SBC_SS_TURN     = 104 ' 3D cube / text: ROT_Y (left / right while dragging)
CONST SBC_L_LIGHT     = 105 ' a label
CONST SBC_SS_LAZ      = 106 ' SS_LIGHT.AZIMUTH -180-180 (A / D while dragging)
CONST SBC_SS_LEL      = 107 ' SS_LIGHT.ELEVATION -89-89 (W / S)
CONST SBC_SS_LINT     = 108 ' SS_LIGHT.INTENSITY as % 20-180 (L + digit)
CONST SBC_SS_BEVEL    = 109 ' bevel rect: BEVEL_SIZE 1-30
CONST SBC_SS_BORDER   = 110 ' bevel rect: BORDER_SIZE 0-10
CONST SBC_SS_INNER    = 111 ' chips: bevel STYLE 0 / 1 (I / O)
CONST SBC_SS_OUTER    = 112
CONST SBC_SS_STEM     = 113 ' arrow: STEM_FATNESS_PCT 10-90
CONST SBC_SS_HEAD     = 114 ' arrow: HEAD_LEN_PCT 10-80
CONST SBC_SS_FLARE    = 115 ' arrow: HEAD_FLARE_PCT 50-200
CONST SBC_SS_THICK    = 116 ' arrow: THICKNESS 4-200 px (new: no key set it before)
' the fill, the spray, the picker (cfg: FILL_* / SPRAY_* / PICKER_* - saved)
CONST SBC_L_SAMPLE    = 117 ' a label
CONST SBC_FL_S0       = 118 ' chips: CFG.FILL_SAMPLE 0-3 = LAYER / MERGED / ALL / REPLACE (118-121)
CONST SBC_FL_TOL      = 122 ' slider: CFG.FILL_TOLERANCE 0-255
CONST SBC_FL_CONTIG   = 123 ' toggle: CFG.FILL_CONTIGUOUS
CONST SBC_FL_GRID     = 124 ' toggle: GRID.CELL_FILL (action 908)
CONST SBC_FL_ADJ      = 125 ' toggle: FILL_ADJ.ENABLED (action 909)
CONST SBC_L_BLEND     = 126 ' a label
CONST SBC_FL_B0       = 127 ' chips: CFG.GRADIENT_BLEND_SPACE 0-3 = SRGB / OKLAB / LINEAR / PIGMENT (127-130)
CONST SBC_SP_SPREAD   = 131 ' slider: CFG.SPRAY_SPREAD 25-400 %
CONST SBC_SP_DENSITY  = 132 ' slider: CFG.SPRAY_DENSITY 10-400 %
CONST SBC_SP_FLOW     = 133 ' slider: CFG.SPRAY_FLOW 10-400 % (the airbrush: AA on)
CONST SBC_PK_S0       = 134 ' chips: CFG.PICKER_SAMPLE 0-2 = MERGED / LAYER / REFERENCE (134-136)
CONST SBC_L_AREA      = 137 ' a label
CONST SBC_PK_SZ0      = 138 ' chips: CFG.PICKER_SAMPLE_SIZE 1 / 3 / 5 (138-140)
CONST SBC_PK_LOUPE    = 141 ' slider: CFG.PICKER_LOUPE_ZOOM_LEVEL 1-8 (0 = the theme's)
' brush (mix), eraser, MyPaint, move / transform, crop, zoom / pan (PLANS/TOOL-OPTIONS-BAR.md phase 3)
CONST SBC_BR_MIX      = 142 ' toggle: CFG.BRUSH_MIX (Brush > Mix Colors, action 2026)
CONST SBC_BR_SMUDGE   = 143 ' slider: CFG.BRUSH_MIX_SMUDGE 0-100
CONST SBC_BR_LENGTH   = 144 ' slider: CFG.BRUSH_MIX_LENGTH 0-100
CONST SBC_BR_MIXRAD   = 145 ' slider: CFG.BRUSH_MIX_RADIUS 25-400
CONST SBC_BR_TILE     = 146 ' toggle: View > Pattern Tile Mode (action 440)
CONST SBC_ER_SMART    = 147 ' toggle: ERASER_BAR_SMART - every layer (Shift flips it for one stroke)
CONST SBC_MP_FROMBR   = 148 ' toggle: CFG.MYPAINT_SIZE_FROM_BRUSH (action 2690)
CONST SBC_MP_SIZE     = 149 ' slider: MPS_SIZE (the brush's own radius offset, -40..40)
CONST SBC_MP_OPAQUE   = 150 ' slider: MPS_OPAQUE
CONST SBC_MP_PRESS    = 151 ' slider: MPS_PRESSURE (the mouse's pressure %)
CONST SBC_MP_TWIST    = 152 ' slider: MPS_TWIST (degrees)
CONST SBC_MP_BRUSHES  = 153 ' toggle: View > MyPaint Brushes (MYPAINT_ACT_PANEL)
CONST SBC_MP_SETTINGS = 154 ' toggle: View > MyPaint Brush Settings (MPS_ACT_PANEL)
CONST SBC_MV_FLIPH    = 155 ' buttons: actions 315 / 316 / 320 / 319 / 317 / 318
CONST SBC_MV_FLIPV    = 156
CONST SBC_MV_ROTCCW   = 157
CONST SBC_MV_ROTCW    = 158
CONST SBC_MV_HALF     = 159
CONST SBC_MV_DOUBLE   = 160
CONST SBC_TR_APPLY    = 161 ' buttons: TRANSFORM_commit / TRANSFORM_cancel (Enter / Esc)
CONST SBC_TR_CANCEL   = 162
CONST SBC_CR_W        = 163 ' sliders: the crop box's W / H (MARQUEE.BOX)
CONST SBC_CR_H        = 164
CONST SBC_CR_APPLY    = 165 ' buttons: CROP_apply (Enter) / CROP_cancel (Esc) / CROP_trim_to_content / the whole image
CONST SBC_CR_CANCEL   = 166
CONST SBC_CR_TRIM     = 167
CONST SBC_CR_WHOLE    = 168
CONST SBC_VW_OUT      = 169 ' buttons: View > Zoom Out / Zoom In / Zoom 100% (407 / 406 / 405), fit, Reset Canvas (413)
CONST SBC_VW_IN       = 170
CONST SBC_VW_100      = 171
CONST SBC_VW_FIT      = 172
CONST SBC_VW_CENTER   = 173
CONST SBC_LAST        = 173
CONST SELBAR_MAX_CTL  = 80 ' entries (controls + group breaks) one tool's bar can hold

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
    scroll  AS INTEGER ' lines scrolled off the top, px (its units): a bar shorter than its lines - the wheel off a slider scrolls it, no scrollbar drawn
    contentH AS INTEGER ' its lines' height at the last render
END TYPE
DIM SHARED SELBAR AS SELBAR_OBJ

' the controls as last laid out by a render (its units): SELBAR_layout
DIM SHARED SB_N AS INTEGER
DIM SHARED SB_ID(1 TO SELBAR_MAX_CTL) AS INTEGER
DIM SHARED SB_X(1 TO SELBAR_MAX_CTL) AS INTEGER, SB_Y(1 TO SELBAR_MAX_CTL) AS INTEGER, SB_W(1 TO SELBAR_MAX_CTL) AS INTEGER
DIM SHARED SB_TX(1 TO SELBAR_MAX_CTL) AS INTEGER ' a slider's track x
