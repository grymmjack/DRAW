''
' HW Partial Mix Test — reproduce DRAW's ghost trails by mixing
' HW full-frame present with CPU partial-rect overlays.
'
' Pattern under test:
'   1. Each frame, animate content on software canvas
'   2. Present full canvas to screen 0 via HW image (the "full path")
'   3. Then do a CPU partial _PUTIMAGE from canvas to a SMALL rect of
'      screen 0 (simulating DRAW's STATUS-only or dirty-rect partial paths)
'   4. The partial rect deliberately does NOT cover the moving overlay's
'      area — so if anything leaks, it's because the partial rect's pixel
'      output differs from the HW path's pixel output at its boundary
'
' If you see seams, color discontinuities, or trailing pixels along the
' boundary between the HW-rendered area and the CPU partial-rect area,
' that's the bug.
'
' Modes:
'   1 — HW full present every frame (no partial)
'   2 — HW full present + CPU partial-rect overlay (DRAW's mixed pattern)
'   3 — CPU full present + CPU partial-rect overlay (matches pre-HW DRAW)
'   4 — HW full present every 2nd frame + CPU partial in between
'       (simulates DRAW's full ↔ partial ping-pong)
'   ESC — quit
'
$RESIZE:OFF

CONST CANVAS_W = 200
CONST CANVAS_H = 150
CONST SCALE    = 4
CONST WIN_W    = CANVAS_W * SCALE
CONST WIN_H    = CANVAS_H * SCALE

' Partial-rect coverage area (in canvas coords).  Covers the upper-right
' quadrant ONLY — the moving square is in the middle, so the partial
' rect's boundary should never overlap the square.
CONST PART_X1 = CANVAS_W / 2 + 10
CONST PART_Y1 = 5
CONST PART_X2 = CANVAS_W - 5
CONST PART_Y2 = CANVAS_H / 2 - 10

SCREEN _NEWIMAGE(WIN_W, WIN_H, 32)
_TITLE "HW Partial Mix Test (1/2/3/4 modes, ESC quit)"

DIM canvas AS LONG : canvas = _NEWIMAGE(CANVAS_W, CANVAS_H, 32)
DIM hw     AS LONG : hw = 0

DIM frame AS LONG    : frame = 0
DIM mode  AS INTEGER : mode = 2 ' Start in the suspected bug mode
DIM cx    AS INTEGER : cx = CANVAS_W \ 2
DIM cy    AS INTEGER : cy = CANVAS_H \ 2
DIM dirX  AS INTEGER : dirX = 1
DIM dirY  AS INTEGER : dirY = 1
DIM k     AS LONG

DO
    frame = frame + 1

    k = _KEYHIT
    IF k = 27 THEN EXIT DO
    IF k >= ASC("1") AND k <= ASC("4") THEN mode = k - ASC("0")

    ' === Animate ===
    _DEST canvas
    _DONTBLEND canvas
    CLS , _RGBA32(0, 0, 64, 255)
    _BLEND canvas

    cx = cx + dirX : cy = cy + dirY
    IF cx <= 10 OR cx >= CANVAS_W - 10 THEN dirX = -dirX
    IF cy <= 10 OR cy >= CANVAS_H - 10 THEN dirY = -dirY
    LINE (cx - 8, cy - 8)-(cx + 8, cy + 8), _RGB32(255, 255, 255), BF

    ' Draw a static yellow rect in the upper-right (the "chrome" area).
    ' The partial-rect overlay will redraw THIS area each frame.  If full
    ' HW present and partial CPU present produce different pixels at the
    ' boundary of this rect, we'll see artifacts.
    LINE (PART_X1 + 4, PART_Y1 + 4)-(PART_X2 - 4, PART_Y2 - 4), _RGB32(200, 200, 0), BF
    _PRINTSTRING (PART_X1 + 8, PART_Y1 + 8), "chrome"

    _PRINTSTRING (4, 4), "Mode " + LTRIM$(STR$(mode)) + " Frame " + LTRIM$(STR$(frame))

    ' === Present ===
    DIM doHwFull  AS INTEGER : doHwFull = 0
    DIM doCpuFull AS INTEGER : doCpuFull = 0
    DIM doPartial AS INTEGER : doPartial = 0

    SELECT CASE mode
        CASE 1 : doHwFull = 1                  ' pure HW
        CASE 2 : doHwFull = 1  : doPartial = 1 ' HW + CPU partial (DRAW's pattern)
        CASE 3 : doCpuFull = 1 : doPartial = 1 ' CPU + CPU partial (pre-HW pattern)
        CASE 4
            IF (frame MOD 2) = 1 THEN doHwFull = 1 ELSE doPartial = 1
    END SELECT

    IF doHwFull THEN
        IF hw < -1 THEN _FREEIMAGE hw
        hw = _COPYIMAGE(canvas, 33)
        _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), hw, 0
    END IF

    IF doCpuFull THEN
        _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), canvas, 0
    END IF

    IF doPartial THEN
        ' Partial _PUTIMAGE: just the upper-right quadrant in canvas coords,
        ' mapped to the corresponding screen 0 rect.
        DIM winX1 AS LONG, winY1 AS LONG, winX2 AS LONG, winY2 AS LONG
        winX1 = PART_X1 * SCALE
        winY1 = PART_Y1 * SCALE
        winX2 = PART_X2 * SCALE
        winY2 = PART_Y2 * SCALE
        _PUTIMAGE (winX1, winY1)-(winX2, winY2), canvas, 0, (PART_X1, PART_Y1)-(PART_X2, PART_Y2)
    END IF

    _DISPLAY
    _LIMIT 60
LOOP

IF hw < -1 THEN _FREEIMAGE hw
_FREEIMAGE canvas
SYSTEM
