''
' SETALPHA Verify Test — does _SETALPHA actually fix alpha-0 holes
' caused by _RGBA32(...,240) draws with _BLEND on?
'
$CONSOLE

SCREEN _NEWIMAGE(400, 200, 32)

DIM img AS LONG : img = _NEWIMAGE(100, 100, 32)
_DEST img
_BLEND img
CLS , _RGBA32(255, 255, 255, 255)
LINE (10, 10)-(70, 70), _RGBA32(255, 0, 0, 240), BF

DIM px AS _UNSIGNED LONG : px = POINT(30, 30)
DIM aBefore AS LONG : aBefore = _ALPHA32(px)
DIM rBefore AS LONG : rBefore = _RED32(px)
DIM gBefore AS LONG : gBefore = _GREEN32(px)
DIM bBefore AS LONG : bBefore = _BLUE32(px)

' Now apply _SETALPHA 255 to the whole image (correct syntax — no middle param)
_SETALPHA 255, img

px = POINT(30, 30)
DIM aAfter AS LONG : aAfter = _ALPHA32(px)
DIM rAfter AS LONG : rAfter = _RED32(px)
DIM gAfter AS LONG : gAfter = _GREEN32(px)
DIM bAfter AS LONG : bAfter = _BLUE32(px)

_DEST 0
CLS , _RGB32(0, 0, 0)
COLOR _RGB32(255, 255, 255)
PRINT
PRINT " Pixel (30, 30) of LINE BF _RGBA32(255,0,0,240) on opaque white canvas:"
PRINT
PRINT "   Before _SETALPHA 255:"
PRINT "     RGBA = "; rBefore; ","; gBefore; ","; bBefore; ","; aBefore
PRINT
PRINT "   After _SETALPHA 255:"
PRINT "     RGBA = "; rAfter; ","; gAfter; ","; bAfter; ","; aAfter
PRINT
IF aAfter = 255 THEN
    COLOR _RGB32(0, 255, 0)
    PRINT " _SETALPHA worked: alpha is now 255."
    IF rAfter > 0 OR gAfter > 0 OR bAfter > 0 THEN
        PRINT " Pixel HAS color data — _SETALPHA didn't wipe color."
    ELSE
        PRINT " Pixel is BLACK — _SETALPHA might have wiped color."
    END IF
ELSE
    COLOR _RGB32(255, 100, 100)
    PRINT " _SETALPHA did NOT fix alpha. Alpha after is "; aAfter
END IF
PRINT
COLOR _RGB32(200, 200, 200)
PRINT " Press any key to exit."

DIM k AS LONG
DO
    k = _KEYHIT
    _LIMIT 30
LOOP UNTIL k > 0

_FREEIMAGE img
SYSTEM
