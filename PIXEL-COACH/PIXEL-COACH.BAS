' PIXEL-COACH/PIXEL-COACH.BAS — Standalone Pixel Art Coach
' Rule-based pixel art analysis tool
' by grymmjack (Rick Christy)
'
' Usage: PIXEL-COACH <image.png|image.bmp>
' Or run without args and use Open dialog

OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ============================================================================
' Include the analysis engine
' ============================================================================
'$INCLUDE:'COACH.BI'

' ============================================================================
' UI constants
' ============================================================================
CONST APP_TITLE$   = "Pixel Coach"
CONST APP_VERSION$ = "0.1.0"

CONST SCREEN_W      = 1024
CONST SCREEN_H      = 768
CONST PANEL_W       = 320           ' Right panel width for issue list
CONST TITLE_BAR_H   = 24
CONST ISSUE_ROW_H   = 48            ' Height of each issue card in the list
CONST BUTTON_H      = 28
CONST BUTTON_PAD    = 6
CONST CHECKBOX_SIZE = 14

' Colors
CONST UI_BG~&            = &HFF282830
CONST UI_PANEL_BG~&      = &HFF1E1E26
CONST UI_TITLE_BG~&      = &HFF3A3A4A
CONST UI_TEXT~&          = &HFFE0E0E0
CONST UI_TEXT_DIM~&      = &HFF9090A0
CONST UI_BUTTON_BG~&     = &HFF444455
CONST UI_BUTTON_HOVER~&  = &HFF555577
CONST UI_BUTTON_ACTIVE~& = &HFF6688AA
CONST UI_SELECTED~&      = &HFF446699
CONST UI_DIVIDER~&       = &HFF444455
CONST UI_GREEN~&         = &HFF33CC66
CONST UI_RED~&           = &HFFFF5555
CONST UI_YELLOW~&        = &HFFFFCC33
CONST UI_CHECK_BG~&      = &HFF555566
CONST UI_CHECK_ON~&      = &HFF4488FF

' ============================================================================
' UI state
' ============================================================================
DIM SHARED viewX         AS SINGLE  ' Pan offset
DIM SHARED viewY         AS SINGLE
DIM SHARED viewZoom      AS SINGLE  ' Zoom level
DIM SHARED uiFont        AS LONG    ' Font handle
DIM SHARED uiFontSmall   AS LONG
DIM SHARED hoverIssue    AS INTEGER
DIM SHARED imgFilePath   AS STRING
DIM SHARED statusMsg     AS STRING
DIM SHARED statusTimer   AS SINGLE
DIM SHARED canvasArea    AS INTEGER ' Width available for canvas display
DIM SHARED needRedraw    AS INTEGER
DIM SHARED grayscaleImg  AS LONG    ' Grayscale version of source image
DIM SHARED showHelp      AS INTEGER
DIM SHARED hoverCheckbox AS INTEGER ' Index 0-7 of hovered detector checkbox, -1 = none
DIM SHARED tooltipMX     AS INTEGER ' Mouse X when tooltip was triggered
DIM SHARED tooltipMY     AS INTEGER ' Mouse Y when tooltip was triggered
DIM SHARED lastOpenDir   AS STRING  ' Last directory used in open file dialog
DIM SHARED uiScale       AS INTEGER ' Display scale multiplier: 1, 2, or 3
DIM SHARED renderBuf     AS LONG    ' Offscreen render buffer (always SCREEN_W x SCREEN_H)
DIM SHARED screenHandle  AS LONG    ' Current screen image handle

' (chk* visibility flags are declared in COACH.BI)

' ============================================================================
' Initialize
' ============================================================================
uiScale      = 1
renderBuf    = _NEWIMAGE(SCREEN_W, SCREEN_H, 32)
screenHandle = _NEWIMAGE(SCREEN_W * uiScale, SCREEN_H * uiScale, 32)
SCREEN screenHandle
_TITLE APP_TITLE$ + " v" + APP_VERSION$
_SCREENMOVE _MIDDLE

COACH_init
viewX         = 0: viewY = 0: viewZoom = 1.0!
hoverIssue    = -1
statusMsg     = "Drag & drop an image or press O to open"
statusTimer   = TIMER
needRedraw    = -1
showHelp      = 0
hoverCheckbox = -1

' Sync checkbox states
chkJaggies   = COACH.detectJaggies
chkIslands   = COACH.detectIslands
chkBanding   = COACH.detectBanding
chkFatPixels = COACH.detectFatPixels
chkDithering = COACH.detectDithering
chkContrast  = COACH.detectContrast
chkValue     = COACH.detectValue
chkNoise     = COACH.detectNoise

canvasArea = SCREEN_W - PANEL_W

' Load built-in font
uiFont = _LOADFONT("", 16, "MONOSPACE")
IF uiFont <= 0 THEN uiFont = 16 ' Fallback to built-in
uiFontSmall = _LOADFONT("", 12, "MONOSPACE")
IF uiFontSmall <= 0 THEN uiFontSmall = 8

' Accept drag and drop
_ACCEPTFILEDROP

' Check command line
IF _COMMANDCOUNT >= 1 THEN
    imgFilePath = COMMAND$(1)
    COACH_load_image imgFilePath
    IF COACH.srcImg < -1 THEN
        UI_fit_image_to_view
        UI_build_grayscale
        lastOpenDir = UI_extract_dir$(imgFilePath)
        statusMsg   = "Loaded. Press A to analyze or SPACE to toggle overlay"
    END IF
END IF

' ============================================================================
' Main loop
' ============================================================================
DO
    ' --- Handle drag & drop ---
    IF _TOTALDROPPEDFILES > 0 THEN
        imgFilePath = _DROPPEDFILE(1)
        _FINISHDROP
        COACH_load_image imgFilePath
        IF COACH.srcImg < -1 THEN
            UI_fit_image_to_view
            UI_build_grayscale
            COACH_clear_issues
            lastOpenDir = UI_extract_dir$(imgFilePath)
            needRedraw  = -1
            statusMsg   = "Loaded. Press A to analyze"
        END IF
    END IF

    ' --- Handle input ---
    UI_handle_keyboard
    UI_handle_mouse

    ' --- Render ---
    IF needRedraw THEN
        _DEST renderBuf
        UI_render
        _DEST screenHandle
        _PUTIMAGE (0, 0)-(SCREEN_W * uiScale - 1, SCREEN_H * uiScale - 1), renderBuf
        _DISPLAY
        needRedraw = 0
    END IF

    _LIMIT 30
