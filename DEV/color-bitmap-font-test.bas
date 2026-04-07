OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ============================================================================
' Color Bitmap Font (CBF) Test Program
' ============================================================================
' Loads Amiga/DPaint-style spritesheet fonts (.BMP) and renders text
' preserving original pixel colors.
'
' Format convention (DPaint-style):
'   - Row 0 = marker row (single-pixel markers indicate glyph starts)
'   - Rows 1..H-1 = glyph pixel data
'   - Background color = most frequent color at y=0
'   - Marker color = isolated non-background pixels at y=0
'   - Variable-width glyphs (width = distance between markers)
'
' Usage:
'   color-bitmap-font-test.run [path-to-bmp]
'   Defaults to DEV/FONTS/COLOR_BITMAP/epicpin.bmp
'
' Controls:
'   Type text to render with color font
'   Backspace = delete last char
'   Enter = clear typed text
'   Left/Right arrows = cycle through fonts
'   Up/Down arrows = adjust spacing
'   ESC = quit
' ============================================================================

' --- Constants ---
CONST SCR_W = 1280
CONST SCR_H = 900
CONST MAX_GLYPHS = 128
CONST MAX_FONTS = 30

' Extended key codes
CONST KEY_LEFT = 19200
CONST KEY_RIGHT = 19712
CONST KEY_UP = 18432
CONST KEY_DOWN = 20480

' --- Types ---
TYPE CBF_GLYPH_T
    srcX AS INTEGER ' X position in source spritesheet
    srcW AS INTEGER ' Width in pixels
    img AS LONG     ' Extracted glyph image handle (bg = transparent)
END TYPE

' --- Shared state ---
DIM SHARED gly(0 TO MAX_GLYPHS - 1) AS CBF_GLYPH_T
DIM SHARED char2glyph(0 TO 255) AS INTEGER ' ASCII code -> glyph index (-1 = unmapped)
DIM SHARED glyCount AS INTEGER             ' Number of detected glyphs
DIM SHARED sheet AS LONG                   ' Spritesheet image handle
DIM SHARED sheetW AS INTEGER               ' Spritesheet width
DIM SHARED sheetH AS INTEGER               ' Spritesheet height
DIM SHARED glyH AS INTEGER                 ' Actual glyph height (sheetH - 1, minus marker row)
DIM SHARED bgClr AS _UNSIGNED LONG         ' Detected background color
DIM SHARED mkClr AS _UNSIGNED LONG         ' Detected marker color
DIM SHARED charSeq AS STRING               ' Character sequence mapping
DIM SHARED charSpacing AS INTEGER          ' Pixel gap between rendered characters
DIM SHARED spaceW AS INTEGER               ' Width of space character (average glyph width)
DIM SHARED curFontPath AS STRING           ' Current font file path

' Font list for cycling
DIM SHARED fontFiles(0 TO MAX_FONTS - 1) AS STRING
DIM SHARED fontFileCount AS INTEGER
DIM SHARED fontFileIdx AS INTEGER

' ============================================================================
' MAIN
' ============================================================================
DIM fontArg AS STRING
DIM scrn AS LONG
DIM i AS INTEGER

' Build font file list
CBF_init_font_list

fontArg$ = COMMAND$
IF LEN(fontArg$) = 0 THEN
    fontArg$ = "./FONTS/COLOR_BITMAP/epicpin.bmp"
    ' Find epicpin in list and set index
    FOR i% = 0 TO fontFileCount - 1
        IF INSTR(LCASE$(fontFiles(i%)), "epicpin") > 0 THEN
            fontFileIdx = i%
            EXIT FOR
        END IF
    NEXT i%
END IF

scrn& = _NEWIMAGE(SCR_W, SCR_H, 32)
SCREEN scrn&
_TITLE "Color Bitmap Font Test"
_PRINTMODE _KEEPBACKGROUND

IF NOT CBF_load%(fontArg$) THEN
    COLOR _RGB32(255, 80, 80)
    PRINT "ERROR: Could not load "; fontArg$
    PRINT "Press any key to exit..."
    _DISPLAY
    SLEEP
    SYSTEM
END IF

CBF_main_loop

CBF_free_glyphs
SYSTEM

