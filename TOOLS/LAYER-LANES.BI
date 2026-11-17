$INCLUDEONCE
' =============================================================================
' TOOLS/LAYER-LANES.BI - keyframe lanes on any layer (branch xsheet-holds-lanes,
' PLANS/XSHEET-HOLDS-LANES.md phase 3). A pixel layer or a group gets the clip
' layers' lanes - X, Y, SCALE X / Y, ROTATE, OPACITY, TINT, PIVOT X / Y, and the
' effect lanes BLUR / PIXELATE / INVERT / NOISE (LL_fx) - keyed per frame with
' the same eases and modulators. They never change the layer's
' pixels: the layer is shown through a display copy (LL_display&) with each
' frame cell drawn through that frame's lanes (its own, then each enclosing
' group's), clipped to the cell, which the canvas composite and
' LAYERS_flatten& (every export) use instead of its pixels.
' =============================================================================

CONST LL_MAX = 256       ' layers with lanes (one entry per historyId)
CONST LL_LANES = 16      ' X .. PIVOT Y (CLIP_LANE_X .. CLIP_LANE_PVY), BLEND (12), BLUR / PIXELATE / INVERT / NOISE (13-16); 10 / 11 (VOLUME / PAN) unused - no sound on a pixel layer.
'                          An older DRAW skips a lane past its own LL_LANES (LL_from_blob), so new lanes load there as absent
CONST LL_CHUNK_VERSION = 1

DIM SHARED LL_N AS INTEGER
DIM SHARED LL_ID(1 TO LL_MAX) AS LONG
DIM SHARED LL_KEYS(1 TO LL_MAX, 1 TO LL_LANES) AS STRING ' 8-byte keys (CLIP-MATH): frame - 1 (2), value SINGLE (4), ease (2)
DIM SHARED LL_MOD(1 TO LL_MAX, 1 TO LL_LANES) AS STRING  ' CLIP_mod_pack$ (20 bytes) or ""
DIM SHARED LL_TINT(1 TO LL_MAX) AS _UNSIGNED LONG        ' the TINT lane's colour
DIM SHARED LL_GEN AS LONG                                ' bumped on every lane change (display signatures)

' the display copy per layer slot (0 = none built)
DIM SHARED LL_IMG(1 TO MAX_LAYERS) AS LONG
DIM SHARED LL_DSIG(1 TO MAX_LAYERS) AS STRING
