'
' font-test3.bas — Workaround for QB64-PE font clipping bug
'
' ROOT CAUSE: _PRINTSTRING uses FontRenderTextUTF32() which allocates a
' render buffer of exactly `defaultHeight` (ppem) pixels. Fonts whose
' ascender-descender span exceeds unitsPerEm (like dp-tuxedo.ttf) have
' glyphs that extend above the buffer, causing hard clipping.
'
' WORKAROUND: _UPRINTSTRING uses sub__UPrintString() which correctly
' calculates the buffer height as (ascender-descender)/unitsPerEm * ppem.
' Use _UFONTHEIGHT instead of _FONTHEIGHT for the true pixel height.
'
' This test shows _PRINTSTRING (LEFT, clipped) vs _UPRINTSTRING (RIGHT, fixed).
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

CONST FP$       = "../ASSETS/FONTS/dp-tuxedo.ttf"
CONST TEST_STR$ = "ABCDEFGHIJKLM"

SCREEN _NEWIMAGE(1280, 900, 32)
_TITLE "Font Clipping Workaround: _PRINTSTRING (left) vs _UPRINTSTRING (right)"
CLS , _RGB32(32, 32, 32)

DIM sizes(0 TO 7) AS INTEGER
sizes(0) = 12 : sizes(1) = 16 : sizes(2) = 20 : sizes(3) = 24 
sizes(4) = 28 : sizes(5) = 32 : sizes(6) = 48 : sizes(7) = 64

DIM y     AS INTEGER
DIM i     AS INTEGER
DIM sz    AS INTEGER
DIM fh    AS LONG
DIM oldH  AS INTEGER
DIM newH  AS INTEGER
DIM label AS STRING

' Column headers
_FONT 16
COLOR _RGB32(255, 200, 0), _RGB32(32, 32, 32)
_PRINTSTRING (20, 4), "_PRINTSTRING (CLIPPED)"
_PRINTSTRING (660, 4), "_UPRINTSTRING (FIXED)"

' Draw divider
LINE (640, 0)-(640, 899), _RGB32(100, 100, 100)

y% = 30

FOR i% = 0 TO 7
    sz% = sizes(i%)

    fh& = _LOADFONT(FP$, sz%, "DONTBLEND")
    IF fh& < = 0 THEN
        _FONT 16
        COLOR _RGB32(255, 80, 80), _RGB32(32, 32, 32)
        _PRINTSTRING (20, y%), "SIZE " + LTRIM$(STR$(sz%)) + ": FAILED"
        y% = y% + 20
        _CONTINUE
    END IF

    _FONT fh&
    oldH% = _FONTHEIGHT
    newH% = _UFONTHEIGHT

    ' --- Label row (VGA font) ---
    _FONT 16
    COLOR _RGB32(128, 128, 128), _RGB32(32, 32, 32)
    label$ = LTRIM$(STR$(sz%)) + "pt _FONTHEIGHT=" + LTRIM$(STR$(oldH%)) + " _UFONTHEIGHT=" + LTRIM$(STR$(newH%))
    _PRINTSTRING (20, y%), label$
    _PRINTSTRING (660, y%), label$
    y% = y% + 18

    ' --- LEFT column: _PRINTSTRING (buggy, clips) ---
    _FONT fh&
    COLOR _RGB32(255, 255, 255), _RGB32(32, 32, 32)
    _PRINTSTRING (20, y%), TEST_STR$

    ' --- RIGHT column: _UPRINTSTRING (correct, no clipping) ---
    _UPRINTSTRING (660, y%), TEST_STR$

    ' Draw reference lines showing the ppem boundary
    LINE (20, y% + oldH%)-(620, y% + oldH%), _RGB32(255, 60, 60)   ' red   = ppem height
    LINE (660, y% + newH%)-(1260, y% + newH%), _RGB32(60, 255, 60) ' green = true height

    ' Advance Y by the larger height + padding
    DIM advY AS INTEGER
    IF newH% > oldH% THEN advY% = newH% ELSE advY% = oldH%
    _FONT 16
    _FREEFONT fh&
    y% = y% + advY% + 8

    IF y% > 860 THEN EXIT FOR
NEXT i%

' Legend
_FONT 16
COLOR _RGB32(255, 60, 60), _RGB32(32, 32, 32)
_PRINTSTRING (20, y% + 4), "--- Red line = _FONTHEIGHT (ppem, wrong)"
COLOR _RGB32(60, 255, 60), _RGB32(32, 32, 32)
_PRINTSTRING (20, y% + 22), "--- Green line = _UFONTHEIGHT (true height, correct)"

_DISPLAY

' Save screenshot
DIM ssImg AS LONG
ssImg& = _COPYIMAGE(0, 32)
IF ssImg& < -1 THEN
    _SAVEIMAGE "./font-test3-output.png", ssImg&
    _FREEIMAGE ssImg&
    _LOGINFO "Saved DEV/font-test3-output.png"
END IF

DO
    IF _KEYHIT THEN EXIT DO
    IF _EXIT THEN EXIT DO
    _LIMIT 30
LOOP
SYSTEM
