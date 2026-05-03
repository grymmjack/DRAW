'
' font-test2.bas — Plain text rendering of dp-tuxedo.ttf at multiple sizes
' No charmap, no grid, no ink-crop. Just _PRINTSTRING on black background.
' Proves whether QB64-PE _PRINTSTRING itself clips the font.
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

CONST FP$       = "../ASSETS/FONTS/dp-tuxedo.ttf"
CONST TEST_STR$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz 0123456789"

SCREEN _NEWIMAGE(1280, 900, 32)
_TITLE "dp-tuxedo.ttf — plain render at multiple sizes"
CLS , _RGB32(0, 0, 0)

DIM y     AS INTEGER
DIM sz    AS INTEGER
DIM fh    AS LONG
DIM label AS STRING
DIM sizes(0 TO 11) AS INTEGER

sizes(0) = 8  : sizes(1) = 10 : sizes(2) = 12  : sizes(3) = 14
sizes(4) = 16 : sizes(5) = 18 : sizes(6) = 20  : sizes(7) = 24
sizes(8) = 28 : sizes(9) = 32 : sizes(10) = 48 : sizes(11) = 64

y% = 4

DIM i AS INTEGER
FOR i% = 0 TO 11
    sz% = sizes(i%)

    ' Load with DONTBLEND (non-AA, like charmap uses)
    fh& = _LOADFONT(FP$, sz%, "DONTBLEND")
    IF fh& <= 0 THEN
        COLOR _RGB32(255, 80, 80), _RGB32(0, 0, 0)
        _FONT 16
        _PRINTSTRING (4, y%), "SIZE " + LTRIM$(STR$(sz%)) + ": FAILED TO LOAD"
        y% = y% + 20
        _CONTINUE
    END IF

    _FONT fh&
    label$ = LTRIM$(STR$(sz%)) + "pt h=" + LTRIM$(STR$(_FONTHEIGHT)) + "px pw(M)=" + LTRIM$(STR$(_PRINTWIDTH("M"))) + "px"

    ' Print label in VGA first
    _FONT 16
    COLOR _RGB32(128, 128, 128), _RGB32(0, 0, 0)
    _PRINTSTRING (4, y%), label$
    y% = y% + 16

    ' Print test string in dp-tuxedo
    _FONT fh&
    COLOR _RGB32(255, 255, 255), _RGB32(0, 0, 0)
    _PRINTSTRING (4, y%), TEST_STR$
    DIM fhHeight AS INTEGER
    fhHeight% = _FONTHEIGHT
    _FONT 16
    _FREEFONT fh&
    y% = y% + fhHeight% + 4

    IF y% > 880 THEN EXIT FOR
NEXT i%

_DISPLAY

' Save screenshot
DIM ssImg AS LONG
ssImg& = _COPYIMAGE(0, 32)
IF ssImg& < -1 THEN
    _SAVEIMAGE "./font-test2-output.png", ssImg&
    _FREEIMAGE ssImg&
    _LOGINFO "Saved DEV/font-test2-output.png"
END IF

' Wait
DO
    IF _KEYHIT THEN EXIT DO
    IF _EXIT THEN EXIT DO
    _LIMIT 30
LOOP
SYSTEM
