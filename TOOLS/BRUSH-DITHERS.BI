'' DRAW - TOOLS/BRUSH-DITHERS.BI
' =============================================================================
' UDT for brush dither patterns.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Current active dither pattern (0 = none/solid, 1-9 = patterns)
DIM SHARED BRUSH_DITHER_ACTIVE AS INTEGER

' 8x8 dither patterns (0 = skip pixel, 1 = draw pixel)
DIM SHARED DITHER_PATTERN(0 TO 9, 0 TO 7, 0 TO 7) AS INTEGER

' Pattern names for UI feedback
DIM SHARED DITHER_NAMES(0 TO 9) AS STRING

' Initialize dither patterns
BRUSH_DITHERS_init