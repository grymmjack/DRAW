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
' on the header or holds row, the frame. Each layer's name has an eye (show /
' hide; a group's hides its layers), a lock (the alpha lock) and its opacity
' (wheel +/- 5 %, Shift 1 %; drag up / down; click to type), as the layers
' panel; a right-click on a layer's row opens the layers panel's menu for it
' (F5). The wheel scrolls the frames,
' Shift+wheel (or the wheel over the names) the layers when they overflow.
' Editing on the grid (4.2), each one undo step:
'   - drag along the holds row: the frame's hold, a tick at a time
'   - drag a cell to another frame / layer: the drawing moves there (the
'     cell it lands on is replaced, the one it left is cleared); Ctrl when
'     dropping copies it instead
'   - drag a frame number: the selected frames move there (as the strip)
' Past the grid's left / right edge a drag scrolls it.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_ACT_XSHEET = 2540 ' ANIM > X-Sheet (Num 8)
CONST XS_DRAG_NONE   = 0
CONST XS_DRAG_HOLD   = 1 ' along the holds row
CONST XS_DRAG_CELL   = 2 ' a drawing to another cell
CONST XS_DRAG_FRAMES = 3 ' frame numbers: reorder
CONST XS_DRAG_SOUND  = 4 ' a sound clip: along its track / to another track (F6)
CONST XS_EYE_X  = 2  ' name column: the eye from x1 + 2, the lock from x1 + 13,
CONST XS_LOCK_X = 13 ' the name from x1 + XS_ICONS_W (F5)
CONST XS_ICONS_W = 25
CONST XS_TAG_BTN_W = 11 ' the TAGS row's < / > buttons
DIM SHARED ANIM_LOOP_TICK AS LONG ' main-loop passes (DRAW.BAS): a double-click is two presses within 0.45 s, or seen two passes apart when frames are slow
DIM SHARED ANIM_XS_BEFORE AS STRING ' ANIM_OPS_snapshot$ at a hold drag's press

TYPE ANIM_XS_OBJ
    shown    AS INTEGER ' drawn on the last full render
    x1       AS INTEGER ' the band (viewport px)
    y1       AS INTEGER
    x2       AS INTEGER
    y2       AS INTEGER
    nameW    AS INTEGER ' the layer name column
    rowH     AS INTEGER
    tickW    AS INTEGER ' one tick, rounded (the dump; a frame spans hold x tick)
    tick     AS SINGLE  ' one tick in px - fractional when zoomed out (XSHEET_ZOOM)
    tickAuto AS SINGLE  ' the tick at the default size: a thumbnail wide
    tickMin  AS SINGLE  ' the smallest zoom: every frame fits across (tickAuto when they already do)
    layH     AS INTEGER ' a layer row's height (XSHEET_ROWS: text / thumbnail sizes) - the SOUND rows' too; the other rows are rowH
    zx1      AS INTEGER ' the zoom slider in the header's name cell (0 = not shown)
    zx2      AS INTEGER
    zDrag    AS INTEGER ' dragging its handle
    zLastT   AS DOUBLE  ' its last press (a double-click: the default size)
    gx       AS INTEGER ' the grid's left edge (after the names)
    firstF   AS INTEGER ' first frame shown
    lastF    AS INTEGER ' last frame shown (it may be cut at the right edge)
    nRows    AS INTEGER ' layer rows in all
    firstRow AS INTEGER ' first layer row shown (1-based)
    rowsShown AS INTEGER
    lastCur  AS INTEGER ' current frame / layer at the last layout: a change scrolls it into view
    lastLayer AS INTEGER
    sig      AS STRING  ' the cell fill cache was built for this (history / layout / layers)
    ' a drag on the grid (4.2): XS_DRAG_* until every button is up
    dMode    AS INTEGER
    dOn      AS INTEGER ' moved far enough to be a drag (else a click)
    dPressX  AS INTEGER
    dPressY  AS INTEGER
    dFrame   AS INTEGER ' the frame pressed
    dSlot    AS INTEGER ' the layer pressed (a cell drag)
    dHold0   AS INTEGER ' the hold at the press (stretching)
    dTo      AS INTEGER ' where it would land: frame (a cell) / drop slot (frame numbers)
    dToSlot  AS INTEGER ' the layer it would land on (a cell)
    dCollapse AS INTEGER ' a plain press on a frame in a multi-selection: just it on release
    dScrollT AS DOUBLE  ' past the edges: when it next scrolls
    ' layer controls in the name column (F5, field kit T-22): eye, lock, opacity
    oSlot    AS INTEGER ' the layer whose opacity box is pressed (0 none)
    oY0      AS INTEGER ' the press's viewport y
    oV0      AS INTEGER ' its opacity at the press (0-100 %)
    oMoved   AS INTEGER ' dragged (else a click: type it)
    rSlot    AS INTEGER ' a right press on this layer's row: its menu on the release
    rSound   AS INTEGER ' a right press on this SOUND track's row: the SOUND menu on the release (F6)
    rTag     AS INTEGER ' a right press on the TAGS / NOTES row: their menu on the release (field kit R-13)
END TYPE
DIM SHARED ANIM_XS AS ANIM_XS_OBJ
DIM SHARED ANIM_XS_ROW(1 TO MAX_LAYERS) AS INTEGER   ' layer slot of row r (display order)
DIM SHARED ANIM_XS_DEPTH(1 TO MAX_LAYERS) AS INTEGER ' its group depth (indent)
DIM SHARED ANIM_XS_FILL(1 TO MAX_LAYERS) AS STRING   ' per layer slot: per frame "1" drawn, "0" empty, " " not known yet
DIM SHARED ANIM_XS_BOXES(1 TO MAX_LAYERS) AS STRING    ' per layer slot: per frame 16 bytes, MKL$ x y w h of the box round its drawing (buffer coords), set with a "1" in ANIM_XS_FILL
