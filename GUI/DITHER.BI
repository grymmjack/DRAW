''
' DRAW - GUI/DITHER.BI
' =============================================================================
' Dithering infrastructure for gradients, palette remapping, and posterize.
' Provides per-pixel threshold functions for spatially-deterministic dithering
' and algorithm name/metadata helpers.
'
$INCLUDEONCE

' Sentinel value: no dithering
CONST DITHER_NONE = -1

' Per-pixel capable algorithms (ordered, noise, pattern) for gradient painting
CONST DITHER_COUNT_PERPIXEL = 10

' All algorithms including error diffusion (for remap/posterize on full images)
CONST DITHER_COUNT_ALL = 22

' Map per-pixel UI index (0..9) → GJ_IMGADJ_DITHER_* constant
DIM SHARED DITHER_PERPIXEL_MAP(0 TO 9) AS INTEGER

' Shared Bayer matrices populated by DITHER_init
DIM SHARED DITHER_BAYER2(0 TO 1, 0 TO 1) AS INTEGER
DIM SHARED DITHER_BAYER4(0 TO 3, 0 TO 3) AS INTEGER
DIM SHARED DITHER_BAYER8(0 TO 7, 0 TO 7) AS INTEGER
DIM SHARED DITHER_BAYER16(0 TO 15, 0 TO 15) AS INTEGER

' Clustered dot 4x4 matrix
DIM SHARED DITHER_CLUSTERED4(0 TO 3, 0 TO 3) AS INTEGER

' Track init state
DIM SHARED DITHER_INITIALIZED AS INTEGER

DECLARE SUB DITHER_init ()
DECLARE FUNCTION DITHER_get_threshold! (ditherMode AS INTEGER, x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION DITHER_algorithm_name$ (ditherMode AS INTEGER)
DECLARE FUNCTION DITHER_perpixel_name$ (uiIndex AS INTEGER)
DECLARE FUNCTION DITHER_is_perpixel% (ditherMode AS INTEGER)
DECLARE FUNCTION DITHER_perpixel_to_imgadj% (uiIndex AS INTEGER)
DECLARE FUNCTION DITHER_imgadj_to_perpixel% (ditherMode AS INTEGER)
DECLARE FUNCTION DITHER_apply_to_image& (sourceImg AS LONG, ditherMode AS INTEGER, amount AS SINGLE)
