''
' Test: Smart PUA scan — _FONT must be set per-destination!
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST TRUE  = -1
CONST FALSE = 0

DIM fontPath AS STRING
DIM fHandle  AS LONG
DIM cp       AS LONG
DIM scanImg  AS LONG
DIM oldDest  AS LONG
DIM found    AS LONG
DIM t1       AS DOUBLE, t2 AS DOUBLE

SCREEN _NEWIMAGE(800, 800, 32)
CLS , _RGB32(0, 0, 0)
_TITLE "Smart PUA Scan v3"

fontPath$ = "../ASSETS/FONTS/rpgawesome-webfont.ttf"
fHandle&  = _LOADFONT(fontPath$, 16)
IF fHandle& < 1 THEN PRINT "FONT LOAD FAILED": GOTO done

_FONT fHandle&
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT "Font:"; fontPath$; " h="; _UFONTHEIGHT

' Scan buffer — must also set font on this image!
DIM scanSz AS INTEGER: scanSz% = 20
scanImg&                       = _NEWIMAGE(scanSz%, scanSz%, 32)
' SET FONT ON SCAN IMAGE TOO
oldDest& = _DEST: _DEST scanImg&: _FONT fHandle&: _DEST oldDest&

DIM imgBytes AS LONG: imgBytes& = CLng(scanSz%) * CLng(scanSz%) * 4&
DIM scanMem  AS _MEM
DIM byteOff  AS LONG
DIM pixel    AS _UNSIGNED LONG

' Step 1: .notdef hash — use U+FFFD (replacement char, not in icon fonts)
_MAPUNICODE &HFFFD& TO 1
oldDest& = _DEST: _DEST scanImg&
CLS , _RGBA32(0, 0, 0, 0)
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (0, 0), CHR$(1)
_DEST oldDest&
DIM notdefHash AS LONG: notdefHash& = 0
scanMem                             = _MEMIMAGE(scanImg&)
FOR byteOff& = 0 TO imgBytes& - 4 STEP 4
    _MEMGET scanMem, scanMem.OFFSET + byteOff&, pixel~&
    notdefHash& = notdefHash& XOR CLng(_ALPHA32(pixel~&))
    notdefHash& = (notdefHash& * 31&) AND &H7FFFFFFF&
NEXT byteOff&
_MEMFREE scanMem

' Also check if .notdef has ANY ink
DIM notdefHasInk AS INTEGER: notdefHasInk% = FALSE
scanMem                                    = _MEMIMAGE(scanImg&)
FOR byteOff& = 0 TO imgBytes& - 4 STEP 4
    _MEMGET scanMem, scanMem.OFFSET + byteOff&, pixel~&
    IF _ALPHA32(pixel~&) > 0 THEN notdefHasInk% = TRUE: EXIT FOR
NEXT byteOff&
_MEMFREE scanMem

COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT ".notdef hash:"; notdefHash&; " hasInk:"; notdefHasInk%

' Step 2: Scan full PUA with .notdef filtering
DIM foundCPs(0 TO 6400) AS LONG
DIM glyphHash AS LONG
found& = 0
PRINT "Scanning PUA E000..F8FF (6400)...";
t1# = TIMER(.001)
FOR cp& = &HE000& TO &HF8FF&
    _MAPUNICODE cp& TO 1
    oldDest& = _DEST: _DEST scanImg&
    CLS , _RGBA32(0, 0, 0, 0)
    COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
    _PRINTSTRING (0, 0), CHR$(1)
    _DEST oldDest&
    glyphHash& = 0
    scanMem    = _MEMIMAGE(scanImg&)
    FOR byteOff& = 0 TO imgBytes& - 4 STEP 4
        _MEMGET scanMem, scanMem.OFFSET + byteOff&, pixel~&
        glyphHash& = glyphHash& XOR CLng(_ALPHA32(pixel~&))
        glyphHash& = (glyphHash& * 31&) AND &H7FFFFFFF&
    NEXT byteOff&
    _MEMFREE scanMem
    IF glyphHash& <> notdefHash& THEN
        foundCPs(found&) = cp&
        found& = found& + 1
    END IF
NEXT cp&
t2# = TIMER(.001)
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT " found"; found&; "in";
PRINT USING " ##.## sec"; t2# - t1#
IF found& > 0 THEN
    DIM li AS LONG: li& = found& - 1
    PRINT "  Range: U+"; HEX$(foundCPs(0)); "..U+"; HEX$(foundCPs(li&))
END IF

' Step 3: Render grid of discovered glyphs
PRINT
PRINT "Discovered glyphs:"
DIM renderY   AS INTEGER
renderY%                             = CSRLIN * _UFONTHEIGHT + 4
DIM showCount AS INTEGER: showCount% = found&
IF showCount% > 160 THEN showCount% = 160
DIM gx        AS INTEGER, gy AS INTEGER, gi AS INTEGER
gi% = 0
FOR gy% = 0 TO 9
    FOR gx% = 0 TO 15
        IF gi% < showCount% THEN
            _MAPUNICODE foundCPs(gi%) TO 1
            COLOR _RGB32(0, 255, 128)
            _PRINTSTRING (10 + gx% * 24, renderY% + gy% * 24), CHR$(1)
            gi% = gi% + 1
        END IF
    NEXT gx%
NEXT gy%

_MAPUNICODE 1 TO 1
_FONT 16
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
LOCATE (renderY% + 260) \ 16, 1
PRINT "=== DONE ==="

done:
_DISPLAY
IF scanImg& < -1 THEN _FREEIMAGE scanImg&
_SAVEIMAGE "/home/grymmjack/git/DRAW/DEV/unicode-smartscan-test.png"
_DELAY 0.5
IF fHandle& > = 1 THEN _FONT 16: _FREEFONT fHandle&
SYSTEM
