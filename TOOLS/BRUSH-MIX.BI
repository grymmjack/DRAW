''
' DRAW - TOOLS/BRUSH-MIX.BI
' =============================================================================
' Mix brush: wet-paint smudging with pigment mixing. Toggle via Brush > Mix
' Colors (Pigment) (action 2026, CFG.BRUSH_MIX). Colors mix with QB64_GJ_LIB
' COLOR-PIGMENT (Kubelka-Munk, a Spectral.js port): blue into yellow = green.
'
' Smudge model after libmypaint (ISC, (c) Martin Renold and contributors):
' the brush carries one SMUDGE COLOR. Before each dab it samples the layer
' under the dab (a disc of CFG.BRUSH_MIX_RADIUS% of the brush radius, weighted
' by alpha) and moves the smudge color toward the sample; how much
' of the old color it keeps is CFG.BRUSH_MIX_LENGTH%. Each dab is then drawn
' in pigment_mix(smudge color, brush color) with CFG.BRUSH_MIX_SMUDGE% of
' smudge (100 = pure smudge tool, no new paint). Samples are taken every
' half brush radius along the stroke, so behavior is independent of FPS.
' Unlike libmypaint, samples come from a snapshot of the layer taken when the
' stroke began: MyPaint's soft, translucent dabs let the canvas show through,
' but a hard pixel dab would mostly re-sample its own fresh paint and the
' brush would turn back into plain paint within a few pixels.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST BMIX_CACHE_N = 4096 ' direct-mapped memo of (smudge, paint, share) -> mix

TYPE BRUSH_MIX_OBJ
    active    AS INTEGER        ' TRUE while a mixing stroke is in progress
    inResolve AS INTEGER        ' re-entry guard for the DRAWER resolver hook
    snapImg   AS LONG           ' layer snapshot at stroke start (BMIX_MEM views it)
    imgW      AS INTEGER
    imgH      AS INTEGER
    apronW    AS INTEGER        ' layer apron (canvas -> buffer offset)
    apronH    AS INTEGER
    hasSmudge AS INTEGER        ' TRUE once the brush has picked up a color
    smudge    AS _UNSIGNED LONG ' the smudge color carried by the brush (opaque)
    hasLast   AS INTEGER        ' last sample point (canvas), for dab spacing
    lastX     AS INTEGER
    lastY     AS INTEGER
    replay    AS INTEGER        ' TRUE during the pixel-perfect redraw at release
    replayImg AS LONG           ' copy of the finished stroke used by the replay
END TYPE

DIM SHARED BMIX AS BRUSH_MIX_OBJ
DIM SHARED BMIX_MEM  AS _MEM                    ' _MEMIMAGE view of BMIX.snapImg
DIM SHARED BMIX_RMEM AS _MEM                    ' _MEMIMAGE view of BMIX.replayImg
DIM SHARED BMIX_LIN(0 TO 255) AS SINGLE         ' sRGB byte -> linear light
DIM SHARED BMIX_LIN_READY AS INTEGER
DIM SHARED BMIX_C_A(0 TO BMIX_CACHE_N - 1)   AS _UNSIGNED LONG
DIM SHARED BMIX_C_B(0 TO BMIX_CACHE_N - 1)   AS _UNSIGNED LONG
DIM SHARED BMIX_C_OUT(0 TO BMIX_CACHE_N - 1) AS _UNSIGNED LONG
DIM SHARED BMIX_C_S(0 TO BMIX_CACHE_N - 1)   AS INTEGER ' share + 1 (0 = empty)
