''
' DRAW - OUTPUT/FILE-CYCLE-BAS.BI
' =============================================================================
' Color cycling exports hub (File > Color Cycling) + the single-file QB64
' color cycling program exporter.
'
'   2330  Export Cycling QB64 Program (.bas)     - this module
'   2331  Export GIF + Cycle Ranges (GrafX2)     - OUTPUT/FILE-GIF.BM
'   2332  Export Animated GIF of the Cycle       - OUTPUT/FILE-GIF.BM
'   2333  Export DeluxePaint ILBM (.lbm)         - OUTPUT/FILE-LBM.BM
'   2334  Export DeluxePaint PBM (.lbm, chunky)  - OUTPUT/FILE-LBM.BM
'   2335  Open DeluxePaint / GrafX2 file...      - INPUT/FILE-LBM.BM + GIF import
'
' The .bas is self-contained: one deflated + base64 DATA blob holds the
' palette, the ranges, the flattened art (32-bit) and an 8-bit overlay of
' just the cycling pixels. The generated program draws the art once per
' step and rotates the overlay's palette with _PALETTECOLOR, each range on
' its own timer (same CRNG speed units and FWD/REV/PING math as DRAW).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST CYCX_ACT_BAS      = 2330
CONST CYCX_ACT_GIF      = 2331
CONST CYCX_ACT_ANIM_GIF = 2332
CONST CYCX_ACT_ILBM     = 2333
CONST CYCX_ACT_PBM      = 2334
CONST CYCX_ACT_OPEN     = 2335

DIM SHARED CYCX_LAST_ERROR AS STRING ' why the last cycling export failed ("" = ok)
DIM SHARED CYCX_BAS_LINES  AS STRING ' generator scratch (CHR$(10)-joined lines)
