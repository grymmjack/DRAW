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
' Steppers: click - / +, Shift = 10 at a time, hold to repeat. Every change
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
CONST ANIMP_CTL_COUNT  = 26

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
    hoverCtl   AS INTEGER
    closeHover AS INTEGER

    ' layout (native px, ANIMP_layout)
    yStatus AS INTEGER
    yNav    AS INTEGER
    yOps    AS INTEGER ' ADD DUP INS DEL
    yMode   AS INTEGER ' RE-SLICE RESIZE
    yLoop   AS INTEGER
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
END TYPE

DIM SHARED ANIMP AS ANIM_PANEL_OBJ
DIM SHARED ANIMP_rowY(1 TO ANIMP_ROWS) AS INTEGER ' native top of each stepper row
