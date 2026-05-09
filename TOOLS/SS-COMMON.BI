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
CONST SS_MAX_VERTS = 256