LOOP UNTIL _EXIT

' ============================================================================
' Cleanup
' ============================================================================
IF COACH.srcImg < -1 THEN _FREEIMAGE COACH.srcImg
IF COACH.overlayImg < -1 THEN _FREEIMAGE COACH.overlayImg
IF grayscaleImg < -1 THEN _FREEIMAGE grayscaleImg
IF renderBuf < -1 THEN _FREEIMAGE renderBuf
SYSTEM

' ============================================================================
' SUB: Fit image to the canvas view area
' ============================================================================
SUB UI_fit_image_to_view
    IF COACH.srcImg >= -1 THEN EXIT SUB
    ' Fit image within canvas area with some padding
    DIM padW%, padH%
    padW% = canvasArea - 40
    padH% = SCREEN_H - 40

    DIM scaleX!, scaleY!
    scaleX! = CSNG(padW%) / CSNG(COACH.imgW)
    scaleY! = CSNG(padH%) / CSNG(COACH.imgH)

    viewZoom = scaleX!
    IF scaleY! < viewZoom THEN viewZoom = scaleY!
    IF viewZoom > 16.0! THEN viewZoom = 16.0!
    IF viewZoom < 0.25! THEN viewZoom = 0.25!

    ' Center image
    DIM scaledW!, scaledH!
    scaledW! = CSNG(COACH.imgW) * viewZoom
    scaledH! = CSNG(COACH.imgH) * viewZoom
    viewX    = (CSNG(canvasArea) - scaledW!) / 2.0!
    viewY    = (CSNG(SCREEN_H) - scaledH!) / 2.0!
END SUB

' ============================================================================
' SUB: Build grayscale version of loaded image
' ============================================================================
SUB UI_build_grayscale
    IF COACH.srcImg >= -1 THEN EXIT SUB
    IF grayscaleImg < -1 THEN _FREEIMAGE grayscaleImg

    grayscaleImg = _NEWIMAGE(COACH.imgW, COACH.imgH, 32)
    DIM mem AS _MEM, gmem AS _MEM
    mem  = _MEMIMAGE(COACH.srcImg)
    gmem = _MEMIMAGE(grayscaleImg)

    DIM i&, totalPx&, px AS _UNSIGNED LONG
    totalPx& = CLNG(COACH.imgW) * CLNG(COACH.imgH)

    FOR i& = 0 TO totalPx& - 1
        _MEMGET mem, mem.OFFSET + i& * 4, px
        DIM a%, r%, g%, b%, gray%
        a%    = _ALPHA32(px)
        r%    = _RED32(px)
        g%    = _GREEN32(px)
        b%    = _BLUE32(px)
        gray% = INT(0.299! * CSNG(r%) + 0.587! * CSNG(g%) + 0.114! * CSNG(b%))
        IF gray% > 255 THEN gray% = 255
        IF gray% < 0 THEN gray% = 0
        DIM gPx AS _UNSIGNED LONG
        gPx = _RGBA32(gray%, gray%, gray%, a%)
        _MEMPUT gmem, gmem.OFFSET + i& * 4, gPx
    NEXT i&

    _MEMFREE mem
    _MEMFREE gmem
END SUB

