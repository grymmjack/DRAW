''
' HW Alpha Ghost Test — verify that drawing semi-transparent (alpha < 255)
' content to a software canvas, then _COPYIMAGE'ing to HW and blitting to
' screen 0, causes the source alpha to bleed through and leave ghost trails
' from previous frames.
'
' Pattern:
'   1. Each frame, fully CLS canvas to opaque background (alpha=255 everywhere)
'   2. Draw a moving "tooltip" rectangle with alpha=240 (NOT 255 — this is
'      the actual DRAW tooltip default at TOOLTIP.BM:550)
'   3. _COPYIMAGE(canvas, 33), _PUTIMAGE to screen 0
'
' If the moving tooltip leaves trails on screen 0, the hypothesis is
' confirmed: semi-transparent content on the source canvas causes alpha
' to leak through the HW path, preserving stale screen 0 pixels.
'
' Modes:
'   1 — Tooltip alpha 240 (matches DRAW)
'   2 — Tooltip alpha 255 (forced opaque — should be clean)
'   3 — Tooltip alpha 240 + _SETALPHA 255 on canvas before _COPYIMAGE
'       (forces destination alpha back to 255 to override the leak)
'   ESC — quit
'
$RESIZE:OFF

CONST CANVAS_W = 200
CONST CANVAS_H = 150
CONST SCALE    = 4
CONST WIN_W    = CANVAS_W * SCALE
CONST WIN_H    = CANVAS_H * SCALE

SCREEN _NEWIMAGE(WIN_W, WIN_H, 32)
_TITLE "HW Alpha Ghost Test (1/2/3 modes, ESC quit)"

DIM canvas AS LONG : canvas = _NEWIMAGE(CANVAS_W, CANVAS_H, 32)
DIM hw     AS LONG : hw = 0

DIM frame  AS LONG : frame = 0
DIM mode   AS INTEGER : mode = 1
DIM cx     AS INTEGER : cx = CANVAS_W \ 2
DIM cy     AS INTEGER : cy = CANVAS_H \ 2
DIM dirX   AS INTEGER : dirX = 1
DIM dirY   AS INTEGER : dirY = 1
DIM k      AS LONG

DO
    frame = frame + 1

    k = _KEYHIT
    IF k = 27 THEN EXIT DO
    IF k >= ASC("1") AND k <= ASC("3") THEN mode = k - ASC("0")

    ' === Update canvas ===
    _DEST canvas
    _DONTBLEND canvas
    CLS , _RGBA32(0, 0, 64, 255)  ' opaque dark blue
    _BLEND canvas

    ' Move "tooltip" position
    cx = cx + dirX : cy = cy + dirY
    IF cx <= 10 OR cx >= CANVAS_W - 10 THEN dirX = -dirX
    IF cy <= 10 OR cy >= CANVAS_H - 10 THEN dirY = -dirY

    ' Draw "tooltip" — semi-transparent in mode 1 (matches DRAW behavior),
    ' fully opaque in mode 2 (control).  Mode 3 uses semi-transparent but
    ' force-sets canvas alpha to 255 before _COPYIMAGE.
    DIM tipAlpha AS INTEGER
    SELECT CASE mode
        CASE 1: tipAlpha = 240
        CASE 2: tipAlpha = 255
        CASE 3: tipAlpha = 240
    END SELECT

    LINE (cx - 8, cy - 8)-(cx + 8, cy + 8), _RGBA32(255, 255, 100, tipAlpha), BF
    _PRINTSTRING (4, 4), "Mode " + LTRIM$(STR$(mode)) + " alpha=" + LTRIM$(STR$(tipAlpha)) + " F=" + LTRIM$(STR$(frame))

    ' Mode 3: forcibly restore canvas alpha to 255 across the whole image
    ' before snapshotting.  Slow but tests whether alpha-leak is the bug.
    IF mode = 3 THEN
        _SETALPHA 255, , canvas
    END IF

    ' === Present via HW path ===
    IF hw < -1 THEN _FREEIMAGE hw
    hw = _COPYIMAGE(canvas, 33)
    _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), hw, 0

    _DISPLAY
    _LIMIT 60
LOOP

IF hw < -1 THEN _FREEIMAGE hw
_FREEIMAGE canvas
SYSTEM
