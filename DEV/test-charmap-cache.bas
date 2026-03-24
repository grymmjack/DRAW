OPTION _EXPLICIT
'$DYNAMIC
_SCREENHIDE

' Test: replicate CHARMAP_rebuild_cache glyph rendering conditions
' to find why row 0 is all-zero alpha for Apple ][ font at size 8.

DIM fontPath AS STRING
DIM fHandle AS LONG
DIM charW AS INTEGER, charH AS INTEGER
DIM tmpImg AS LONG, oldDest AS LONG, prevFont AS LONG
DIM measImg AS LONG
DIM ch AS STRING
DIM px AS INTEGER, py AS INTEGER, c AS _UNSIGNED LONG
DIM srcSave AS LONG
DIM F AS INTEGER
DIM r AS STRING

fontPath$ = "/home/grymmjack/git/DRAW/ASSETS/FONTS/Apple ][.ttf"
ch$ = "A"
F% = FREEFILE
OPEN "/home/grymmjack/git/DRAW/DEV/test-charmap-cache-out.txt" FOR OUTPUT AS #F%

' Load font with DONTBLEND, MONOSPACE (same as CHARMAP)
fHandle& = _LOADFONT(fontPath$, 8, "DONTBLEND, MONOSPACE")
IF fHandle& <= 0 THEN
    PRINT #F%, "Failed to load font": CLOSE #F%: SYSTEM
END IF

' --- Measure on 1x1 image (same as CHARMAP) ---
measImg& = _NEWIMAGE(1, 1, 32)
oldDest& = _DEST: _DEST measImg&
prevFont& = _FONT: _FONT fHandle&
_CONTROLCHR OFF
charW% = _PRINTWIDTH(ch$): charH% = _FONTHEIGHT
_CONTROLCHR ON
_FONT prevFont&: _DEST oldDest&: _FREEIMAGE measImg&

PRINT #F%, "Measured: charW=" + _TRIM$(STR$(charW%)) + " charH=" + _TRIM$(STR$(charH%))

' === Test 1: _DONTBLEND on exact-size dest (same as CHARMAP) ===
tmpImg& = _NEWIMAGE(charW%, charH%, 32)
oldDest& = _DEST: _DEST tmpImg&
CLS , _RGBA32(0, 0, 0, 0): _DONTBLEND
prevFont& = _FONT: _FONT fHandle&
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_CONTROLCHR OFF: _PRINTSTRING (0, 0), ch$: _CONTROLCHR ON
_FONT prevFont&: _BLEND: _DEST oldDest&

PRINT #F%, "": PRINT #F%, "=== Test 1: _DONTBLEND on exact-size dest ==="
srcSave& = _SOURCE: _SOURCE tmpImg&
FOR py% = 0 TO charH% - 1
    r$ = "  row" + _TRIM$(STR$(py%)) + ":"
    FOR px% = 0 TO charW% - 1
        c~& = POINT(px%, py%)
        IF _ALPHA32(c~&) > 0 THEN r$ = r$ + " ##" ELSE r$ = r$ + " .."
    NEXT px%
    PRINT #F%, r$
NEXT py%
_SOURCE srcSave&: _FREEIMAGE tmpImg&

' === Test 2: _BLEND on exact-size dest (no _DONTBLEND) ===
tmpImg& = _NEWIMAGE(charW%, charH%, 32)
oldDest& = _DEST: _DEST tmpImg&
CLS , _RGBA32(0, 0, 0, 0)
prevFont& = _FONT: _FONT fHandle&
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_CONTROLCHR OFF: _PRINTSTRING (0, 0), ch$: _CONTROLCHR ON
_FONT prevFont&: _DEST oldDest&

PRINT #F%, "": PRINT #F%, "=== Test 2: _BLEND on exact-size dest ==="
srcSave& = _SOURCE: _SOURCE tmpImg&
FOR py% = 0 TO charH% - 1
    r$ = "  row" + _TRIM$(STR$(py%)) + ":"
    FOR px% = 0 TO charW% - 1
        c~& = POINT(px%, py%)
        IF _ALPHA32(c~&) > 0 THEN r$ = r$ + " ##" ELSE r$ = r$ + " .."
    NEXT px%
    PRINT #F%, r$
NEXT py%
_SOURCE srcSave&: _FREEIMAGE tmpImg&

