'
' font-test.bas — Standalone charmap grid renderer for diagnosing font clipping
' Renders two fonts side-by-side: dp-tuxedo.ttf and MIXELATE.TTF
' Each font gets a 16x16 grid (256 chars, CP437 via _CONTROLCHR OFF)
'
' Three render modes per font:
'   1. RAW   — _PRINTSTRING at exact _FONTHEIGHT, no crop (how QB64-PE gives it)
'   2. CROP  — Ink-crop approach (DRAW's current charmap method)
'   3. MONO  — Same as CROP but with MONOSPACE style
'
' Build: qb64pe -x DEV/font-test.bas -o DEV/font-test.run
' Run:   ./DEV/font-test.run
'
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

CONST FONT_PATH_1$ = "../ASSETS/FONTS/dp-tuxedo.ttf"
CONST FONT_PATH_2$ = "../ASSETS/FONTS/MIXELATE.TTF"
CONST FONT_SIZE% = 16
CONST GRID_COLS% = 16
CONST GRID_ROWS% = 16
CONST CELL_PAD% = 1
CONST BG_COLOR~& = _RGB32(32, 32, 32)
CONST GRID_BG~& = _RGB32(48, 48, 48)
CONST CELL_BG~& = _RGB32(24, 24, 24)
CONST LABEL_FG~& = _RGB32(200, 200, 200)
CONST GLYPH_FG~& = _RGB32(255, 255, 255)
CONST INK_BOX_FG~& = _RGB32(255, 80, 80)

' Window layout: 3 grids per font, 2 fonts = 6 grids total
' Layout: 2 rows x 3 columns
'   Row 1: Font1-RAW, Font1-CROP, Font1-MONO
'   Row 2: Font2-RAW, Font2-CROP, Font2-MONO

DIM SHARED cellW AS INTEGER
DIM SHARED cellH AS INTEGER
DIM SHARED gridW AS INTEGER
DIM SHARED gridH AS INTEGER
DIM SHARED labelH AS INTEGER

labelH% = 20

' Load fonts to measure cell size
DIM fh1 AS LONG, fh1m AS LONG
DIM fh2 AS LONG, fh2m AS LONG
DIM tmpImg AS LONG

' Load regular (DONTBLEND = non-antialised)
fh1& = _LOADFONT(FONT_PATH_1$, FONT_SIZE%, "DONTBLEND")
IF fh1& <= 0 THEN PRINT "ERROR: Cannot load " + FONT_PATH_1$: SYSTEM
fh1m& = _LOADFONT(FONT_PATH_1$, FONT_SIZE%, "DONTBLEND, MONOSPACE")
IF fh1m& <= 0 THEN PRINT "ERROR: Cannot load " + FONT_PATH_1$ + " MONO": SYSTEM

fh2& = _LOADFONT(FONT_PATH_2$, FONT_SIZE%, "DONTBLEND")
IF fh2& <= 0 THEN PRINT "ERROR: Cannot load " + FONT_PATH_2$: SYSTEM
fh2m& = _LOADFONT(FONT_PATH_2$, FONT_SIZE%, "DONTBLEND, MONOSPACE")
IF fh2m& <= 0 THEN PRINT "ERROR: Cannot load " + FONT_PATH_2$ + " MONO": SYSTEM

' Measure max cell from both fonts
DIM maxCW AS INTEGER, maxCH AS INTEGER
maxCW% = 0: maxCH% = 0
tmpImg& = _NEWIMAGE(1, 1, 32)
_DEST tmpImg&

_FONT fh1&
IF _PRINTWIDTH("M") > maxCW% THEN maxCW% = _PRINTWIDTH("M")
IF _FONTHEIGHT > maxCH% THEN maxCH% = _FONTHEIGHT

_FONT fh2&
IF _PRINTWIDTH("M") > maxCW% THEN maxCW% = _PRINTWIDTH("M")
IF _FONTHEIGHT > maxCH% THEN maxCH% = _FONTHEIGHT

_FONT 16
_DEST 0
IF tmpImg& < -1 THEN _FREEIMAGE tmpImg&

cellW% = maxCW% + 2
cellH% = maxCH% + 2
IF cellW% < 10 THEN cellW% = 10
IF cellH% < 10 THEN cellH% = 10

gridW% = GRID_COLS% * (cellW% + CELL_PAD%) + CELL_PAD%
gridH% = GRID_ROWS% * (cellH% + CELL_PAD%) + CELL_PAD%

