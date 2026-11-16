' =============================================================================
' QA/unit/gradimg-unit.bas - headless unit test for GUI/GRAD-IMG.BM: which way a
' gradient IMAGE runs, and reading its colors along that way. Stubs the few
' DRAWER globals the module touches. Build + run:
'   ~/git/qb64pe/qb64pe -w -x -o gradimg-unit.run gradimg-unit.bas && ./gradimg-unit.run
' Exit code 0 = all pass.
'
' The bug (2026-11-15): the Gradient Editor read an image slot's stops across
' its middle row, so a top-to-bottom gradient gave 8 stops of one color - and
' the fills read its top row (one color too).
' =============================================================================
$CONSOLE:ONLY
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0
CONST DRAWER_SLOT_COUNT = 4
CONST GRADIENT_FAMILY_HORIZONTAL = 1
CONST GRADIENT_FAMILY_VERTICAL = 2
CONST GRADIENT_FAMILY_DIAGONAL = 3
CONST GRADIENT_FAMILY_ANTI_DIAG = 4
CONST GRADIENT_FAMILY_RADIAL = 5
CONST GRADIENT_FAMILY_REFLECTED_H = 6
CONST GRADIENT_FAMILY_REFLECTED_V = 7
CONST GRADIENT_FAMILY_DIAMOND = 8
DIM SHARED DRAWER_GRADIENT_SLOTS(1 TO DRAWER_SLOT_COUNT) AS LONG
DIM SHARED DRAWER_GRADIENT_RAMP_IMG(1 TO DRAWER_SLOT_COUNT) AS LONG
DIM SHARED DRAWER_GRADIENT_RAMP_FAM(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED FAILS AS INTEGER, PASSES AS INTEGER

DIM famName(1 TO 8) AS STRING
famName(1) = "HORIZONTAL": famName(2) = "VERTICAL": famName(3) = "DIAGONAL": famName(4) = "ANTI-DIAG"
famName(5) = "RADIAL": famName(6) = "REFLECT-H": famName(7) = "REFLECT-V": famName(8) = "DIAMOND"

DIM AS LONG img, os
DIM AS INTEGER f, i, px, py, distinct
DIM AS _UNSIGNED LONG c, prev

' --- each shape is found ---
FOR f = 1 TO 8
    img = mk&(f, 48, 36)
    check GRAD_IMG_detect%(img) = f, famName(f) + " image 48x36 found as " + famName(f) + " (got " + famName(_MAX(1, GRAD_IMG_detect%(img))) + ")"
    _FREEIMAGE img
NEXT f
img = mk&(GRADIENT_FAMILY_VERTICAL, 32, 128)
check GRAD_IMG_detect%(img) = GRADIENT_FAMILY_VERTICAL, "tall vertical 32x128"
_FREEIMAGE img
img = mk&(GRADIENT_FAMILY_HORIZONTAL, 256, 1)
check GRAD_IMG_detect%(img) = GRADIENT_FAMILY_HORIZONTAL, "a one-row strip is horizontal"
_FREEIMAGE img
img = mk&(GRADIENT_FAMILY_VERTICAL, 1, 64)
check GRAD_IMG_detect%(img) = GRADIENT_FAMILY_VERTICAL, "a one-column strip is vertical"
_FREEIMAGE img
' a dark-light-dark strip is both horizontal and reflect-H: the straight one wins
img = mk&(GRADIENT_FAMILY_REFLECTED_H, 64, 8)
check GRAD_IMG_detect%(img) = GRADIENT_FAMILY_HORIZONTAL _ORELSE GRAD_IMG_detect%(img) = GRADIENT_FAMILY_REFLECTED_H, "symmetric strip: horizontal or reflect-H"
_FREEIMAGE img
img = _NEWIMAGE(40, 30, 32): solid img, _RGB32(10, 200, 30)
check GRAD_IMG_detect%(img) = GRADIENT_FAMILY_HORIZONTAL, "one solid color: horizontal"
_FREEIMAGE img
check GRAD_IMG_detect%(0) = GRADIENT_FAMILY_HORIZONTAL, "no image: horizontal"

' --- the bug: 8 stops read from a vertical image are 8 different colors ---
img = mk&(GRADIENT_FAMILY_VERTICAL, 64, 64)
DRAWER_GRADIENT_SLOTS(2) = img
check GRAD_IMG_family%(2) = GRADIENT_FAMILY_VERTICAL, "slot 2: vertical"
distinct = 0: prev = 1
FOR i = 0 TO 7
    GRAD_IMG_ramp_xy 2, i / 7, px, py
    os = _SOURCE: _SOURCE img: c = POINT(px, py): _SOURCE os
    IF c <> prev THEN distinct = distinct + 1
    prev = c
NEXT i
check distinct = 8, "8 stops along a vertical image: 8 colors (got" + STR$(distinct) + ")"
GRAD_IMG_ramp_xy 2, 0, px, py
check py = 0, "t = 0 is the top row (y" + STR$(py) + ")"
GRAD_IMG_ramp_xy 2, 1, px, py
check py = 63, "t = 1 is the bottom row (y" + STR$(py) + ")"

' --- cached per image; a new image is looked at again ---
check DRAWER_GRADIENT_RAMP_IMG(2) = img _ANDALSO DRAWER_GRADIENT_RAMP_FAM(2) = GRADIENT_FAMILY_VERTICAL, "cached for its image"
DRAWER_GRADIENT_SLOTS(2) = mk&(GRADIENT_FAMILY_HORIZONTAL, 64, 64)
check GRAD_IMG_family%(2) = GRADIENT_FAMILY_HORIZONTAL, "another image in the slot: found again"
_FREEIMAGE DRAWER_GRADIENT_SLOTS(2): _FREEIMAGE img

' --- paths stay inside the image ---
FOR f = 1 TO 8
    GRAD_IMG_path f, 1, 7, 5, px, py
    check px >= 0 _ANDALSO px <= 6 _ANDALSO py >= 0 _ANDALSO py <= 4, famName(f) + " path end inside 7x5"
    GRAD_IMG_path f, -1, 7, 5, px, py
    check px >= 0 _ANDALSO py >= 0, famName(f) + " path clamps t < 0"
NEXT f

PRINT "gradimg-unit:"; PASSES; "passed,"; FAILS; "failed"
IF FAILS THEN SYSTEM 1 ELSE SYSTEM 0

SUB check (ok AS INTEGER, what AS STRING)
    IF ok THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1
        PRINT "FAIL: "; what
    END IF
END SUB

SUB solid (img AS LONG, c AS _UNSIGNED LONG)
    DIM d AS LONG
    d = _DEST: _DEST img: CLS , c: _DEST d
END SUB

' a w x h gradient of family f: dark blue -> white, like the bug report's
FUNCTION mk& (f AS INTEGER, w AS INTEGER, h AS INTEGER)
    DIM AS LONG img, d
    DIM AS INTEGER x, y
    DIM AS SINGLE t, u, v
    img = _NEWIMAGE(w, h, 32)
    d = _DEST: _DEST img
    FOR y = 0 TO h - 1
        FOR x = 0 TO w - 1
            IF w > 1 THEN u = x / (w - 1) ELSE u = 0
            IF h > 1 THEN v = y / (h - 1) ELSE v = 0
            t = GRAD_family_t!(f, u, v)
            PSET (x, y), _RGB32(20 + 235 * t, 60 + 195 * t, 120 + 135 * t)
        NEXT x
    NEXT y
    _DEST d
    mk& = img
END FUNCTION

'$INCLUDE:'../../GUI/GRAD-IMG.BM'
