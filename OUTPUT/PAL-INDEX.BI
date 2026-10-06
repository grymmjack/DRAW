''
' DRAW - OUTPUT/PAL-INDEX.BI
' =============================================================================
' Map a 32-bit image onto the palette (PAL 0..PAL_COLOR_COUNT-1) for the
' indexed exporters (color cycling .BAS, GIF, LBM).
'
' Same ownership rule as Color Ops / color cycling: a pixel belongs to the
' FIRST palette index with exactly its RGB. Pixels with no exact match are
' quantized to the nearest color (RGB distance) that is NOT inside a cycle
' range, so off-palette pixels never start cycling in an exported file.
' Pixels with alpha < 128 become the transparent index (if one is given).
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM SHARED IDX_QUANTIZED   AS LONG ' pixels with no exact palette match (last IDX_index_image$)
DIM SHARED IDX_TRANSPARENT AS LONG ' pixels mapped to the transparent index
DIM SHARED IDX_USED(0 TO 255) AS LONG ' pixel count per index (last IDX_index_image$)

' Exact-match lookup (first index wins) + nearest-color cache, both hashed on
' the low 16 bits of RGB.
DIM SHARED IDX_LUT_HEAD(0 TO 65535) AS INTEGER
DIM SHARED IDX_LUT_RGB(1 TO 256)    AS _UNSIGNED LONG
DIM SHARED IDX_LUT_IDX(1 TO 256)    AS INTEGER
DIM SHARED IDX_LUT_NEXT(1 TO 256)   AS INTEGER
DIM SHARED IDX_LUT_N                AS INTEGER
DIM SHARED IDX_NEAR_KEY(0 TO 65535) AS _UNSIGNED LONG ' rgb + &H1000000 (0 = empty)
DIM SHARED IDX_NEAR_VAL(0 TO 65535) AS INTEGER
