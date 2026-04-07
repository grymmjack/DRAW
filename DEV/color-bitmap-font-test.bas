OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ============================================================================
' Color Bitmap Font (CBF) Test Program
' ============================================================================
' Loads Amiga/DPaint-style spritesheet fonts (.BMP/.PNG) and renders text
' preserving original pixel colors.
'
' Two format conventions supported:
'
'   1. DPaint-style (marker row):
'      - Row 0 = marker row (single-pixel markers indicate glyph starts)
'      - Rows 1..H-1 = glyph pixel data
'      - Background color = most frequent color at y=0
'      - Marker color = isolated non-background pixels at y=0
'      - Variable-width glyphs (width = distance between markers)
'
'   2. Fixed-width grid (16x16):
'      - 256 characters in a 16-column x 16-row grid
'      - Cell size = imageWidth/16 x imageHeight/16
'      - Character code = row*16 + col
'      - Fallback when marker-row detection finds < 3 glyphs
'
' Usage:
'   color-bitmap-font-test.run [path-to-dir-or-file]
'   If argument is a directory, use it as BitmapFonts base directory
'   If argument is a file, load that single font
'   Defaults to ../../BitmapFonts/ + ./FONTS/COLOR_BITMAP/
'
' Controls:
'   Type text to render with color font
'   Backspace = delete last char
'   Enter = clear typed text
'   Left/Right arrows = cycle through fonts
'   Up/Down arrows = adjust spacing
'   PgUp/PgDn = skip 10 fonts
'   Home/End = first/last font
'   ESC = quit
' ============================================================================

' --- Constants ---
CONST SCR_W = 1280
CONST SCR_H = 900
CONST MAX_GLYPHS = 256
CONST MAX_FONTS = 1500

' Font type constants
CONST FTYPE_MARKER_ROW = 0
CONST FTYPE_GRID = 1
CONST FTYPE_PACKED_GRID = 2
CONST FTYPE_MULTI_MARKER = 3
CONST FTYPE_UNKNOWN = -1

' Extended key codes
CONST KEY_LEFT = 19200
CONST KEY_RIGHT = 19712
CONST KEY_UP = 18432
CONST KEY_DOWN = 20480
CONST KEY_PGUP = 18688
CONST KEY_PGDN = 20736
CONST KEY_HOME = 18176
CONST KEY_END = 20224

' --- Types ---
TYPE CBF_GLYPH_T
    srcX AS INTEGER ' X position in source spritesheet
    srcY AS INTEGER ' Y position in source spritesheet (grid fonts use this)
    srcW AS INTEGER ' Width in pixels
    srcH AS INTEGER ' Height in pixels (for variable-height packed grid rows)
    img AS LONG     ' Extracted glyph image handle (bg = transparent)
END TYPE

' --- Shared state ---
DIM SHARED gly(0 TO MAX_GLYPHS - 1) AS CBF_GLYPH_T
DIM SHARED char2glyph(0 TO 255) AS INTEGER ' ASCII code -> glyph index (-1 = unmapped)
DIM SHARED glyCount AS INTEGER             ' Number of detected glyphs
DIM SHARED sheet AS LONG                   ' Spritesheet image handle
DIM SHARED sheetW AS INTEGER               ' Spritesheet width
DIM SHARED sheetH AS INTEGER               ' Spritesheet height
DIM SHARED glyH AS INTEGER                 ' Actual glyph height
DIM SHARED bgClr AS _UNSIGNED LONG         ' Detected background color
DIM SHARED mkClr AS _UNSIGNED LONG         ' Detected marker color
DIM SHARED charSeq AS STRING               ' Character sequence mapping
DIM SHARED charSpacing AS INTEGER          ' Pixel gap between rendered characters
DIM SHARED spaceW AS INTEGER               ' Width of space character (average glyph width)
DIM SHARED curFontPath AS STRING           ' Current font file path
DIM SHARED fontType AS INTEGER             ' FTYPE_MARKER_ROW or FTYPE_GRID
DIM SHARED gridCellW AS INTEGER            ' Grid cell width (grid mode only)
DIM SHARED gridCellH AS INTEGER            ' Grid cell height (grid mode only)
DIM SHARED loadFailed AS INTEGER           ' TRUE if last load attempt failed

' Font list for cycling
DIM SHARED fontFiles(0 TO MAX_FONTS - 1) AS STRING
DIM SHARED fontFileCount AS INTEGER
DIM SHARED fontFileIdx AS INTEGER
DIM SHARED bitmapFontsDir AS STRING        ' Base directory for BitmapFonts repo

' ============================================================================
' MAIN
' ============================================================================
DIM fontArg AS STRING
DIM scrn AS LONG
DIM i AS INTEGER

' Parse command line — directory or file path
fontArg$ = LTRIM$(RTRIM$(COMMAND$))
IF LEN(fontArg$) > 0 THEN
    IF _DIREXISTS(fontArg$) THEN
        ' Argument is a directory — use as BitmapFonts base
        bitmapFontsDir$ = fontArg$
        ' Ensure trailing separator
        IF RIGHT$(bitmapFontsDir$, 1) <> "/" AND RIGHT$(bitmapFontsDir$, 1) <> "\" THEN
            bitmapFontsDir$ = bitmapFontsDir$ + "/"
        END IF
    END IF
ELSE
    ' Default: BitmapFonts is sibling to DRAW, we run from DRAW/DEV/
    bitmapFontsDir$ = "../../BitmapFonts/"
END IF

scrn& = _NEWIMAGE(SCR_W, SCR_H, 32)
SCREEN scrn&
_TITLE "Color Bitmap Font Test — Scanning fonts..."
_PRINTMODE _KEEPBACKGROUND

' Show loading message
COLOR _RGB32(255, 255, 100)
_PRINTSTRING (10, 10), "Scanning for fonts..."
_DISPLAY

' Build font file list (runtime directory scan)
CBF_init_font_list

_TITLE "Color Bitmap Font Test — " + LTRIM$(STR$(fontFileCount)) + " fonts"

IF fontFileCount = 0 THEN
    COLOR _RGB32(255, 80, 80)
    _PRINTSTRING (10, 30), "ERROR: No font files found!"
    _PRINTSTRING (10, 50), "Searched: ./FONTS/COLOR_BITMAP/ and " + bitmapFontsDir$
    _PRINTSTRING (10, 70), "Usage: color-bitmap-font-test.run [path-to-BitmapFonts-dir]"
    _PRINTSTRING (10, 100), "Press any key to exit..."
    _DISPLAY
    SLEEP
    SYSTEM
END IF

' If command-line arg was a specific file, find it in the list
IF LEN(fontArg$) > 0 AND _FILEEXISTS(fontArg$) THEN
    FOR i% = 0 TO fontFileCount - 1
        IF fontFiles(i%) = fontArg$ THEN
            fontFileIdx = i%
            EXIT FOR
        END IF
    NEXT i%
ELSE
    ' Try to start at epicpin if available
    FOR i% = 0 TO fontFileCount - 1
        IF INSTR(LCASE$(fontFiles(i%)), "epicpin") > 0 THEN
            fontFileIdx = i%
            EXIT FOR
        END IF
    NEXT i%
END IF

' Load first font — if it fails, the main loop handles it gracefully
loadFailed% = 0
IF NOT CBF_load%(fontFiles(fontFileIdx)) THEN
    loadFailed% = -1