' === Test 3: _DONTBLEND on 100x100 dest ===
DIM bigImg AS LONG
bigImg& = _NEWIMAGE(100, 100, 32)
oldDest& = _DEST: _DEST bigImg&
CLS , _RGBA32(0, 0, 0, 0): _DONTBLEND
prevFont& = _FONT: _FONT fHandle&
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_CONTROLCHR OFF: _PRINTSTRING (0, 0), ch$: _CONTROLCHR ON
_FONT prevFont&: _BLEND: _DEST oldDest&

PRINT #F%, "": PRINT #F%, "=== Test 3: _DONTBLEND on 100x100 dest ==="
srcSave& = _SOURCE: _SOURCE bigImg&
FOR py% = 0 TO charH% - 1
    r$ = "  row" + _TRIM$(STR$(py%)) + ":"
    FOR px% = 0 TO charW% - 1
        c~& = POINT(px%, py%)
        IF _ALPHA32(c~&) > 0 THEN r$ = r$ + " ##" ELSE r$ = r$ + " .."
    NEXT px%
    PRINT #F%, r$
NEXT py%
_SOURCE srcSave&: _FREEIMAGE bigImg&

' === Test 4: _DONTBLEND, +1px height padding ===
tmpImg& = _NEWIMAGE(charW%, charH% + 1, 32)
oldDest& = _DEST: _DEST tmpImg&
CLS , _RGBA32(0, 0, 0, 0): _DONTBLEND
prevFont& = _FONT: _FONT fHandle&
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_CONTROLCHR OFF: _PRINTSTRING (0, 0), ch$: _CONTROLCHR ON
_FONT prevFont&: _BLEND: _DEST oldDest&

PRINT #F%, "": PRINT #F%, "=== Test 4: _DONTBLEND, +1px height ==="
srcSave& = _SOURCE: _SOURCE tmpImg&
FOR py% = 0 TO charH%
    r$ = "  row" + _TRIM$(STR$(py%)) + ":"
    FOR px% = 0 TO charW% - 1
        c~& = POINT(px%, py%)
        IF _ALPHA32(c~&) > 0 THEN r$ = r$ + " ##" ELSE r$ = r$ + " .."
    NEXT px%
    PRINT #F%, r$
NEXT py%
_SOURCE srcSave&: _FREEIMAGE tmpImg&

' === Test 5: _DONTBLEND, +1px width padding ===
tmpImg& = _NEWIMAGE(charW% + 1, charH%, 32)
oldDest& = _DEST: _DEST tmpImg&
CLS , _RGBA32(0, 0, 0, 0): _DONTBLEND
prevFont& = _FONT: _FONT fHandle&
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_CONTROLCHR OFF: _PRINTSTRING (0, 0), ch$: _CONTROLCHR ON
_FONT prevFont&: _BLEND: _DEST oldDest&

PRINT #F%, "": PRINT #F%, "=== Test 5: _DONTBLEND, +1px width ==="
srcSave& = _SOURCE: _SOURCE tmpImg&
FOR py% = 0 TO charH% - 1
    r$ = "  row" + _TRIM$(STR$(py%)) + ":"
    FOR px% = 0 TO charW%
        c~& = POINT(px%, py%)
        IF _ALPHA32(c~&) > 0 THEN r$ = r$ + " ##" ELSE r$ = r$ + " .."
    NEXT px%
    PRINT #F%, r$
NEXT py%
_SOURCE srcSave&: _FREEIMAGE tmpImg&

' === Test 6: DONTBLEND font but _BLEND dest, exact size ===
DIM fHandle2 AS LONG
fHandle2& = _LOADFONT(fontPath$, 8, "DONTBLEND, MONOSPACE")
tmpImg& = _NEWIMAGE(charW%, charH%, 32)
oldDest& = _DEST: _DEST tmpImg&
CLS , _RGBA32(0, 0, 0, 0)
' _BLEND is default — keep it
_FONT fHandle2&
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_CONTROLCHR OFF: _PRINTSTRING (0, 0), ch$: _CONTROLCHR ON
_FONT 16: _DEST oldDest&

PRINT #F%, "": PRINT #F%, "=== Test 6: DONTBLEND font, _BLEND dest, fresh handle ==="
srcSave& = _SOURCE: _SOURCE tmpImg&
FOR py% = 0 TO charH% - 1
    r$ = "  row" + _TRIM$(STR$(py%)) + ":"
    FOR px% = 0 TO charW% - 1
        c~& = POINT(px%, py%)
        IF _ALPHA32(c~&) > 0 THEN r$ = r$ + " ##" ELSE r$ = r$ + " .."
    NEXT px%
    PRINT #F%, r$
NEXT py%
_SOURCE srcSave&: _FREEIMAGE tmpImg&
IF fHandle2& > 16 THEN _FREEFONT fHandle2&

