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
' 3.2 PNG sequence (ANIM_PNGSEQ_export%): what plays, one PNG per tick at the
' FPS (holds and ping-pong written out - the stand-in for a video export,
' Q-24): name_0001.png ... Sprite sheet (ANIM_SHEET_export%): the composite
' sheet as a PNG plus the frame rects - name.json (Aseprite's "array" layout:
' frames[] with frame {x,y,w,h} + duration ms, meta size / fps / loop and a
' frameTags entry with the direction) and name.bi (QB64 CONSTs + DATA x, y, w,
' h, ms per frame). Both scaled by ANIM_EXPORT_SCALE.
'
' Uses the GIF writer in OUTPUT/FILE-GIF (LZW, sub-blocks, GCE, the cycle
' timeline GIF_cycle_ticks& / GIF_display_map).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST ANIM_ACT_EXPORT_GIF   = 2532 ' ANIM > Export Animated GIF...
CONST ANIM_ACT_EXPORT_SCALE = 2533 ' ANIM > Export Scale 1x / 2x / 4x
CONST ANIM_ACT_EXPORT_PNGS  = 2534 ' ANIM > Export PNG Sequence...
CONST ANIM_ACT_EXPORT_SHEET = 2535 ' ANIM > Export Sprite Sheet + Frame Data...
CONST ANIM_PNGSEQ_MAX = 20000      ' files one PNG sequence may write

CONST ANIM_GIF_MAX_TICKS  = 6000 ' with colour cycling the GIF loop is at most 120 s (2-cs ticks)
CONST ANIM_GIF_MAX_FRAMES = 2000

DIM SHARED ANIM_EXPORT_INFO AS STRING ' summary of the last export ("6 frames, 1.2 s loop, 5 colours")

' exact colour table of an export: RGB -> index (hashed on the low 16 bits)
DIM SHARED ANIM_GH_HEAD(0 TO 65535) AS INTEGER
DIM SHARED ANIM_GH_RGB(1 TO 256) AS _UNSIGNED LONG
DIM SHARED ANIM_GH_NEXT(1 TO 256) AS INTEGER
DIM SHARED ANIM_GH_N AS INTEGER