END IF

CBF_main_loop

CBF_free_glyphs
SYSTEM

' ============================================================================
' Load a color bitmap font spritesheet
' Returns TRUE (-1) on success, FALSE (0) on failure
'
' Detection strategy (in priority order):
'   1. Single marker-row strip (Type A) — very wide, short aspect ratio
'   2. Multi-row marker-row (Type B) — moderate aspect ratio, marker rows
'   3. Packed grid (Type C) — characters separated by bg-color rows/columns
'   4. Fixed 16x16 grid (Type D) — 256-char ASCII grid, last fallback
' ============================================================================
FUNCTION CBF_load% (path$)
    CBF_load% = 0
    curFontPath$ = path$
    fontType = FTYPE_UNKNOWN

    ' Free any previous font data
    CBF_free_glyphs

    ' Load spritesheet as 32-bit RGBA
    sheet& = _LOADIMAGE(path$, 32)
    IF sheet& >= -1 THEN EXIT FUNCTION

    sheetW = _WIDTH(sheet&)
    sheetH = _HEIGHT(sheet&)

    IF sheetW < 2 OR sheetH < 2 THEN
        _FREEIMAGE sheet&
        sheet& = 0
        EXIT FUNCTION
    END IF

    DIM aspect AS SINGLE
    aspect! = sheetW / sheetH

    DIM markerValid AS INTEGER
    markerValid% = 0

    ' --- Strategy 1: Single marker-row (only for strip-like images) ---
    ' Marker-row fonts are very wide and short (aspect ratio >= 3.0)
    IF aspect! >= 3.0 THEN
        glyH = sheetH - 1
        CBF_detect_markers

        IF glyCount >= 3 THEN
            ' Validate: check that there's no significant content below first row
            IF NOT CBF_has_content_below%(1 + glyH) THEN
                markerValid% = -1
                fontType = FTYPE_MARKER_ROW
            END IF
        END IF

        IF NOT markerValid% THEN
            ' Marker detection was a false positive — try multi-row marker
            glyCount = 0
            glyH = 0

            CBF_detect_multi_marker
            IF glyCount >= 3 THEN
                fontType = FTYPE_MULTI_MARKER
                markerValid% = -1
            ELSE
                glyCount = 0
            END IF
        END IF
    END IF

    ' --- Strategy 2: For moderate aspect ratios, try multi-row marker ---
    IF fontType = FTYPE_UNKNOWN AND aspect! >= 1.5 THEN
        CBF_detect_multi_marker
        IF glyCount >= 3 THEN
            fontType = FTYPE_MULTI_MARKER
        ELSE
            glyCount = 0
        END IF
    END IF

    ' --- Strategy 3: Packed grid (rows/cols separated by bg color) ---
    IF fontType = FTYPE_UNKNOWN THEN
        CBF_detect_packed_grid
        IF glyCount >= 3 THEN
            fontType = FTYPE_PACKED_GRID
        ELSE
            glyCount = 0
        END IF
    END IF

    ' --- Strategy 4: Fixed 16x16 grid fallback ---
    IF fontType = FTYPE_UNKNOWN AND (sheetW >= 16) AND (sheetH >= 16) THEN
        CBF_detect_grid
        IF glyCount >= 3 THEN
            fontType = FTYPE_GRID
            CBF_build_char_lookup_grid
            CBF_extract_glyphs
        END IF
    END IF

    ' --- Common post-processing for marker/packed types ---
    IF fontType = FTYPE_MARKER_ROW OR fontType = FTYPE_MULTI_MARKER OR fontType = FTYPE_PACKED_GRID THEN
        gridCellW = 0
        gridCellH = 0

        ' Build character sequence (ASCII 33+)
        charSeq$ = ""
        DIM ci AS INTEGER
        FOR ci% = 33 TO 33 + glyCount - 1
            IF ci% > 126 THEN EXIT FOR
            charSeq$ = charSeq$ + CHR$(ci%)
        NEXT ci%

        CBF_build_char_lookup
        CBF_extract_glyphs
    END IF

    IF glyCount < 1 THEN
        _FREEIMAGE sheet&
        sheet& = 0
        EXIT FUNCTION
    END IF

    ' Compute space width = average glyph width
    DIM totalW AS LONG
    DIM ci2 AS INTEGER
    totalW& = 0
    FOR ci2% = 0 TO glyCount - 1
        totalW& = totalW& + gly(ci2%).srcW
    NEXT ci2%
    IF glyCount > 0 THEN
        spaceW = totalW& \ glyCount
    ELSE
        spaceW = 8
    END IF

    charSpacing = 1
    CBF_load% = -1 ' TRUE
END FUNCTION

' ============================================================================
' Check if image has significant content below a given Y coordinate
' Returns TRUE if >10% of sampled pixels are non-bg in the lower portion
' Used to validate that a "marker-row" detection isn't a false positive
' on a multi-row image like a packed grid font
' ============================================================================
FUNCTION CBF_has_content_below% (startY%)
    CBF_has_content_below% = 0
    IF startY% >= sheetH THEN EXIT FUNCTION

    DIM oldSrc AS LONG
    oldSrc& = _SOURCE
    _SOURCE sheet&

    ' Sample 3 horizontal scanlines in the lower portion
    DIM nonBg AS INTEGER, total AS INTEGER
    DIM x AS INTEGER, y AS INTEGER
    nonBg% = 0: total% = 0

    DIM step3 AS INTEGER
    step3% = (sheetH - startY%) \ 4
    IF step3% < 1 THEN step3% = 1

    FOR y% = startY% + step3% TO sheetH - 1 STEP step3%
        IF y% >= sheetH THEN EXIT FOR
        FOR x% = 0 TO sheetW - 1 STEP 2
            total% = total% + 1
            IF POINT(x%, y%) <> bgClr THEN nonBg% = nonBg% + 1
        NEXT x%
    NEXT y%

    _SOURCE oldSrc&

    IF total% > 0 THEN
        IF nonBg% * 100 \ total% > 10 THEN CBF_has_content_below% = -1
    END IF
END FUNCTION