' ============================================================================
' SUB: Handle keyboard input
' ============================================================================
SUB UI_handle_keyboard
    DIM k&
    k& = _KEYHIT

    IF k& = 0 THEN EXIT SUB
    needRedraw = -1

    SELECT CASE k&
        CASE 27      ' ESC
            SYSTEM

        CASE 111, 79 ' O/o - Open file
            DIM f$
            f$ = _OPENFILEDIALOG$(APP_TITLE$ + " - Open Image", lastOpenDir, "*.png|*.bmp|*.jpg|*.gif", "Image Files")
            IF LEN(f$) > 0 THEN
                imgFilePath = f$
                lastOpenDir = UI_extract_dir$(imgFilePath)
                COACH_load_image imgFilePath
                IF COACH.srcImg < -1 THEN
                    UI_fit_image_to_view
                    UI_build_grayscale
                    COACH_clear_issues
                    statusMsg = "Loaded. Press A to analyze"
                ELSE
                    statusMsg = "Failed to load image"
                END IF
            END IF

        CASE 97, 65  ' A/a - Analyze
            IF COACH.srcImg < -1 THEN
                ' Sync checkboxes to coach state
                COACH.detectJaggies   = chkJaggies
                COACH.detectIslands   = chkIslands
                COACH.detectBanding   = chkBanding
                COACH.detectFatPixels = chkFatPixels
                COACH.detectDithering = chkDithering
                COACH.detectContrast  = chkContrast
                COACH.detectValue     = chkValue
                COACH.detectNoise     = chkNoise

                statusMsg = "Analyzing..."
                UI_render: _DISPLAY ' Show status before blocking analysis
                COACH_run_analysis
                IF COACH.issueCount = 0 THEN
                    statusMsg = "All clear! No issues found"
                ELSE
                    statusMsg = LTRIM$(STR$(COACH.issueCount)) + " issue(s) found"
                END IF
            ELSE
                statusMsg = "No image loaded"
            END IF

        CASE 32      ' SPACE - Toggle overlay
            COACH.showOverlay = NOT COACH.showOverlay
            IF COACH.showOverlay THEN
                statusMsg = "Overlay ON"
            ELSE
                statusMsg = "Overlay OFF"
            END IF

        CASE 103, 71 ' G/g - Toggle grayscale
            COACH.showGrayscale = NOT COACH.showGrayscale
            IF COACH.showGrayscale THEN
                statusMsg = "Grayscale ON"
            ELSE
                statusMsg = "Grayscale OFF"
            END IF

        CASE 102, 70 ' F/f - Fit to view
            UI_fit_image_to_view

        CASE 43, 61  ' +/ = - Zoom in
            viewZoom = viewZoom * 1.5!
            IF viewZoom > 32.0! THEN viewZoom = 32.0!

        CASE 45      ' - Zoom out
            viewZoom = viewZoom / 1.5!
            IF viewZoom < 0.125! THEN viewZoom = 0.125!

        CASE 49      ' 1 - Toggle Jaggies
            chkJaggies = NOT chkJaggies
            IF chkJaggies THEN statusMsg = "Jaggies: ON" ELSE statusMsg = "Jaggies: OFF"
            IF COACH.issueCount > 0 THEN COACH_build_overlay

        CASE 50      ' 2 - Toggle Islands
            chkIslands = NOT chkIslands
            IF chkIslands THEN statusMsg = "Islands: ON" ELSE statusMsg = "Islands: OFF"
            IF COACH.issueCount > 0 THEN COACH_build_overlay

        CASE 51      ' 3 - Toggle Banding
            chkBanding = NOT chkBanding
            IF chkBanding THEN statusMsg = "Banding: ON" ELSE statusMsg = "Banding: OFF"
            IF COACH.issueCount > 0 THEN COACH_build_overlay

        CASE 52      ' 4 - Toggle Fat Pixels
            chkFatPixels = NOT chkFatPixels
            IF chkFatPixels THEN statusMsg = "Fat Pixels: ON" ELSE statusMsg = "Fat Pixels: OFF"
            IF COACH.issueCount > 0 THEN COACH_build_overlay

        CASE 53      ' 5 - Toggle Dithering
            chkDithering = NOT chkDithering
            IF chkDithering THEN statusMsg = "Dithering: ON" ELSE statusMsg = "Dithering: OFF"
            IF COACH.issueCount > 0 THEN COACH_build_overlay

        CASE 54      ' 6 - Toggle Contrast
            chkContrast = NOT chkContrast
            IF chkContrast THEN statusMsg = "Contrast: ON" ELSE statusMsg = "Contrast: OFF"
            IF COACH.issueCount > 0 THEN COACH_build_overlay

        CASE 55      ' 7 - Toggle Value
            chkValue = NOT chkValue
            IF chkValue THEN statusMsg = "Value: ON" ELSE statusMsg = "Value: OFF"
            IF COACH.issueCount > 0 THEN COACH_build_overlay

        CASE 56      ' 8 - Toggle Noise
            chkNoise = NOT chkNoise
            IF chkNoise THEN statusMsg = "Noise: ON" ELSE statusMsg = "Noise: OFF"
            IF COACH.issueCount > 0 THEN COACH_build_overlay

        CASE 48      ' 0 - Show all types
            chkJaggies   = -1 : chkIslands = -1  : chkBanding = -1 : chkFatPixels = -1
            chkDithering = -1 : chkContrast = -1 : chkValue = -1   : chkNoise = -1
            IF COACH.issueCount > 0 THEN COACH_build_overlay
            statusMsg = "All types visible"

        CASE 57      ' 9 - Hide all types
            chkJaggies   = 0 : chkIslands = 0  : chkBanding = 0 : chkFatPixels = 0
            chkDithering = 0 : chkContrast = 0 : chkValue = 0   : chkNoise = 0
            IF COACH.issueCount > 0 THEN COACH_build_overlay
            statusMsg = "All types hidden"

        CASE 96      ' ` - Actual size (1:1)
            viewZoom = 1.0!
            viewX    = (CSNG(canvasArea) - CSNG(COACH.imgW)) / 2.0!
            viewY    = (CSNG(SCREEN_H) - CSNG(COACH.imgH)) / 2.0!

        CASE 91      ' [ - decrease confidence threshold
            COACH.confidenceThreshold = COACH.confidenceThreshold - 0.1!
            IF COACH.confidenceThreshold < 0.1! THEN COACH.confidenceThreshold = 0.1!
            COACH.scrollOffset = 0
            IF COACH.issueCount > 0 THEN COACH_build_overlay
            statusMsg = "Min confidence: " + LTRIM$(STR$(INT(COACH.confidenceThreshold * 100 + 0.5!))) + "%"

        CASE 93      ' ] - increase confidence threshold
            COACH.confidenceThreshold = COACH.confidenceThreshold + 0.1!
            IF COACH.confidenceThreshold > 0.9! THEN COACH.confidenceThreshold = 0.9!
            COACH.scrollOffset = 0
            IF COACH.issueCount > 0 THEN COACH_build_overlay
            statusMsg = "Min confidence: " + LTRIM$(STR$(INT(COACH.confidenceThreshold * 100 + 0.5!))) + "%"

        CASE 104, 72 ' H/h - Toggle help
            showHelp = NOT showHelp

        CASE 42      ' * - Cycle UI scale 1x -> 2x -> 3x -> 1x
            uiScale = uiScale + 1
            IF uiScale > 3 THEN uiScale = 1
            DIM oldScreen AS LONG
            oldScreen    = screenHandle
            screenHandle = _NEWIMAGE(SCREEN_W * uiScale, SCREEN_H * uiScale, 32)
            SCREEN screenHandle
            _SCREENMOVE _MIDDLE
            _ACCEPTFILEDROP
            IF oldScreen < -1 THEN _FREEIMAGE oldScreen
            needRedraw = -1
            statusMsg  = "UI Scale: " + LTRIM$(STR$(uiScale)) + "x  (* to change)"

        CASE 18432   ' Up
            viewY = viewY + 20
        CASE 20480   ' Down
            viewY = viewY - 20
        CASE 19200   ' Left
            viewX = viewX + 20
        CASE 19712   ' Right
            viewX = viewX - 20
    END SELECT
END SUB