DIM totalW AS INTEGER, totalH AS INTEGER
DIM margin AS INTEGER
margin% = 8
totalW% = margin% + 3 * gridW% + 2 * margin% + margin%
totalH% = margin% + labelH% + gridH% + margin% + labelH% + gridH% + margin%

SCREEN _NEWIMAGE(totalW%, totalH%, 32)
_TITLE "Font Rendering Test — dp-tuxedo.ttf / MIXELATE.TTF"
CLS , BG_COLOR~&

' Draw grids
DIM gx AS INTEGER, gy AS INTEGER

' === ROW 1: dp-tuxedo.ttf ===
gy% = margin%
' RAW
gx% = margin%
DrawLabel gx%, gy%, "dp-tuxedo RAW (no crop)"
DrawGrid gx%, gy% + labelH%, fh1&, 0
' CROP
gx% = margin% + gridW% + margin%
DrawLabel gx%, gy%, "dp-tuxedo CROP (ink-scan)"
DrawGrid gx%, gy% + labelH%, fh1&, 1
' MONO
gx% = margin% + 2 * (gridW% + margin%)
DrawLabel gx%, gy%, "dp-tuxedo MONO+CROP"
DrawGrid gx%, gy% + labelH%, fh1m&, 1

' === ROW 2: MIXELATE.TTF ===
gy% = margin% + labelH% + gridH% + margin%
' RAW
gx% = margin%
DrawLabel gx%, gy%, "MIXELATE RAW (no crop)"
DrawGrid gx%, gy% + labelH%, fh2&, 0
' CROP
gx% = margin% + gridW% + margin%
DrawLabel gx%, gy%, "MIXELATE CROP (ink-scan)"
DrawGrid gx%, gy% + labelH%, fh2&, 1
' MONO
gx% = margin% + 2 * (gridW% + margin%)
DrawLabel gx%, gy%, "MIXELATE MONO+CROP"
DrawGrid gx%, gy% + labelH%, fh2m&, 1

_DISPLAY

' Dump metrics via _LOGINFO (never use _DEST _CONSOLE — corrupts graphics state)
DIM mTmp AS LONG
mTmp& = _NEWIMAGE(1, 1, 32)
IF mTmp& < -1 THEN
    DIM oldMetDest AS LONG: oldMetDest& = _DEST
    _DEST mTmp&

    _FONT fh1&
    _CONTROLCHR OFF
    _LOGINFO "=== FONT METRICS ==="
    _LOGINFO "dp-tuxedo.ttf:"
    _LOGINFO "  _FONTHEIGHT =" + STR$(_FONTHEIGHT)
    _LOGINFO "  _PRINTWIDTH('A') =" + STR$(_PRINTWIDTH("A"))
    _LOGINFO "  _PRINTWIDTH('M') =" + STR$(_PRINTWIDTH("M"))
    _LOGINFO "  _PRINTWIDTH(CHR$(1)) =" + STR$(_PRINTWIDTH(CHR$(1)))
    _LOGINFO "  _PRINTWIDTH(CHR$(128)) =" + STR$(_PRINTWIDTH(CHR$(128)))
    _LOGINFO "  _PRINTWIDTH(CHR$(219)) =" + STR$(_PRINTWIDTH(CHR$(219)))
    _CONTROLCHR ON

    _FONT fh2&
    _CONTROLCHR OFF
    _LOGINFO "MIXELATE.TTF:"
    _LOGINFO "  _FONTHEIGHT =" + STR$(_FONTHEIGHT)
    _LOGINFO "  _PRINTWIDTH('A') =" + STR$(_PRINTWIDTH("A"))
    _LOGINFO "  _PRINTWIDTH('M') =" + STR$(_PRINTWIDTH("M"))
    _LOGINFO "  _PRINTWIDTH(CHR$(1)) =" + STR$(_PRINTWIDTH(CHR$(1)))
    _LOGINFO "  _PRINTWIDTH(CHR$(128)) =" + STR$(_PRINTWIDTH(CHR$(128)))
    _LOGINFO "  _PRINTWIDTH(CHR$(219)) =" + STR$(_PRINTWIDTH(CHR$(219)))
    _CONTROLCHR ON

    _FONT 16
    _DEST oldMetDest&
    _FREEIMAGE mTmp&
END IF

_LOGINFO "Cell size:" + STR$(cellW%) + " x" + STR$(cellH%)
_LOGINFO "Grid size:" + STR$(gridW%) + " x" + STR$(gridH%)
_LOGINFO "Window:" + STR$(totalW%) + " x" + STR$(totalH%)
_LOGINFO "Press any key or close window to exit..."