' ============================================================================
' Detect marker pixels at y=0 and compute glyph boundaries
' ============================================================================
SUB CBF_detect_markers
    DIM oldSrc AS LONG
    DIM x AS INTEGER, j AS INTEGER
    DIM c AS _UNSIGNED LONG
    DIM prevIsBg AS INTEGER

    oldSrc& = _SOURCE
    _SOURCE sheet&

    ' --- Step 1: Color frequency analysis at y=0 ---
    DIM uClr(0 TO 511) AS _UNSIGNED LONG
    DIM uCnt(0 TO 511) AS LONG
    DIM uNum AS INTEGER
    DIM found AS INTEGER

    uNum% = 0
    FOR x% = 0 TO sheetW - 1
        c~& = POINT(x%, 0)
        found% = 0
        FOR j% = 0 TO uNum% - 1
            IF uClr(j%) = c~& THEN
                uCnt(j%) = uCnt(j%) + 1
                found% = -1
                EXIT FOR
            END IF
        NEXT j%
        IF NOT found% AND uNum% < 512 THEN
            uClr(uNum%) = c~&
            uCnt(uNum%) = 1
            uNum% = uNum% + 1
        END IF
    NEXT x%

    ' Most frequent color at y=0 = background
    DIM maxCnt AS LONG, maxIdx AS INTEGER
    maxCnt& = 0: maxIdx% = 0
    FOR j% = 0 TO uNum% - 1
        IF uCnt(j%) > maxCnt& THEN
            maxCnt& = uCnt(j%)
            maxIdx% = j%
        END IF
    NEXT j%
    bgClr = uClr(maxIdx%)

    ' Second most frequent = marker color
    DIM mk2Cnt AS LONG, mk2Idx AS INTEGER
    mk2Cnt& = 0: mk2Idx% = -1
    FOR j% = 0 TO uNum% - 1
        IF j% <> maxIdx% AND uCnt(j%) > mk2Cnt& THEN
            mk2Cnt& = uCnt(j%)
            mk2Idx% = j%
        END IF
    NEXT j%
    IF mk2Idx% >= 0 THEN
        mkClr = uClr(mk2Idx%)
    ELSE
        mkClr = _RGB32(255, 255, 0) ' fallback yellow
    END IF

    ' --- Step 2: Find glyph boundaries ---
    ' Every transition from bg to non-bg at y=0 = glyph start
    glyCount = 0
    prevIsBg% = -1 ' TRUE

    FOR x% = 0 TO sheetW - 1
        c~& = POINT(x%, 0)
        IF c~& <> bgClr THEN
            IF prevIsBg% THEN
                IF glyCount < MAX_GLYPHS THEN
                    gly(glyCount).srcX = x%
                    gly(glyCount).srcY = 1 ' Marker row fonts: glyph data starts at y=1
                    gly(glyCount).srcH = glyH
                    glyCount = glyCount + 1
                END IF
            END IF
            prevIsBg% = 0
        ELSE
            prevIsBg% = -1
        END IF
    NEXT x%

    ' --- Step 3: Calculate widths ---
    FOR j% = 0 TO glyCount - 1
        IF j% < glyCount - 1 THEN
            gly(j%).srcW = gly(j% + 1).srcX - gly(j%).srcX
        ELSE
            gly(j%).srcW = sheetW - gly(j%).srcX
        END IF
    NEXT j%

    _SOURCE oldSrc&

    ' --- Log results ---
    _LOGINFO "CBF: Sheet " + LTRIM$(STR$(sheetW)) + "x" + LTRIM$(STR$(sheetH))
    _LOGINFO "CBF: Background RGB(" + LTRIM$(STR$(_RED32(bgClr))) + "," + LTRIM$(STR$(_GREEN32(bgClr))) + "," + LTRIM$(STR$(_BLUE32(bgClr))) + ")"
    _LOGINFO "CBF: Marker RGB(" + LTRIM$(STR$(_RED32(mkClr))) + "," + LTRIM$(STR$(_GREEN32(mkClr))) + "," + LTRIM$(STR$(_BLUE32(mkClr))) + ")"
    _LOGINFO "CBF: Found " + LTRIM$(STR$(glyCount)) + " glyphs, height " + LTRIM$(STR$(glyH)) + "px"
    _LOGINFO "CBF: Unique colors at y=0: " + LTRIM$(STR$(uNum%))
END SUB

' ============================================================================
' Detect multi-row marker-row font (Type B)
' Multiple rows of characters, each preceded by a marker scanline.
' Marker scanlines have >80% bg pixels with scattered non-bg transitions.
' ============================================================================
SUB CBF_detect_multi_marker
    DIM oldSrc AS LONG
    oldSrc& = _SOURCE
    _SOURCE sheet&

    ' --- Step 1: Detect background from corners ---
    DIM cornerClr(0 TO 3) AS _UNSIGNED LONG
    cornerClr(0) = POINT(0, 0)
    cornerClr(1) = POINT(sheetW - 1, 0)
    cornerClr(2) = POINT(0, sheetH - 1)
    cornerClr(3) = POINT(sheetW - 1, sheetH - 1)

    DIM ci3 AS INTEGER, cj3 AS INTEGER
    DIM bestClr3 AS _UNSIGNED LONG, bestCnt3 AS INTEGER, cnt3 AS INTEGER
    bestCnt3% = 0
    FOR ci3% = 0 TO 3
        cnt3% = 0
        FOR cj3% = 0 TO 3
            IF cornerClr(ci3%) = cornerClr(cj3%) THEN cnt3% = cnt3% + 1
        NEXT cj3%
        IF cnt3% > bestCnt3% THEN
            bestCnt3% = cnt3%
            bestClr3~& = cornerClr(ci3%)
        END IF
    NEXT ci3%
    bgClr = bestClr3~&

    ' --- Step 2: Classify each scanline ---
    ' A "marker scanline" has >80% bg pixels AND >=3 bg->non-bg transitions
    ' A "content scanline" has <80% bg pixels
    ' A "separator scanline" has >98% bg pixels (fully bg)
    CONST MAX_ROWS = 32
    DIM markerY(0 TO MAX_ROWS - 1) AS INTEGER   ' Y position of each marker row
    DIM contentEnd(0 TO MAX_ROWS - 1) AS INTEGER ' Y end of content below each marker
    DIM rowCount AS INTEGER

    DIM y AS INTEGER, x AS INTEGER
    DIM bgCount AS INTEGER, transitions AS INTEGER
    DIM isBg AS INTEGER, wasBg AS INTEGER
    DIM c AS _UNSIGNED LONG
    DIM bgPct AS SINGLE

    rowCount% = 0

    y% = 0
    DO WHILE y% < sheetH AND rowCount% < MAX_ROWS
        ' Count bg pixels and transitions at this scanline
        bgCount% = 0: transitions% = 0: wasBg% = -1
        FOR x% = 0 TO sheetW - 1
            c~& = POINT(x%, y%)
            isBg% = 0: IF c~& = bgClr THEN isBg% = -1
            IF isBg% THEN
                bgCount% = bgCount% + 1
            END IF
            IF NOT isBg% AND wasBg% THEN transitions% = transitions% + 1
            wasBg% = isBg%
        NEXT x%

        bgPct! = bgCount% / sheetW

        ' Check if this is a marker scanline
        IF bgPct! >= 0.80 AND bgPct! < 0.99 AND transitions% >= 3 THEN
            markerY(rowCount%) = y%

            ' Find where the content below this marker ends
            DIM yEnd AS INTEGER
            yEnd% = y% + 1
            DO WHILE yEnd% < sheetH
                ' Check if this line is mostly bg (>98% = separator/next marker)
                DIM bgCnt2 AS INTEGER, trans2 AS INTEGER, wasBg2 AS INTEGER
                bgCnt2% = 0: trans2% = 0: wasBg2% = -1
                DIM x2 AS INTEGER
                FOR x2% = 0 TO sheetW - 1
                    DIM c2 AS _UNSIGNED LONG
                    c2~& = POINT(x2%, yEnd%)
                    IF c2~& = bgClr THEN
                        bgCnt2% = bgCnt2% + 1
                    END IF
                    IF c2~& <> bgClr AND wasBg2% THEN trans2% = trans2% + 1
                    wasBg2% = 0: IF c2~& = bgClr THEN wasBg2% = -1
                NEXT x2%

                DIM bgPct2 AS SINGLE
                bgPct2! = bgCnt2% / sheetW

                ' If this line looks like it could be a marker for the next row,
                ' or is a full separator, end the current content row
                IF bgPct2! >= 0.80 AND (trans2% >= 3 OR bgPct2! >= 0.98) THEN
                    EXIT DO
                END IF
                yEnd% = yEnd% + 1
            LOOP

            contentEnd(rowCount%) = yEnd% - 1
            rowCount% = rowCount% + 1

            ' Jump to where content ended (the loop will check if next line is marker)
            y% = yEnd%
        ELSE
            y% = y% + 1
        END IF
    LOOP

    _LOGINFO "CBF: Multi-marker: found " + LTRIM$(STR$(rowCount%)) + " marker rows"

    IF rowCount% < 1 THEN
        _SOURCE oldSrc&
        EXIT SUB
    END IF

    ' --- Step 3: Extract glyphs from each row ---
    glyCount = 0
    glyH = 0

    DIM r AS INTEGER
    FOR r% = 0 TO rowCount% - 1
        DIM rMkY AS INTEGER, rContentY AS INTEGER, rEndY AS INTEGER, rH AS INTEGER
        rMkY% = markerY(r%)
        rContentY% = rMkY% + 1
        rEndY% = contentEnd(r%)
        rH% = rEndY% - rContentY% + 1
        IF rH% < 1 THEN _CONTINUE
        IF rH% > glyH THEN glyH = rH%

        ' Find glyph boundaries from marker transitions at rMkY%
        DIM prevBg AS INTEGER
        prevBg% = -1
        FOR x% = 0 TO sheetW - 1
            c~& = POINT(x%, rMkY%)
            IF c~& <> bgClr THEN
                IF prevBg% THEN
                    IF glyCount < MAX_GLYPHS THEN
                        gly(glyCount).srcX = x%
                        gly(glyCount).srcY = rContentY%
                        gly(glyCount).srcH = rH%
                        glyCount = glyCount + 1
                    END IF
                END IF
                prevBg% = 0
            ELSE
                prevBg% = -1
            END IF
        NEXT x%
    NEXT r%

    ' --- Step 4: Calculate widths ---
    ' Widths are per-row: distance between consecutive glyph starts within same Y row
    DIM gi AS INTEGER
    FOR gi% = 0 TO glyCount - 1
        IF gi% < glyCount - 1 AND gly(gi%).srcY = gly(gi% + 1).srcY THEN
            ' Same row: width = next glyph start - this glyph start
            gly(gi%).srcW = gly(gi% + 1).srcX - gly(gi%).srcX
        ELSE
            ' Last in row or last glyph: width = sheet edge - this glyph start
            gly(gi%).srcW = sheetW - gly(gi%).srcX
        END IF
    NEXT gi%

    mkClr = _RGB32(255, 255, 0) ' No specific marker color tracked

    _SOURCE oldSrc&

    _LOGINFO "CBF: Multi-marker: " + LTRIM$(STR$(glyCount)) + " glyphs across " + LTRIM$(STR$(rowCount%)) + " rows, maxH=" + LTRIM$(STR$(glyH))
