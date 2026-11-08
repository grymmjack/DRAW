''
' DRAW - TOOLS/ANIM-OPS.BI
' =============================================================================
' Frame operations (Animation 1.7, PLANS/ANIMATION.md R-03 / R-04): add (a
' copy of the last frame; Shift = blank), insert before / after, duplicate,
' delete, move earlier / later, reverse. The sheet is always in play order, so
' each one moves cell pixels on every pixel layer (TOOLS/ANIM ANIM_plan% says
' which old cell lands where) and adding past the last cell grows the canvas
' by a row. One undo step each: HISTORY_KIND_ANIM_FRAMES keeps the whole sheet
' before and after (canvas size, every layer's pixels, the frame data).
'
' Text and linked symbol layers keep their pixels where they are (text is
' redrawn from its words, a linked copy from its parent); groups have none.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

' Actions (ANIM menu, Animation panel, numpad +): action = ANIM_ACT_OP0 + ANIM_OP_*
CONST ANIM_ACT_OP0            = 2509
CONST ANIM_ACT_APPEND         = 2510 ' Num +
CONST ANIM_ACT_APPEND_BLANK   = 2511 ' Shift + Num +
CONST ANIM_ACT_INSERT_BEFORE  = 2512
CONST ANIM_ACT_INSERT_AFTER   = 2513
CONST ANIM_ACT_DUPLICATE      = 2514
CONST ANIM_ACT_DELETE         = 2515
CONST ANIM_ACT_MOVE_EARLIER   = 2516
CONST ANIM_ACT_MOVE_LATER     = 2517
CONST ANIM_ACT_REVERSE        = 2518

' Copy / cut / paste frames (2.5): the selected frames ride the OS clipboard
' as one picture - a column per frame, a row per pixel layer (in slot order) -
' with the text line "DRAWFRAMES1|w|h|frames|layers|id|hold,..." in a header
' strip on top (ANIM_OPS_clip_pack&; [Linux] the clipboard holds a picture OR
' text, so the line can't ride _CLIPBOARD$). The copy is also kept here
' without the strip, so a paste in the same window uses the exact pixels.
CONST ANIM_ACT_COPY_FRAMES       = 2523
CONST ANIM_ACT_CUT_FRAMES        = 2524
CONST ANIM_ACT_PASTE_FRAMES      = 2525 ' as new frames after the current one
CONST ANIM_ACT_PASTE_FRAMES_OVER = 2526 ' over the frames from the first selected one
CONST ANIM_CLIP_MAGIC$ = "DRAWFRAMES1"
DIM SHARED ANIM_CLIP_IMG AS LONG        ' the last copy's image (0 none)
DIM SHARED ANIM_CLIP_META AS STRING     ' and its text line
DIM SHARED ANIM_OPS_STEP_NAME AS STRING     ' ANIM_OPS_run: the undo step's name instead of the op's ("" = the op's)

' Apply to the selected frames (2.7): in the lightbox, the effects (IMAGE /
' EFFECTS, Remap to Palette) run as usual and then everything outside the
' selected frames (the current one when none is) is put back from a copy taken
' before - in HISTORY_store_after_image too, so the undo step holds the masked
' result (ANIM_FM_*). Flip / rotate are done per frame cell instead
' (ANIM_OPS_frames_geom%): a whole-layer flip would move the frames. Replace
' FG with BG (2529) works in sheet view too. A marquee selection keeps the
' commands' own behaviour.
CONST ANIM_ACT_SWAP_FG_BG = 2529 ' ANIM > Replace FG Color with BG in Frames
CONST ANIM_ACT_REF_LAYER  = 2530 ' ANIM > Reference Layer (the current layer; 2.8)
CONST ANIM_ACT_SAME_LAYER = 2531 ' ANIM > Same on Every Frame (the current layer)
CONST ANIM_ACT_LINK_CELLS   = 2541 ' ANIM > Link Cells (4.3: the current layer's cells in the selected frames show the first one's drawing; one frame: linked to the frame before)
CONST ANIM_ACT_UNLINK_CELLS = 2542 ' ANIM > Unlink Cells (the current layer, the selected frames)
CONST ANIM_ACT_TAG_FRAMES   = 2543 ' ANIM > Tag Frames... (4.4: name the selected frames' span; the same name moves the tag)
CONST ANIM_ACT_DELETE_TAG   = 2544 ' ANIM > Delete Tag (the selected tag, else the one at the current frame)
CONST ANIM_ACT_FRAME_NOTE   = 2545 ' ANIM > Frame Note... (4.5: the current frame's note; also a double-click on the X-sheet's NOTES row)
CONST ANIM_ACT_CLEAR_NOTE   = 2546 ' ANIM > Clear Frame Note (the selected frames, else the current one)
' A selection inside the current frame's cell moves with it to the next current
' frame, same place in the cell (2.9, Q-18; ANIM_SELBOX_watch)
DIM SHARED ANIM_SELBOX_LAST AS INTEGER ' the current frame the watcher last saw (0 = none)
DIM SHARED ANIM_FM_ON AS INTEGER
DIM SHARED ANIM_FM_IMG(1 TO MAX_LAYERS) AS LONG ' each pixel layer before the command (0 = none)

DIM SHARED ANIM_OPS_LAST_KEY AS LONG    ' the panel press whose undo step is on top (ANIM_OPS_record)
DIM SHARED ANIM_OPS_LAST_REC AS INTEGER ' and that step's record
