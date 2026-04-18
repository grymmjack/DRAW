''
' Test: Different approaches to render PUA icon font glyphs
' The UTF-32 MKL$ approach produces no ink. Try alternatives.
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST TRUE  = -1
CONST FALSE = 0

DIM fontPath AS STRING
DIM fHandle  AS LONG
DIM cp       AS LONG
DIM renderY  AS INTEGER

SCREEN _NEWIMAGE(800, 700, 32)
CLS , _RGB32(0, 0, 0)
_TITLE "Unicode Render Methods Test"

fontPath$ = "../ASSETS/FONTS/rpgawesome-webfont.ttf"
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT "Font: "; fontPath$

fHandle& = _LOADFONT(fontPath$, 32)
IF fHandle& < 1 THEN
    PRINT "ERROR: Font failed to load"
    GOTO done
END IF
PRINT "Font handle:"; fHandle&; " UFontHeight:"; _UFONTHEIGHT(fHandle&)
PRINT

' === Helper: convert codepoint to UTF-8 string ===
' U+E900 is in range 0800-FFFF = 3 bytes
'   byte1 = 0xE0 | (cp >> 12)
'   byte2 = 0x80 | ((cp >> 6) AND 0x3F)
'   byte3 = 0x80 | (cp AND 0x3F)

DIM utf8str  AS STRING
DIM utf32str AS STRING
DIM b1       AS INTEGER, b2 AS INTEGER, b3 AS INTEGER

cp& = &HE900&

' Build UTF-8
b1%       = &HE0& OR (cp& \ 4096)
b2%       = &H80& OR ((cp& \ 64) AND &H3F&)
b3%       = &H80& OR (cp& AND &H3F&)
utf8str$  = CHR$(b1%) + CHR$(b2%) + CHR$(b3%)
utf32str$ = MKL$(cp&)

PRINT "Codepoint: U+"; HEX$(cp&); " ("; cp&; ")"
PRINT "UTF-32 bytes:"; LEN(utf32str$); " = ";
DIM bi AS INTEGER
FOR bi% = 1 TO LEN(utf32str$)
    PRINT HEX$(ASC(utf32str$, bi%)); " ";
NEXT bi%
PRINT
PRINT "UTF-8  bytes:"; LEN(utf8str$); "  = ";
FOR bi% = 1 TO LEN(utf8str$)
    PRINT HEX$(ASC(utf8str$, bi%)); " ";
NEXT bi%
PRINT
PRINT

' ================================================================
' METHOD 1: _UPRINTSTRING with UTF-32 (current broken approach)
' ================================================================
renderY% = CSRLIN * 16 + 4
PRINT "Method 1: _UPRINTSTRING utf32str$, 0, 32"
renderY% = CSRLIN * 16 + 4
_FONT fHandle&
COLOR _RGB32(0, 255, 128)
DIM ri AS INTEGER
FOR ri% = 0 TO 9
    cp&       = &HE900& + ri%
    utf32str$ = MKL$(cp&)
    _UPRINTSTRING (10 + ri% * 40, renderY%), utf32str$, 0, 32
NEXT ri%
_FONT 16
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT
PRINT

' ================================================================
' METHOD 2: _UPRINTSTRING with UTF-8
' ================================================================
PRINT "Method 2: _UPRINTSTRING utf8str$, 0, 8"
renderY% = CSRLIN * 16 + 4
_FONT fHandle&
COLOR _RGB32(0, 255, 128)
FOR ri% = 0 TO 9
    cp&      = &HE900& + ri%
    b1%      = &HE0& OR (cp& \ 4096)
    b2%      = &H80& OR ((cp& \ 64) AND &H3F&)
    b3%      = &H80& OR (cp& AND &H3F&)
    utf8str$ = CHR$(b1%) + CHR$(b2%) + CHR$(b3%)
    _UPRINTSTRING (10 + ri% * 40, renderY%), utf8str$, 0, 8
NEXT ri%
_FONT 16
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT
PRINT

' ================================================================
' METHOD 3: _UPRINTSTRING with UTF-32 + explicit fontHandle param
' ================================================================
PRINT "Method 3: _UPRINTSTRING utf32str$, 0, 32, fHandle&"
renderY% = CSRLIN * 16 + 4
COLOR _RGB32(0, 255, 128)
FOR ri% = 0 TO 9
    cp&       = &HE900& + ri%
    utf32str$ = MKL$(cp&)
    _UPRINTSTRING (10 + ri% * 40, renderY%), utf32str$, 0, 32, fHandle&
NEXT ri%
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT
PRINT

