''
' DRAW - TOOLS/ANIM-EXPORT.BI
' =============================================================================
' Animation exports (Phase 3): the frames of the sheet out the door.
'
' 3.1 Animated GIF (ANIM_GIF_export%): one GIF frame per frame shown, in loop
' order (ping-pong written out, play once = no loop block), each up for its
' hold at the FPS; transparent pixels keep through (disposal 2); colour cycling
' runs along (a local colour table per change); every pixel scaled 1x / 2x / 4x
' (CFG.ANIM_EXPORT_SCALE). Pixels come from LAYERS_flatten&, so hidden and
' reference layers are left out, like every export. Colours are exact when the
' frames use 256 or fewer, else the document palette (nearest).
'
' Uses the GIF writer in OUTPUT/FILE-GIF (LZW, sub-blocks, GCE, the cycle
' timeline GIF_cycle_ticks& / GIF_display_map).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_ACT_EXPORT_GIF   = 2532 ' ANIM > Export Animated GIF...
CONST ANIM_ACT_EXPORT_SCALE = 2533 ' ANIM > Export Scale 1x / 2x / 4x

CONST ANIM_GIF_MAX_TICKS  = 6000 ' with colour cycling the GIF loop is at most 120 s (2-cs ticks)
CONST ANIM_GIF_MAX_FRAMES = 2000

DIM SHARED ANIM_EXPORT_INFO AS STRING ' summary of the last export ("6 frames, 1.2 s loop, 5 colours")

' exact colour table of an export: RGB -> index (hashed on the low 16 bits)
DIM SHARED ANIM_GH_HEAD(0 TO 65535) AS INTEGER
DIM SHARED ANIM_GH_RGB(1 TO 256) AS _UNSIGNED LONG
DIM SHARED ANIM_GH_NEXT(1 TO 256) AS INTEGER
DIM SHARED ANIM_GH_N AS INTEGER