END SUB

' ============================================================================
' Detect packed grid layout (Type C)
' Characters arranged in rows on a solid background, separated by bg-color
' bands (horizontal = row separators, vertical = column separators)
' ============================================================================
SUB CBF_detect_packed_grid
    DIM oldSrc AS LONG
    oldSrc& = _SOURCE
    _SOURCE sheet&

    ' --- Step 1: Detect background color from corners ---
    DIM cornerClr(0 TO 3) AS _UNSIGNED LONG
    cornerClr(0) = POINT(0, 0)
    cornerClr(1) = POINT(sheetW - 1, 0)
    cornerClr(2) = POINT(0, sheetH - 1)
    cornerClr(3) = POINT(sheetW - 1, sheetH - 1)

    DIM ci4 AS INTEGER, cj4 AS INTEGER
    DIM bestClr4 AS _UNSIGNED LONG, bestCnt4 AS INTEGER, cnt4 AS INTEGER
    bestCnt4% = 0
    FOR ci4% = 0 TO 3
        cnt4% = 0
        FOR cj4% = 0 TO 3
            IF cornerClr(ci4%) = cornerClr(cj4%) THEN cnt4% = cnt4% + 1
        NEXT cj4%
        IF cnt4% > bestCnt4% THEN
            bestCnt4% = cnt4%
            bestClr4~& = cornerClr(ci4%)
        END IF
    NEXT ci4%
    bgClr = bestClr4~&
    mkClr = _RGB32(255, 255, 0) ' No markers in packed grid

    ' --- Step 2: Find content rows by scanning horizontal bands ---
    ' A scanline is "bg" if 100% of its pixels match bgClr
    ' (Strict matching to avoid splitting rows at sparse content lines)
    CONST MAX_PROWS = 32
    DIM pRowStart(0 TO MAX_PROWS - 1) AS INTEGER
    DIM pRowEnd(0 TO MAX_PROWS - 1) AS INTEGER
    DIM pRowCount AS INTEGER

    DIM y AS INTEGER, x AS INTEGER
    DIM allBg AS INTEGER
    DIM inContent AS INTEGER

    pRowCount% = 0
    inContent% = 0

    FOR y% = 0 TO sheetH - 1
        ' Check if this scanline is fully bg
        allBg% = -1
        FOR x% = 0 TO sheetW - 1
            IF POINT(x%, y%) <> bgClr THEN
                allBg% = 0
                EXIT FOR
            END IF
        NEXT x%

        IF NOT allBg% THEN
            ' Content line
            IF NOT inContent% THEN
                IF pRowCount% < MAX_PROWS THEN
                    pRowStart(pRowCount%) = y%
                    inContent% = -1
                END IF
            END IF
        ELSE
            ' Background line — end current content row
            IF inContent% THEN
                pRowEnd(pRowCount%) = y% - 1
                pRowCount% = pRowCount% + 1
                inContent% = 0
            END IF
        END IF
    NEXT y%
    ' Close last content row if image ends with content
    IF inContent% AND pRowCount% < MAX_PROWS THEN
        pRowEnd(pRowCount%) = sheetH - 1
        pRowCount% = pRowCount% + 1
    END IF

    _LOGINFO "CBF: Packed grid: found " + LTRIM$(STR$(pRowCount%) + " content rows")

    IF pRowCount% < 1 THEN
        _SOURCE oldSrc&
        EXIT SUB
    END IF

    ' --- Step 3: For each content row, find column boundaries ---
    glyCount = 0
    glyH = 0

    DIM r AS INTEGER
    FOR r% = 0 TO pRowCount% - 1
        DIM rY0 AS INTEGER, rY1 AS INTEGER, rH AS INTEGER
        rY0% = pRowStart(r%)
        rY1% = pRowEnd(r%)
        rH% = rY1% - rY0% + 1
        IF rH% < 2 THEN _CONTINUE  ' Skip trivially small rows (likely stray pixels)
        IF rH% > glyH THEN glyH = rH%

        ' Scan each vertical column within this row for bg content
        DIM inCell AS INTEGER
        DIM cellStart AS INTEGER
        inCell% = 0

        FOR x% = 0 TO sheetW - 1
            ' Check if this column is fully bg within the row
            DIM colAllBg AS INTEGER
            colAllBg% = -1
            DIM y2 AS INTEGER
            FOR y2% = rY0% TO rY1%
                IF POINT(x%, y2%) <> bgClr THEN
                    colAllBg% = 0
                    EXIT FOR
                END IF
            NEXT y2%

            IF NOT colAllBg% THEN
                ' Content column
                IF NOT inCell% THEN
                    cellStart% = x%
                    inCell% = -1
                END IF
            ELSE
                ' Background column — end current cell
                IF inCell% THEN
                    IF glyCount < MAX_GLYPHS THEN
                        gly(glyCount).srcX = cellStart%
                        gly(glyCount).srcY = rY0%
                        gly(glyCount).srcW = x% - cellStart%
                        gly(glyCount).srcH = rH%
                        glyCount = glyCount + 1
                    END IF
                    inCell% = 0
                END IF
            END IF
        NEXT x%

        ' Close last cell if row ends with content
        IF inCell% THEN
            IF glyCount < MAX_GLYPHS THEN
                gly(glyCount).srcX = cellStart%
                gly(glyCount).srcY = rY0%
                gly(glyCount).srcW = sheetW - cellStart%
                gly(glyCount).srcH = rH%
                glyCount = glyCount + 1
            END IF
        END IF
    NEXT r%

    gridCellW = 0: gridCellH = 0
    IF glyCount > 0 THEN
        gridCellW = gly(0).srcW
        gridCellH = glyH
    END IF

    _SOURCE oldSrc&

    _LOGINFO "CBF: Packed grid: " + LTRIM$(STR$(glyCount)) + " glyphs, maxH=" + LTRIM$(STR$(glyH)) + " across " + LTRIM$(STR$(pRowCount%)) + " rows"
