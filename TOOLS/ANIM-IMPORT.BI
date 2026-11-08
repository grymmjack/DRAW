''
' DRAW - TOOLS/ANIM-IMPORT.BI
' =============================================================================
' Bring frames in (Animation phase 5, PLANS/ANIMATION.md Q-26).
'
'   5.1 Animated GIF: opening a GIF with two or more images (and no colour
'       cycling ranges - those keep GIF_load_cycling%'s indexed path) makes a
'       sheet with frames. Each frame is the GIF's logical screen as a viewer
'       shows it after that image (disposal: keep, back to transparent, back
'       to the previous picture), laid out in reading order on a grid about
'       as wide as tall. The delays become the FPS and holds (FPS = 100 / the
'       delays' common divisor, at most 50; a delay under 2 cs counts as 10 as
'       browsers do), the NETSCAPE loop block forward looping (none = play
'       once). The global colour table (else the first local one) becomes the
'       palette.
'   5.2 Aseprite: a .aseprite / .ase with two or more frames opens the same
'       way (FILE_ASE_load): each image layer gets every frame's cel in its
'       cell. Frame durations (ms) become the FPS and holds as above (FPS =
'       1000 / their common divisor, at most 50), the tags become tags (a
'       tag over every frame sets the loop: reverse / ping-pong), linked
'       cels become linked cells (ANIM_LK_*, per layer). A cel's own opacity
'       and z-index are not applied (DRAW has neither per cell).
'   5.3 Sprite sheets: a PNG opened with name.json beside it (Aseprite /
'       TexturePacker / DRAW sheet export) gets its frames, sliced in place
'       when they form a regular grid, else laid out again (ANIM_SHEET_import%);
'       ANIM > Detect Frames finds a plain sheet's grid from its gaps
'       (ANIM_DT_action, the solver ANIM_DT_solve% in ANIM.BM).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_IMP_MAX_PIXELS = 67108864 ' a sheet bigger than this (pixels) is refused: the GIF opens as its first frame
DIM SHARED ANIM_IMP_INFO AS STRING   ' summary of the last import ("12 frames at 10 fps")
