''
' Test: Fast PUA glyph scanning using _MAPUNICODE + ink detection
' Benchmark: Can we scan 6400 PUA codepoints in <1 second?
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST TRUE = -1
CONST FALSE = 0

DIM fontPath AS STRING
DIM fHandle AS LONG
DIM cp AS LONG
DIM scanImg AS LONG, scanMem AS _MEM
DIM byteOff AS LONG, pixel AS _UNSIGNED LONG
DIM hasInk AS INTEGER, imgBytes AS LONG
DIM oldDest AS LONG
DIM found AS LONG
DIM t1 AS DOUBLE, t2 AS DOUBLE
DIM ri AS INTEGER

SCREEN _NEWIMAGE(800, 600, 32)
CLS , _RGB32(0, 0, 0)
_TITLE "Fast MAPUNICODE Scan"

fontPath$ = "../ASSETS/FONTS/rpgawesome-webfont.ttf"
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT "Font: "; fontPath$

fHandle& = _LOADFONT(fontPath$, 16)
IF fHandle& < 1 THEN
    PRINT "ERROR: Font failed to load"
    GOTO done
END IF

' Use small scan buffer for speed
DIM scanSz AS INTEGER
scanSz% = 24
scanImg& = _NEWIMAGE(scanSz%, scanSz%, 32)
imgBytes& = CLng(scanSz%) * CLng(scanSz%) * 4&

PRINT "Font handle:"; fHandle&
PRINT "Scan buffer:"; scanSz%; "x"; scanSz%; " ("; imgBytes&; "bytes)"
PRINT

' ================================================================
' SCAN 1: Full PUA E000-F8FF via _MAPUNICODE (6400 codepoints)
' ================================================================
PRINT "--- SCAN: Full PUA E000..F8FF (6400 cps) via _MAPUNICODE ---"
_FONT fHandle&
found& = 0

' Store found codepoints
DIM foundCPs(0 TO 6400) AS LONG
DIM foundMax AS LONG
foundMax& = 6400

t1# = TIMER(.001)
FOR cp& = &HE000& TO &HF8FF&
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

    IF hasInk% THEN
        IF found& <= foundMax& THEN foundCPs(found&) = cp&
        found& = found& + 1
    END IF
NEXT cp&
t2# = TIMER(.001)

PRINT "  Found:"; found&; "glyphs with ink"
PRINT "  Time:"; USING "##.### sec"; t2# - t1#
IF found& > 0 THEN
    PRINT "  First: U+"; HEX$(foundCPs(0))
    DIM lastIdx AS LONG
    lastIdx& = found& - 1
    IF lastIdx& > foundMax& THEN lastIdx& = foundMax&
    IF found& > 1 THEN PRINT "  Last:  U+"; HEX$(foundCPs(lastIdx&))
END IF
PRINT

' ================================================================
' SCAN 2: Just PUA subrange E900-EAFF (rpgawesome known range)
' ================================================================
PRINT "--- SCAN: rpgawesome range E900..EAFF (512 cps) ---"
DIM found2 AS LONG
found2& = 0
t1# = TIMER(.001)
FOR cp& = &HE900& TO &HEAFF&
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

    IF hasInk% THEN found2& = found2& + 1
NEXT cp&
t2# = TIMER(.001)
PRINT "  Found:"; found2&; "glyphs with ink"
PRINT "  Time:"; USING "##.### sec"; t2# - t1#
PRINT

' ================================================================
' VISUAL: Render first 48 found glyphs as a grid
' ================================================================
PRINT "--- Rendering first 48 discovered glyphs ---"
DIM renderY AS INTEGER
renderY% = CSRLIN * 16 + 8
DIM showCount AS INTEGER
showCount% = found&
IF showCount% > 48 THEN showCount% = 48

DIM gx AS INTEGER, gy AS INTEGER, gi AS INTEGER
gi% = 0
FOR gy% = 0 TO 2
    FOR gx% = 0 TO 15
        IF gi% < showCount% THEN
            _MAPUNICODE foundCPs(gi%) TO 1
            COLOR _RGB32(0, 255, 128)
            _PRINTSTRING (10 + gx% * 48, renderY% + gy% * 24), CHR$(1)
            gi% = gi% + 1
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
IF scanImg& < -1 THEN _FREEIMAGE scanImg&
_SAVEIMAGE "/home/grymmjack/git/DRAW/DEV/unicode-fastscan-test.png"
_DELAY 0.5
IF fHandle& >= 1 THEN
    _FONT 16
    _FREEFONT fHandle&
END IF
SYSTEM