END SUB

' ============================================================================
' Build character-to-glyph lookup table
' ============================================================================
SUB CBF_build_char_lookup
    DIM i AS INTEGER, ch AS INTEGER

    FOR i% = 0 TO 255
        char2glyph(i%) = -1
    NEXT i%

    FOR i% = 1 TO LEN(charSeq$)
        IF i% - 1 < glyCount THEN
            ch% = ASC(MID$(charSeq$, i%, 1))
            char2glyph(ch%) = i% - 1
            ' Map lowercase to uppercase
            IF ch% >= 65 AND ch% <= 90 THEN
                char2glyph(ch% + 32) = i% - 1
            END IF
        END IF
    NEXT i%
END SUB

' ============================================================================
' Extract all glyphs from spritesheet, making background transparent
' Works for both marker-row and grid fonts using gly().srcY
' ============================================================================
SUB CBF_extract_glyphs
    DIM i AS INTEGER, x AS INTEGER, y AS INTEGER
    DIM gx AS INTEGER, gy AS INTEGER, gw AS INTEGER, gh AS INTEGER
    DIM srcC AS _UNSIGNED LONG
    DIM oldSrc AS LONG, oldDest AS LONG

    oldSrc& = _SOURCE
    oldDest& = _DEST
    _SOURCE sheet&

    FOR i% = 0 TO glyCount - 1
        gx% = gly(i%).srcX
        gy% = gly(i%).srcY
        gw% = gly(i%).srcW
        gh% = gly(i%).srcH
        IF gh% <= 0 THEN gh% = glyH ' Fallback to global height

        IF gw% < 1 OR gh% < 1 THEN _CONTINUE

        gly(i%).img = _NEWIMAGE(gw%, gh%, 32)
        IF gly(i%).img >= -1 THEN
            _LOGWARN "CBF: Failed to create glyph image " + LTRIM$(STR$(i%))
            _CONTINUE
        END IF

        _DEST gly(i%).img
        CLS , _RGBA32(0, 0, 0, 0) ' Fully transparent background

        ' Copy pixels from spritesheet at (gx, gy) -> (gx+gw-1, gy+gh-1)
        ' Replace background color with transparent
        FOR y% = 0 TO gh% - 1
            FOR x% = 0 TO gw% - 1
                srcC~& = POINT(gx% + x%, gy% + y%)
                IF srcC~& <> bgClr THEN
                    PSET (x%, y%), srcC~&
                END IF
            NEXT x%
        NEXT y%
    NEXT i%

    _DEST oldDest&
    _SOURCE oldSrc&
END SUB

' ============================================================================
' Render text string at given position using color bitmap font
' ============================================================================
SUB CBF_render_text (text$, startX%, startY%)
    DIM i AS INTEGER, ch AS INTEGER, gi AS INTEGER
    DIM xPos AS INTEGER

    xPos% = startX%

    FOR i% = 1 TO LEN(text$)
        ch% = ASC(MID$(text$, i%, 1))

        IF ch% = 32 THEN
            xPos% = xPos% + spaceW + charSpacing
            _CONTINUE
        END IF

        gi% = char2glyph(ch%)
        IF gi% >= 0 AND gi% < glyCount THEN
            IF gly(gi%).img < -1 THEN
                _PUTIMAGE (xPos%, startY%), gly(gi%).img
                xPos% = xPos% + gly(gi%).srcW + charSpacing
            END IF
        END IF
    NEXT i%
END SUB

' ============================================================================
' Measure rendered text width in pixels
' ============================================================================
FUNCTION CBF_text_width% (text$)
    DIM i AS INTEGER, ch AS INTEGER, gi AS INTEGER
    DIM w AS INTEGER

    w% = 0
    FOR i% = 1 TO LEN(text$)
        ch% = ASC(MID$(text$, i%, 1))
        IF ch% = 32 THEN
            w% = w% + spaceW + charSpacing
        ELSE
            gi% = char2glyph(ch%)
            IF gi% >= 0 AND gi% < glyCount THEN
                w% = w% + gly(gi%).srcW + charSpacing
            END IF
        END IF
    NEXT i%
    CBF_text_width% = w%
END FUNCTION

' ============================================================================
' Free glyph images and spritesheet
' ============================================================================
SUB CBF_free_glyphs
    DIM i AS INTEGER
    FOR i% = 0 TO glyCount - 1
        IF gly(i%).img < -1 THEN
            _FREEIMAGE gly(i%).img
            gly(i%).img = 0
        END IF
    NEXT i%
    glyCount = 0
    IF sheet& < -1 THEN
        _FREEIMAGE sheet&
        sheet& = 0
    END IF
END SUB

