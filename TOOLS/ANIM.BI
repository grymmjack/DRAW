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
CONST ANIM_SHEET_MAX   = 16384 ' frame ops / resized frames grow the sheet up to this wide / tall (canvas sizes are INTEGERs)

' Changing the frame layout of a drawn sheet (R-07): asked once per document
CONST ANIM_SIZE_ASK     = 0 ' not asked yet
CONST ANIM_SIZE_RESLICE = 1 ' the grid moves, the pixels stay
CONST ANIM_SIZE_RESIZE  = 2 ' the frames resize, each drawing stays in its frame (the sheet refits)
CONST ANIM_CHUNK_VERSION = 1 ' ANIM_serialize$ layout (PNG chunk "drAn")

' loop modes
CONST ANIM_LOOP_FWD  = 0 ' 1 2 3 1 2 3
CONST ANIM_LOOP_REV  = 1 ' 3 2 1 3 2 1
CONST ANIM_LOOP_PING = 2 ' 1 2 3 2 1 2 3
CONST ANIM_LOOP_ONCE = 3 ' 1 2 3, stop

' Frame operations (ANIM_plan%; TOOLS/ANIM-OPS moves the pixels)
CONST ANIM_OP_APPEND        = 1 ' a copy of the last frame at the end
CONST ANIM_OP_APPEND_BLANK  = 2 ' a blank frame at the end
CONST ANIM_OP_INSERT_BEFORE = 3 ' a blank frame before the current one
CONST ANIM_OP_INSERT_AFTER  = 4 ' a blank frame after it
CONST ANIM_OP_DUPLICATE     = 5 ' a copy of the current frame after it
CONST ANIM_OP_DELETE        = 6
CONST ANIM_OP_EARLIER       = 7 ' swap with the frame before
CONST ANIM_OP_LATER         = 8 ' swap with the frame after
CONST ANIM_OP_REVERSE       = 9
CONST ANIM_OP_LAST          = 9
CONST ANIM_OP_MOVE_SEL      = 10 ' the selected frames, in order, to before frame ANIM_MOVE_TO (the strip's drag; no action id)
CONST ANIM_OP_SET_COUNT     = 11 ' ANIM_COUNT_TO frames: blank ones added at the end, or the last ones dropped (the lightbox's total; no action id)

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

' Playback (1.9): ANIM.current steps through fromF..toF at ANIM.fps, each frame
' up for its hold, by ANIM.loopMode
TYPE ANIM_PLAY_OBJ
    playing AS INTEGER
    dir     AS INTEGER ' +1 / -1 (ping-pong turns it round)
    fromF   AS INTEGER ' the range played (1..count; the strip selection in 2.3)
    toF     AS INTEGER
    nextT   AS DOUBLE  ' TIMER when the next frame is due
END TYPE
DIM SHARED ANIM_PLAY AS ANIM_PLAY_OBJ
DIM SHARED ANIM_HOLDS(1 TO ANIM_MAX_FRAMES) AS INTEGER ' ticks frame n stays up (0 = 1)
DIM SHARED ANIM_SRC(1 TO ANIM_MAX_FRAMES) AS INTEGER   ' ANIM_plan%: new frame n is old frame ANIM_SRC(n) (0 = blank)
DIM SHARED ANIM_SIZE_MODE AS INTEGER                    ' ANIM_SIZE_*: the answer for this document
' The strip selection (2.3, R-12 = the layers panel's rules): click = current,
' Ctrl+click toggles, Shift+click a range from the anchor. Frame ops carry it
' with the frames (ANIM_apply_plan); not saved, not an undo step.
DIM SHARED ANIM_SEL(1 TO ANIM_MAX_FRAMES) AS INTEGER    ' TRUE = selected
DIM SHARED ANIM_SEL_ANCHOR AS INTEGER                   ' Shift+click ranges from here
DIM SHARED ANIM_MOVE_TO AS INTEGER                      ' ANIM_OP_MOVE_SEL: drop before this frame (count + 1 = at the end)
DIM SHARED ANIM_COUNT_TO AS INTEGER                     ' ANIM_OP_SET_COUNT: the new total

ANIM_reset