' Wait for keypress or window close
DO
    IF _KEYHIT THEN EXIT DO
    IF _EXIT THEN EXIT DO
    _LIMIT 30
LOOP

' Save screenshot
DIM ssImg AS LONG
ssImg& = _COPYIMAGE(0, 32)
IF ssImg& < -1 THEN
    _SAVEIMAGE "./font-test-output.png", ssImg& 
    _FREEIMAGE ssImg&
    _LOGINFO "Screenshot saved to DEV/font-test-output.png"
END IF

IF fh1& > 0 AND fh1& <> 16 THEN _FREEFONT fh1&
IF fh1m& > 0 AND fh1m& <> 16 THEN _FREEFONT fh1m&
IF fh2& > 0 AND fh2& <> 16 THEN _FREEFONT fh2&
IF fh2m& > 0 AND fh2m& <> 16 THEN _FREEFONT fh2m&
SYSTEM


''
' Draw a label above a grid
'
SUB DrawLabel (x AS INTEGER, y AS INTEGER, txt AS STRING)
    DIM oldF AS LONG
    oldF& = _FONT
    _FONT 16 ' VGA 8x16 for labels
    COLOR LABEL_FG~&, BG_COLOR~&
    _PRINTSTRING (x%, y% + 2), txt$
    _FONT oldF&
END SUB


''
' Draw a 16x16 character grid
' mode% = 0: RAW (direct _PRINTSTRING, no crop)
' mode% = 1: CROP (ink-scan bounding box)
'
SUB DrawGrid (gx AS INTEGER, gy AS INTEGER, fHandle AS LONG, mode AS INTEGER)
    DIM i AS INTEGER
    DIM col AS INTEGER, row AS INTEGER
    DIM cx AS INTEGER, cy AS INTEGER
    DIM ch AS STRING

    ' Grid background
    LINE (gx%, gy%)-(gx% + gridW% - 1, gy% + gridH% - 1), GRID_BG~&, BF

    FOR i% = 0 TO 255
        col% = i% MOD GRID_COLS%
        row% = i% \ GRID_COLS%
        cx% = gx% + CELL_PAD% + col% * (cellW% + CELL_PAD%)
        cy% = gy% + CELL_PAD% + row% * (cellH% + CELL_PAD%)

        ' Cell background
        LINE (cx%, cy%)-(cx% + cellW% - 1, cy% + cellH% - 1), CELL_BG~&, BF

        IF i% = 0 THEN
            ch$ = CHR$(32)
        ELSE
            ch$ = CHR$(i%)
        END IF

        IF mode% = 0 THEN
            ' RAW: direct render into cell
            DrawGlyph_Raw cx%, cy%, ch$, fHandle&
        ELSE
            ' CROP: ink-scan then blit centered
            DrawGlyph_Crop cx%, cy%, ch$, fHandle&
        END IF
    NEXT i%
END SUB


''
' RAW render: _PRINTSTRING directly at cell position, clipped to cell bounds
'
SUB DrawGlyph_Raw (cx AS INTEGER, cy AS INTEGER, ch AS STRING, fHandle AS LONG)
    DIM tmpImg AS LONG
    DIM charW AS INTEGER, charH AS INTEGER
    DIM oldDest AS LONG, prevFont AS LONG
    DIM drawX AS INTEGER, drawY AS INTEGER

    ' Measure
    tmpImg& = _NEWIMAGE(1, 1, 32)
    IF tmpImg& >= -1 THEN EXIT SUB
    oldDest& = _DEST
    _DEST tmpImg&
    prevFont& = _FONT
    _FONT fHandle&
    _CONTROLCHR OFF
    charW% = _PRINTWIDTH(ch$)
    charH% = _FONTHEIGHT
    _CONTROLCHR ON
    _FONT prevFont&
    _DEST oldDest&
    IF tmpImg& < -1 THEN _FREEIMAGE tmpImg&

    IF charW% < 1 OR charH% < 1 THEN EXIT SUB

    ' Render into temp image at exact size
    tmpImg& = _NEWIMAGE(charW%, charH%, 32)
    IF tmpImg& >= -1 THEN EXIT SUB
    oldDest& = _DEST
    _DEST tmpImg&
    CLS , _RGBA32(0, 0, 0, 0)
    prevFont& = _FONT
    _FONT fHandle&
    COLOR GLYPH_FG~&, _RGBA32(0, 0, 0, 0)
    _CONTROLCHR OFF
    _PRINTSTRING (0, 0), ch$
    _CONTROLCHR ON
    _FONT prevFont&
    _DEST oldDest&

    ' Center in cell
    drawX% = cx% + (cellW% - charW%) \ 2
    drawY% = cy% + (cellH% - charH%) \ 2
    _PUTIMAGE (drawX%, drawY%), tmpImg&
    IF tmpImg& < -1 THEN _FREEIMAGE tmpImg&
