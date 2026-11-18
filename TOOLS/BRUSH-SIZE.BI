''
' DRAW - TOOLS/BRUSH-SIZE.BI
' =============================================================================
' Brush size state management for circular brushes
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE BRUSH_SIZE_TYPE
    CURRENT       AS INTEGER ' Current brush size index (1-25)
    MIN           AS INTEGER ' Minimum index (1)
    MAX           AS INTEGER ' Maximum index (25)
    PRESET1       AS INTEGER ' F1 preset index
    PRESET2       AS INTEGER ' F2 preset index
    PRESET3       AS INTEGER ' F3 preset index
    PRESET4       AS INTEGER ' F4 preset index
    PREVIEW       AS INTEGER ' Show brush preview (0 = off, -1 = on)
    SHAPE         AS INTEGER ' Brush shape: BRUSH_SHAPE_* (0 = circle, -1 = square, 2 = slant /, 3 = slant \)
    PIXEL_PERFECT AS INTEGER ' Pixel perfect mode (0 = off, -1 = on) - removes corner pixels
    SOFT          AS INTEGER ' edge softness 0 (hard) .. 100 (feathered from the centre): round + slant (BRUSH_SIZE_special%)
END TYPE

' BRUSH_SIZE.SHAPE (the brush palette, GUI/BRUSH-PANEL, 2026-11-18). Old code tests SHAPE = 0
' for round and treats anything else as square: a slant falls back to a square there.
CONST BRUSH_SHAPE_ROUND     = 0
CONST BRUSH_SHAPE_SQUARE    = -1
CONST BRUSH_SHAPE_SLASH     = 2  ' a nib from bottom-left to top-right
CONST BRUSH_SHAPE_BACKSLASH = 3  ' a nib from top-left to bottom-right

DIM SHARED BRUSH_SIZE AS BRUSH_SIZE_TYPE
DIM SHARED BRUSH_PIXEL_SIZES(1 TO 25) AS INTEGER

BRUSH_SIZE_init
