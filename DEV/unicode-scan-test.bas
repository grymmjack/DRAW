''
' Test: Fast Unicode glyph detection for icon fonts
' Compares _UPRINTWIDTH-based detection vs render+ink scan.
' Goal: find a fast way to discover which codepoints have glyphs.
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST TRUE  = -1
CONST FALSE = 0

DIM fontPath AS STRING
DIM fHandle  AS LONG
DIM cp       AS LONG
DIM utf32str AS STRING
DIM pw       AS LONG
DIM found    AS LONG
DIM t1       AS DOUBLE, t2 AS DOUBLE

SCREEN _NEWIMAGE(800, 600, 32)
CLS , _RGB32(0, 0, 0)
_TITLE "Unicode Scan Speed Test"

fontPath$ = "../ASSETS/FONTS/rpgawesome-webfont.ttf"
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT "Font: "; fontPath$

fHandle& = _LOADFONT(fontPath$, 24)
IF fHandle& < 1 THEN
    PRINT "ERROR: Font failed to load"
    _DISPLAY
    _SAVEIMAGE "/home/grymmjack/git/DRAW/DEV/unicode-scan-test.png"
    _DELAY 0.5
    SYSTEM
END IF
PRINT "Font handle:"; fHandle&; " UFontHeight:"; _UFONTHEIGHT(fHandle&)
PRINT

' ================================================================
' TEST 1: _UPRINTWIDTH detection on PUA range (E000-F8FF = 6400 cp)
' ================================================================
PRINT "--- TEST 1: _UPRINTWIDTH on full PUA (6400 codepoints) ---"
found& = 0
t1#    = TIMER(.001)
FOR cp& = &HE000& TO &HF8FF&
    utf32str$ = MKL$(cp&)
    pw&       = _UPRINTWIDTH(utf32str$, 32, fHandle&)
    IF pw& > 0 THEN found& = found& + 1
NEXT cp&
t2# = TIMER(.001)
PRINT "  Found:"; found&; " with width > 0"
PRINT "  Time:"; USING "##.### sec"; t2# - t1#
PRINT

' ================================================================
' TEST 2: _UPRINTWIDTH on Dingbats range (2700-27BF = 192 cp)
' ================================================================
PRINT "--- TEST 2: _UPRINTWIDTH on Dingbats (192 codepoints) ---"
found& = 0
t1#    = TIMER(.001)
FOR cp& = &H2700& TO &H27BF&
    utf32str$ = MKL$(cp&)
    pw&       = _UPRINTWIDTH(utf32str$, 32, fHandle&)
    IF pw& > 0 THEN found& = found& + 1
NEXT cp&
t2# = TIMER(.001)
PRINT "  Found:"; found&; " with width > 0"
PRINT "  Time:"; USING "##.### sec"; t2# - t1#
PRINT

' ================================================================
' TEST 3: Render+ink scan on 100 PUA codepoints for comparison
' ================================================================
PRINT "--- TEST 3: Render+ink on 100 PUA codepoints ---"
DIM scanImg AS LONG, scanMem AS _MEM
DIM byteOff AS LONG, pixel AS _UNSIGNED LONG
DIM hasInk  AS INTEGER, imgBytes AS LONG
DIM oldDest AS LONG, prevFont AS LONG

scanImg&  = _NEWIMAGE(64, 32, 32)
imgBytes& = 64& * 32& * 4&
found&    = 0
t1#       = TIMER(.001)
FOR cp& = &HE900& TO &HE963&
    utf32str$ = MKL$(cp&)
    oldDest&  = _DEST
    _DEST scanImg&
    CLS , _RGBA32(0, 0, 0, 0)
    prevFont& = _FONT
    _FONT fHandle&
    COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
    _UPRINTSTRING (0, 0), utf32str$, 0, 32
    _FONT prevFont&
    _DEST oldDest&

    scanMem = _MEMIMAGE(scanImg&)
    hasInk% = FALSE
    FOR byteOff& = 0 TO imgBytes& - 4 STEP 4
        _MEMGET scanMem, scanMem.OFFSET + byteOff&, pixel~&
        IF _ALPHA32(pixel~&) > 0 THEN
            hasInk% = TRUE
            EXIT FOR
        END IF
    NEXT byteOff&
    _MEMFREE scanMem

    IF hasInk% THEN found& = found& + 1
NEXT cp&
t2# = TIMER(.001)
IF scanImg& < -1 THEN _FREEIMAGE scanImg&
PRINT "  Found:"; found&; " with ink (out of 100)"
PRINT "  Time:"; USING "##.### sec"; t2# - t1#
PRINT

' ================================================================
' TEST 4: Show if _UPRINTWIDTH can distinguish real vs missing glyphs
'         Compare width=0 count vs ink count on same 100 cp range
' ================================================================
PRINT "--- TEST 4: Width vs Ink comparison (E900..E963) ---"
DIM widthFound AS LONG, inkFound AS LONG
DIM widthZero  AS LONG
scanImg&    = _NEWIMAGE(64, 32, 32)
imgBytes&   = 64& * 32& * 4&
widthFound& = 0: inkFound& = 0: widthZero& = 0
FOR cp& = &HE900& TO &HE963&
    utf32str$ = MKL$(cp&)

    ' Width test
    pw& = _UPRINTWIDTH(utf32str$, 32, fHandle&)
    IF pw& > 0 THEN
        widthFound& = widthFound& + 1
    ELSE
        widthZero& = widthZero& + 1
    END IF

    ' Ink test
    oldDest& = _DEST
    _DEST scanImg&
    CLS , _RGBA32(0, 0, 0, 0)
    prevFont& = _FONT
    _FONT fHandle&
    COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
    _UPRINTSTRING (0, 0), utf32str$, 0, 32
    _FONT prevFont&
    _DEST oldDest&

    scanMem = _MEMIMAGE(scanImg&)
    hasInk% = FALSE
    FOR byteOff& = 0 TO imgBytes& - 4 STEP 4
        _MEMGET scanMem, scanMem.OFFSET + byteOff&, pixel~&
        IF _ALPHA32(pixel~&) > 0 THEN
            hasInk% = TRUE
            EXIT FOR
        END IF
    NEXT byteOff&
    _MEMFREE scanMem
    IF hasInk% THEN inkFound& = inkFound& + 1
NEXT cp&
IF scanImg& < -1 THEN _FREEIMAGE scanImg&
PRINT "  _UPRINTWIDTH > 0:"; widthFound&
PRINT "  _UPRINTWIDTH = 0:"; widthZero&
PRINT "  Ink found:       "; inkFound&
PRINT "  Match:"; (widthFound& = inkFound&)
PRINT

' ================================================================
' TEST 5: Render a few PUA icons to screen as visual proof
' ================================================================
PRINT "--- TEST 5: Render first 16 PUA icons ---"
DIM renderY AS INTEGER
renderY% = CSRLIN * _UFONTHEIGHT(16) + 8
_FONT fHandle&
COLOR _RGB32(0, 255, 128)
DIM ri      AS INTEGER
FOR ri% = 0 TO 15
    cp&       = &HE900& + ri%
    utf32str$ = MKL$(cp&)
    _UPRINTSTRING (10 + ri% * 30, renderY%), utf32str$, 0, 32
NEXT ri%
_FONT 16

PRINT
PRINT
PRINT "=== DONE ==="

_DISPLAY
_SAVEIMAGE "/home/grymmjack/git/DRAW/DEV/unicode-scan-test.png"
_DELAY 0.5
_FONT 16
_FREEFONT fHandle&
SYSTEM
