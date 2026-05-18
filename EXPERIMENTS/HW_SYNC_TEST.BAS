''
' HW Sync Test — verify that HW _PUTIMAGE defers rendering until _DISPLAY,
' causing subsequent CPU writes to screen 0 to be invisible.
'
' Modes:
'   1 — HW _PUTIMAGE → CPU LINE → _DISPLAY (DRAW's current pattern)
'   2 — HW _PUTIMAGE → _DISPLAY → CPU LINE → _DISPLAY (two flips, force sync)
'   3 — CPU _PUTIMAGE → CPU LINE → _DISPLAY (CPU baseline)
'   4 — HW _PUTIMAGE only (no CPU LINE) → _DISPLAY (control)
'   ESC quit
'
' If mode 1 shows no panel but mode 2 does, then a forced flush between HW
' and CPU operations is the workaround.
'
$RESIZE:OFF

CONST CANVAS_W = 200
CONST CANVAS_H = 150
CONST SCALE    = 4
CONST WIN_W    = CANVAS_W * SCALE
CONST WIN_H    = CANVAS_H * SCALE

SCREEN _NEWIMAGE(WIN_W, WIN_H, 32)
_TITLE "HW Sync Test (1/2/3/4 modes, ESC quit)"

DIM canvas AS LONG : canvas = _NEWIMAGE(CANVAS_W, CANVAS_H, 32)
DIM hw     AS LONG : hw = 0
DIM mode   AS INTEGER : mode = 1
DIM frame  AS LONG : frame = 0
DIM k      AS LONG

DO
    frame = frame + 1
    k = _KEYHIT
    IF k = 27 THEN EXIT DO
    IF k >= ASC("1") AND k <= ASC("4") THEN mode = k - ASC("0")

    ' Render canvas with moving square + background grid
    _DEST canvas
    _DONTBLEND canvas
    CLS , _RGB32(20, 30, 50)
    _BLEND canvas
    DIM sx AS INTEGER
    FOR sx = 0 TO CANVAS_W - 1 STEP 25
        LINE (sx, 0)-(sx, CANVAS_H - 1), _RGB32(50, 60, 80)
    NEXT sx

    DIM mx AS INTEGER : mx = 30 + (frame \ 2) MOD (CANVAS_W - 60)
    LINE (mx - 8, 30)-(mx + 8, 50), _RGB32(255, 255, 255), BF

    _PRINTSTRING (4, 4), "Mode " + LTRIM$(STR$(mode)) + " F=" + LTRIM$(STR$(frame))

    ' === Mode-specific present + CPU write ===
    SELECT CASE mode
        CASE 1
            ' DRAW's pattern: HW present, then CPU LINE, then _DISPLAY
            IF hw < -1 THEN _FREEIMAGE hw
            hw = _COPYIMAGE(canvas, 33)
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), hw, 0
            _DEST 0
            LINE (WIN_W / 2, WIN_H / 2)-(WIN_W - 50, WIN_H - 50), _RGB32(255, 100, 100), BF
            _PRINTSTRING (WIN_W / 2 + 8, WIN_H / 2 + 8), "CPU PANEL"
            _DISPLAY

        CASE 2
            ' Forced flush: HW present, _DISPLAY, then CPU LINE, _DISPLAY again
            IF hw < -1 THEN _FREEIMAGE hw
            hw = _COPYIMAGE(canvas, 33)
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), hw, 0
            _DISPLAY  ' Flush HW
            _DEST 0
            LINE (WIN_W / 2, WIN_H / 2)-(WIN_W - 50, WIN_H - 50), _RGB32(255, 100, 100), BF
            _PRINTSTRING (WIN_W / 2 + 8, WIN_H / 2 + 8), "CPU PANEL"
            _DISPLAY  ' Flush CPU

        CASE 3
            ' CPU baseline: CPU _PUTIMAGE, CPU LINE, _DISPLAY
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), canvas, 0
            _DEST 0
            LINE (WIN_W / 2, WIN_H / 2)-(WIN_W - 50, WIN_H - 50), _RGB32(255, 100, 100), BF
            _PRINTSTRING (WIN_W / 2 + 8, WIN_H / 2 + 8), "CPU PANEL"
            _DISPLAY

        CASE 4
            ' HW only, no CPU write (control)
            IF hw < -1 THEN _FREEIMAGE hw
            hw = _COPYIMAGE(canvas, 33)
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), hw, 0
            _DISPLAY
    END SELECT

    _LIMIT 60
LOOP

IF hw < -1 THEN _FREEIMAGE hw
_FREEIMAGE canvas
SYSTEM
