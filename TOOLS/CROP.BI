''
' DRAW - TOOLS/CROP.BI
' =============================================================================
' Canvas resize and crop tool declarations.
'
' Crop delegates to the MARQUEE tool for all box interaction (click-drag
' creation, resize handles, move, keyboard nudge). CROP just adds:
'   - Dark overlay outside the marquee region
'   - Size label above the crop box
'   - Enter = apply crop, ESC = cancel crop
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' --- Crop state constants ---
CONST CROP_STATE_IDLE   = 0
CONST CROP_STATE_ACTIVE = 1

TYPE CROP_OBJ
    STATE          AS INTEGER  ' CROP_STATE_*
    PREV_TOOL      AS INTEGER  ' Tool active before crop was started
END TYPE

DIM SHARED CROP AS CROP_OBJ

CROP.STATE  = CROP_STATE_IDLE

DECLARE SUB CROP_reset ()
DECLARE SUB CANVAS_resize (newW AS INTEGER, newH AS INTEGER)
DECLARE SUB CANVAS_resize_dialog ()
DECLARE SUB CROP_begin ()
DECLARE SUB CROP_cancel ()
DECLARE SUB CROP_apply ()
DECLARE SUB CROP_render (dest AS LONG)