' ============================================================================
' Load a color bitmap font spritesheet
' Returns TRUE (-1) on success, FALSE (0) on failure
' ============================================================================
FUNCTION CBF_load% (path$)
    CBF_load% = 0
    curFontPath$ = path$

    ' Free any previous font data
    CBF_free_glyphs

    ' Load spritesheet as 32-bit RGBA
    sheet& = _LOADIMAGE(path$, 32)
    IF sheet& >= -1 THEN EXIT FUNCTION

    sheetW = _WIDTH(sheet&)
    sheetH = _HEIGHT(sheet&)
    glyH = sheetH - 1 ' Row 0 is marker row

    IF glyH < 1 THEN
        _FREEIMAGE sheet&
        sheet& = 0
        EXIT FUNCTION
    END IF

    ' Detect markers and glyph boundaries
    CBF_detect_markers

    IF glyCount < 1 THEN
        _FREEIMAGE sheet&
        sheet& = 0
        EXIT FUNCTION
    END IF

    ' Build default character sequence (ASCII 33 through 33+glyphCount-1)
    charSeq$ = ""
    DIM ci AS INTEGER
    FOR ci% = 33 TO 33 + glyCount - 1
        IF ci% > 126 THEN EXIT FOR
        charSeq$ = charSeq$ + CHR$(ci%)
    NEXT ci%

    CBF_build_char_lookup

    ' Extract glyph images
    CBF_extract_glyphs

    ' Compute space width = average glyph width
    DIM totalW AS LONG
    totalW& = 0
    FOR ci% = 0 TO glyCount - 1
        totalW& = totalW& + gly(ci%).srcW
    NEXT ci%
    IF glyCount > 0 THEN
        spaceW = totalW& \ glyCount
    ELSE
        spaceW = 8
    END IF

    charSpacing = 1
    CBF_load% = -1 ' TRUE
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
' ============================================================================
SUB CBF_extract_glyphs
    DIM i AS INTEGER, x AS INTEGER, y AS INTEGER
    DIM gx AS INTEGER, gw AS INTEGER
    DIM srcC AS _UNSIGNED LONG
    DIM oldSrc AS LONG, oldDest AS LONG

    oldSrc& = _SOURCE
    oldDest& = _DEST
    _SOURCE sheet&

    FOR i% = 0 TO glyCount - 1
        gx% = gly(i%).srcX
        gw% = gly(i%).srcW

        gly(i%).img = _NEWIMAGE(gw%, glyH, 32)
        IF gly(i%).img >= -1 THEN
            _LOGWARN "CBF: Failed to create glyph image " + LTRIM$(STR$(i%))
            _CONTINUE
        END IF

        _DEST gly(i%).img
        CLS , _RGBA32(0, 0, 0, 0) ' Fully transparent background

        ' Copy pixels from spritesheet, skipping marker row (y+1)
        ' Replace background color with transparent
        FOR y% = 0 TO glyH - 1
            FOR x% = 0 TO gw% - 1
                srcC~& = POINT(gx% + x%, y% + 1)
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
' Initialize font file list (hardcoded from DEV/FONTS/COLOR_BITMAP/)
' ============================================================================
SUB CBF_init_font_list
    DIM b AS STRING
    b$ = "./FONTS/COLOR_BITMAP/"

    fontFileCount = 0
    fontFileIdx = 0

    fontFiles(0) = b$ + "epicpin.bmp"
    fontFiles(1) = b$ + "mario3.bmp"
    fontFiles(2) = b$ + "anomaly.bmp"
    fontFiles(3) = b$ + "BlazingStar.bmp"
    fontFiles(4) = b$ + "BlazingStar2.bmp"
    fontFiles(5) = b$ + "bubsy.bmp"
    fontFiles(6) = b$ + "coolspot.bmp"
    fontFiles(7) = b$ + "ddrocr.bmp"
    fontFiles(8) = b$ + "ddrolive.bmp"
    fontFiles(9) = b$ + "ddrsmall.bmp"
    fontFiles(10) = b$ + "ddrtiny.bmp"
    fontFiles(11) = b$ + "dkc2.bmp"
    fontFiles(12) = b$ + "furyfurries.bmp"
    fontFiles(13) = b$ + "lemblue.bmp"
    fontFiles(14) = b$ + "lemcyan.bmp"
    fontFiles(15) = b$ + "lemgreen.bmp"
    fontFiles(16) = b$ + "lemorange.bmp"
    fontFiles(17) = b$ + "lempurple.bmp"
    fontFiles(18) = b$ + "lemred.bmp"
    fontFiles(19) = b$ + "lemyellow.bmp"
    fontFiles(20) = b$ + "magic-pockets.bmp"
    fontFiles(21) = b$ + "ontheball.bmp"
    fontFiles(22) = b$ + "ontheball-big.bmp"
    fontFiles(23) = b$ + "xenon2.bmp"
    fontFileCount = 24
