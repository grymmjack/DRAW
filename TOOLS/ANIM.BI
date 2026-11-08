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
CONST ANIM_CHUNK_VERSION = 2 ' ANIM_serialize$ layout (PNG chunk "drAn"; 2 = + layer flags)
CONST ANIM_CHUNK_VERSION_LINKS = 3 ' written only when there are linked cells (4.3): the layer flags always, then the links
CONST ANIM_CHUNK_VERSION_TAGS = 4  ' written only when there are tags (4.4): the layer flags and the links always, then the tags

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
CONST ANIM_OP_DELETE_SEL    = 12 ' the selected frames (Cut Frames; no action id)
CONST ANIM_OP_INSERT_N      = 13 ' ANIM_COUNT_TO blank frames after the current one (Paste Frames; no action id)

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

' Layer flags (2.8), by layer historyId: saved in the drAn chunk, part of every
' frame-op undo snapshot, and each change is an undo step of its own.
'   REF  - a reference layer: shown while drawing and in the lightbox, left out
'          of every export (LAYERS_flatten&) - Q-19
'   SAME - the same on every frame (R-05 phase 1): a change in any cell is
'          copied to every cell (TOOLS/ANIM-OPS ANIM_SAME_tick%); frame ops
'          leave the layer as it is
CONST ANIM_LF_MAX  = 256
CONST ANIM_LF_REF  = 1
CONST ANIM_LF_SAME = 2
DIM SHARED ANIM_LF_N AS INTEGER                     ' entries in use (only flags <> 0 are kept)
DIM SHARED ANIM_LF_ID(1 TO ANIM_LF_MAX) AS LONG     ' layer historyId
DIM SHARED ANIM_LF_FL(1 TO ANIM_LF_MAX) AS INTEGER  ' ANIM_LF_* bits
' SAME layers: the picture every cell holds (frameW x frameH RGBA), by historyId.
' Rebuilt from the current frame's cell when missing or the frame size changed.
DIM SHARED ANIM_SB_N AS INTEGER
DIM SHARED ANIM_SB_ID(1 TO ANIM_LF_MAX) AS LONG
DIM SHARED ANIM_SB_W(1 TO ANIM_LF_MAX) AS INTEGER
DIM SHARED ANIM_SB_H(1 TO ANIM_LF_MAX) AS INTEGER
DIM SHARED ANIM_SB_PX(1 TO ANIM_LF_MAX) AS STRING
DIM SHARED ANIM_SB_KEEP AS INTEGER
DIM SHARED ANIM_ORDER(1 TO 2 * ANIM_MAX_FRAMES) AS INTEGER ' ANIM_play_order%: the frames one loop shows (exports)
DIM SHARED ANIM_SAME_CHECK AS INTEGER ' an undo step was added / undone / redone: compare the SAME layers' cells

' Linked cells (4.3, Q-03 / R-05): a layer's cells in two or more frames show
' one drawing. Entry k: layer historyId ANIM_LK_ID(k)'s cell in frame
' ANIM_LK_F(k) is in link group ANIM_LK_G(k) (numbers shared by the cells of
' one drawing on that layer). The group's lowest frame is its source; the
' others are hatched in sheet view. Any change to one cell goes to all of
' them (ANIM_LK_tick%, with the SAME layers' check). Saved in drAn v3, in
' every frame-op snapshot; frames carry their links through frame ops.
CONST ANIM_LK_MAX = 4096
DIM SHARED ANIM_LK_N AS INTEGER
DIM SHARED ANIM_LK_ID(1 TO ANIM_LK_MAX) AS LONG
DIM SHARED ANIM_LK_F(1 TO ANIM_LK_MAX) AS INTEGER
DIM SHARED ANIM_LK_G(1 TO ANIM_LK_MAX) AS INTEGER
' each group's picture (the cells it last made the same), rebuilt from the
' source cells when the links or the frame size change (ANIM_LK_SIG)
DIM SHARED ANIM_LKP_N AS INTEGER
DIM SHARED ANIM_LKP_ID(1 TO ANIM_LK_MAX) AS LONG
DIM SHARED ANIM_LKP_G(1 TO ANIM_LK_MAX) AS INTEGER
DIM SHARED ANIM_LKP_PX(1 TO ANIM_LK_MAX) AS STRING
DIM SHARED ANIM_LK_SIG AS STRING

' Tags (4.4, Q-20): named frame ranges ANIM_TG_A(k)..ANIM_TG_B(k) (they may
' overlap). The X-sheet's TAGS row shows them; a click there selects a tag's
' frames, so Play plays it, and an export with exactly a tag selected writes
' just that tag (ANIM_EXP_A..B). Saved in drAn v4, in every frame-op
' snapshot; frame ops carry them along (ANIM_TG_remap).
CONST ANIM_TG_MAX = 64
CONST ANIM_TG_NAME_MAX = 32
DIM SHARED ANIM_TG_N AS INTEGER
DIM SHARED ANIM_TG_NAME(1 TO ANIM_TG_MAX) AS STRING
DIM SHARED ANIM_TG_A(1 TO ANIM_TG_MAX) AS INTEGER
DIM SHARED ANIM_TG_B(1 TO ANIM_TG_MAX) AS INTEGER
' the frames ANIM_play_order% covers (exports, the full-screen preview);
' 0 = all of them. Set around one export / preview, then back to 0.
DIM SHARED ANIM_EXP_A AS INTEGER
DIM SHARED ANIM_EXP_B AS INTEGER

ANIM_reset