' ============================================================================
' SUB: Handle mouse input
' ============================================================================
SUB UI_handle_mouse
    STATIC dragging   AS INTEGER
    STATIC dragStartX AS SINGLE, dragStartY AS SINGLE
    STATIC dragViewX  AS SINGLE, dragViewY AS SINGLE
    STATIC prevB1     AS INTEGER

    DO WHILE _MOUSEINPUT
        ' Scroll wheel = zoom (canvas) or scroll (panel)
        DIM wheel%
        wheel% = _MOUSEWHEEL
        IF wheel% <> 0 THEN
            IF _MOUSEX \ uiScale > canvasArea THEN
                ' Wheel in panel = scroll issue list
                COACH.scrollOffset = COACH.scrollOffset + wheel%
                IF COACH.scrollOffset < 0 THEN COACH.scrollOffset = 0
                needRedraw = -1
            ELSE
                DIM oldZoom!
                oldZoom! = viewZoom
                IF wheel% < 0 THEN
                    viewZoom = viewZoom * 1.2!
                ELSE
                    viewZoom = viewZoom / 1.2!
                END IF
                IF viewZoom > 32.0! THEN viewZoom = 32.0!
                IF viewZoom < 0.125! THEN viewZoom = 0.125!

                ' Zoom toward mouse position (in virtual coords)
                DIM mx!, my!
                mx!   = CSNG(_MOUSEX) / CSNG(uiScale)
                my!   = CSNG(_MOUSEY) / CSNG(uiScale)
                viewX = mx! - (mx! - viewX) * (viewZoom / oldZoom!)
                viewY = my! - (my! - viewY) * (viewZoom / oldZoom!)

                needRedraw = -1
            END IF
        END IF
    LOOP

    DIM mx%, my%, b1%, b2%
    mx% = _MOUSEX \ uiScale
    my% = _MOUSEY \ uiScale
    b1% = _MOUSEBUTTON(1)
    b2% = _MOUSEBUTTON(2)

    DIM justClickedB1%
    justClickedB1% = b1% AND NOT prevB1%

    ' Middle-click or right-click drag to pan
    IF _MOUSEBUTTON(3) OR b2% THEN
        IF NOT dragging THEN
            dragging   = -1
            dragStartX = CSNG(mx%)
            dragStartY = CSNG(my%)
            dragViewX  = viewX
            dragViewY  = viewY
        ELSE
            viewX      = dragViewX + (CSNG(mx%) - dragStartX)
            viewY      = dragViewY + (CSNG(my%) - dragStartY)
            needRedraw = -1
        END IF
    ELSE
        dragging = 0
    END IF

    ' Check hover over issue list in panel
    ' Clear checkbox hover when mouse leaves panel
    IF mx% <= canvasArea AND hoverCheckbox >= 0 THEN
        hoverCheckbox = -1
        needRedraw    = -1
    END IF

    IF mx% > canvasArea THEN
        ' --- Checkbox click detection ---
        ' Checkbox column starts at X = canvasArea + BUTTON_PAD
        ' Checkbox row 0 starts at Y = CHK_BASE_Y (calculated from layout constants)
        DIM chkBaseY%
        chkBaseY% = TITLE_BAR_H + BUTTON_PAD + (BUTTON_H + BUTTON_PAD) * 2 + 4 + 18

        ' Checkbox hover detection (for tooltips)
        DIM cbHov%
        cbHov% = my% - chkBaseY%
        IF cbHov% >= 0 AND cbHov% < 8 * 18 THEN
            DIM newChkHov%
            newChkHov% = cbHov% \ 18
            IF newChkHov% <> hoverCheckbox THEN
                hoverCheckbox = newChkHov%
                tooltipMX     = mx%
                tooltipMY     = my%
                needRedraw    = -1
            END IF
        ELSE
            IF hoverCheckbox >= 0 THEN
                hoverCheckbox = -1
                needRedraw    = -1
            END IF
        END IF
        IF justClickedB1% AND mx% >= canvasArea + BUTTON_PAD AND mx% <= SCREEN_W - BUTTON_PAD THEN
            DIM chkHit%
            chkHit% = my% - chkBaseY%
            IF chkHit% >= 0 AND chkHit% < 8 * 18 THEN
                SELECT CASE chkHit% \ 18
                    CASE 0 : chkJaggies = NOT chkJaggies
                    CASE 1 : chkIslands = NOT chkIslands
                    CASE 2 : chkBanding = NOT chkBanding
                    CASE 3 : chkFatPixels = NOT chkFatPixels
                    CASE 4 : chkDithering = NOT chkDithering
                    CASE 5 : chkContrast = NOT chkContrast
                    CASE 6 : chkValue = NOT chkValue
                    CASE 7 : chkNoise = NOT chkNoise
                END SELECT
                IF COACH.issueCount > 0 THEN COACH_build_overlay
                needRedraw = -1
            END IF
        END IF
        DIM panelY%
        panelY% = my% - TITLE_BAR_H - (BUTTON_H + BUTTON_PAD) * 3 - CHECKBOX_SIZE * 10 - 20
        IF panelY% >= 0 THEN
            DIM newHover%
            newHover% = panelY% \ ISSUE_ROW_H + COACH.scrollOffset
            IF newHover% <> hoverIssue THEN
                hoverIssue = newHover%
                needRedraw = -1
            END IF
        END IF

        ' Left click on issue in panel = select it
        IF b1% THEN
            IF hoverIssue >= 0 AND hoverIssue < COACH.issueCount THEN
                IF COACH.selectedIssue <> hoverIssue THEN
                    COACH.selectedIssue = hoverIssue
                    needRedraw          = -1

                    ' Center view on selected issue
                    DIM cx!, cy!
                    cx!   = CSNG(COACH_ISSUES(hoverIssue).x1 + COACH_ISSUES(hoverIssue).x2) / 2.0!
                    cy!   = CSNG(COACH_ISSUES(hoverIssue).y1 + COACH_ISSUES(hoverIssue).y2) / 2.0!
                    viewX = CSNG(canvasArea) / 2.0! - cx! * viewZoom
                    viewY = CSNG(SCREEN_H) / 2.0! - cy! * viewZoom
                END IF
            END IF
        END IF
    END IF

    prevB1% = b1%
END SUB