END SUB


''
' CROP render: render padded, ink-scan, crop, center in cell
' (Matches DRAW's CHARMAP_rebuild_cache approach)
'
SUB DrawGlyph_Crop (cx AS INTEGER, cy AS INTEGER, ch AS STRING, fHandle AS LONG)
    DIM tmpImg AS LONG, renderImg AS LONG
    DIM charW AS INTEGER, charH AS INTEGER
    DIM oldDest AS LONG, prevFont AS LONG
    DIM padH AS INTEGER
    DIM inkMinX AS INTEGER, inkMinY AS INTEGER
    DIM inkMaxX AS INTEGER, inkMaxY AS INTEGER
    DIM scanX AS INTEGER, scanY AS INTEGER
    DIM scanC AS _UNSIGNED LONG
    DIM inkW AS INTEGER, inkH AS INTEGER
    DIM drawX AS INTEGER, drawY AS INTEGER
    DIM oldSrc AS LONG

    ' Measure
    tmpImg& = _NEWIMAGE(1, 1, 32)
    IF tmpImg& >= -1 THEN EXIT SUB
    oldDest& = _DEST
    _DEST tmpImg&
    prevFont& = _FONT
    _FONT fHandle&
    _CONTROLCHR OFF
    charW% = _PRINTWIDTH(ch$)
    charH% = _FONTHEIGHT
    _CONTROLCHR ON
    _FONT prevFont&
    _DEST oldDest&
    IF tmpImg& < -1 THEN _FREEIMAGE tmpImg&

    IF charW% < 1 OR charH% < 1 THEN EXIT SUB

    ' Render into padded buffer
    padH% = 4
    renderImg& = _NEWIMAGE(charW% + 4, charH% + padH%, 32)
    IF renderImg& >= -1 THEN EXIT SUB
    oldDest& = _DEST
    _DEST renderImg&
    CLS , _RGBA32(0, 0, 0, 0)
    prevFont& = _FONT
    _FONT fHandle&
    COLOR GLYPH_FG~&, _RGBA32(0, 0, 0, 0)
    _CONTROLCHR OFF
    _PRINTSTRING (0, 0), ch$
    _CONTROLCHR ON
    _FONT prevFont&
    _DEST oldDest&

    ' Ink-scan bounding box
    inkMinX% = _WIDTH(renderImg&)
    inkMinY% = _HEIGHT(renderImg&)
    inkMaxX% = -1
    inkMaxY% = -1
    oldSrc& = _SOURCE
    _SOURCE renderImg&
    FOR scanY% = 0 TO _HEIGHT(renderImg&) - 1
        FOR scanX% = 0 TO _WIDTH(renderImg&) - 1
            scanC~& = POINT(scanX%, scanY%)
            IF _ALPHA32(scanC~&) > 0 THEN
                IF scanX% < inkMinX% THEN inkMinX% = scanX%
                IF scanX% > inkMaxX% THEN inkMaxX% = scanX%
                IF scanY% < inkMinY% THEN inkMinY% = scanY%
                IF scanY% > inkMaxY% THEN inkMaxY% = scanY%
            END IF
        NEXT scanX%
    NEXT scanY%
    _SOURCE oldSrc&

    ' Blank glyph
    IF inkMaxX% < 0 THEN
        _FREEIMAGE renderImg&
        EXIT SUB
    END IF

    ' Crop
    inkW% = inkMaxX% - inkMinX% + 1
    inkH% = inkMaxY% - inkMinY% + 1
    IF inkW% < 1 THEN inkW% = 1
    IF inkH% < 1 THEN inkH% = 1

    tmpImg& = _NEWIMAGE(inkW%, inkH%, 32)
    IF tmpImg& >= -1 THEN
        _FREEIMAGE renderImg&
        EXIT SUB
    END IF
    _PUTIMAGE (0, 0)-(inkW% - 1, inkH% - 1), renderImg&, tmpImg&, (inkMinX%, inkMinY%)-(inkMaxX%, inkMaxY%)
    _FREEIMAGE renderImg&

    ' Center cropped glyph in cell
    drawX% = cx% + (cellW% - inkW%) \ 2
    drawY% = cy% + (cellH% - inkH%) \ 2
    _PUTIMAGE (drawX%, drawY%), tmpImg&
    IF tmpImg& < -1 THEN _FREEIMAGE tmpImg&
END SUB