' ================================================================
' METHOD 4: _UPRINTSTRING with UTF-8 + explicit fontHandle param
' ================================================================
PRINT "Method 4: _UPRINTSTRING utf8str$, 0, 8, fHandle&"
renderY% = CSRLIN * 16 + 4
COLOR _RGB32(0, 255, 128)
FOR ri% = 0 TO 9
    cp&      = &HE900& + ri%
    b1%      = &HE0& OR (cp& \ 4096)
    b2%      = &H80& OR ((cp& \ 64) AND &H3F&)
    b3%      = &H80& OR (cp& AND &H3F&)
    utf8str$ = CHR$(b1%) + CHR$(b2%) + CHR$(b3%)
    _UPRINTSTRING (10 + ri% * 40, renderY%), utf8str$, 0, 8, fHandle&
NEXT ri%
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT
PRINT

' ================================================================
' METHOD 5: _UPRINTSTRING with default encoding (0 = ASCII/CP437)
'           Pass raw MKL$ — probably won't work but let's see
' ================================================================
PRINT "Method 5: _UPRINTSTRING utf32str$  (no encoding param)"
renderY% = CSRLIN * 16 + 4
_FONT fHandle&
COLOR _RGB32(0, 255, 128)
FOR ri% = 0 TO 9
    cp&       = &HE900& + ri%
    utf32str$ = MKL$(cp&)
    _UPRINTSTRING (10 + ri% * 40, renderY%), utf32str$
NEXT ri%
_FONT 16
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT
PRINT

' ================================================================
' METHOD 6: Try loading font with "DONTBLEND" option
' ================================================================
DIM fHandle2 AS LONG
fHandle2& = _LOADFONT(fontPath$, 32, "DONTBLEND")
IF fHandle2& > = 1 THEN
    PRINT "Method 6: _LOADFONT with DONTBLEND, utf8 encoding=8"
    renderY% = CSRLIN * 16 + 4
    _FONT fHandle2&
    COLOR _RGB32(0, 255, 128)
    FOR ri% = 0 TO 9
        cp&      = &HE900& + ri%
        b1%      = &HE0& OR (cp& \ 4096)
        b2%      = &H80& OR ((cp& \ 64) AND &H3F&)
        b3%      = &H80& OR (cp& AND &H3F&)
        utf8str$ = CHR$(b1%) + CHR$(b2%) + CHR$(b3%)
        _UPRINTSTRING (10 + ri% * 40, renderY%), utf8str$, 0, 8
    NEXT ri%
    _FONT 16
    _FREEFONT fHandle2&
ELSE
    PRINT "Method 6: DONTBLEND font load FAILED"
END IF
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT
PRINT

' ================================================================
' METHOD 7: _UPRINTSTRING with UTF-32, encoding = 256 (literal UTF-32LE?)
' ================================================================
PRINT "Method 7: _UPRINTSTRING utf32str$, 0, 256"
renderY% = CSRLIN * 16 + 4
_FONT fHandle&
COLOR _RGB32(0, 255, 128)
FOR ri% = 0 TO 9
    cp&       = &HE900& + ri%
    utf32str$ = MKL$(cp&)
    _UPRINTSTRING (10 + ri% * 40, renderY%), utf32str$, 0, 256
NEXT ri%
_FONT 16
COLOR _RGB32(255, 255, 0), _RGB32(0, 0, 0)
PRINT
PRINT

' ================================================================
' METHOD 8: Ink detection using UTF-8 + render to offscreen
' ================================================================
PRINT "Method 8: Ink test - UTF-8 render to offscreen buffer"
DIM scanImg  AS LONG, scanMem AS _MEM
DIM byteOff  AS LONG, pixel AS _UNSIGNED LONG
DIM hasInk   AS INTEGER, imgBytes AS LONG
DIM oldDest  AS LONG, prevFont AS LONG
DIM inkCount AS LONG, noInkCount AS LONG

scanImg&  = _NEWIMAGE(64, 48, 32)
imgBytes& = 64& * 48& * 4&
inkCount& = 0: noInkCount& = 0

FOR ri% = 0 TO 19
    cp&      = &HE900& + ri%
    b1%      = &HE0& OR (cp& \ 4096)
    b2%      = &H80& OR ((cp& \ 64) AND &H3F&)
    b3%      = &H80& OR (cp& AND &H3F&)
    utf8str$ = CHR$(b1%) + CHR$(b2%) + CHR$(b3%)

    oldDest& = _DEST
    _DEST scanImg&
    CLS , _RGBA32(0, 0, 0, 0)
    prevFont& = _FONT
    _FONT fHandle&
    COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
    _UPRINTSTRING (0, 0), utf8str$, 0, 8
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
        inkCount& = inkCount& + 1
    ELSE
        noInkCount& = noInkCount& + 1
    END IF
NEXT ri%
IF scanImg& < -1 THEN _FREEIMAGE scanImg&
PRINT "  UTF-8 ink found:"; inkCount&; " no ink:"; noInkCount&; " (out of 20)"
PRINT

PRINT "=== DONE ==="

done:
_DISPLAY
_SAVEIMAGE "/home/grymmjack/git/DRAW/DEV/unicode-render-test.png"
_DELAY 0.5
IF fHandle& > = 1 THEN
    _FONT 16
    _FREEFONT fHandle&
END IF
SYSTEM
