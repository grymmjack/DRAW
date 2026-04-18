OPTION _EXPLICIT
' Test: check what QB64-PE actually renders for Apple ][ font
' at various sizes. Saves screenshots for analysis.

DIM img      AS LONG
DIM fh       AS LONG
DIM testSize AS INTEGER
DIM y        AS INTEGER
DIM ch       AS STRING
DIM pw       AS INTEGER, fHeight AS INTEGER
DIM scanX    AS INTEGER, scanY AS INTEGER
DIM c        AS _UNSIGNED LONG
DIM minY     AS INTEGER, maxY AS INTEGER, minX AS INTEGER, maxX AS INTEGER

img& = _NEWIMAGE(800, 600, 32)
SCREEN img&
CLS , _RGB32(0, 0, 0)

y% = 10
COLOR _RGB32(255, 255, 0)
_PRINTSTRING (10, y%), "Apple ][ font rendering test"
y% = y% + 20

' Test sizes 8, 12, 16
DIM sizes(2) AS INTEGER
sizes(0) = 8: sizes(1) = 12: sizes(2) = 16

DIM si AS INTEGER
FOR si% = 0 TO 2
    testSize% = sizes(si%)
    fh&       = _LOADFONT("ASSETS/FONTS/Apple ][.ttf", testSize%, "MONOSPACE")
    IF fh& < = 0 THEN
        COLOR _RGB32(255, 0, 0)
        _PRINTSTRING (10, y%), "FAILED to load at size" + STR$(testSize%)
        y% = y% + 16
        _CONTINUE
    END IF

    _FONT fh&
    fHeight% = _FONTHEIGHT
    pw%      = _PRINTWIDTH("M")

    COLOR _RGB32(255, 255, 255)
    _FONT 16 ' Switch back to default for label
    _PRINTSTRING (10, y%), "Size:" + STR$(testSize%) + " _FONTHEIGHT:" + STR$(fHeight%) + " _PRINTWIDTH(M):" + STR$(pw%)
    y% = y% + 16

    ' Render test string into a large buffer and scan for ink bounds
    DIM bufW   AS INTEGER, bufH AS INTEGER
    bufW% = 400: bufH% = testSize% * 4
    DIM buf    AS LONG
    buf& = _NEWIMAGE(bufW%, bufH%, 32)
    DIM oldD   AS LONG: oldD& = _DEST
    _DEST buf&
    CLS , _RGBA32(0, 0, 0, 0)
    _DONTBLEND
    _FONT fh&
    COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
    ' Print at vertical center of buffer so we can detect overshoot
    DIM printY AS INTEGER
    printY% = bufH% \ 4
    _CONTROLCHR OFF
    _PRINTSTRING (10, printY%), "AjgpWM!#][{}|"
    _CONTROLCHR ON
    _BLEND
    _DEST oldD&

    ' Scan for actual ink bounds
    minY% = bufH%      : maxY% = -1 : minX% = bufW% : maxX% = -1
    DIM oldSrc AS LONG : oldSrc& = _SOURCE
    _SOURCE buf&
    FOR scanY% = 0 TO bufH% - 1
        FOR scanX% = 0 TO bufW% - 1
            c~& = POINT(scanX%, scanY%)
            IF _ALPHA32(c~&) > 0 THEN
                IF scanY% < minY% THEN minY% = scanY%
                IF scanY% > maxY% THEN maxY% = scanY%
                IF scanX% < minX% THEN minX% = scanX%
                IF scanX% > maxX% THEN maxX% = scanX%
            END IF
        NEXT scanX%
    NEXT scanY%
    _SOURCE oldSrc&

    _FONT 16
    COLOR _RGB32(128, 255, 128)
    _PRINTSTRING (10, y%), "  Printed at Y=" + STR$(printY%) + "  Ink Y range:" + STR$(minY%) + " to" + STR$(maxY%)
    y% = y% + 16
    _PRINTSTRING (10, y%), "  Expected Y range:" + STR$(printY%) + " to" + STR$(printY% + fHeight% - 1) + "  Overshoot top:" + STR$(printY% - minY%) + " bottom:" + STR$(maxY% - (printY% + fHeight% - 1))
    y% = y% + 16

    ' Draw the buffer content at current Y position, scaled 2x for visibility
    _PUTIMAGE (10, y%)-(10 + bufW% * 2 - 1, y% + bufH% * 2 - 1), buf&, img&
    y% = y% + bufH% * 2 + 10

    IF buf& < -1 THEN _FREEIMAGE buf&
    IF fh& > 0 THEN _FREEFONT fh&
NEXT si%

_DISPLAY
SLEEP 10
SYSTEM
