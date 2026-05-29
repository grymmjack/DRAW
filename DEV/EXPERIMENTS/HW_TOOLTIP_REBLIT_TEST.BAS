''
' HW Tooltip Reblit Test — replicate DRAW's TOOLTIP_reblit_to_screen0 pattern:
'   1. Software canvas has full frame including a "tooltip" rect
'   2. HW full present (entire screen 0 painted via HW path)
'   3. Some "panel" drawn directly to screen 0, partially covering tooltip
'   4. CPU partial _PUTIMAGE of JUST the tooltip rect from canvas to screen 0
'      (mirroring TOOLTIP_reblit_to_screen0 exactly)
'   5. _DISPLAY
'
' This is the EXACT pattern that fires in DRAW after every render path.
' The tooltip rect on screen 0 gets painted twice: HW first, then CPU.
' If they produce different pixels, the boundary of TOOLTIP.RENDER_W/H
' becomes visible — which would look like "tooltip fragments" because
' the tooltip exists in CPU pixels inside the rect, HW pixels just
' outside the rect.
'
' Modes:
'   1 — HW full + CPU re-blit (DRAW's exact pattern)
'   2 — CPU full + CPU re-blit (pre-HW DRAW pattern)
'   3 — HW full only (no re-blit)
'   ESC quit
'
$RESIZE:OFF

CONST CANVAS_W = 200
CONST CANVAS_H = 150
CONST SCALE    = 4
CONST WIN_W    = CANVAS_W * SCALE
CONST WIN_H    = CANVAS_H * SCALE

SCREEN _NEWIMAGE(WIN_W, WIN_H, 32)
_TITLE "HW Tooltip Reblit Test (1/2/3 modes, ESC quit)"

DIM canvas AS LONG    : canvas = _NEWIMAGE(CANVAS_W, CANVAS_H, 32)
DIM hw     AS LONG    : hw = 0
DIM mode   AS INTEGER : mode = 1
DIM frame  AS LONG    : frame = 0
DIM tipX   AS INTEGER : tipX = 40
DIM dir    AS INTEGER : dir = 1
DIM k      AS LONG

' Tooltip size (mimics DRAW's tooltip dimensions roughly)
CONST TT_W = 50
CONST TT_H = 14

DO
    frame = frame + 1
    k = _KEYHIT
    IF k = 27 THEN EXIT DO
    IF k = ASC("1") THEN mode = 1
    IF k = ASC("2") THEN mode = 2
    IF k = ASC("3") THEN mode = 3

    ' Tooltip moves left-right
    tipX = tipX + dir
    IF tipX < 20 OR tipX > CANVAS_W - TT_W - 20 THEN dir = -dir

    DIM tipY AS INTEGER : tipY = 40

    ' === Render scene + tooltip to software canvas ===
    _DEST canvas
    _DONTBLEND canvas
    CLS , _RGBA32(20, 30, 50, 255) ' dark background (the "canvas content")
    _BLEND canvas

    ' Draw some background detail (so we can see if anything bleeds through)
    DIM sx AS INTEGER, sy AS INTEGER
    FOR sx = 0 TO CANVAS_W - 1 STEP 20
        LINE (sx, 0)-(sx, CANVAS_H - 1), _RGB32(40, 50, 70)
    NEXT sx
    FOR sy = 0 TO CANVAS_H - 1 STEP 20
        LINE (0, sy)-(CANVAS_W - 1, sy), _RGB32(40, 50, 70)
    NEXT sy

    ' Draw tooltip background + border + striped content
    LINE (tipX, tipY)-(tipX + TT_W - 1, tipY + TT_H - 1), _RGB32(40, 40, 50), BF
    LINE (tipX, tipY)-(tipX + TT_W - 1, tipY + TT_H - 1), _RGB32(120, 120, 140), B
    FOR sx = tipX + 2 TO tipX + TT_W - 3 STEP 2
        LINE (sx, tipY + 3)-(sx, tipY + TT_H - 4), _RGB32(255, 255, 100)
    NEXT sx

    _PRINTSTRING (4, 4), "Mode " + LTRIM$(STR$(mode)) + " F=" + LTRIM$(STR$(frame))

    ' === Step 1: full present (HW or CPU based on mode) ===
    SELECT CASE mode
        CASE 1, 3
            IF hw < -1 THEN _FREEIMAGE hw
            hw = _COPYIMAGE(canvas, 33)
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), hw, 0
        CASE 2
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), canvas, 0
    END SELECT

    ' === Step 2: a "floating panel" draws directly to screen 0,
    '   overlapping the tooltip area (mimics COLORMIXER_render behavior) ===
    DIM panelX1 AS LONG, panelY1 AS LONG, panelX2 AS LONG, panelY2 AS LONG
    panelX1 = (CANVAS_W \ 2) * SCALE
    panelY1 = 0
    panelX2 = WIN_W - 1
    panelY2 = (TT_H + 60) * SCALE
    _DEST 0
    LINE (panelX1, panelY1)-(panelX2, panelY2), _RGB32(100, 50, 50), BF
    _PRINTSTRING (panelX1 + 8, panelY1 + 8), "FLOATING PANEL"
    _DEST canvas

    ' === Step 3: CPU re-blit of tooltip rect (mimics TOOLTIP_reblit_to_screen0) ===
    IF mode = 1 OR mode = 2 THEN
        DIM srcX1 AS INTEGER, srcY1 AS INTEGER, srcX2 AS INTEGER, srcY2 AS INTEGER
        srcX1 = tipX
        srcY1 = tipY
        srcX2 = tipX + TT_W - 1
        srcY2 = tipY + TT_H - 1
        DIM dstX1 AS LONG, dstY1 AS LONG, dstX2 AS LONG, dstY2 AS LONG
        dstX1 = CLNG(srcX1) * SCALE
        dstY1 = CLNG(srcY1) * SCALE
        dstX2 = (CLNG(srcX1) + CLNG(TT_W)) * SCALE - 1
        dstY2 = (CLNG(srcY1) + CLNG(TT_H)) * SCALE - 1
        _PUTIMAGE (dstX1, dstY1)-(dstX2, dstY2), canvas, 0, (srcX1, srcY1)-(srcX2, srcY2)
    END IF

    _DISPLAY
    _LIMIT 60
LOOP

IF hw < -1 THEN _FREEIMAGE hw
_FREEIMAGE canvas
SYSTEM
