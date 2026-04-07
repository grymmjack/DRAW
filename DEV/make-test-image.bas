OPTION _EXPLICIT
' make-test-image.bas — Generate pixel art test images with deliberate
' examples of every issue the Pixel Art Analyzer detects.
'
' DESIGN: Uses a CONTROLLED palette throughout. No random colors — they
' pollute the global palette analysis (Value/Contrast detectors).
'
' Palette strategy:
'   - Black background (lum 0)
'   - Art colors in lum 100..150 range → forces VALUE gap (0→100 = 100 > 80)
'   - 7+ art colors in 50-unit band → VALUE clumping (>60% in 40 units)
'   - Adjacent blocks with delta < 15 → local CONTRAST flags
'   - NO random colors, NO wide-spectrum palette
'
' Detectors tested:
'   1. Jaggies      — irregular staircase on diagonal edge
'   2. Islands      — isolated single pixels (area=1 components)
'   3. Banding      — parallel contours with identical staircases
'   4. Fat pixels   — 1px→2px→1px inconsistent line thickness
'   5. Over-dither  — checkerboard alternation pattern
'   6. Contrast     — adjacent regions with barely different luminance
'   7. Value        — compressed palette with large luminance gaps
'   8. Noise        — dense single-pixel components in 8×8 blocks
'
' ===========================================================================

CONST IMG_W = 160
CONST IMG_H = 80

DIM img&
img& = _NEWIMAGE(IMG_W, IMG_H, 32)
_DEST img&

' Background — black (lum 0). This creates a big gap to the art palette.
CLS , _RGB32(0, 0, 0)

' ---- CONTROLLED PALETTE ----
' All art colors in lum ~100..150 range (ITU-R BT.601 weighted)
' This ensures:
'   VALUE gap:   0 → ~100 = 100 > 80 threshold ✓
'   VALUE clump: 7 of 8 colors (incl black) within 50 units → >60% ✓
'   CONTRAST:    adjacent pairs with delta < 15 ✓
DIM cA~&, cB~&, cC~&, cD~&, cE~&, cF~&, cG~&, cH~&

cA~& = _RGB32(115, 100, 100) ' lum ~104  dark warm gray
cB~& = _RGB32(108, 108, 108) ' lum ~108  neutral gray
cC~& = _RGB32(110, 115, 110) ' lum ~113  slight green-gray
cD~& = _RGB32(120, 120, 120) ' lum ~120  mid gray
cE~& = _RGB32(125, 125, 125) ' lum ~125  mid-light gray
cF~& = _RGB32(130, 130, 130) ' lum ~130  light gray
cG~& = _RGB32(140, 135, 135) ' lum ~137  warm light
cH~& = _RGB32(150, 145, 140) ' lum ~146  lightest

DIM x%, y%

' ===========================================================================
' SECTION 1: JAGGIES (0-31, 0-39) — top-left
' Irregular staircase: run lengths 1, 2, 1, 3, 1, 2, 4, 1
' A smooth diagonal would be 2,2,2,2 — this one is chaotic
' ===========================================================================
' Two jaggy diagonals for more hits
' Diagonal 1
PSET (4, 4), cA~&
PSET (5, 5), cA~&
PSET (6, 6), cA~&
PSET (7, 7), cA~&: PSET (8, 7), cA~&             ' run=2
PSET (9, 8), cA~&
PSET (10, 9), cA~&: PSET (11, 9), cA~&: PSET (12, 9), cA~& ' run=3
PSET (13, 10), cA~&
PSET (14, 11), cA~&
PSET (15, 12), cA~&: PSET (16, 12), cA~&          ' run=2
PSET (17, 13), cA~&: PSET (18, 13), cA~&: PSET (19, 13), cA~&: PSET (20, 13), cA~& ' run=4
PSET (21, 14), cA~&
PSET (22, 15), cA~&: PSET (23, 15), cA~&          ' run=2
PSET (24, 16), cA~&
PSET (25, 17), cA~&

' Diagonal 2 — different rhythm
PSET (4, 20), cB~&
PSET (5, 21), cB~&: PSET (6, 21), cB~&: PSET (7, 21), cB~& ' run=3
PSET (8, 22), cB~&
PSET (9, 23), cB~&: PSET (10, 23), cB~&           ' run=2
PSET (11, 24), cB~&
PSET (12, 25), cB~&
PSET (13, 26), cB~&: PSET (14, 26), cB~&: PSET (15, 26), cB~&: PSET (16, 26), cB~&: PSET (17, 26), cB~& ' run=5
PSET (18, 27), cB~&
PSET (19, 28), cB~&: PSET (20, 28), cB~&          ' run=2
PSET (21, 29), cB~&
PSET (22, 30), cB~&