' ============================================================================
' SUB: Main render
' ============================================================================
SUB UI_render
    CLS , UI_BG~&

    ' --- Draw canvas area ---
    IF COACH.srcImg < -1 THEN
        ' Draw checkerboard background (transparency indicator)
        DIM cx%, cy%, checkSize%
        checkSize% = 8
        DIM imgX1%, imgY1%, imgX2%, imgY2%
        imgX1% = INT(viewX)
        imgY1% = INT(viewY)
        imgX2% = imgX1% + INT(CSNG(COACH.imgW) * viewZoom)
        imgY2% = imgY1% + INT(CSNG(COACH.imgH) * viewZoom)

        ' Clip to canvas area
        DIM clipX1%, clipY1%, clipX2%, clipY2%
        clipX1% = imgX1% : IF clipX1% < 0 THEN clipX1% = 0
        clipY1% = imgY1% : IF clipY1% < 0 THEN clipY1% = 0
        clipX2% = imgX2% : IF clipX2% > canvasArea THEN clipX2% = canvasArea
        clipY2% = imgY2% : IF clipY2% > SCREEN_H THEN clipY2% = SCREEN_H

        FOR cy% = clipY1% TO clipY2% STEP checkSize%
            FOR cx% = clipX1% TO clipX2% STEP checkSize%
                IF ((cx% \ checkSize%) + (cy% \ checkSize%)) MOD 2 = 0 THEN
                    LINE (cx%, cy%)-(cx% + checkSize% - 1, cy% + checkSize% - 1), _RGB32(200, 200, 200), BF
                ELSE
                    LINE (cx%, cy%)-(cx% + checkSize% - 1, cy% + checkSize% - 1), _RGB32(160, 160, 160), BF
                END IF
            NEXT cx%
        NEXT cy%

        ' Draw the image (or grayscale version)
        DIM displayImg AS LONG
        IF COACH.showGrayscale AND grayscaleImg < -1 THEN
            displayImg = grayscaleImg
        ELSE
            displayImg = COACH.srcImg
        END IF

        _PUTIMAGE (imgX1%, imgY1%)-(imgX2% - 1, imgY2% - 1), displayImg

        ' Draw overlay on top if enabled
        IF COACH.showOverlay AND COACH.overlayImg < -1 AND COACH.issueCount > 0 THEN
            _PUTIMAGE (imgX1%, imgY1%)-(imgX2% - 1, imgY2% - 1), COACH.overlayImg
        END IF

        ' Draw selected issue highlight (blinking box)
        IF COACH.selectedIssue >= 0 AND COACH.selectedIssue < COACH.issueCount THEN
            DIM si%
            si% = COACH.selectedIssue
            DIM blink%
            blink% = INT(TIMER * 4) MOD 2

            IF blink% THEN
                DIM sx1%, sy1%, sx2%, sy2%
                sx1% = INT(viewX + CSNG(COACH_ISSUES(si%).x1) * viewZoom) - 2
                sy1% = INT(viewY + CSNG(COACH_ISSUES(si%).y1) * viewZoom) - 2
                sx2% = INT(viewX + CSNG(COACH_ISSUES(si%).x2 + 1) * viewZoom) + 2
                sy2% = INT(viewY + CSNG(COACH_ISSUES(si%).y2 + 1) * viewZoom) + 2
                LINE (sx1%, sy1%)-(sx2%, sy2%), _RGB32(255, 255, 0), B
                LINE (sx1% - 1, sy1% - 1)-(sx2% + 1, sy2% + 1), _RGB32(0, 0, 0), B
            END IF
        END IF
    ELSE
        ' No image loaded — show instructions
        COLOR UI_TEXT_DIM~&, UI_BG~&
        DIM msgX%, msgY%
        msgX% = canvasArea \ 2 - 120
        msgY% = SCREEN_H \ 2 - 40
        _PRINTSTRING (msgX%, msgY%), "Drag & drop an image here"
        _PRINTSTRING (msgX%, msgY% + 20), "or press O to open a file"
        _PRINTSTRING (msgX%, msgY% + 50), "Press H for help"
    END IF

    ' --- Draw right panel ---
    LINE (canvasArea, 0)-(SCREEN_W - 1, SCREEN_H - 1), UI_PANEL_BG~&, BF

    ' Per-type issue counts (above confidence threshold) — used by checkboxes below
    DIM tc(1 TO 10) AS INTEGER

    ' Panel title bar
    LINE (canvasArea, 0)-(SCREEN_W - 1, TITLE_BAR_H - 1), UI_TITLE_BG~&, BF
    COLOR UI_TEXT~&, UI_TITLE_BG~&
    _PRINTSTRING (canvasArea + 8, 4), "PIXEL COACH"
    IF COACH.issueCount > 0 THEN
        ' Count visible issues and per-type counts (above confidence threshold)
        DIM visCount%, vi%
        visCount% = 0
        FOR vi% = 0 TO COACH.issueCount - 1
            IF COACH_ISSUES(vi%).confidence >= COACH.confidenceThreshold THEN
                DIM vt%
                vt% = COACH_ISSUES(vi%).issueType
                IF vt% >= 1 AND vt% <= 10 THEN tc(vt%) = tc(vt%) + 1
                DIM vShow%
                vShow% = 0
                SELECT CASE vt%
                    CASE COACH_JAGGY       : vShow% = chkJaggies
                    CASE COACH_ISLAND      : vShow% = chkIslands
                    CASE COACH_BANDING     : vShow% = chkBanding
                    CASE COACH_FAT_PIXEL   : vShow% = chkFatPixels
                    CASE COACH_OVER_DITHER : vShow% = chkDithering
                    CASE COACH_CONTRAST    : vShow% = chkContrast
                    CASE COACH_VALUE       : vShow% = chkValue
                    CASE COACH_NOISE       : vShow% = chkNoise
                END SELECT
                IF vShow% THEN visCount% = visCount% + 1
            END IF
        NEXT vi%
        DIM countStr$
        countStr$ = LTRIM$(STR$(visCount%)) + "/" + LTRIM$(STR$(COACH.issueCount))
        _PRINTSTRING (SCREEN_W - LEN(countStr$) * 8 - 8, 4), countStr$
    END IF

    ' Panel: buttons row
    DIM panelX%, panelY%
    panelX% = canvasArea + BUTTON_PAD
    panelY% = TITLE_BAR_H + BUTTON_PAD

    ' Analyze button
    UI_draw_button panelX%, panelY%, PANEL_W - BUTTON_PAD * 2, BUTTON_H, "[A] ANALYZE", UI_GREEN~&
    panelY% = panelY% + BUTTON_H + BUTTON_PAD

    ' Toggle buttons row
    DIM halfW%
    halfW% = (PANEL_W - BUTTON_PAD * 3) \ 2
    IF COACH.showOverlay THEN
        UI_draw_button panelX%, panelY%, halfW%, BUTTON_H, "[SPC] Overlay ON", UI_BUTTON_ACTIVE~&
    ELSE
        UI_draw_button panelX%, panelY%, halfW%, BUTTON_H, "[SPC] Overlay OFF", UI_BUTTON_BG~&
    END IF
    IF COACH.showGrayscale THEN
        UI_draw_button panelX% + halfW% + BUTTON_PAD, panelY%, halfW%, BUTTON_H, "[G] Gray ON", UI_BUTTON_ACTIVE~&
    ELSE
        UI_draw_button panelX% + halfW% + BUTTON_PAD, panelY%, halfW%, BUTTON_H, "[G] Gray OFF", UI_BUTTON_BG~&
    END IF
    panelY% = panelY% + BUTTON_H + BUTTON_PAD

    ' Divider
    LINE (canvasArea, panelY%)-(SCREEN_W - 1, panelY%), UI_DIVIDER~&
    panelY% = panelY% + 4

    ' Detector checkboxes
    COLOR UI_TEXT_DIM~&, UI_PANEL_BG~&
    _PRINTSTRING (panelX%, panelY%), "Detectors:"
    panelY% = panelY% + 18

    UI_draw_checkbox_colored panelX%, panelY%, "Jaggies  [1]" + STR$(tc(COACH_JAGGY)), chkJaggies, COACH_COLOR_JAGGY~&          : panelY% = panelY% + 18
    UI_draw_checkbox_colored panelX%, panelY%, "Islands  [2]" + STR$(tc(COACH_ISLAND)), chkIslands, COACH_COLOR_ISLAND~&        : panelY% = panelY% + 18
    UI_draw_checkbox_colored panelX%, panelY%, "Banding  [3]" + STR$(tc(COACH_BANDING)), chkBanding, COACH_COLOR_BANDING~&      : panelY% = panelY% + 18
    UI_draw_checkbox_colored panelX%, panelY%, "Fat Px   [4]" + STR$(tc(COACH_FAT_PIXEL)), chkFatPixels, COACH_COLOR_FAT~&      : panelY% = panelY% + 18
    UI_draw_checkbox_colored panelX%, panelY%, "Dither   [5]" + STR$(tc(COACH_OVER_DITHER)), chkDithering, COACH_COLOR_DITHER~& : panelY% = panelY% + 18
    UI_draw_checkbox_colored panelX%, panelY%, "Contrast [6]" + STR$(tc(COACH_CONTRAST)), chkContrast, COACH_COLOR_CONTRAST~&   : panelY% = panelY% + 18
    UI_draw_checkbox_colored panelX%, panelY%, "Value    [7]" + STR$(tc(COACH_VALUE)), chkValue, COACH_COLOR_VALUE~&            : panelY% = panelY% + 18
    UI_draw_checkbox_colored panelX%, panelY%, "Noise    [8]" + STR$(tc(COACH_NOISE)), chkNoise, COACH_COLOR_NOISE~&            : panelY% = panelY% + 18

    ' Confidence threshold
    COLOR UI_TEXT_DIM~&, UI_PANEL_BG~&
    DIM threshPct%
    threshPct% = INT(COACH.confidenceThreshold * 100 + 0.5!)
    _PRINTSTRING (panelX%, panelY%), "Conf >=" + STR$(threshPct%) + "%  [ / ]": panelY% = panelY% + 18

    ' Divider
    LINE (canvasArea, panelY%)-(SCREEN_W - 1, panelY%), UI_DIVIDER~&
    panelY% = panelY% + 4

    ' Issue list
    COLOR UI_TEXT_DIM~&, UI_PANEL_BG~&
    IF COACH.issueCount = 0 THEN
        _PRINTSTRING (panelX%, panelY%), "No issues yet. Press A to analyze."
    ELSE
        ' Build filtered visible index list
        DIM visIdx(0 TO COACH_MAX_ISSUES - 1) AS INTEGER
        DIM visTotal%
        visTotal% = 0
        DIM fvi%
        FOR fvi% = 0 TO COACH.issueCount - 1
            IF COACH_ISSUES(fvi%).confidence >= COACH.confidenceThreshold THEN
                DIM ft%
                ft% = COACH_ISSUES(fvi%).issueType
                DIM fShow%
                fShow% = 0
                SELECT CASE ft%
                    CASE COACH_JAGGY       : fShow% = chkJaggies
                    CASE COACH_ISLAND      : fShow% = chkIslands
                    CASE COACH_BANDING     : fShow% = chkBanding
                    CASE COACH_FAT_PIXEL   : fShow% = chkFatPixels
                    CASE COACH_OVER_DITHER : fShow% = chkDithering
                    CASE COACH_CONTRAST    : fShow% = chkContrast
                    CASE COACH_VALUE       : fShow% = chkValue
                    CASE COACH_NOISE       : fShow% = chkNoise
                END SELECT
                IF fShow% THEN
                    visIdx(visTotal%) = fvi%
                    visTotal% = visTotal% + 1
                END IF
            END IF
        NEXT fvi%

        IF visTotal% = 0 THEN
            _PRINTSTRING (panelX%, panelY%), "All types hidden (0/9 to toggle)"
        ELSE
            ' Clamp scroll offset
            DIM maxVisible%
            maxVisible% = (SCREEN_H - panelY%) \ ISSUE_ROW_H
            IF COACH.scrollOffset > visTotal% - maxVisible% THEN
                COACH.scrollOffset = visTotal% - maxVisible%
            END IF
            IF COACH.scrollOffset < 0 THEN COACH.scrollOffset = 0

            ' Draw issue cards
            DIM i%, listY%, issueIdx%
            FOR i% = 0 TO maxVisible% - 1
                DIM scrolledIdx%
                scrolledIdx% = i% + COACH.scrollOffset
                IF scrolledIdx% >= visTotal% THEN EXIT FOR
                issueIdx% = visIdx(scrolledIdx%)

            listY% = panelY% + i% * ISSUE_ROW_H

            ' Background (selected or hover highlight)
            IF issueIdx% = COACH.selectedIssue THEN
                LINE (canvasArea + 2, listY%)-(SCREEN_W - 3, listY% + ISSUE_ROW_H - 2), UI_SELECTED~&, BF
            ELSEIF issueIdx% = hoverIssue THEN
                LINE (canvasArea + 2, listY%)-(SCREEN_W - 3, listY% + ISSUE_ROW_H - 2), _RGBA32(80, 80, 100, 60), BF
            END IF

            ' Color indicator bar
            DIM typeCol AS _UNSIGNED LONG
            typeCol = COACH_issue_color~&(COACH_ISSUES(issueIdx%).issueType)
            LINE (canvasArea + 2, listY% + 2)-(canvasArea + 6, listY% + ISSUE_ROW_H - 4), typeCol, BF

            ' Issue type name + confidence
            COLOR UI_TEXT~&, UI_PANEL_BG~&
            DIM typeName$
            typeName$ = COACH_issue_type_name$(COACH_ISSUES(issueIdx%).issueType)
            DIM confStr$
            confStr$ = LTRIM$(STR$(INT(COACH_ISSUES(issueIdx%).confidence * 100))) + "%"
            _PRINTSTRING (canvasArea + 12, listY% + 4), typeName$ + " (" + confStr$ + ")"

            ' Message (truncated)
            COLOR UI_TEXT_DIM~&, UI_PANEL_BG~&
            DIM msg$
            msg$ = RTRIM$(COACH_ISSUES(issueIdx%).message)
            IF LEN(msg$) > 36 THEN msg$ = LEFT$(msg$, 33) + "..."
            _PRINTSTRING (canvasArea + 12, listY% + 20), msg$

            ' Location
            DIM locStr$
            locStr$ = "(" + LTRIM$(STR$(COACH_ISSUES(issueIdx%).x1)) + "," + _
                      LTRIM$(STR$(COACH_ISSUES(issueIdx%).y1)) + ")"
            _PRINTSTRING (canvasArea + 12, listY% + 34), locStr$

            ' Divider between cards
            LINE (canvasArea + 8, listY% + ISSUE_ROW_H - 1)-(SCREEN_W - 8, listY% + ISSUE_ROW_H - 1), UI_DIVIDER~&
        NEXT i%
        END IF
    END IF

    ' --- Status bar at bottom ---
    LINE (0, SCREEN_H - 20)-(canvasArea - 1, SCREEN_H - 1), UI_TITLE_BG~&, BF
    COLOR UI_TEXT~&, UI_TITLE_BG~&
    _PRINTSTRING (8, SCREEN_H - 16), statusMsg

    ' Zoom indicator
    DIM zoomStr$
    zoomStr$ = LTRIM$(STR$(INT(viewZoom * 100))) + "%"
    _PRINTSTRING (canvasArea - LEN(zoomStr$) * 8 - 8, SCREEN_H - 16), zoomStr$

    ' --- Tooltip for hovered detector checkbox ---
    IF hoverCheckbox >= 0 THEN
        UI_draw_tooltip tooltipMY, hoverCheckbox
    END IF

    ' --- Help overlay ---
    IF showHelp THEN
        UI_draw_help
    END IF