' ============================================================================
' Initialize font file list via runtime directory scan
' Scans: ./FONTS/COLOR_BITMAP/*.bmp, <bitmapFontsDir>/*.png, font-pack/*.png
' ============================================================================
SUB CBF_init_font_list
    DIM tmpFile AS STRING
    DIM cmd AS STRING

    fontFileCount = 0
    fontFileIdx = 0
    tmpFile$ = "/tmp/cbf_fontlist_" + LTRIM$(STR$(INT(RND * 99999))) + ".txt"

    ' --- Source 1: existing BMP fonts in DEV/FONTS/COLOR_BITMAP/ ---
    IF _DIREXISTS("./FONTS/COLOR_BITMAP") THEN
        cmd$ = "find " + CHR$(34) + "./FONTS/COLOR_BITMAP" + CHR$(34)
        cmd$ = cmd$ + " -maxdepth 1 -type f \( -iname '*.bmp' -o -iname '*.png' \) 2>/dev/null | sort > " + CHR$(34) + tmpFile$ + CHR$(34)
        SHELL _HIDE cmd$
        CBF_read_font_list tmpFile$
    END IF

    ' --- Source 2: BitmapFonts root directory ---
    IF LEN(bitmapFontsDir$) > 0 AND _DIREXISTS(bitmapFontsDir$) THEN
        cmd$ = "find " + CHR$(34) + bitmapFontsDir$ + CHR$(34)
        cmd$ = cmd$ + " -maxdepth 1 -type f \( -iname '*.bmp' -o -iname '*.png' \) 2>/dev/null | sort > " + CHR$(34) + tmpFile$ + CHR$(34)
        SHELL _HIDE cmd$
        CBF_read_font_list tmpFile$

        ' --- Source 3: BitmapFonts/font-pack/ subdirectory ---
        DIM fpDir AS STRING
        fpDir$ = bitmapFontsDir$ + "font-pack/"
        IF _DIREXISTS(fpDir$) THEN
            cmd$ = "find " + CHR$(34) + fpDir$ + CHR$(34)
            cmd$ = cmd$ + " -maxdepth 1 -type f \( -iname '*.bmp' -o -iname '*.png' \) 2>/dev/null | sort > " + CHR$(34) + tmpFile$ + CHR$(34)
            SHELL _HIDE cmd$
            CBF_read_font_list tmpFile$
        END IF
    END IF

    ' Clean up temp file
    IF _FILEEXISTS(tmpFile$) THEN KILL tmpFile$

    _LOGINFO "CBF: Discovered " + LTRIM$(STR$(fontFileCount)) + " font files"
END SUB

' ============================================================================
' Read font paths from a temp file into fontFiles() array
' ============================================================================
SUB CBF_read_font_list (tmpFile$)
    IF NOT _FILEEXISTS(tmpFile$) THEN EXIT SUB

    DIM ff AS INTEGER
    DIM ln AS STRING

    ff% = FREEFILE
    OPEN tmpFile$ FOR INPUT AS #ff%
    DO WHILE NOT EOF(ff%)
        LINE INPUT #ff%, ln$
        ln$ = LTRIM$(RTRIM$(ln$))
        IF LEN(ln$) = 0 THEN _CONTINUE
        IF fontFileCount >= MAX_FONTS THEN EXIT DO
        fontFiles(fontFileCount) = ln$
        fontFileCount = fontFileCount + 1
    LOOP
    CLOSE #ff%
END SUB

' ============================================================================
' Detect 16x16 grid layout — fallback when marker-row detection fails
' ============================================================================
SUB CBF_detect_grid
    DIM oldSrc AS LONG
    DIM row AS INTEGER, col AS INTEGER
    DIM charIdx AS INTEGER

    ' Calculate cell dimensions
    gridCellW = sheetW \ 16
    gridCellH = sheetH \ 16

    IF gridCellW < 1 OR gridCellH < 1 THEN EXIT SUB

    glyH = gridCellH

    ' Detect background color from corners of the image
    oldSrc& = _SOURCE
    _SOURCE sheet&

    DIM cornerClr(0 TO 3) AS _UNSIGNED LONG
    cornerClr(0) = POINT(0, 0)
    cornerClr(1) = POINT(sheetW - 1, 0)
    cornerClr(2) = POINT(0, sheetH - 1)
    cornerClr(3) = POINT(sheetW - 1, sheetH - 1)

    ' Most common corner color = background
    DIM ci AS INTEGER, cj AS INTEGER
    DIM bestClr AS _UNSIGNED LONG
    DIM bestCnt AS INTEGER, cnt AS INTEGER
    bestCnt% = 0
    FOR ci% = 0 TO 3
        cnt% = 0
        FOR cj% = 0 TO 3
            IF cornerClr(ci%) = cornerClr(cj%) THEN cnt% = cnt% + 1
        NEXT cj%
        IF cnt% > bestCnt% THEN
            bestCnt% = cnt%
            bestClr~& = cornerClr(ci%)
        END IF
    NEXT ci%
    bgClr = bestClr~&
    mkClr = _RGB32(255, 255, 0) ' No marker in grid mode

    _SOURCE oldSrc&

    ' Build glyph entries for printable ASCII (32-127) mapped from grid positions
    glyCount = 0
    charSeq$ = ""

    FOR charIdx% = 32 TO 127
        IF glyCount >= MAX_GLYPHS THEN EXIT FOR
        row% = charIdx% \ 16
        col% = charIdx% MOD 16

        gly(glyCount).srcX = col% * gridCellW
        gly(glyCount).srcY = row% * gridCellH
        gly(glyCount).srcW = gridCellW
        gly(glyCount).srcH = gridCellH
        charSeq$ = charSeq$ + CHR$(charIdx%)
        glyCount = glyCount + 1
    NEXT charIdx%

    _LOGINFO "CBF: Grid mode " + LTRIM$(STR$(gridCellW)) + "x" + LTRIM$(STR$(gridCellH)) + " cells, " + LTRIM$(STR$(glyCount)) + " glyphs"
END SUB

' ============================================================================
' Build character-to-glyph lookup for grid fonts (direct ASCII mapping)
' ============================================================================
SUB CBF_build_char_lookup_grid
    DIM i AS INTEGER, ch AS INTEGER

    FOR i% = 0 TO 255
        char2glyph(i%) = -1
    NEXT i%

    ' charSeq$ contains CHR$(32) through CHR$(127) in order
    FOR i% = 1 TO LEN(charSeq$)
        IF i% - 1 < glyCount THEN
            ch% = ASC(MID$(charSeq$, i%, 1))
            char2glyph(ch%) = i% - 1
            ' Map uppercase to lowercase and vice versa
            IF ch% >= 65 AND ch% <= 90 THEN
                IF char2glyph(ch% + 32) = -1 THEN char2glyph(ch% + 32) = i% - 1
            ELSEIF ch% >= 97 AND ch% <= 122 THEN
                IF char2glyph(ch% - 32) = -1 THEN char2glyph(ch% - 32) = i% - 1
            END IF
        END IF
    NEXT i%
END SUB

' ============================================================================
' Get font source label (which collection this font came from)
' ============================================================================
FUNCTION CBF_source_label$ (path$)
    IF INSTR(path$, "font-pack") > 0 THEN
        CBF_source_label$ = "font-pack"
    ELSEIF INSTR(path$, "COLOR_BITMAP") > 0 THEN
        CBF_source_label$ = "COLOR_BITMAP"
    ELSEIF INSTR(path$, "BitmapFonts") > 0 THEN
        CBF_source_label$ = "BitmapFonts"
    ELSE
        CBF_source_label$ = "local"
    END IF
END FUNCTION

' ============================================================================
' Get font type label
' ============================================================================
FUNCTION CBF_type_label$ ()
    SELECT CASE fontType
        CASE FTYPE_MARKER_ROW
            CBF_type_label$ = "MARKER ROW"
        CASE FTYPE_MULTI_MARKER
            CBF_type_label$ = "MULTI MARKER (" + LTRIM$(STR$(glyCount)) + " glyphs)"
        CASE FTYPE_PACKED_GRID
            CBF_type_label$ = "PACKED GRID"
        CASE FTYPE_GRID
            CBF_type_label$ = "GRID " + LTRIM$(STR$(gridCellW)) + "x" + LTRIM$(STR$(gridCellH))
        CASE ELSE
            CBF_type_label$ = "UNKNOWN"
    END SELECT
END FUNCTION