' ===========================================================================
' SECTION 2: ISLANDS (0-31, 40-79) — bottom-left
' Scattered single pixels, well-separated, in empty (black) space
' ===========================================================================
PSET (5, 45), cA~&
PSET (10, 48), cC~&
PSET (15, 43), cE~&
PSET (20, 50), cG~&
PSET (8, 55), cB~&
PSET (18, 58), cD~&
PSET (25, 46), cF~&
PSET (12, 62), cH~&
PSET (22, 65), cA~&
PSET (6, 68), cC~&
PSET (16, 70), cE~&
PSET (28, 55), cG~&
PSET (3, 60), cB~&
PSET (26, 72), cD~&
PSET (14, 75), cF~&

' ===========================================================================
' SECTION 3: BANDING (32-63, 0-39) — top-center-left
' Three parallel diagonal contours with identical staircase pattern
' Detector looks for neighboring contours that follow each other
' ===========================================================================
DIM bY%
FOR x% = 0 TO 28
    bY% = 3 + x% \ 3  ' staircase with run=3

    ' Line 1
    PSET (34 + x%, bY%), cA~&
    ' Line 2 — parallel, 2px gap (banding!)
    PSET (34 + x%, bY% + 3), cC~&
    ' Line 3 — parallel, 4px gap (more banding!)
    PSET (34 + x%, bY% + 6), cA~&
NEXT x%

' Second set — horizontal parallel lines (easy banding)
FOR x% = 34 TO 62
    PSET (x%, 22), cD~&
    PSET (x%, 24), cD~&    ' 1px gap — banding!
    PSET (x%, 26), cD~&    ' 1px gap — banding!
NEXT x%

' ===========================================================================
' SECTION 4: FAT PIXELS (64-95, 0-39) — top-center-right
' Horizontal line: 1px thick → 2px thick → 1px thick (inconsistency)
' Vertical line: same pattern
' Detector requires: both sides of 2-row band differ, nearby 1px proof
' ===========================================================================
' Horizontal fat line — make line LONG for clear run detection
FOR x% = 66 TO 93
    PSET (x%, 8), cA~&                    ' top row — always present
    IF x% >= 74 AND x% <= 86 THEN
        PSET (x%, 9), cA~&                ' 2px thick section (13px run)
    END IF
NEXT x%

' Second horizontal fat line — different color
FOR x% = 66 TO 93
    PSET (x%, 18), cE~&
    IF x% >= 72 AND x% <= 88 THEN
        PSET (x%, 19), cE~&               ' 2px thick section (17px run)
    END IF
NEXT x%

' Vertical fat line
FOR y% = 4 TO 36
    PSET (68, y%), cC~&                    ' left col — always
    IF y% >= 14 AND y% <= 28 THEN
        PSET (69, y%), cC~&                ' 2px thick section (15px run)
    END IF
NEXT y%

' ===========================================================================
' SECTION 5: OVER-DITHER (96-127, 0-39) — top-right
' Large checkerboard: two colors alternating
' Needs interior pixels (skip 1px border scan), so use full 28×36 area
' ===========================================================================
FOR y% = 2 TO 37
    FOR x% = 98 TO 125
        IF (x% + y%) MOD 2 = 0 THEN
            PSET (x%, y%), cA~&            ' lum ~104
        ELSE
            PSET (x%, y%), cH~&            ' lum ~146 (delta ~42)
        END IF
    NEXT x%
NEXT y%

' ===========================================================================
' SECTION 6: CONTRAST (64-127, 40-59) — middle
' Large adjacent blocks with barely different luminance (delta < 15)
' Both blocks must be midtone (lum 40-215) and area >= 4
' ===========================================================================
' Block pair 1: cD (lum 120) vs cE (lum 125) — delta = 5
FOR y% = 42 TO 57
    FOR x% = 66 TO 81
        PSET (x%, y%), cD~&
    NEXT x%
    FOR x% = 82 TO 97
        PSET (x%, y%), cE~&
    NEXT x%
NEXT y%

' Block pair 2: cB (lum 108) vs cC (lum 113) — delta = 5
FOR y% = 42 TO 57
    FOR x% = 100 TO 112
        PSET (x%, y%), cB~&
    NEXT x%
    FOR x% = 113 TO 125
        PSET (x%, y%), cC~&
    NEXT x%
NEXT y%

' ===========================================================================
' SECTION 7: VALUE (128-159, 0-39) — top-far-right
' A "sprite" drawn entirely with the compressed palette
' The VALUE detector analyzes the WHOLE image's palette, not this section
' alone — the constrained palette (all lum 100-146 + black bg) ensures:
'   - Gap: 0→104 = 104 > 80 ✓
'   - Clumping: most colors in a 42-unit band ✓
' ===========================================================================
' Simple character/sprite using palette colors
' Head
FOR x% = 140 TO 150
    PSET (x%, 4), cG~&
