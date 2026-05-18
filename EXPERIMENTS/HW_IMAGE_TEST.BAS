''
' HW Image Test — isolate the QB64-PE hardware-image final-blit path
' to reproduce (or rule out) the ghost-trail bug observed in DRAW.
'
' Pattern under test (matches DRAW's reverted optimization):
'   1. Each frame, CLS a software canvas to an opaque background
'   2. Draw an animated overlay on the software canvas
'   3. _FREEIMAGE old hardware handle, _COPYIMAGE(canvas, 33) for new HW
'   4. _PUTIMAGE HW to screen 0 with stretch (4x upscale)
'   5. Repeat
'
' If the screen shows trailing/ghosted previous frames of the moving
' overlay, the HW path itself is buggy (rules out DRAW's partial-present
' paths).  If the moving overlay is clean, the bug is in DRAW's mix of
' HW full-path and CPU partial-path rendering.
'
' Controls:
'   ESC  — quit
'   1    — _PUTIMAGE HW source (the simple variant)
'   2    — _MAPTRIANGLE HW source (two triangles)
'   3    — Original CPU _PUTIMAGE (no HW image, baseline)
'   D    — toggle _DONTBLEND on HW image
'
$RESIZE:OFF

CONST CANVAS_W = 200
CONST CANVAS_H = 150
CONST SCALE    = 4
CONST WIN_W    = CANVAS_W * SCALE
CONST WIN_H    = CANVAS_H * SCALE

CONST MODE_PUT_HW       = 1
CONST MODE_MAPTRI_HW    = 2
CONST MODE_PUT_SOFTWARE = 3

' Set up screen 0 as 32-bit graphics, scaled up 4x
SCREEN _NEWIMAGE(WIN_W, WIN_H, 32)
_TITLE "HW Image Test (1/2/3 to switch path, D for dontblend, ESC to quit)"

DIM canvas AS LONG : canvas = _NEWIMAGE(CANVAS_W, CANVAS_H, 32)
DIM hw     AS LONG : hw = 0

DIM frame      AS LONG : frame = 0
DIM mode       AS INTEGER : mode = MODE_PUT_HW
DIM dontblend  AS INTEGER : dontblend = 0
DIM circleX    AS INTEGER
DIM circleY    AS INTEGER
DIM dirX       AS INTEGER : dirX = 1
DIM dirY       AS INTEGER : dirY = 1
circleX = CANVAS_W \ 2
circleY = CANVAS_H \ 2

DIM k AS LONG

DO
    frame = frame + 1

    ' === Handle input ===
    k = _KEYHIT
    IF k = 27 THEN EXIT DO
    IF k = ASC("1") OR k = ASC("!") THEN mode = MODE_PUT_HW
    IF k = ASC("2") OR k = ASC("@") THEN mode = MODE_MAPTRI_HW
    IF k = ASC("3") OR k = ASC("#") THEN mode = MODE_PUT_SOFTWARE
    IF k = ASC("d") OR k = ASC("D") THEN dontblend = 1 - dontblend

    ' === Animate the software canvas ===
    _DEST canvas
    _DONTBLEND canvas
    CLS , _RGBA32(0, 0, 64, 255)  ' opaque dark blue background
    _BLEND canvas

    ' Move a white circle each frame.  If we see trails, the present path
    ' is preserving previous frame pixels — that's the ghosting bug.
    circleX = circleX + dirX
    circleY = circleY + dirY
    IF circleX <= 10 OR circleX >= CANVAS_W - 10 THEN dirX = -dirX
    IF circleY <= 10 OR circleY >= CANVAS_H - 10 THEN dirY = -dirY

    LINE (circleX - 8, circleY - 8)-(circleX + 8, circleY + 8), _RGB32(255, 255, 255), BF

    ' Mode indicator text on canvas
    _PRINTSTRING (4, 4), "Mode " + LTRIM$(STR$(mode)) + " DB=" + LTRIM$(STR$(dontblend)) + " Frame " + LTRIM$(STR$(frame))

    ' === Present to screen 0 using the selected path ===
    SELECT CASE mode
        CASE MODE_PUT_HW
            IF hw < -1 THEN _FREEIMAGE hw
            hw = _COPYIMAGE(canvas, 33)
            IF dontblend THEN _DONTBLEND hw
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), hw, 0

        CASE MODE_MAPTRI_HW
            IF hw < -1 THEN _FREEIMAGE hw
            hw = _COPYIMAGE(canvas, 33)
            IF dontblend THEN _DONTBLEND hw
            DIM oldDest AS LONG : oldDest = _DEST
            _DEST 0
            _MAPTRIANGLE (0, 0)-(0, CANVAS_H - 1)-(CANVAS_W - 1, CANVAS_H - 1), hw TO (0, 0)-(0, WIN_H - 1)-(WIN_W - 1, WIN_H - 1)
            _MAPTRIANGLE (0, 0)-(CANVAS_W - 1, 0)-(CANVAS_W - 1, CANVAS_H - 1), hw TO (0, 0)-(WIN_W - 1, 0)-(WIN_W - 1, WIN_H - 1)
            _DEST oldDest

        CASE MODE_PUT_SOFTWARE
            ' Baseline: no HW image, direct CPU upscale (original DRAW path)
            _PUTIMAGE (0, 0)-(WIN_W - 1, WIN_H - 1), canvas, 0
    END SELECT

    _DISPLAY
    _LIMIT 60
LOOP

' Cleanup
IF hw < -1 THEN _FREEIMAGE hw
_FREEIMAGE canvas
SYSTEM