' ============================================================================
' Draw a gradient background
' ============================================================================
SUB CBF_draw_background
    DIM y AS INTEGER
    DIM r AS INTEGER, g AS INTEGER, b AS INTEGER
    FOR y% = 0 TO SCR_H - 1
        r% = 25 + y% * 35 \ SCR_H
        g% = 20 + y% * 25 \ SCR_H
        b% = 55 + y% * 65 \ SCR_H
        LINE (0, y%)-(SCR_W - 1, y%), _RGB32(r%, g%, b%)
    NEXT y%
END SUB

' ============================================================================
' Draw a checkerboard rectangle (shows transparency)
' ============================================================================
SUB CBF_draw_checker (x1%, y1%, w%, h%)
    DIM cx AS INTEGER, cy AS INTEGER
    DIM clr AS _UNSIGNED LONG
    FOR cy% = 0 TO h% - 1 STEP 4
        FOR cx% = 0 TO w% - 1 STEP 4
            IF ((cx% \ 4) + (cy% \ 4)) MOD 2 = 0 THEN
                clr~& = _RGB32(70, 70, 70)
            ELSE
                clr~& = _RGB32(110, 110, 110)
            END IF
            LINE (x1% + cx%, y1% + cy%)-(x1% + cx% + 3, y1% + cy% + 3), clr~&, BF
        NEXT cx%
    NEXT cy%
END SUB

' ============================================================================
' Extract just the filename from a path
' ============================================================================
FUNCTION CBF_filename$ (path$)
    DIM p AS INTEGER
    DIM idx AS INTEGER

    p% = 0
    FOR idx% = LEN(path$) TO 1 STEP -1
        IF MID$(path$, idx%, 1) = "/" OR MID$(path$, idx%, 1) = "\" THEN
            p% = idx%
            EXIT FOR
        END IF
    NEXT idx%

    IF p% > 0 THEN
        CBF_filename$ = MID$(path$, p% + 1)
    ELSE
        CBF_filename$ = path$
    END IF
END FUNCTION

