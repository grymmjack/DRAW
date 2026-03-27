OPTION _EXPLICIT
' Test: check what QB64-PE renders for Apple ][ font at various sizes
' Compares DONTBLEND vs normal (AA) rendering

DIM img AS LONG
img& = _NEWIMAGE(800, 600, 32)
SCREEN img&
_FONT 16

OPEN "test-font-render.txt" FOR OUTPUT AS #1

DIM testSize AS INTEGER
DIM fhAA AS LONG, fhDB AS LONG
DIM pw AS INTEGER, fHeight AS INTEGER
DIM buf AS LONG, bufW AS INTEGER, bufH AS INTEGER
DIM scanX AS INTEGER, scanY AS INTEGER
DIM c AS _UNSIGNED LONG
DIM minY AS INTEGER, maxY AS INTEGER
DIM printY AS INTEGER
DIM oldD AS LONG, oldS AS LONG
DIM si AS INTEGER
DIM sizes(3) AS INTEGER
sizes(0) = 8: sizes(1) = 9: sizes(2) = 12: sizes(3) = 16

DIM mode AS INTEGER
DIM modeLabel AS STRING
DIM fh AS LONG

FOR si% = 0 TO 3
    testSize% = sizes(si%)

    FOR mode% = 0 TO 1
        IF mode% = 0 THEN
            modeLabel$ = "AA (normal)"
            fh& = _LOADFONT("../ASSETS/FONTS/Apple ][.ttf", testSize%, "MONOSPACE")
        ELSE
            modeLabel$ = "DONTBLEND"
            fh& = _LOADFONT("../ASSETS/FONTS/Apple ][.ttf", testSize%, "DONTBLEND, MONOSPACE")
        END IF
        IF fh& <= 0 THEN
            PRINT #1, "FAILED to load at size"; testSize%; " mode: "; modeLabel$
            _CONTINUE
        END IF

        _FONT fh&
        fHeight% = _FONTHEIGHT
        pw% = _PRINTWIDTH("M")
        PRINT #1, "=== Size:"; testSize%; " "; modeLabel$; " _FONTHEIGHT:"; fHeight%; " _PRINTWIDTH(M):"; pw%; " ==="

        ' Render 'A' into buffer and check top rows
        bufW% = pw% * 4
        bufH% = fHeight% * 4
        IF bufW% < 4 THEN bufW% = 4
        IF bufH% < 4 THEN bufH% = 4
        buf& = _NEWIMAGE(bufW%, bufH%, 32)
        oldD& = _DEST
        _DEST buf&
        CLS , _RGBA32(0, 0, 0, 0)
        _DONTBLEND
        _FONT fh&
        COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
        _CONTROLCHR OFF
        printY% = fHeight%
        _PRINTSTRING (pw%, printY%), "A"
        _CONTROLCHR ON
        _BLEND
        _DEST oldD&

        ' Print top 3 and bottom 3 rows of pixels for area where A was drawn
        DIM py AS INTEGER, px AS INTEGER
        DIM rowStr AS STRING
        oldS& = _SOURCE
        _SOURCE buf&
        PRINT #1, "  'A' pixel rows (x="; pw%; " to "; pw% + _PRINTWIDTH("A") - 1; "):"
        FOR py% = printY% TO printY% + fHeight% - 1
            rowStr$ = "    row" + STR$(py% - printY%) + ":"
            FOR px% = pw% TO pw% + pw% - 1
                c~& = POINT(px%, py%)
                IF _ALPHA32(c~&) > 0 THEN
                    rowStr$ = rowStr$ + " " + _TRIM$(STR$(_ALPHA32(c~&)))
                ELSE
                    rowStr$ = rowStr$ + " ."
                END IF
            NEXT px%
            PRINT #1, rowStr$
        NEXT py%
        _SOURCE oldS&

        IF buf& < -1 THEN _FREEIMAGE buf&
        _FONT 16
        IF fh& > 0 THEN _FREEFONT fh&
    NEXT mode%
    PRINT #1, ""
NEXT si%

CLOSE #1
PRINT "Done - see test-font-render.txt"
SYSTEM
