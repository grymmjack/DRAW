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
' while the document has frames. Every tool draws in a pane's picture (2.2):
' the mouse handler runs in a view that puts that pane's frame cell under
' the pointer, and the stroke is clipped to the cell (ANIM > Clip Strokes to
' the Frame in the Lightbox, 2521; the same for sheet view, 2522). Strip
' clicks / selection are 2.3, the rest of the transport bar 2.4; a press
' anywhere else in the lightbox does not reach the tools.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_ACT_LIGHTBOX = 2519 ' ANIM > Lightbox (Num 0)
CONST ANIM_ACT_LB_PANES = 2520 ' ANIM > Lightbox Panes 3 / 5 / 7 (Num *)
CONST ANIM_ACT_CLIP_LB  = 2521 ' ANIM > Clip Strokes to the Frame in the Lightbox (R-06; on by default)
CONST ANIM_ACT_CLIP_SHEET = 2522 ' ANIM > Clip Strokes to the Frame in Sheet View (off by default)

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

    ' Drawing in a pane (2.2): while the mouse handler runs, SCRN.zoom /
    ' offsetX / offsetY are a view that puts the pane's frame cell on the pane
    ' (ANIM_LB_view_push / _pick / _pop), so every tool maps, paints and
    ' previews in that cell. The overlays (tool previews, ants, the brush
    ' footprint) are drawn through the same view, clipped to the pane.
    pushed     AS INTEGER ' the real view is saved (in the mouse handler / an overlay)
    realZoom   AS SINGLE
    realOX     AS INTEGER
    realOY     AS INTEGER
    realTile   AS INTEGER
    vPane      AS INTEGER ' the pane the view was picked for (-1 none)
    strokePane AS INTEGER ' the pane a press started in, kept until every button is up (-1 none)
    overlay    AS INTEGER ' an overlay is being drawn through the pane view
    scratch    AS LONG    ' overlays draw here, then the pane's part is copied over
    realCanvas AS LONG

    ' Strokes clipped to a frame (R-06): the layer as it was at the press;
    ' everything outside the cell is put back after each mouse frame and
    ' before the undo step stores the result.
    clipOn     AS INTEGER
    clipLayer  AS INTEGER
    clipImg    AS LONG
    clipX      AS LONG    ' the cell, canvas px
    clipY      AS LONG
    clipW      AS LONG
    clipH      AS LONG

    ' The strip (2.3): click / Ctrl / Shift select (ANIM_SEL_click), drag
    ' reorders the selected frames (ANIM_OP_MOVE_SEL), the wheel scrolls it.
    lastCur    AS INTEGER ' current frame at the last layout: a change scrolls it into view
    sPress     AS INTEGER ' frame a strip press landed on (0 none), until the release
    sPressX    AS INTEGER
    sDrag      AS INTEGER ' the press moved far enough to be a drag
    sDrop      AS INTEGER ' drag: drop before this frame (count + 1 = the end)
    sCollapse  AS INTEGER ' a plain press on a frame already in a multi-selection: select just it on release (no drag)
    sScrollT   AS DOUBLE  ' drag past the strip's ends: when it next scrolls a frame
END TYPE
DIM SHARED ANIM_LB AS ANIM_LB_OBJ
DIM SHARED ANIM_LB_CX(1 TO LB_CTLS) AS INTEGER
DIM SHARED ANIM_LB_CW(1 TO LB_CTLS) AS INTEGER
ANIM_LB.vPane = -1: ANIM_LB.strokePane = -1
