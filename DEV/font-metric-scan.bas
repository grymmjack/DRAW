''
' Font Metric Scanner — loads every TTF/OTF/TTC/FON in ASSETS/FONTS and
' reports fonts with bad metrics (zero height, crash on load, negative
' _UPRINTWIDTH, render ink mismatch, etc.)
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST TRUE = -1
CONST FALSE = 0

DIM SHARED scanImg AS LONG
DIM SHARED outFile AS INTEGER

SCREEN _NEWIMAGE(1024, 768, 32)
_TITLE "Font Metric Scanner"
CLS , _RGB32(0, 0, 0)
COLOR _RGB32(0, 255, 128), _RGB32(0, 0, 0)

' Create scan buffer
scanImg& = _NEWIMAGE(200, 80, 32)

' Open results file
outFile% = FREEFILE
OPEN "../DEV/font-metric-results.txt" FOR OUTPUT AS #outFile%

' Get font list via find
DIM tmpFile AS STRING
tmpFile$ = "../DEV/_font_scan_tmp.txt"
SHELL "find ../ASSETS/FONTS -type f \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' -o -iname '*.fon' \) 2>/dev/null | sort > " + CHR$(34) + tmpFile$ + CHR$(34)

DIM ff AS INTEGER
DIM fontPath AS STRING
DIM fontCount AS INTEGER
DIM badCount AS INTEGER
DIM fonCount AS INTEGER
fontCount% = 0
badCount% = 0
fonCount% = 0

ff% = FREEFILE
OPEN tmpFile$ FOR INPUT AS #ff%
DO WHILE NOT EOF(ff%)
    LINE INPUT #ff%, fontPath$
    fontPath$ = LTRIM$(RTRIM$(fontPath$))
    IF LEN(fontPath$) = 0 THEN _CONTINUE
    fontCount% = fontCount% + 1

    IF UCASE$(RIGHT$(fontPath$, 4)) = ".FON" THEN fonCount% = fonCount% + 1

    DIM testSize AS INTEGER
    DIM fHandle AS LONG
    DIM fHeight AS INTEGER
    DIM testW AS INTEGER
    DIM hasInk AS INTEGER
    DIM oldDest AS LONG
    DIM prevFont AS LONG
    DIM scanMem AS _MEM
    DIM byteOff AS LONG
    DIM pixel AS _UNSIGNED LONG
    DIM imgBytes AS LONG
    DIM problems AS STRING
    DIM baseName AS STRING

    ' Extract base name
    DIM slashPos AS INTEGER
    slashPos% = _INSTRREV(fontPath$, "/")
    IF slashPos% > 0 THEN
        baseName$ = MID$(fontPath$, slashPos% + 1)
    ELSE
        baseName$ = fontPath$
    END IF

    problems$ = ""

    ' Test at sizes 8, 10, 12, 16, 20, 24
    DIM sizes(0 TO 5) AS INTEGER
    sizes(0) = 8: sizes(1) = 10: sizes(2) = 12
    sizes(3) = 16: sizes(4) = 20: sizes(5) = 24
    DIM si AS INTEGER
    FOR si% = 0 TO 5
        testSize% = sizes(si%)
        fHandle& = _LOADFONT(fontPath$, testSize%)
        IF fHandle& < 1 THEN
            problems$ = problems$ + " LOAD_FAIL@" + _TRIM$(STR$(testSize%))
            _CONTINUE
        END IF

        ' Check font height
        oldDest& = _DEST: _DEST scanImg&
        prevFont& = _FONT: _FONT fHandle&
        fHeight% = _UFONTHEIGHT
        IF fHeight% < 1 THEN
            problems$ = problems$ + " HEIGHT=0@" + _TRIM$(STR$(testSize%))
        END IF
        IF fHeight% > testSize% * 3 THEN
            problems$ = problems$ + " HEIGHT_HUGE=" + _TRIM$(STR$(fHeight%)) + "@" + _TRIM$(STR$(testSize%))
        END IF

        ' Check _PRINTWIDTH for "A" (set font first, use _PRINTWIDTH not _UPRINTWIDTH)
        testW% = _PRINTWIDTH("A")
        IF testW% < 0 THEN
            problems$ = problems$ + " NEG_WIDTH@" + _TRIM$(STR$(testSize%))
        END IF
        IF testW% = 0 THEN
            problems$ = problems$ + " ZERO_WIDTH@" + _TRIM$(STR$(testSize%))
        END IF

        ' Render test and check for ink
        CLS , _RGBA32(0, 0, 0, 0)
        COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
        _UPRINTSTRING (0, 0), "AZaz09"
        _FONT prevFont&: _DEST oldDest&

        imgBytes& = CLng(_WIDTH(scanImg&)) * CLng(_HEIGHT(scanImg&)) * 4&
        scanMem = _MEMIMAGE(scanImg&)
        hasInk% = FALSE
        FOR byteOff& = 0 TO imgBytes& - 4& STEP 4
            _MEMGET scanMem, scanMem.OFFSET + byteOff&, pixel~&
            IF _ALPHA32(pixel~&) > 0 THEN
                hasInk% = TRUE
                EXIT FOR
            END IF
        NEXT byteOff&
        _MEMFREE scanMem

        IF NOT hasInk% THEN
            problems$ = problems$ + " NO_INK@" + _TRIM$(STR$(testSize%))
        END IF

        _FONT 16
        _FREEFONT fHandle&
    NEXT si%

    ' Report
    IF LEN(problems$) > 0 THEN
        badCount% = badCount% + 1
        DIM msg AS STRING
        msg$ = "BAD: " + baseName$ + " ->" + problems$
        PRINT msg$
        PRINT #outFile%, msg$
    ELSE
        LOCATE , 1
        PRINT "OK:  " + baseName$ + SPACE$(40);
        LOCATE , 1
    END IF
LOOP
CLOSE #ff%

PRINT
PRINT "=== SCAN COMPLETE ==="
PRINT "Total fonts:"; fontCount%
PRINT "Bad fonts:  "; badCount%
PRINT ".FON files: "; fonCount%

PRINT #outFile%, ""
PRINT #outFile%, "=== SCAN COMPLETE ==="
PRINT #outFile%, "Total fonts:" + STR$(fontCount%)
PRINT #outFile%, "Bad fonts:  " + STR$(badCount%)
PRINT #outFile%, ".FON files: " + STR$(fonCount%)
CLOSE #outFile%

IF scanImg& < -1 THEN _FREEIMAGE scanImg&
IF _FILEEXISTS(tmpFile$) THEN KILL tmpFile$

_DISPLAY
PRINT "Results saved to DEV/font-metric-results.txt"
PRINT "Press any key..."
_DELAY 0.5
SLEEP
SYSTEM
