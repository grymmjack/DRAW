''
' DRAW - GUI/ANIM-PANEL.BI
' =============================================================================
' Animation panel (Animation 1.6, PLANS/ANIMATION.md): the sheet's frame
' layout and timing in one floating, dockable window - frame W x H, gutter,
' margin, FPS, the current frame's hold, loop mode, current / total and the
' first / previous / next / last buttons. Toggle: View > Animation Panel or
' ANIM > Animation Panel (action 2505). Same window model as the Pen Pressure
' panel (GUI/PEN-PANEL: FPANEL look, title-bar drag, close box, dock slot,
' region, auto-hide while drawing over it, F11).
'
' On a picture without frames the size rows show the whole canvas (one frame);
' changing one gives the picture a frame layout (TOOLS/ANIM ANIM_set_layout%).
' Steppers: click - / +, Shift = 10 at a time, hold to repeat. A row's number:
' wheel +/- 1 (Shift 10), drag up / down, click to type, middle click = its
' default (ANIMP_value_at% / ANIMP_box_*, ANIMP_wheel%). Every change
' marks the document unsaved (the layout is saved in the drAn chunk); it is
' not an undo step.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST ANIMP_ACT_TOGGLE = 2505 ' View / ANIM > Animation Panel

' Stepper rows (ANIMP_ROW_*): - and + of row r are controls 2r-1 and 2r
CONST ANIMP_ROW_W      = 1
CONST ANIMP_ROW_H      = 2
CONST ANIMP_ROW_GUTTER = 3
CONST ANIMP_ROW_MARGIN = 4
CONST ANIMP_ROW_FPS    = 5
CONST ANIMP_ROW_HOLD   = 6
CONST ANIMP_ROWS       = 6

' Controls (ANIMP_hit% ids)
CONST ANIMP_CTL_NONE   = 0
' 1..12: steppers (above)
CONST ANIMP_CTL_FIRST  = 13
CONST ANIMP_CTL_PREV   = 14
CONST ANIMP_CTL_NEXT   = 15
CONST ANIMP_CTL_LAST   = 16
CONST ANIMP_CTL_LOOP0  = 17 ' + ANIM_LOOP_* (FWD / REV / PING / ONCE)
CONST ANIMP_CTL_ADD    = 21 ' frame operations: ADD (Shift = blank), DUP, INS (blank after), DEL
CONST ANIMP_CTL_DUP    = 22
CONST ANIMP_CTL_INS    = 23
CONST ANIMP_CTL_DEL    = 24
CONST ANIMP_CTL_RESLICE = 25 ' changing the layout of a drawn sheet: RE-SLICE / RESIZE (ANIM_SIZE_MODE)
CONST ANIMP_CTL_RESIZE  = 26
CONST ANIMP_CTL_PLAY   = 27 ' the middle of |< < PLAY > >|
' onion skin (2.6; DRAW.cfg, not undo steps): BEFORE / AFTER / OPACITY steppers
' (28 + 2 * (row - 1) = -, + 1 = +), then the ONION and TINT chips
CONST ANIMP_CTL_ON0    = 28
CONST ANIMP_ON_ROWS    = 3
CONST ANIMP_CTL_ONION  = 34
CONST ANIMP_CTL_TINT   = 35
' export (F4, field kit T-17): the scale chips 1X / 2X / 4X (CFG.ANIM_EXPORT_SCALE)
' and the GIF / APNG / BAS buttons (ANIM > Export ...)
CONST ANIMP_CTL_SCALE0 = 36 ' + 0 1X, + 1 2X, + 2 4X
CONST ANIMP_CTL_EXP0   = 39 ' + 0 GIF, + 1 APNG, + 2 BAS
' Move Brush (TOOLS/ANIM-MVBRUSH): while it is on, the rows under the status
' show the move's settings instead (ANIMP_mvY): PATH chips / FRAMES / MOVE /
' TURN / SIZE / OPACITY / TINT / CEL EVERY number boxes / EASE chips / PLAY
' RESET STAMP CANCEL. The boxes are ANIMP_MV_BOX0 + MVB_BOX_* (ANIMP_box_*).
CONST ANIMP_CTL_MVPATH0 = 42 ' + 0 LINE, + 1 DRAWN, + 2 LIVE
CONST ANIMP_CTL_MVEASE0 = 45 ' + 0 NONE, + 1 IN, + 2 OUT, + 3 BOTH
CONST ANIMP_CTL_MVBTN0  = 49 ' + 0 PLAY, + 1 RESET, + 2 STAMP, + 3 CANCEL
' Clip layers (TOOLS/CLIP): while the current layer is a clip layer (and Move
' Brush is off) the rows under the nav row show the clip's settings: mode
' chips / FRAMES IN OUT / CEL START EVERY / POSITION X Y boxes / FLIP X FLIP Y
' BAKE. The boxes are ANIMP_CL_BOX0 + 1..6 (ANIMP_box_*).
CONST ANIMP_CTL_CLMODE0 = 52 ' + CLIP_MODE_* (LOOP PING ONCE HOLD REV)
CONST ANIMP_CTL_CLBTN0  = 57 ' + 0 FLIP X, + 1 FLIP Y, + 2 BAKE
CONST ANIMP_CTL_CLSRC0  = 60 ' the SOURCE row: + 0 <, + 1 >, + 2 RENAME, + 3 LAYERS
CONST ANIMP_CTL_CLSND0  = 64 ' the SOUND row: + 0 CEL, + 1 START, + 2 LOOP (add a sound)
CONST ANIMP_CTL_CLCUE0  = 67 ' the sound list row: + 0 <, + 1 >, + 2 X (remove it)
CONST ANIMP_CTL_COUNT  = 70
CONST ANIMP_MV_ROWS    = 10
CONST ANIMP_MV_BOX0    = 20 ' number box vr of MVB box j = ANIMP_MV_BOX0 + j
CONST ANIMP_CL_BOX0    = 40 ' number box vr of clip box j (1 IN, 2 OUT, 3 START, 4 EVERY, 5 X, 6 Y) = ANIMP_CL_BOX0 + j
CONST ANIMP_CL_BOXES   = 6