' ============================================================================
' Main display and interactive loop
' ============================================================================
SUB CBF_main_loop
    DIM typedText AS STRING
    DIM k AS LONG
    DIM needRedraw AS INTEGER
    DIM yy AS INTEGER
    DIM i AS INTEGER
    DIM xp AS INTEGER
    DIM fn AS STRING
    DIM ch AS STRING
    DIM infoLine AS STRING

    typedText$ = ""
    needRedraw% = -1 ' TRUE

    DO
        IF needRedraw% THEN
            ' --- Background gradient ---
            CBF_draw_background

            yy% = 8

            ' --- Font index and name header ---
            fn$ = CBF_filename$(curFontPath$)

            infoLine$ = "Font " + LTRIM$(STR$(fontFileIdx + 1)) + "/" + LTRIM$(STR$(fontFileCount))
            infoLine$ = infoLine$ + "  |  " + fn$
            infoLine$ = infoLine$ + "  |  [" + CBF_source_label$(curFontPath$) + "]"

            COLOR _RGB32(255, 255, 100)
            _PRINTSTRING (10, yy%), infoLine$
            yy% = yy% + 18

            IF loadFailed% THEN
                ' --- Load failure display ---
                COLOR _RGB32(255, 80, 80)
                _PRINTSTRING (10, yy%), "LOAD FAILED — could not parse as marker-row or grid font"
                yy% = yy% + 18
                _PRINTSTRING (10, yy%), "Path: " + curFontPath$
                yy% = yy% + 18
                COLOR _RGB32(180, 180, 180)
                _PRINTSTRING (10, yy%), "Use Left/Right arrows to cycle to another font"
                yy% = yy% + 30
            ELSE
                ' --- Font details ---
                infoLine$ = "[" + CBF_type_label$ + "]"
                infoLine$ = infoLine$ + "  |  Sheet: " + LTRIM$(STR$(sheetW)) + "x" + LTRIM$(STR$(sheetH))
                infoLine$ = infoLine$ + "  |  Glyphs: " + LTRIM$(STR$(glyCount))
                infoLine$ = infoLine$ + "  |  Height: " + LTRIM$(STR$(glyH)) + "px"
                infoLine$ = infoLine$ + "  |  Spacing: " + LTRIM$(STR$(charSpacing)) + "px"

                COLOR _RGB32(200, 200, 200)
                _PRINTSTRING (10, yy%), infoLine$
                yy% = yy% + 18

                infoLine$ = "BG: RGB(" + LTRIM$(STR$(_RED32(bgClr)))
                infoLine$ = infoLine$ + "," + LTRIM$(STR$(_GREEN32(bgClr)))
                infoLine$ = infoLine$ + "," + LTRIM$(STR$(_BLUE32(bgClr))) + ")"
                IF fontType = FTYPE_MARKER_ROW THEN
                    infoLine$ = infoLine$ + "   Marker: RGB(" + LTRIM$(STR$(_RED32(mkClr)))
                    infoLine$ = infoLine$ + "," + LTRIM$(STR$(_GREEN32(mkClr)))
                    infoLine$ = infoLine$ + "," + LTRIM$(STR$(_BLUE32(mkClr))) + ")"
                END IF

                COLOR _RGB32(150, 150, 150)
                _PRINTSTRING (10, yy%), infoLine$
                yy% = yy% + 22

                ' --- Original spritesheet ---
                COLOR _RGB32(150, 150, 150)
                IF fontType = FTYPE_MARKER_ROW THEN
                    _PRINTSTRING (10, yy%), "Original spritesheet (with marker indicators):"
                ELSE
                    _PRINTSTRING (10, yy%), "Original spritesheet (grid layout):"
                END IF
                yy% = yy% + 16

                IF sheet& < -1 THEN
                    ' Cap display size to fit screen
                    DIM dispW AS INTEGER, dispH AS INTEGER
                    dispW% = sheetW: IF dispW% > SCR_W - 20 THEN dispW% = SCR_W - 20
                    dispH% = sheetH: IF dispH% > 300 THEN dispH% = 300

                    ' Draw checkerboard behind spritesheet to show any transparency
                    CBF_draw_checker 10, yy%, dispW%, dispH%

                    IF dispW% = sheetW AND dispH% = sheetH THEN
                        _PUTIMAGE (10, yy%), sheet&
                    ELSE
                        _PUTIMAGE (10, yy%)-(10 + dispW% - 1, yy% + dispH% - 1), sheet&, , (0, 0)-(dispW% - 1, dispH% - 1)
                    END IF

                    ' Draw red tick marks above each detected glyph position
                    IF fontType = FTYPE_MARKER_ROW THEN
                        FOR i% = 0 TO glyCount - 1
                            IF gly(i%).srcX < dispW% THEN
                                LINE (10 + gly(i%).srcX, yy% - 4)-(10 + gly(i%).srcX, yy% - 1), _RGB32(255, 50, 50)
                            END IF
                        NEXT i%
                    END IF
                END IF
                yy% = yy% + dispH% + 10

                ' --- Extracted glyphs with character labels ---
                COLOR _RGB32(150, 150, 150)
                _PRINTSTRING (10, yy%), "Extracted glyphs (bg=transparent, on checkerboard):"
                yy% = yy% + 16

                ' Cap how many glyphs we display (for large grid fonts)
                DIM maxDisplay AS INTEGER
                maxDisplay% = glyCount
                IF maxDisplay% > 96 THEN maxDisplay% = 96

                xp% = 10
                FOR i% = 0 TO maxDisplay% - 1
                    IF gly(i%).img < -1 THEN
                        ' Checkerboard behind glyph
                        CBF_draw_checker xp%, yy%, gly(i%).srcW, glyH

                        ' Glyph on top
                        _PUTIMAGE (xp%, yy%), gly(i%).img

                        ' Character label below
                        IF i% < LEN(charSeq$) THEN
                            ch$ = MID$(charSeq$, i% + 1, 1)
                        ELSE
                            ch$ = "?"
                        END IF
                        COLOR _RGB32(200, 200, 200)
                        _PRINTSTRING (xp%, yy% + glyH + 2), ch$

                        xp% = xp% + gly(i%).srcW + 2

                        ' Wrap to next row if needed
                        IF xp% > SCR_W - 30 THEN
                            xp% = 10
                            yy% = yy% + glyH + 16
                            ' Don't overflow screen
                            IF yy% > SCR_H - 120 THEN EXIT FOR
                        END IF
                    END IF
                NEXT i%
                yy% = yy% + glyH + 22

                ' --- Character map info ---
                IF LEN(charSeq$) > 0 THEN
                    COLOR _RGB32(120, 120, 120)
                    DIM mapInfo AS STRING
                    mapInfo$ = "Char map (ASCII " + LTRIM$(STR$(ASC(LEFT$(charSeq$, 1)))) + "-" + LTRIM$(STR$(ASC(RIGHT$(charSeq$, 1)))) + "): "
                    IF LEN(charSeq$) <= 96 THEN
                        mapInfo$ = mapInfo$ + charSeq$
                    ELSE
                        mapInfo$ = mapInfo$ + LEFT$(charSeq$, 96) + "..."
                    END IF
                    _PRINTSTRING (10, yy%), mapInfo$
                    yy% = yy% + 20
                END IF

                ' --- Sample text (only if room) ---
                IF yy% < SCR_H - 100 THEN
                    COLOR _RGB32(150, 150, 150)
                    _PRINTSTRING (10, yy%), "Sample text:"
                    yy% = yy% + 16

                    CBF_render_text "HELLO WORLD!", 10, yy%
                    yy% = yy% + glyH + 4

                    IF yy% < SCR_H - 80 THEN
                        CBF_render_text "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 10, yy%
                        yy% = yy% + glyH + 4
                    END IF

                    IF yy% < SCR_H - 80 THEN
                        CBF_render_text "0123456789 !@#$%", 10, yy%
                        yy% = yy% + glyH + 4
                    END IF

                    IF yy% < SCR_H - 80 THEN
                        CBF_render_text "the quick brown fox jumps over the lazy dog", 10, yy%
                        yy% = yy% + glyH + 16
                    END IF
                END IF

                ' --- Typed text ---
                IF yy% < SCR_H - 40 THEN
                    IF LEN(typedText$) > 0 THEN
                        CBF_render_text typedText$, 10, yy%
                    END IF

                    ' Cursor blink
                    DIM curX AS INTEGER
                    curX% = 10 + CBF_text_width%(typedText$)
                    LINE (curX%, yy%)-(curX% + 1, yy% + glyH - 1), _RGB32(255, 255, 255), BF
                    yy% = yy% + glyH + 8
                END IF
            END IF

            ' --- Controls help (always show at bottom) ---
            DIM helpY AS INTEGER
            helpY% = SCR_H - 20
            COLOR _RGB32(255, 255, 100)
            _PRINTSTRING (10, helpY%), "Type text  |  L/R=cycle  |  PgUp/Dn=skip 10  |  Home/End=first/last  |  U/D=spacing  |  Enter=clear  |  ESC=quit"

            _DISPLAY
            needRedraw% = 0
        END IF

        ' --- Input handling ---
        k& = _KEYHIT

        SELECT CASE k&
            CASE 27 ' ESC
                EXIT DO

            CASE 13 ' Enter = clear text
                typedText$ = ""
                needRedraw% = -1

            CASE 8 ' Backspace
                IF LEN(typedText$) > 0 THEN
                    typedText$ = LEFT$(typedText$, LEN(typedText$) - 1)
                    needRedraw% = -1
                END IF

            CASE KEY_LEFT ' Previous font
                IF fontFileCount > 1 THEN
                    fontFileIdx = fontFileIdx - 1
                    IF fontFileIdx < 0 THEN fontFileIdx = fontFileCount - 1
                    loadFailed% = 0
                    IF NOT CBF_load%(fontFiles(fontFileIdx)) THEN loadFailed% = -1
                    needRedraw% = -1
                END IF

            CASE KEY_RIGHT ' Next font
                IF fontFileCount > 1 THEN
                    fontFileIdx = fontFileIdx + 1
                    IF fontFileIdx >= fontFileCount THEN fontFileIdx = 0
                    loadFailed% = 0
                    IF NOT CBF_load%(fontFiles(fontFileIdx)) THEN loadFailed% = -1
                    needRedraw% = -1
                END IF

            CASE KEY_PGUP ' Skip 10 fonts back
                IF fontFileCount > 1 THEN
                    fontFileIdx = fontFileIdx - 10
                    IF fontFileIdx < 0 THEN fontFileIdx = fontFileCount + fontFileIdx
                    IF fontFileIdx < 0 THEN fontFileIdx = 0
                    loadFailed% = 0
                    IF NOT CBF_load%(fontFiles(fontFileIdx)) THEN loadFailed% = -1
                    needRedraw% = -1
                END IF

            CASE KEY_PGDN ' Skip 10 fonts forward
                IF fontFileCount > 1 THEN
                    fontFileIdx = fontFileIdx + 10
                    IF fontFileIdx >= fontFileCount THEN fontFileIdx = fontFileIdx - fontFileCount
                    IF fontFileIdx >= fontFileCount THEN fontFileIdx = fontFileCount - 1
                    loadFailed% = 0
                    IF NOT CBF_load%(fontFiles(fontFileIdx)) THEN loadFailed% = -1
                    needRedraw% = -1
                END IF

            CASE KEY_HOME ' First font
                IF fontFileCount > 0 THEN
                    fontFileIdx = 0
                    loadFailed% = 0
                    IF NOT CBF_load%(fontFiles(fontFileIdx)) THEN loadFailed% = -1
                    needRedraw% = -1
                END IF

            CASE KEY_END ' Last font
                IF fontFileCount > 0 THEN
                    fontFileIdx = fontFileCount - 1
                    loadFailed% = 0
                    IF NOT CBF_load%(fontFiles(fontFileIdx)) THEN loadFailed% = -1
                    needRedraw% = -1
                END IF

            CASE KEY_UP ' Increase spacing
                charSpacing = charSpacing + 1
                IF charSpacing > 20 THEN charSpacing = 20
                needRedraw% = -1

            CASE KEY_DOWN ' Decrease spacing
                charSpacing = charSpacing - 1
                IF charSpacing < -5 THEN charSpacing = -5
                needRedraw% = -1

            CASE 32 TO 126 ' Printable ASCII
                typedText$ = typedText$ + CHR$(k&)
                needRedraw% = -1

        END SELECT

        _LIMIT 30
    LOOP
END SUB
