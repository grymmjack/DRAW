''
' Alpha Preserve Test — does QB64-PE's alpha-blend draw preserve destination
' alpha (proper source-over compositing) or overwrite it (naive)?
'
' Setup:
'   1. Create a 32-bit software image
'   2. Fill it with opaque white (alpha = 255 everywhere)
'   3. Draw a LINE BF with _RGBA32(R, G, B, 240) — semi-transparent
'   4. Check the alpha at a pixel inside the drawn rect
'
' Expected results:
'   Proper alpha compositing: dest alpha stays 255 (A_out = A_src + A_dst*(1-A_src))
'   Naive overwrite:          dest alpha becomes 240 (A_out = A_src)
'
' If naive, DRAW's semi-transparent tooltip bg leaves alpha-240 pixels on
' SCRN.CANVAS, which then make their way through _COPYIMAGE(,33) to the
' hardware image, and the HW present alpha-blends those pixels with the
' GL framebuffer — causing accumulation/ghost trails when source alpha < 255.
'
$CONSOLE

SCREEN _NEWIMAGE(400, 200, 32)

DIM img AS LONG : img = _NEWIMAGE(100, 100, 32)
_DEST img
_BLEND img
CLS , _RGBA32(255, 255, 255, 255) ' opaque white

' Draw a semi-transparent red rect with alpha 240
LINE (10, 10)-(70, 70), _RGBA32(255, 0, 0, 240), BF

DIM px AS _UNSIGNED LONG
px = POINT(30, 30)
DIM r  AS LONG, g AS LONG, b AS LONG, a AS LONG
r = _RED32(px)
g = _GREEN32(px)
b = _BLUE32(px)
a = _ALPHA32(px)

_DEST 0
CLS , _RGB32(0, 0, 0)
COLOR _RGB32(255, 255, 255), _RGB32(0, 0, 0)
PRINT
PRINT " Pixel at (30, 30) of semi-transparent (alpha=240) draw on opaque dest:"
PRINT
PRINT "   R = "; r
PRINT "   G = "; g
PRINT "   B = "; b
PRINT "   A = "; a
PRINT
IF a = 255 THEN
    COLOR _RGB32(0, 255, 0)
    PRINT " RESULT: Alpha preserved at 255 = proper source-over compositing."
    PRINT "         DRAW's tooltip alpha bg should NOT cause HW ghost trails."
ELSE
    COLOR _RGB32(255, 100, 100)
    PRINT " RESULT: Alpha is "; a; " < 255 = NAIVE overwrite (not proper compositing)."
    PRINT "         DRAW's tooltip alpha bg DOES cause SCRN.CANVAS to have sub-255"
    PRINT "         alpha pixels.  HW present alpha-blends them with GL framebuffer,"
    PRINT "         causing ghost-trail accumulation when path alternates."
END IF
PRINT
COLOR _RGB32(200, 200, 200)
PRINT " Press any key to exit."

_DEST img
DIM k AS LONG
DO
    k = _KEYHIT
    _LIMIT 30
LOOP UNTIL k > 0

_FREEIMAGE img
SYSTEM