_FREEFONT fHandle&

' === Test 7: WITHOUT MONOSPACE (proportional, like DRAW when mono=FALSE) ===
DIM fProp AS LONG
fProp& = _LOADFONT(fontPath$, 8, "DONTBLEND")
IF fProp& <= 0 THEN
    PRINT #F%, "": PRINT #F%, "Test 7: font load failed": CLOSE #F%: SYSTEM
END IF
measImg& = _NEWIMAGE(1, 1, 32)
oldDest& = _DEST: _DEST measImg&
prevFont& = _FONT: _FONT fProp&
_CONTROLCHR OFF
DIM propW AS INTEGER, propH AS INTEGER
propW% = _PRINTWIDTH(ch$): propH% = _FONTHEIGHT
_CONTROLCHR ON
_FONT prevFont&: _DEST oldDest&: _FREEIMAGE measImg&

PRINT #F%, "": PRINT #F%, "=== Test 7: DONTBLEND, NO MONOSPACE (proportional) ==="
PRINT #F%, "  propW=" + _TRIM$(STR$(propW%)) + " propH=" + _TRIM$(STR$(propH%))

tmpImg& = _NEWIMAGE(propW%, propH%, 32)
oldDest& = _DEST: _DEST tmpImg&
CLS , _RGBA32(0, 0, 0, 0): _DONTBLEND
prevFont& = _FONT: _FONT fProp&
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_CONTROLCHR OFF: _PRINTSTRING (0, 0), ch$: _CONTROLCHR ON
_FONT prevFont&: _BLEND: _DEST oldDest&

srcSave& = _SOURCE: _SOURCE tmpImg&
FOR py% = 0 TO propH% - 1
    r$ = "  row" + _TRIM$(STR$(py%)) + ":"
    FOR px% = 0 TO propW% - 1
        c~& = POINT(px%, py%)
        IF _ALPHA32(c~&) > 0 THEN r$ = r$ + " ##" ELSE r$ = r$ + " .."
    NEXT px%
    PRINT #F%, r$
NEXT py%
_SOURCE srcSave&: _FREEIMAGE tmpImg&

' === Test 8: proportional, _BLEND dest ===
tmpImg& = _NEWIMAGE(propW%, propH%, 32)
oldDest& = _DEST: _DEST tmpImg&
CLS , _RGBA32(0, 0, 0, 0)
prevFont& = _FONT: _FONT fProp&
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_CONTROLCHR OFF: _PRINTSTRING (0, 0), ch$: _CONTROLCHR ON
_FONT prevFont&: _DEST oldDest&

PRINT #F%, "": PRINT #F%, "=== Test 8: DONTBLEND font, _BLEND dest, proportional ==="
srcSave& = _SOURCE: _SOURCE tmpImg&
FOR py% = 0 TO propH% - 1
    r$ = "  row" + _TRIM$(STR$(py%)) + ":"
    FOR px% = 0 TO propW% - 1
        c~& = POINT(px%, py%)
        IF _ALPHA32(c~&) > 0 THEN r$ = r$ + " ##" ELSE r$ = r$ + " .."
    NEXT px%
    PRINT #F%, r$
NEXT py%
_SOURCE srcSave&: _FREEIMAGE tmpImg&

' === Test 9: proportional, on 100x100 ===
bigImg& = _NEWIMAGE(100, 100, 32)
oldDest& = _DEST: _DEST bigImg&
CLS , _RGBA32(0, 0, 0, 0): _DONTBLEND
prevFont& = _FONT: _FONT fProp&
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_CONTROLCHR OFF: _PRINTSTRING (0, 0), ch$: _CONTROLCHR ON
_FONT prevFont&: _BLEND: _DEST oldDest&

PRINT #F%, "": PRINT #F%, "=== Test 9: proportional DONTBLEND, 100x100 dest ==="
srcSave& = _SOURCE: _SOURCE bigImg&
FOR py% = 0 TO propH% - 1
    r$ = "  row" + _TRIM$(STR$(py%)) + ":"
    FOR px% = 0 TO propW% + 4
        c~& = POINT(px%, py%)
        IF _ALPHA32(c~&) > 0 THEN r$ = r$ + " ##" ELSE r$ = r$ + " .."
    NEXT px%
    PRINT #F%, r$
NEXT py%
_SOURCE srcSave&: _FREEIMAGE bigImg&

IF fProp& > 16 THEN _FREEFONT fProp&
PRINT #F%, "": PRINT #F%, "Done."
CLOSE #F%
SYSTEM