END SUB

' ============================================================================
' SUB: Draw a button
' ============================================================================
SUB UI_draw_button (x%, y%, w%, h%, label$, bgColor~&)
    LINE (x%, y%)-(x% + w% - 1, y% + h% - 1), bgColor~&, BF
    LINE (x%, y%)-(x% + w% - 1, y% + h% - 1), _RGB32(80, 80, 90), B
    COLOR UI_TEXT~&, bgColor~&
    DIM tx%
    tx% = x% + (w% - LEN(label$) * 8) \ 2
    _PRINTSTRING (tx%, y% + (h% - 16) \ 2), label$
END SUB

' ============================================================================
' SUB: Draw a checkbox
' ============================================================================
SUB UI_draw_checkbox (x%, y%, label$, state%)
    ' Box
    IF state% THEN
        LINE (x%, y%)-(x% + CHECKBOX_SIZE - 1, y% + CHECKBOX_SIZE - 1), UI_CHECK_ON~&, BF
        COLOR UI_TEXT~&, UI_CHECK_ON~&
        _PRINTSTRING (x% + 2, y% - 1), CHR$(251) ' checkmark
    ELSE
        LINE (x%, y%)-(x% + CHECKBOX_SIZE - 1, y% + CHECKBOX_SIZE - 1), UI_CHECK_BG~&, BF
    END IF
    LINE (x%, y%)-(x% + CHECKBOX_SIZE - 1, y% + CHECKBOX_SIZE - 1), _RGB32(100, 100, 110), B

    ' Label
    COLOR UI_TEXT~&, UI_PANEL_BG~&
    _PRINTSTRING (x% + CHECKBOX_SIZE + 6, y%), label$
