''
' DRAW - TOOLS/ANIM-XS.BI
' =============================================================================
' X-sheet (Animation 4.1, PLANS/ANIMATION.md Q-05 "X-sheet one click away"):
' the lightbox's top band shows a frames x layers grid in place of the strip,
' the transport bar and the panes stay under it.
'
'   - one column per tick at the FPS, so a frame spans its hold (hold 3 =
'     three columns): the time line is to scale, as on a paper X-sheet
'   - the header row: frame numbers at each frame's start; the current
'     frame's span is tinted down every row, selected frames lighter
'   - one row per layer, top layer first, as the layers panel shows them
'     (collapsed groups' layers left out, groups as label rows): the name
'     (hidden layers dim, [R] reference, [=] same on every frame), then per
'     frame the layer's drawing in that cell as a thumbnail, with a hold
'     line along the rest of the span; an empty cell is left blank
'   - the holds row at the bottom: each frame's hold
'
' Toggle: ANIM > X-Sheet, Num 8, the transport bar's X-SHEET chip (action
' 2540, DRAW.cfg XSHEET). From sheet view it opens the lightbox with it.
' A click on a cell makes that frame current and that layer the current
' layer (frames select as in the strip: Ctrl / Shift); on a name, the layer;
' on the header or holds row, the frame. The wheel scrolls the frames,
' Shift+wheel (or the wheel over the names) the layers when they overflow.
' Editing on the grid (dragging drawings, stretching holds) is 4.2.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_ACT_XSHEET = 2540 ' ANIM > X-Sheet (Num 8)

TYPE ANIM_XS_OBJ
    shown    AS INTEGER ' drawn on the last full render
    x1       AS INTEGER ' the band (viewport px)
    y1       AS INTEGER
    x2       AS INTEGER
    y2       AS INTEGER
    nameW    AS INTEGER ' the layer name column
    rowH     AS INTEGER
    tickW    AS INTEGER ' one tick (a frame spans hold x tickW)
    gx       AS INTEGER ' the grid's left edge (after the names)
    firstF   AS INTEGER ' first frame shown
    lastF    AS INTEGER ' last frame shown (it may be cut at the right edge)
    nRows    AS INTEGER ' layer rows in all
    firstRow AS INTEGER ' first layer row shown (1-based)
    rowsShown AS INTEGER
    lastCur  AS INTEGER ' current frame / layer at the last layout: a change scrolls it into view
    lastLayer AS INTEGER
    sig      AS STRING  ' the cell fill cache was built for this (history / layout / layers)
END TYPE
DIM SHARED ANIM_XS AS ANIM_XS_OBJ
DIM SHARED ANIM_XS_ROW(1 TO MAX_LAYERS) AS INTEGER   ' layer slot of row r (display order)
DIM SHARED ANIM_XS_DEPTH(1 TO MAX_LAYERS) AS INTEGER ' its group depth (indent)
DIM SHARED ANIM_XS_FILL(1 TO MAX_LAYERS) AS STRING   ' per layer slot: per frame "1" drawn, "0" empty, " " not known yet