NEXT x%
FOR x% = 138 TO 152
    FOR y% = 5 TO 8
        PSET (x%, y%), cF~&
    NEXT y%
NEXT x%
FOR x% = 139 TO 151
    PSET (x%, 9), cE~&
NEXT x%

' Eyes
PSET (141, 6), cA~&: PSET (142, 6), cA~&
PSET (148, 6), cA~&: PSET (149, 6), cA~&

' Mouth
FOR x% = 143 TO 147
    PSET (x%, 8), cA~&
NEXT x%

' Body
FOR x% = 140 TO 150
    FOR y% = 11 TO 22
        PSET (x%, y%), cD~&
    NEXT y%
NEXT x%

' Arms
FOR y% = 12 TO 18
    PSET (138, y%), cD~&
    PSET (152, y%), cD~&
NEXT y%

' Legs
FOR y% = 23 TO 30
    PSET (141, y%), cC~&: PSET (142, y%), cC~&: PSET (143, y%), cC~&
    PSET (147, y%), cC~&: PSET (148, y%), cC~&: PSET (149, y%), cC~&
NEXT y%

' Feet
FOR x% = 140 TO 144
    PSET (x%, 31), cB~&
NEXT x%
FOR x% = 146 TO 150
    PSET (x%, 31), cB~&
NEXT x%

' ===========================================================================
' SECTION 8: NOISE (128-159, 42-77) — bottom-right
' Many unique-color single pixels arranged so NO two same-color pixels
' are 8-connected → each becomes a component with area=1
' Detector: >40% of block's opaque pixels must be area=1, in 8×8 blocks
'
' Strategy: place dots on a sparse grid (every 2px), each a unique shade.
' Unique shades via slight R variation (keeps lum in same band).
' ===========================================================================
DIM noiseIdx%
noiseIdx% = 0
FOR y% = 44 TO 75 STEP 2
    FOR x% = 130 TO 157 STEP 2
        ' Each pixel gets a unique shade: vary R from 100..154
        ' G and B stay at 120 → lum stays in ~107..123 range
        DIM nR%
        nR% = 100 + (noiseIdx% MOD 55)
        PSET (x%, y%), _RGB32(nR%, 120, 120)
        noiseIdx% = noiseIdx% + 1
    NEXT x%
NEXT y%

' ===========================================================================
' SECTION 9: More contrast — gradient blocks (32-63, 42-77) — bottom-left-center
' Three blocks that transition very gently
' ===========================================================================
FOR y% = 44 TO 60
    FOR x% = 34 TO 44
        PSET (x%, y%), cA~&     ' lum ~104
    NEXT x%
    FOR x% = 45 TO 55
        PSET (x%, y%), cB~&     ' lum ~108 (delta=4)
    NEXT x%
    FOR x% = 56 TO 63
        PSET (x%, y%), cC~&     ' lum ~113 (delta=5)
    NEXT x%
NEXT y%

' ===========================================================================
' SAVE as BMP
' ===========================================================================
DIM savePath$
savePath$ = "PIXEL-COACH-TEST.BMP"
_SAVEIMAGE savePath$, img&
PRINT "Saved test image: "; savePath$
PRINT "Size: "; IMG_W; "x"; IMG_H; " pixels"
PRINT
PRINT "All art colors use lum 104-146 + black background."
PRINT "This controlled palette triggers VALUE (gap 0->104, clumping)"
PRINT "and CONTRAST (adjacent blocks with delta < 15)."
PRINT
PRINT "Sections:"
PRINT "  Top-left (0-31,0-39)    : JAGGIES — two irregular staircase diagonals"
PRINT "  Top-center-L (32-63,0-39): BANDING — parallel contours + h-lines"
PRINT "  Top-center-R (64-95,0-39): FAT PIXELS — 1px->2px->1px lines"
PRINT "  Top-right (96-127,0-39) : DITHER — 28x36 checkerboard"
PRINT "  Top-far-R (128-159,0-39): VALUE sprite — compressed palette"
PRINT "  Bottom-left (0-31,40-79): ISLANDS — 15 isolated single pixels"
PRINT "  Bottom-ctr-L (32-63,42-77): CONTRAST — gentle gradient blocks"
PRINT "  Bottom-center (64-127,40-59): CONTRAST — two block pairs, delta=5"
PRINT "  Bottom-right (128-159,42-77): NOISE — sparse unique-color dots"
PRINT
PRINT "Load in DRAW → open Pixel Art Analyzer (F12) → click RE-ANALYZE"

_FREEIMAGE img&

SYSTEM
