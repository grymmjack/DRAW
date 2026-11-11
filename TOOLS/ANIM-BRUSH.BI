$INCLUDEONCE
' =============================================================================
' ANIM-BRUSH.BI — AnimBrush: a custom brush with one picture (cel) per frame.
'
' ANIM > AnimBrush > Pick Up takes the marquee's area from several frames of
' the sprite sheet: the same spot in each frame's cell, so a walk cycle
' becomes a brush that walks. The cels live here; CUSTOM_BRUSH.IMAGE is a copy
' of the current cel (AB_show), so every custom-brush routine (render, stamp,
' cursor preview) works unchanged. CUSTOM_BRUSH_reset drops the cels, so the
' plain Ctrl+B brush and a Drawer brush stay one picture; the brush stash
' (pattern / gradient modes) keeps them.
' =============================================================================

CONST AB_MAX_CELS = 256

CONST AB_ACT_PICKUP        = 2563 ' ANIM > AnimBrush > Pick Up (the current layer)
CONST AB_ACT_PICKUP_MERGED = 2564 ' ANIM > AnimBrush > Pick Up Merged (every visible layer)
CONST AB_ACT_PREV_CEL      = 2565 ' Alt+[  previous cel
CONST AB_ACT_NEXT_CEL      = 2566 ' Alt+]  next cel
CONST AB_ACT_FIRST_CEL     = 2567 ' Alt+\  back to cel 1 (follows the frame: the current frame gets cel 1)
CONST AB_ACT_STEP_FOLLOW   = 2568 ' Step: cel follows the frame (default)
CONST AB_ACT_STEP_CLICK    = 2569 ' Step: next cel each click
CONST AB_ACT_STEP_ALL      = 2570 ' Step: every frame at once
CONST AB_ACT_ORD_FWD       = 2571 ' Order: forward / reverse / ping-pong / once
CONST AB_ACT_ORD_REV       = 2572
CONST AB_ACT_ORD_PING      = 2573
CONST AB_ACT_ORD_ONCE      = 2574

' Brush routines that change the picture itself: AB_each% runs them on every cel
CONST AB_OP_ROT_CW  = 1
CONST AB_OP_ROT_CCW = 2
CONST AB_OP_2X_H    = 3
CONST AB_OP_2X_V    = 4
CONST AB_OP_OUTLINE = 5

' Step modes: which cel a stamp uses
CONST AB_STEP_FOLLOW = 0 ' frame f uses cel seq(f - anchor) - stamp the same spot on each frame and it plays
CONST AB_STEP_CLICK  = 1 ' each stroke uses the next cel (Deluxe Paint); also on a picture without frames
CONST AB_STEP_ALL    = 2 ' one stamp lands on every frame, each with its cel (one undo step)
' Orders: how the cels run (the four playback orders)
CONST AB_ORD_FWD  = 0
CONST AB_ORD_REV  = 1
CONST AB_ORD_PING = 2
CONST AB_ORD_ONCE = 3

TYPE AB_OBJ
    n      AS INTEGER ' cels (0 = no AnimBrush: the custom brush is one picture)
    cur    AS INTEGER ' the cel CUSTOM_BRUSH.IMAGE shows (1-based)
    w      AS INTEGER ' cel size (every cel is the same size)
    h      AS INTEGER
    merged AS INTEGER ' picked up from every visible layer
    srcF   AS INTEGER ' the frame the selection was in
    anchor AS INTEGER ' the frame that gets cel 1 (follows the frame / every frame); the pick up's frame, 1 in a new document
    clickPos AS INTEGER ' next cel each click: steps taken (0 = cel 1 next)
    stamped  AS INTEGER ' a stamp landed during this press (the click step moves on at the release)
    lastX    AS INTEGER ' the last stamp: top left (canvas px) and the frame it landed in (QA dump ABRP)
    lastY    AS INTEGER
    lastF    AS INTEGER
    inEach   AS INTEGER ' AB_each% is running a brush routine on each cel
END TYPE
DIM SHARED AB AS AB_OBJ
DIM SHARED AB_CEL(1 TO AB_MAX_CELS) AS LONG      ' cel images (32-bit, w x h)
DIM SHARED AB_FROM(1 TO AB_MAX_CELS) AS INTEGER  ' the frame each cel came from
DIM SHARED AB_STEP AS INTEGER  ' AB_STEP_* (a setting of the AnimBrush, kept across pick ups)
DIM SHARED AB_ORDER AS INTEGER ' AB_ORD_*

' the brush stash (CUSTOM_BRUSH_stash / _unstash) keeps the cels here
DIM SHARED AB_SV AS AB_OBJ
DIM SHARED AB_SV_CEL(1 TO AB_MAX_CELS) AS LONG
DIM SHARED AB_SV_FROM(1 TO AB_MAX_CELS) AS INTEGER

' An AnimBrush in a Drawer brush slot (DRAW_BRUSH.CELS / N / CW / CH): stored
' with Shift+click like any brush, a film-strip badge with the cel count on the
' bin, hovering plays it in the bin and in the Preview's Quick Look. Files: a
' .dset block after the slots (AB_DSET_MAGIC$, skipped by older DRAWs), and
' the "drAb" PNG chunk in a .draw.
CONST AB_DSET_MAGIC$ = "DSA1"
CONST AB_DRAB_VERSION = 1
DIM SHARED AB_QL_CEL AS INTEGER ' the cel the Preview's Quick Look shows (0 = not an AnimBrush slot)
