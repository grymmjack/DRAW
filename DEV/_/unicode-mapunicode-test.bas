''
' Test: _MAPUNICODE approach for PUA icon font rendering
' Maps Unicode codepoints to ASCII slots, then uses _PRINTSTRING
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST TRUE  = -1
CONST FALSE = 0

DIM fontPath AS STRING
DIM fHandle  AS LONG
DIM cp       AS LONG
DIM renderY  AS INTEGER
DIM ri       AS INTEGER

SCREEN _NEWIMAGE(800, 600, 32)
CLS , _RGB32(0, 0, 0)
_TITLE "MAPUNICODE Test"

fontPath$ = "../ASSETS/FONTS/rpgawesome-webfont.ttf"
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT "Font: "; fontPath$

fHandle& = _LOADFONT(fontPath$, 48)
IF fHandle& < 1 THEN
    PRINT "ERROR: Font failed to load"
    GOTO done
END IF
PRINT "Font handle:"; fHandle&

' Set the font active
_FONT fHandle&
PRINT "Active font UFontHeight:"; _UFONTHEIGHT

' ================================================================
' METHOD A: _MAPUNICODE U+E900..E90F to ASCII slots 65-80 (A-P)
'           then render with _PRINTSTRING / PRINT CHR$()
' ================================================================
PRINT
PRINT "--- Method A: _MAPUNICODE PUA -> ASCII slots, then PRINT ---"

' Map 16 PUA codepoints to ASCII 65-80
FOR ri% = 0 TO 15
    cp& = &HE900& + ri%
    _MAPUNICODE cp& TO 65 + ri%
NEXT ri%

' Now print CHR$(65) through CHR$(80) which should render PUA icons
renderY% = CSRLIN * _UFONTHEIGHT + 8
COLOR _RGB32(0, 255, 128)
FOR ri% = 0 TO 15
    _PRINTSTRING (10 + ri% * 48, renderY%), CHR$(65 + ri%)
NEXT ri%
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
_FONT 16
PRINT
PRINT
PRINT "  (16 icons should appear above)"
PRINT

' ================================================================
' METHOD B: _MAPUNICODE then check ink on offscreen buffer
' ================================================================
_FONT fHandle&
PRINT "--- Method B: _MAPUNICODE + ink detection ---"
DIM scanImg  AS LONG, scanMem AS _MEM
DIM byteOff  AS LONG, pixel AS _UNSIGNED LONG
DIM hasInk   AS INTEGER, imgBytes AS LONG
DIM oldDest  AS LONG, prevFont AS LONG
DIM inkCount AS LONG

scanImg&  = _NEWIMAGE(64, 64, 32)
imgBytes& = 64& * 64& * 4&
inkCount& = 0

FOR ri% = 0 TO 19
    cp& = &HE900& + ri%
    ' Map this codepoint to ASCII slot 1
    _MAPUNICODE cp& TO 1

    oldDest& = _DEST
    _DEST scanImg&
    CLS , _RGBA32(0, 0, 0, 0)
    COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
    _PRINTSTRING (0, 0), CHR$(1)
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

    IF hasInk% THEN inkCount& = inkCount& + 1
NEXT ri%
IF scanImg& < -1 THEN _FREEIMAGE scanImg&
PRINT "  Ink found:"; inkCount&; " out of 20"
PRINT

' ================================================================
' METHOD C: Map a BATCH of 256 PUA codepoints at once, render grid
' ================================================================
PRINT "--- Method C: Full 256-char page of PUA icons ---"

' Map E900-E9FF to ASCII 0-255
FOR ri% = 0 TO 255
    cp& = &HE900& + ri%
    _MAPUNICODE cp& TO ri%
NEXT ri%

' Render a 16x16 grid
renderY% = CSRLIN * _UFONTHEIGHT + 8
COLOR _RGB32(255, 200, 100)
DIM gx AS INTEGER, gy AS INTEGER, charIdx AS INTEGER
charIdx% = 0
FOR gy% = 0 TO 5
    FOR gx% = 0 TO 15
        IF charIdx% < 256 THEN
            _PRINTSTRING (10 + gx% * 48, renderY% + gy% * 50), CHR$(charIdx%)
            charIdx% = charIdx% + 1
        END IF
    NEXT gx%
NEXT gy%

_FONT 16
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT
PRINT
PRINT "=== DONE ==="

done:
_DISPLAY
_SAVEIMAGE "/home/grymmjack/git/DRAW/DEV/unicode-mapunicode-test.png"
_DELAY 0.5
IF fHandle& >= 1 THEN
    _FONT 16
    _FREEFONT fHandle&
END IF
SYSTEM