END SUB

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

            ' --- Font info header ---
            fn$ = CBF_filename$(curFontPath$)

            infoLine$ = "FONT: " + fn$
            infoLine$ = infoLine$ + "  |  Sheet: " + LTRIM$(STR$(sheetW)) + "x" + LTRIM$(STR$(sheetH))
            infoLine$ = infoLine$ + "  |  Glyphs: " + LTRIM$(STR$(glyCount))
            infoLine$ = infoLine$ + "  |  Height: " + LTRIM$(STR$(glyH)) + "px"
            infoLine$ = infoLine$ + "  |  Spacing: " + LTRIM$(STR$(charSpacing)) + "px"

            COLOR _RGB32(255, 255, 100)
            _PRINTSTRING (10, yy%), infoLine$
            yy% = yy% + 18

            infoLine$ = "BG: RGB(" + LTRIM$(STR$(_RED32(bgClr)))
            infoLine$ = infoLine$ + "," + LTRIM$(STR$(_GREEN32(bgClr)))
            infoLine$ = infoLine$ + "," + LTRIM$(STR$(_BLUE32(bgClr))) + ")"
            infoLine$ = infoLine$ + "   Marker: RGB(" + LTRIM$(STR$(_RED32(mkClr)))
            infoLine$ = infoLine$ + "," + LTRIM$(STR$(_GREEN32(mkClr)))
            infoLine$ = infoLine$ + "," + LTRIM$(STR$(_BLUE32(mkClr))) + ")"

            COLOR _RGB32(180, 180, 180)
            _PRINTSTRING (10, yy%), infoLine$
            yy% = yy% + 22

            ' --- Original spritesheet ---
            COLOR _RGB32(150, 150, 150)
            _PRINTSTRING (10, yy%), "Original spritesheet (with marker indicators):"
            yy% = yy% + 16

            IF sheet& < -1 THEN
                ' Draw checkerboard behind spritesheet to show any transparency
                CBF_draw_checker 10, yy%, sheetW, sheetH
                _PUTIMAGE (10, yy%), sheet&

                ' Draw red tick marks above each detected marker position
                FOR i% = 0 TO glyCount - 1
                    LINE (10 + gly(i%).srcX, yy% - 4)-(10 + gly(i%).srcX, yy% - 1), _RGB32(255, 50, 50)
                NEXT i%
            END IF
            yy% = yy% + sheetH + 10

            ' --- Extracted glyphs with character labels ---
            COLOR _RGB32(150, 150, 150)
            _PRINTSTRING (10, yy%), "Extracted glyphs (bg=transparent, on checkerboard):"
            yy% = yy% + 16

            xp% = 10
            FOR i% = 0 TO glyCount - 1
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
                    END IF
                END IF
            NEXT i%
            yy% = yy% + glyH + 22

            ' --- Character map info ---
            COLOR _RGB32(120, 120, 120)
            _PRINTSTRING (10, yy%), "Char map (ASCII " + LTRIM$(STR$(ASC(LEFT$(charSeq$, 1)))) + "-" + LTRIM$(STR$(ASC(RIGHT$(charSeq$, 1)))) + "): " + charSeq$
            yy% = yy% + 20

            ' --- Sample text ---
            COLOR _RGB32(150, 150, 150)
            _PRINTSTRING (10, yy%), "Sample text:"
            yy% = yy% + 16

            CBF_render_text "HELLO WORLD!", 10, yy%
            yy% = yy% + glyH + 4

            CBF_render_text "ABCDEFGHIJKLMNOPQRSTUVWXYZ", 10, yy%
            yy% = yy% + glyH + 4

            CBF_render_text "0123456789 !@#$%", 10, yy%
            yy% = yy% + glyH + 4

            CBF_render_text "THE QUICK BROWN FOX JUMPS", 10, yy%
            yy% = yy% + glyH + 4

            CBF_render_text "OVER THE LAZY DOG", 10, yy%
            yy% = yy% + glyH + 16

            ' --- Controls help ---
            COLOR _RGB32(255, 255, 100)
            _PRINTSTRING (10, yy%), "Type below  |  Left/Right=cycle fonts  |  Up/Down=spacing  |  Enter=clear  |  ESC=quit"
            yy% = yy% + 20

            ' --- Typed text ---
            IF LEN(typedText$) > 0 THEN
                CBF_render_text typedText$, 10, yy%
            END IF

            ' Cursor blink
            DIM curX AS INTEGER
            curX% = 10 + CBF_text_width%(typedText$)
            LINE (curX%, yy%)-(curX% + 1, yy% + glyH - 1), _RGB32(255, 255, 255), BF

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
                    IF CBF_load%(fontFiles(fontFileIdx)) THEN
                        needRedraw% = -1
                    END IF
                END IF

            CASE KEY_RIGHT ' Next font
                IF fontFileCount > 1 THEN
                    fontFileIdx = fontFileIdx + 1
                    IF fontFileIdx >= fontFileCount THEN fontFileIdx = 0
                    IF CBF_load%(fontFiles(fontFileIdx)) THEN
                        needRedraw% = -1
                    END IF
                END IF

            CASE KEY_UP ' Increase spacing
                charSpacing = charSpacing + 1
                IF charSpacing > 20 THEN charSpacing = 20
                needRedraw% = -1

            CASE KEY_DOWN ' Decrease spacing
                charSpacing = charSpacing - 1
                IF charSpacing < 0 THEN charSpacing = 0
                needRedraw% = -1

            CASE 32 TO 126 ' Printable ASCII
                typedText$ = typedText$ + CHR$(k&)
                needRedraw% = -1

        END SELECT

        _LIMIT 30
    LOOP
END SUB