END SUB

' ============================================================================
' SUB: Draw a checkbox with a colored indicator square
' ============================================================================
SUB UI_draw_checkbox_colored (x%, y%, label$, state%, indicatorColor~&)
    ' Checkbox box
    IF state% THEN
        LINE (x%, y%)-(x% + CHECKBOX_SIZE - 1, y% + CHECKBOX_SIZE - 1), UI_CHECK_ON~&, BF
        COLOR UI_TEXT~&, UI_CHECK_ON~&
        _PRINTSTRING (x% + 2, y% - 1), CHR$(251) ' checkmark
    ELSE
        LINE (x%, y%)-(x% + CHECKBOX_SIZE - 1, y% + CHECKBOX_SIZE - 1), UI_CHECK_BG~&, BF
    END IF
    LINE (x%, y%)-(x% + CHECKBOX_SIZE - 1, y% + CHECKBOX_SIZE - 1), _RGB32(100, 100, 110), B

    ' Color indicator square (opaque version of the overlay color)
    DIM sq%, sqSz%
    sq%   = x% + CHECKBOX_SIZE + 4
    sqSz% = 10
    DIM opaqueColor~&
    opaqueColor~& = _RGB32(_RED32(indicatorColor~&), _GREEN32(indicatorColor~&), _BLUE32(indicatorColor~&))
    LINE (sq%, y% + 2)-(sq% + sqSz% - 1, y% + sqSz% + 1), opaqueColor~&, BF
    LINE (sq%, y% + 2)-(sq% + sqSz% - 1, y% + sqSz% + 1), _RGB32(40, 40, 50), B

    ' Label (shifted right to accommodate color square)
    COLOR UI_TEXT~&, UI_PANEL_BG~&
    _PRINTSTRING (sq% + sqSz% + 4, y%), label$
