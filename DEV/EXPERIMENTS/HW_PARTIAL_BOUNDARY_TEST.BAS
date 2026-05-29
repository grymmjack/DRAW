''
' HW Partial Boundary Test — check whether HW full-present + CPU partial-blit
' produces visible artifacts at the boundary of the partial rect when source
' content has high-contrast detail (tooltip-like text).
'
' Hypothesis: even though both paths nominally use nearest-neighbor, subtle
' subpixel/rounding differences between GL texture stretch (HW) and software
' nearest-neighbor (CPU) make seam pixels misalign at the partial-blit boundary.
'
' Layout:
'   - Large yellow "tooltip" rectangle with HIGH CONTRAST stripes inside it
'   - The tooltip extends ACROSS the partial-blit rect boundary
'   - Each frame: full HW present → CPU partial blit of a section that
'     partially overlaps the tooltip
'   - If you see fragmented stripes at the partial rect's edge, hypothesis confirmed
'
' Modes:
'   1 — HW full + CPU partial (the suspect)
'   2 — CPU full + CPU partial (baseline — should be clean)
'   ESC — quit
'
$RESIZE:OFF

CONST CANVAS_W = 200
CONST CANVAS_H = 150
CONST SCALE    = 4
CONST WIN_W    = CANVAS_W * SCALE
CONST WIN_H    = CANVAS_H * SCALE

' Partial-blit rect (canvas coords) — vertically spans top half, horizontally right half
CONST PART_X1 = CANVAS_W / 2
CONST PART_Y1 = 0
CONST PART_X2 = CANVAS_W - 1
CONST PART_Y2 = CANVAS_H / 2

SCREEN _NEWIMAGE(WIN_W, WIN_H, 32)
_TITLE "HW Partial Boundary Test (1=HW+partial 2=CPU+partial ESC=quit)"

DIM canvas AS LONG    : canvas = _NEWIMAGE(CANVAS_W, CANVAS_H, 32)
DIM hw     AS LONG    : hw = 0
DIM mode   AS INTEGER : mode = 1
DIM frame  AS LONG    : frame = 0
DIM tipX   AS INTEGER : tipX = 30
DIM dir    AS INTEGER : dir = 1
DIM k      AS LONG

DO
    frame = frame + 1
    k = _KEYHIT
    IF k = 27 THEN EXIT DO
    IF k = ASC("1") THEN mode = 1
    IF k = ASC("2") THEN mode = 2

    ' Animate: a "tooltip" rect moves left-right, deliberately straddles the
    ' partial-blit boundary at PART_X1 = CANVAS_W/2
    tipX = tipX + dir
    IF tipX < 30 OR tipX > CANVAS_W - 80 THEN dir = -dir

    _DEST canvas
    _DONTBLEND canvas
    CLS , _RGBA32(20, 20, 30, 255)
    _BLEND canvas

    ' Tooltip-like rectangle with internal high-contrast stripes
    DIM ttW AS INTEGER : ttW = 60
    DIM ttH AS INTEGER : ttH = 20
    DIM ttY AS INTEGER : ttY = 30
    LINE (tipX, ttY)-(tipX + ttW - 1, ttY + ttH - 1), _RGB32(40, 40, 50), BF
    LINE (tipX, ttY)-(tipX + ttW - 1, ttY + ttH - 1), _RGB32(100, 100, 120), B
    ' Internal stripes (every other pixel column white) — high contrast detail
    DIM sx  AS INTEGER
    FOR sx = tipX + 2 TO tipX + ttW - 3 STEP 2
        LINE (sx, ttY + 4)-(sx, ttY + ttH - 5), _RGB32(255, 255, 100)
    NEXT sx

    ' Visual indicator: the partial-blit boundary (red vertical line)
    LINE (PART_X1, 0)-(PART_X1, CANVAS_H - 1), _RGB32(255, 0, 0)

    _PRINTSTRING (4, 4), "Mode " + LTRIM$(STR$(mode)) + " F=" + LTRIM$(STR$(frame))

    ' === Present ===
    SELECT CASE mode
        CASE 1
            IF hw < -1 THEN _FREEIMAGE hw
            hw = _COPYIMAGE(canvas, 33)
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), hw, 0
        CASE 2
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), canvas, 0
    END SELECT

    ' Then CPU partial overlay (right half, top half)
    DIM wX1 AS LONG, wY1 AS LONG, wX2 AS LONG, wY2 AS LONG
    wX1 = PART_X1 * SCALE
    wY1 = PART_Y1 * SCALE
    wX2 = PART_X2 * SCALE
    wY2 = PART_Y2 * SCALE
    _PUTIMAGE (wX1, wY1)-(wX2, wY2), canvas, 0, (PART_X1, PART_Y1)-(PART_X2, PART_Y2)

    _DISPLAY
    _LIMIT 60
LOOP

IF hw < -1 THEN _FREEIMAGE hw
_FREEIMAGE canvas
SYSTEM
