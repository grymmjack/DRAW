''
' DRAW - TOOLS/SS-COMMON.BI
' =============================================================================
' Shared rendering primitives for Smart Shapes (SS-*).
' All SS-XXX modules call these for outline + fill so selection, symmetry,
' opacity and paint mode are honored uniformly via PAINT_pset_with_symmetry.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Maximum vertex count for any polygon-buffer the SS helpers will receive.
CONST SS_MAX_VERTS = 2048

' The exact (float) vertices behind the whole-pixel px() / py() a curved shape
' builder (rounded rect, tab, pill, pac-man) writes through SS_vert. An
' antialiased commit strokes between these, not the rounded ones (rounding put
' facets and steps into the curves). SS_VF_N = how many are valid for the
' current build; SS_stroke_polyline uses them only when it matches n, and
' always clears it.
DIM SHARED SS_VFX(0 TO SS_MAX_VERTS - 1) AS SINGLE
DIM SHARED SS_VFY(0 TO SS_MAX_VERTS - 1) AS SINGLE
DIM SHARED SS_VF_N AS INTEGER

' Supersampled (antialiased) commit of the solid smart shapes - the dice and
' 3D text faces are _MAPTRIANGLE'd, which has hard edges. With Antialias on
' they render into SS_SSAA_IMG at SS_SSAA_S times the size (canvas point
' (x, y) -> ((x - SS_SSAA_OX) * S, (y - SS_SSAA_OY) * S)), and SS_ssaa_end
' box-filters it down onto the real _DEST. S = 1: off (draw as before).
DIM SHARED SS_SSAA_S AS INTEGER
DIM SHARED SS_SSAA_OX AS LONG, SS_SSAA_OY AS LONG
DIM SHARED SS_SSAA_IMG AS LONG, SS_SSAA_DEST AS LONG
SS_SSAA_S = 1