END SUB

' ============================================================================
' SUB: Draw help overlay
' ============================================================================
SUB UI_draw_help
    DIM hx%, hy%, hw%, hh%
    hw% = 400: hh% = 376
    hx% = (canvasArea - hw%) \ 2
    hy% = (SCREEN_H - hh%) \ 2

    LINE (hx%, hy%)-(hx% + hw% - 1, hy% + hh% - 1), _RGBA32(20, 20, 30, 230), BF
    LINE (hx%, hy%)-(hx% + hw% - 1, hy% + hh% - 1), _RGB32(100, 100, 120), B

    COLOR UI_TEXT~&, _RGBA32(20, 20, 30, 230)
    DIM tx%, ty%
    tx% = hx% + 16: ty% = hy% + 12

    _PRINTSTRING (tx%, ty%), "PIXEL COACH - Keyboard Shortcuts" : ty% = ty% + 24
    _PRINTSTRING (tx%, ty%), ""                                 : ty% = ty% + 8
    COLOR UI_TEXT_DIM~&, _RGBA32(20, 20, 30, 230)
    _PRINTSTRING (tx%, ty%), "O .......... Open image file"         : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "A .......... Analyze image"           : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "1-8 ........ Toggle detector type"    : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "0 .......... Show all types"          : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "9 .......... Hide all types"          : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "[ / ] ...... Confidence threshold"    : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "SPACE ...... Toggle overlay"          : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "G .......... Toggle grayscale"        : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "F .......... Fit image to view"       : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "` .......... Actual size (1:1)"       : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "+/- ........ Zoom in/out"             : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "Arrows ..... Pan view"                : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "Scroll ..... Zoom at cursor (canvas)" : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "Scroll ..... Scroll results (panel)"  : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "R-Click .... Pan (drag)"              : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "* .......... Cycle UI scale 1x/2x/3x" : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "H .......... Toggle this help"        : ty% = ty% + 18
    _PRINTSTRING (tx%, ty%), "ESC ........ Quit"                    : ty% = ty% + 24
    COLOR UI_TEXT~&, _RGBA32(20, 20, 30, 230)
    _PRINTSTRING (tx%, ty%), "Press H to close"
END SUB

' ============================================================================
' FUNCTION: Extract directory path from a file path
' ============================================================================
FUNCTION UI_extract_dir$ (filePath$)
    DIM i         AS INTEGER
    DIM lastSlash AS INTEGER
    lastSlash = 0
    FOR i = LEN(filePath$) TO 1 STEP -1
        IF MID$(filePath$, i, 1) = "/" OR MID$(filePath$, i, 1) = "\" THEN
            lastSlash = i
            EXIT FOR
        END IF
    NEXT i
    IF lastSlash > 0 THEN
        UI_extract_dir$ = LEFT$(filePath$, lastSlash)
    ELSE
        UI_extract_dir$ = ""
    END IF
END FUNCTION

' ============================================================================
' SUB: Draw detector tooltip near hovered checkbox
' ============================================================================
SUB UI_draw_tooltip (my%, idx%)
    DIM line1$, line2$, line3$
    SELECT CASE idx%
        CASE 0
            line1$ = "Jaggies - Diagonal stairstepping"
            line2$ = "Uneven pixel steps on diagonal"
            line3$ = "lines, creating rough/wobbly edges"
        CASE 1
            line1$ = "Islands - Isolated pixel clusters"
            line2$ = "1-2px groups disconnected from"
            line3$ = "nearby shapes (stray specks)"
        CASE 2
            line1$ = "Banding - Parallel repeated edges"
            line2$ = "Striped pattern from aligned"
            line3$ = "outline or shading repetition"
        CASE 3
            line1$ = "Fat Pixels - 2x2 solid blocks"
            line2$ = "Double-width lines or filled"
            line3$ = "squares instead of single-px lines"
        CASE 4
            line1$ = "Dithering - Over-dithered areas"
            line2$ = "Excessive checkerboard patterns"
            line3$ = "where solid color would look better"
        CASE 5
            line1$ = "Contrast - Low value contrast"
            line2$ = "Insufficient light/dark difference"
            line3$ = "between adjacent color regions"
        CASE 6
            line1$ = "Value - Poor tonal range"
            line2$ = "Flat values; missing highlights"
            line3$ = "or deep shadows in the image"
        CASE 7
            line1$ = "Noise - Pixel noise & clutter"
            line2$ = "Dense single-pixel clusters that"
            line3$ = "add visual static or speckles"
        CASE ELSE
            EXIT SUB
    END SELECT

    DIM tw%, th%, tx%, ty%
    tw% = 276: th% = 62
    tx% = canvasArea + 8
    ty% = my% + 22
    IF ty% + th% > SCREEN_H - 24 THEN ty% = my% - th% - 6

    LINE (tx%, ty%)-(tx% + tw% - 1, ty% + th% - 1), _RGBA32(20, 20, 35, 230), BF
    LINE (tx%, ty%)-(tx% + tw% - 1, ty% + th% - 1), _RGBA32(120, 150, 220, 200), B

    COLOR _RGBA32(255, 210, 80, 255), _RGBA32(20, 20, 35, 230)
    _PRINTSTRING (tx% + 6, ty% + 4), line1$
    COLOR UI_TEXT~&, _RGBA32(20, 20, 35, 230)
    _PRINTSTRING (tx% + 6, ty% + 22), line2$
    _PRINTSTRING (tx% + 6, ty% + 38), line3$
END SUB

' ============================================================================
' Include analysis engine implementation
' ============================================================================
'$INCLUDE:'PRECOMPUTE.BM'
'$INCLUDE:'DETECT-JAGGY.BM'
'$INCLUDE:'DETECT-ISLAND.BM'
'$INCLUDE:'DETECT-BANDING.BM'
'$INCLUDE:'DETECT-FAT.BM'
'$INCLUDE:'DETECT-DITHER.BM'
'$INCLUDE:'DETECT-VALUE.BM'
