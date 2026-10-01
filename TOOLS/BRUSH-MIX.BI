''
' DRAW - TOOLS/BRUSH-MIX.BI
' =============================================================================
' Mix brush: Brush strokes mix with the colors already on the layer like wet
' paint, using QB64_GJ_LIB COLOR-PIGMENT (Kubelka-Munk, a Spectral.js port),
' so blue over yellow gives green. Toggle via Brush > Mix Colors (Pigment)
' (action 2026, CFG.BRUSH_MIX).
'
' Each stroke snapshots the layer at press; every painted pixel becomes
' PGM_mix(snapshot pixel, paint, CFG.BRUSH_MIX_STRENGTH%). Mixing against the
' snapshot (not the live layer) keeps overlapping dabs in one stroke from
' compounding. With CFG.BRUSH_MIX_PICKUP% > 0 the paint is a "reservoir" that
' soaks up the colors it passes over and drags them along (smudge).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST BMIX_CACHE_N = 4096 ' direct-mapped memo of (under, paint, strength) -> mix

TYPE BRUSH_MIX_OBJ
    active    AS INTEGER        ' TRUE while a mixing stroke is in progress
    inResolve AS INTEGER        ' re-entry guard for the DRAWER resolver hook
    snap      AS LONG           ' layer snapshot taken at stroke start (buffer coords)
    snapW     AS INTEGER
    snapH     AS INTEGER
    apronW    AS INTEGER        ' layer apron at stroke start (canvas -> buffer offset)
    apronH    AS INTEGER
    reservoir AS _UNSIGNED LONG ' current paint color (FG, dirtied by pickup)
    usePickup AS INTEGER        ' TRUE when the reservoir replaces the resolved paint
    lastX     AS INTEGER        ' last pickup sample point (canvas)
    lastY     AS INTEGER
    hasLast   AS INTEGER
END TYPE

DIM SHARED BMIX AS BRUSH_MIX_OBJ
DIM SHARED BMIX_MEM AS _MEM                    ' _MEMIMAGE view of BMIX.snap
DIM SHARED BMIX_C_UNDER(0 TO BMIX_CACHE_N - 1) AS _UNSIGNED LONG
DIM SHARED BMIX_C_PAINT(0 TO BMIX_CACHE_N - 1) AS _UNSIGNED LONG
DIM SHARED BMIX_C_OUT(0 TO BMIX_CACHE_N - 1)   AS _UNSIGNED LONG
DIM SHARED BMIX_C_S(0 TO BMIX_CACHE_N - 1)     AS INTEGER ' strength + 1 (0 = empty)
