''
' DRAW - TOOLS/ANIM.BI
' =============================================================================
' Animation: the canvas is the sprite sheet.
'
' A frame is a W×H cell of the canvas, numbered in reading order (left to
' right, top to bottom). Cells sit `margin` px in from the canvas edges with
' `gutter` px between them. Every layer covers the whole sheet, so a layer's
' cell is that layer's drawing on that frame. Nothing about layers, tools,
' undo or export changes: animation is metadata beside the pixels, plus views
' (frame grid, lightbox, X-sheet) and frame operations that move cells.
' Rick, 2026-11-07: "edit like a big sprite sheet, and zoom in and all tools
' work already in that context, the frames are just WxH cropped sections of
' each cell ... No compromise to the existing, and only additive tools for
' animators." Plan + decisions: PLANS/ANIMATION.md.
'
' ANIM.active is FALSE until a frame size is set: a plain picture has no frames.
' Frames 1..ANIM.count are the animation; cells past count (the rest of the
' last row) are spare. Pure math lives in ANIM.BM (unit test:
' QA/unit/anim-unit.bas); frame operations that move pixels live elsewhere.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_MAX_FRAMES  = 4096
CONST ANIM_FPS_DEFAULT = 15
CONST ANIM_FPS_MAX     = 120
CONST ANIM_HOLD_MAX    = 99
CONST ANIM_CHUNK_VERSION = 1 ' ANIM_serialize$ layout (PNG chunk "drAn")

' loop modes
CONST ANIM_LOOP_FWD  = 0 ' 1 2 3 1 2 3
CONST ANIM_LOOP_REV  = 1 ' 3 2 1 3 2 1
CONST ANIM_LOOP_PING = 2 ' 1 2 3 2 1 2 3
CONST ANIM_LOOP_ONCE = 3 ' 1 2 3, stop

TYPE ANIM_OBJ
    active   AS INTEGER ' the document has a frame layout
    frameW   AS INTEGER
    frameH   AS INTEGER
    gutter   AS INTEGER ' px between cells
    margin   AS INTEGER ' px from the canvas edges to the first cells
    count    AS INTEGER ' frames in the animation (<= cells)
    wanted   AS INTEGER ' the count asked for (load, frame ops): a layout with fewer cells shows fewer, the rest come back when it fits
    current  AS INTEGER ' 1-based
    fps      AS INTEGER
    loopMode AS INTEGER
END TYPE
DIM SHARED ANIM AS ANIM_OBJ
DIM SHARED ANIM_HOLDS(1 TO ANIM_MAX_FRAMES) AS INTEGER ' ticks frame n stays up (0 = 1)

ANIM_reset
