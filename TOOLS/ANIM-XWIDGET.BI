$INCLUDEONCE
' =============================================================================
' ANIM-XWIDGET.BI — the transform widget on an armed layer (Rick 2026-11-16:
' "a unified transform tool for x, y, w, h, w+h (scale), rotation, (pivot x/y)
' ... like in a 3d art program").
'
' Drawn over the current frame's lightbox pane while the current layer is armed
' for recording (TOOLS/ANIM-XLANE): the frame's drawing as its lanes place it -
' a box with handles. Corners scale W + H (Shift: uniform), edge middles W or H
' alone, the knob above the top edge rotates (Shift: 15 degree steps), the
' crosshair is the pivot (moved without moving the drawing). A drag keys the
' lanes at the current frame - one undo step - with an old -> new tip.
' Moving: the Move tool dragged in the pane (ANIM_XL_move_*).
' =============================================================================

CONST XW_H_TL = 1, XW_H_TR = 2, XW_H_BR = 3, XW_H_BL = 4 ' corners
CONST XW_H_T = 5, XW_H_R = 6, XW_H_B = 7, XW_H_L = 8     ' edge middles
CONST XW_H_ROT = 9, XW_H_PIV = 10
CONST XW_GRAB = 5 ' px around a handle that grab it
CONST XW_H_OPS = 11, XW_H_TNS = 12 ' the bar's OPACITY / TINT sliders (drags)
' the widget bar under the box (Rick: "an opacity slider we can type into, and a tint color chip"):
CONST XW_R_OPS = 1, XW_R_OPV = 2, XW_R_CHIP = 3, XW_R_TNS = 4, XW_R_TNV = 5, XW_R_BAR = 6
CONST XW_FADE_STEP = 32 ' Ctrl+Alt+Shift+wheel over the widget: alpha per tick

TYPE ANIM_XW_OBJ
    shown   AS INTEGER ' drawn by the last lightbox render
    slot    AS INTEGER
    px      AS SINGLE  ' the pane picture's top left (viewport) and px per cell px
    py      AS SINGLE
    sc      AS SINGLE
    ox      AS SINGLE  ' the drawing's origin in the cell (a clip's place; 0 for a layer)
    oy      AS SINGLE
    bx0     AS SINGLE  ' the box, source pixel edges
    by0     AS SINGLE
    bx1     AS SINGLE
    by1     AS SINGLE
    drag    AS INTEGER ' the handle being dragged (XW_H_*), 0 none
    hover   AS INTEGER ' the handle under the pointer
    mx0     AS INTEGER ' the press
    my0     AS INTEGER
    ang0    AS SINGLE
    tip     AS STRING  ' old -> new while dragging; the value on hover
    bbKey   AS STRING  ' the cached box's key (slot / frame / history)
    alpha   AS INTEGER ' 0..255 (ANIM_XW_fade)
    linkSlot AS INTEGER ' the TINT chip clicked: this layer's tint colour follows the FG colour (the mixer)
    linkFG  AS _UNSIGNED LONG ' the FG colour last seen
    linkBefore AS STRING ' the lanes before the first follow (one undo step per mouse release)
    paneX   AS INTEGER ' the current pane (the bar stays in it)
    paneY   AS INTEGER
    paneW   AS INTEGER
    paneH   AS INTEGER
END TYPE
DIM SHARED ANIM_XW AS ANIM_XW_OBJ
DIM SHARED ANIM_XW_HX(1 TO 10) AS SINGLE ' each handle's viewport point
DIM SHARED ANIM_XW_HY(1 TO 10) AS SINGLE
DIM SHARED ANIM_XW_B(1 TO 9) AS SINGLE   ' the lanes X .. PIVOT Y at the press
DIM SHARED ANIM_XW_RX(1 TO 6) AS INTEGER ' the bar's parts (XW_R_*): viewport rects
DIM SHARED ANIM_XW_RY(1 TO 6) AS INTEGER
DIM SHARED ANIM_XW_RW(1 TO 6) AS INTEGER
DIM SHARED ANIM_XW_RH(1 TO 6) AS INTEGER
ANIM_XW.alpha = -1 ' the default (CFG.ANIM_WIDGET_OPACITY), resolved at the first render
