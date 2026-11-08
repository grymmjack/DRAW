''
' DRAW - TOOLS/ANIM-LB.BI
' =============================================================================
' Lightbox view (Animation 2.1, PLANS/ANIMATION.md Q-05 - Q-10, Rick's sketch
' PLANS/DRAW ANIMATION FEATURE.PNG.png): a view toggle over the same pixels
' as sheet view. It fills the canvas work area with
'   - the strip ("sequence"): a row of the sheet's frames, the current one
'     outlined, scrolled to keep it in view (Q-10)
'   - the transport bar: |< < PLAY > >|, loop mode, time, FPS, seek bar,
'     current / total, COPY PASTE CUT, +
'   - the editor: 3 / 5 / 7 panes (Q-08), the current frame in the middle,
'     the frames before and after it round it
' Every picture is cut from the composited sheet (the same composite the
' Preview window reads), so the lightbox shows exactly what sheet view does.
'
' Toggle: ANIM > Lightbox, Num 0 (action 2519); panes: ANIM > Lightbox Panes,
' Num * (2520). Both kept in DRAW.cfg (LIGHTBOX, LIGHTBOX_PANES). Shown only
' while the document has frames. Drawing in a pane is 2.2, strip clicks /
' selection 2.3, the rest of the transport bar 2.4; until then a press in the
' lightbox does not reach the tools.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_ACT_LIGHTBOX = 2519 ' ANIM > Lightbox (Num 0)
CONST ANIM_ACT_LB_PANES = 2520 ' ANIM > Lightbox Panes 3 / 5 / 7 (Num *)

' Transport bar controls, left to right (ANIM_LB_CX / ANIM_LB_CW: x and width, 0 = hidden)
CONST LB_CTL_NONE  = 0
CONST LB_CTL_FIRST = 1
CONST LB_CTL_PREV  = 2
CONST LB_CTL_PLAY  = 3
CONST LB_CTL_NEXT  = 4
CONST LB_CTL_LAST  = 5
CONST LB_CTL_LOOP  = 6  ' click: next loop mode
CONST LB_CTL_TIME  = 7  ' time at the current frame / total time
CONST LB_CTL_FPS   = 8
CONST LB_CTL_SEEK  = 9  ' the current frame's place in the animation
CONST LB_CTL_COUNT = 10 ' current / total
CONST LB_CTL_COPY  = 11 ' copy / paste / cut frames: 2.5
CONST LB_CTL_PASTE = 12
CONST LB_CTL_CUT   = 13
CONST LB_CTL_ADD   = 14 ' + : add a frame (a copy of the last; Shift = blank)
CONST LB_CTLS      = 14

CONST LB_PANES_MAX = 7

TYPE ANIM_LB_OBJ
    shown      AS INTEGER ' drawn on the last full render
    x1         AS INTEGER ' the work area (viewport px)
    y1         AS INTEGER
    x2         AS INTEGER
    y2         AS INTEGER
    hx1        AS INTEGER ' the whole work area, beside floats too: a press there never reaches the tools
    hx2        AS INTEGER
    pad        AS INTEGER
    stripY     AS INTEGER ' strip band
    stripH     AS INTEGER
    barY       AS INTEGER ' transport bar band
    barH       AS INTEGER
    edY        AS INTEGER ' editor band
    edH        AS INTEGER
    stripFirst AS INTEGER ' first frame in the strip
    stripN     AS INTEGER ' frames shown in it
    cellW      AS INTEGER ' a strip cell
    cellH      AS INTEGER
    panes      AS INTEGER ' editor panes shown (CFG.LIGHTBOX_PANES, fewer when the area is narrow)
    paneW      AS INTEGER
    paneH      AS INTEGER ' the picture part (the label sits under it)
    labelH     AS INTEGER
END TYPE
DIM SHARED ANIM_LB AS ANIM_LB_OBJ
DIM SHARED ANIM_LB_CX(1 TO LB_CTLS) AS INTEGER
DIM SHARED ANIM_LB_CW(1 TO LB_CTLS) AS INTEGER
