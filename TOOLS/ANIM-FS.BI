''
' DRAW - TOOLS/ANIM-FS.BI
' =============================================================================
' Full-screen Preview (Animation 3.6, ANIM > Full-Screen Preview, Num .): the
' frames playing over the whole window in a loop of its own, like the Pixel
' Analyzer. What plays is what exports (LAYERS_flatten&: hidden and reference
' layers out), in loop order with the holds at the FPS, colour cycling along.
'
'   SPACE play / pause (play once at its end: from the start), LEFT / RIGHT
'   step (pauses), HOME / END first / last, the seek bar: click or drag to
'   scrub, wheel / Ctrl+wheel zoom about the pointer, double middle click
'   100%, middle drag pans, ESC (or Num . again) closes on the frame shown.
'
' QA dump (DOCK_DUMP_PATH, while open): ANIMFS open step frame playing zoom%
' x y w h barX barY barW barH steps sndStarts sndLastMs sndOn - logical (viewport) px.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_ACT_FULLSCREEN = 2539 ' ANIM > Full-Screen Preview (Num .)
CONST ANIM_FS_HUD_H = 30         ' logical px: the seek bar + the status line

TYPE ANIM_FS_OBJ
    open    AS INTEGER
    k       AS INTEGER ' step in the play order (1..steps)
    steps   AS INTEGER
    playing AS INTEGER
    zoom    AS SINGLE  ' frame px per logical px
    x       AS LONG    ' the frame on screen, logical px
    y       AS LONG
    w       AS LONG
    h       AS LONG
    barX    AS LONG    ' the seek bar, logical px
    barY    AS LONG
    barW    AS LONG
    barH    AS LONG
END TYPE
DIM SHARED ANIM_FS AS ANIM_FS_OBJ
DIM SHARED ANIM_FS_DUMP_LAST AS STRING