TYPE ANIM_PANEL_OBJ
    visible           AS INTEGER
    positioned        AS INTEGER
    initialized       AS INTEGER
    autoHidden        AS INTEGER ' hidden while the user draws over it
    hiddenByToggleAll AS INTEGER ' F11 hid it

    docked      AS INTEGER ' in a dock slot (GUI/DOCK): the slot places it
    dispX       AS INTEGER ' viewport coords
    dispY       AS INTEGER
    dispW       AS INTEGER
    dispH       AS INTEGER
    renderScale AS SINGLE  ' native -> viewport

    panelImg   AS LONG
    panelW     AS INTEGER
    panelH     AS INTEGER
    fitW AS INTEGER ' docked: native size its slot gives it (0 = natural) - FPANEL_fit
    fitH AS INTEGER
    natW AS INTEGER ' its natural (floating) native size, from its layout
    natH AS INTEGER
    hoverCtl   AS INTEGER
    closeHover AS INTEGER

    ' layout (native px, ANIMP_layout)
    yStatus AS INTEGER
    yScale  AS INTEGER ' export: SCALE 1X 2X 4X (F4)
    yExport AS INTEGER ' export: EXPORT GIF APNG BAS
    yNav    AS INTEGER
    yOps    AS INTEGER ' ADD DUP INS DEL
    yMode   AS INTEGER ' RE-SLICE RESIZE
    yLoop   AS INTEGER
    yOnion  AS INTEGER ' ONION TINT (the BEFORE / AFTER / OPACITY rows: ANIMP_onY)
    yInfo   AS INTEGER
    chipW   AS INTEGER ' a stepper's - / + width
    valW    AS INTEGER ' the value between them

    dragging    AS INTEGER
    dragStartMX AS INTEGER
    dragStartMY AS INTEGER
    dragStartDX AS INTEGER
    dragStartDY AS INTEGER
    pressCtl    AS INTEGER ' stepper held (repeats)
    pressT      AS DOUBLE  ' when it next repeats
    pressKey    AS LONG    ' this press (a held stepper is one undo step: ANIM_OPS_record)
    pendRow     AS INTEGER ' a layout change waiting for RE-SLICE / RESIZE (R-07: asked once per document)
    pendD       AS INTEGER
    onionSave   AS INTEGER ' an onion skin stepper changed DRAW.cfg: CONFIG_save on the release
    ' number boxes (F1): a press on one drags it up / down, a click types it
    vRow        AS INTEGER ' the box pressed (ANIMP_value_at%; 0 none)
    vY0         AS INTEGER ' the press's viewport y
    vApplied    AS INTEGER ' drag steps applied so far
    vMoved      AS INTEGER ' it moved: a drag, not a click
    wheelRow    AS INTEGER ' wheel ticks on one row close together are one undo step
    wheelT      AS DOUBLE
END TYPE

DIM SHARED ANIMP AS ANIM_PANEL_OBJ
DIM SHARED ANIMP_rowY(1 TO ANIMP_ROWS) AS INTEGER ' native top of each stepper row
DIM SHARED ANIMP_onY(1 TO ANIMP_ON_ROWS) AS INTEGER ' native top of the onion skin stepper rows
DIM SHARED ANIMP_mvY(1 TO ANIMP_MV_ROWS) AS INTEGER ' native top of the Move Brush rows (over the others)
CONST ANIMP_DRAG_PX = 3 ' viewport px of drag per step on a number box
