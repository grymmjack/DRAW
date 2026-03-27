''
' Test: Unicode charmap scanning + rendering
' Mimics what CHARMAP_scan_unicode_glyphs and CHARMAP_rebuild_cache do
' to diagnose why the charmap shows nothing with icon fonts.
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST TRUE = -1
CONST FALSE = 0

DIM fontPath AS STRING
DIM fHandle AS LONG
DIM charH AS INTEGER
DIM scanW AS INTEGER, scanH AS INTEGER
DIM scanImg AS LONG
DIM imgBytes AS LONG
DIM cp AS LONG
DIM utf32str AS STRING
DIM oldDest AS LONG
DIM prevFont AS LONG
DIM scanMem AS _MEM
DIM byteOff AS LONG
DIM pixel AS _UNSIGNED LONG
DIM hasInk AS INTEGER
DIM foundCount AS LONG
DIM firstFound AS LONG
DIM i AS INTEGER

SCREEN _NEWIMAGE(800, 600, 32)
_TITLE "Unicode Charmap Test"

fontPath$ = "../ASSETS/FONTS/rpgawesome-webfont.ttf"
PRINT "Loading font: "; fontPath$

' Test multiple sizes
DIM testSizes(1 TO 4) AS INTEGER
testSizes(1) = 16
testSizes(2) = 24
testSizes(3) = 32
testSizes(4) = 48

DIM sz AS INTEGER
FOR sz% = 1 TO 4
    PRINT
    PRINT "=== Testing size:"; testSizes(sz%); "==="

    fHandle& = _LOADFONT(fontPath$, testSizes(sz%))
    IF fHandle& < 1 THEN
        PRINT "ERROR: Failed to load font at size"; testSizes(sz%)
        _CONTINUE
    END IF
    PRINT "Font handle:"; fHandle&

    ' Get font height
    DIM tmpI AS LONG
    tmpI& = _NEWIMAGE(1, 1, 32)
    oldDest& = _DEST: _DEST tmpI&
    prevFont& = _FONT: _FONT fHandle&
    charH% = _UFONTHEIGHT
    _FONT prevFont&: _DEST oldDest&
    IF tmpI& < -1 THEN _FREEIMAGE tmpI&
    PRINT "UFontHeight:"; charH%

    ' Create scan buffer
    scanW% = charH% * 2
    scanH% = charH% + 4
    IF scanW% > 128 THEN scanW% = 128
    IF scanH% > 128 THEN scanH% = 128
    PRINT "Scan buffer:"; scanW%; "x"; scanH%

    scanImg& = _NEWIMAGE(scanW%, scanH%, 32)
    IF scanImg& >= -1 THEN
        PRINT "ERROR: Failed to create scan image"
        _FREEFONT fHandle&
        _CONTINUE
    END IF
    imgBytes& = CLng(scanW%) * CLng(scanH%) * 4

    ' Test _UPRINTWIDTH for a few PUA codepoints
    PRINT "Testing _UPRINTWIDTH for PUA codepoints:"
    FOR i% = 0 TO 4
        cp& = &HE900 + i%
        utf32str$ = MKL$(cp&)
        DIM pw AS LONG
        pw& = _UPRINTWIDTH(utf32str$, 32, fHandle&)
        PRINT "  U+"; HEX$(cp&); " _UPRINTWIDTH ="; pw&
    NEXT i%

    ' Test rendering with _UPRINTSTRING + UTF-32
    PRINT "Testing render of U+E900:"
    utf32str$ = MKL$(&HE900)

    oldDest& = _DEST
    _DEST scanImg&
    CLS , _RGBA32(0, 0, 0, 0)
    prevFont& = _FONT
    _FONT fHandle&
    COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
    _UPRINTSTRING (0, 0), utf32str$, 0, 32
    _FONT prevFont&
    _DEST oldDest&

    ' Check for ink
    scanMem = _MEMIMAGE(scanImg&)
    hasInk% = FALSE
    DIM inkPixels AS LONG
    inkPixels& = 0
    FOR byteOff& = 0 TO imgBytes& - 4 STEP 4
        _MEMGET scanMem, scanMem.OFFSET + byteOff&, pixel~&
        IF _ALPHA32(pixel~&) > 0 THEN
            hasInk% = TRUE
            inkPixels& = inkPixels& + 1
        END IF
    NEXT byteOff&
    _MEMFREE scanMem
    PRINT "  hasInk ="; hasInk%; " inkPixels ="; inkPixels&

    ' Also test rendering directly to screen
    PRINT "Rendering 10 PUA icons to screen at y="; CSRLIN * 16; ":"
    DIM screenY AS INTEGER
    screenY% = CSRLIN * 16 + 20
    _FONT fHandle&
    COLOR _RGB32(255, 255, 0)
    FOR i% = 0 TO 9
        cp& = &HE900 + i%
        utf32str$ = MKL$(cp&)
        _UPRINTSTRING (10 + i% * 40, screenY%), utf32str$, 0, 32
    NEXT i%
    _FONT 16

    ' Also test rendering with explicit fontHandle parameter
    PRINT
    PRINT "Rendering with explicit fontHandle param:"
    DIM screenY2 AS INTEGER
    screenY2% = screenY% + charH% + 10
    FOR i% = 0 TO 9
        cp& = &HE900 + i%
        utf32str$ = MKL$(cp&)
        _UPRINTSTRING (10 + i% * 40, screenY2%), utf32str$, 0, 32, fHandle&
    NEXT i%
    PRINT "  (rendered at y="; screenY2%; ")"

    ' Quick scan: count PUA codepoints with ink (first 100 only)
    foundCount& = 0
    firstFound& = -1
    PRINT
    PRINT "Quick PUA scan (E900..E963)..."
    FOR cp& = &HE900 TO &HE963
        utf32str$ = MKL$(cp&)
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

        IF hasInk% THEN
            foundCount& = foundCount& + 1
            IF firstFound& < 0 THEN firstFound& = cp&
        END IF
    NEXT cp&
    PRINT "  Found"; foundCount&; "glyphs with ink"
    IF firstFound& >= 0 THEN PRINT "  First at U+"; HEX$(firstFound&)

    IF scanImg& < -1 THEN _FREEIMAGE scanImg&
    _FONT 16
    _FREEFONT fHandle&
NEXT sz%

PRINT
PRINT "=== TEST COMPLETE ==="
_DISPLAY
_SAVEIMAGE "/home/grymmjack/git/DRAW/DEV/unicode-charmap-test.png"
_DELAY 0.5
SYSTEM
