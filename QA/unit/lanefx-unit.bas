' =============================================================================
' QA/unit/lanefx-unit.bas - headless unit test for native/lanefx.h (the effect
' lanes' kernels: TOOLS/LAYER-LANES LL_fx).
' Build + run:
'   ~/git/qb64pe/qb64pe -w -x -o lanefx-unit.run lanefx-unit.bas && ./lanefx-unit.run
' Exit code 0 = all pass.
' =============================================================================
$CONSOLE:ONLY
OPTION _EXPLICIT
DECLARE LIBRARY "../../native/lanefx"
    SUB gj_lfx_pixelate (BYVAL buf AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL bs AS LONG)
    SUB gj_lfx_invert (BYVAL buf AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL pct AS LONG)
    SUB gj_lfx_noise (BYVAL buf AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL amount AS LONG, BYVAL seed AS LONG)
END DECLARE
DIM SHARED FAILS AS INTEGER, PASSES AS INTEGER
DIM SHARED IMG AS LONG

SUB check (label AS STRING, got AS STRING, want AS STRING)
    IF got = want THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1: PRINT "FAIL "; label; ": got "; got; " want "; want
    END IF
END SUB

FUNCTION hx$ (c AS _UNSIGNED LONG)
    hx$ = RIGHT$("00000000" + HEX$(c), 8)
END FUNCTION

FUNCTION px$ (x AS INTEGER, y AS INTEGER)
    DIM m AS _MEM
    m = _MEMIMAGE(IMG)
    px$ = hx$(_MEMGET(m, m.OFFSET + (y * _WIDTH(IMG) + x) * 4, _UNSIGNED LONG))
    _MEMFREE m
END FUNCTION

SUB put_px (x AS INTEGER, y AS INTEGER, c AS _UNSIGNED LONG)
    DIM m AS _MEM
    m = _MEMIMAGE(IMG)
    _MEMPUT m, m.OFFSET + (y * _WIDTH(IMG) + x) * 4, c
    _MEMFREE m
END SUB

SUB fresh ' an 8x8 cell: clear, a 3x3 square C04040 at (1,1)-(3,3)
    DIM x AS INTEGER, y AS INTEGER
    FOR y = 0 TO 7: FOR x = 0 TO 7: put_px x, y, 0: NEXT x: NEXT y
    FOR y = 1 TO 3: FOR x = 1 TO 3: put_px x, y, &HFFC04040~&: NEXT x: NEXT y
END SUB

SUB run_px (bs AS LONG)
    DIM m AS _MEM
    m = _MEMIMAGE(IMG): gj_lfx_pixelate m.OFFSET, 8, 8, bs: _MEMFREE m
END SUB
SUB run_inv (p AS LONG)
    DIM m AS _MEM
    m = _MEMIMAGE(IMG): gj_lfx_invert m.OFFSET, 8, 8, p: _MEMFREE m
END SUB
SUB run_noise (a AS LONG, s AS LONG)
    DIM m AS _MEM
    m = _MEMIMAGE(IMG): gj_lfx_noise m.OFFSET, 8, 8, a, s: _MEMFREE m
END SUB

FUNCTION all$
    DIM x AS INTEGER, y AS INTEGER, s AS STRING
    FOR y = 0 TO 7: FOR x = 0 TO 7: s = s + px$(x, y): NEXT x: NEXT y
    all$ = s
END FUNCTION

IMG = _NEWIMAGE(8, 8, 32)

' --- pixelate ---
fresh: run_px 1
check "pixelate 1 = none", px$(0, 0) + px$(1, 1), "00000000FFC04040"
fresh: run_px 4
' block (0..3, 0..3): 9 of 16 opaque -> alpha 9*255/16 = 143.4 -> 143 (8F); the colour stays C04040
check "pixelate 4: block alpha", px$(0, 0), "8FC04040"
check "pixelate 4: the whole block", px$(3, 3), "8FC04040"
check "pixelate 4: an empty block stays empty", px$(4, 0) + px$(7, 7), "0000000000000000"
fresh: put_px 1, 1, &HFF0000FF~&: run_px 2
' block (0..1, 0..1): one blue px, opaque -> alpha 255/4 = 63.75 -> 64 (40), colour 0000FF
check "pixelate 2: one blue px", px$(0, 0), "400000FF"
' block (2..3, 2..3): (2,2),(3,2),(2,3),(3,3): 4 opaque C04040 -> unchanged
check "pixelate 2: a full block", px$(2, 2), "FFC04040"

' --- invert ---
fresh: run_inv 0
check "invert 0 = none", px$(1, 1), "FFC04040"
fresh: run_inv 100
check "invert 100", px$(1, 1), "FF3FBFBF"
check "invert keeps transparent", px$(0, 0), "00000000"
fresh: run_inv 50
' C0: 192 + (255-384)*50/100 = 192-64 = 128; 40: 64 + (255-128)*50/100 = 64+63 = 127
check "invert 50", px$(1, 1), "FF807F7F"

' --- noise ---
DIM a$, b$, c$
fresh: run_noise 0, 1
check "noise 0 = none", px$(1, 1), "FFC04040"
fresh: run_noise 40, 7: a$ = all$
fresh: run_noise 40, 7: b$ = all$
fresh: run_noise 40, 8: c$ = all$
check "noise: the same seed, the same grain", STR$(a$ = b$), STR$(-1)
check "noise: another seed, another grain", STR$(a$ <> c$), STR$(-1)
fresh: run_noise 100, 3
check "noise keeps transparent", px$(0, 0) + px$(7, 7), "0000000000000000"
check "noise keeps alpha", LEFT$(px$(2, 2), 2), "FF"
' mono: the same delta on R, G, B (unless clamped) - (2,2) G and B equal
DIM p$: p$ = px$(1, 2)
check "noise is mono (G = B)", MID$(p$, 5, 2), MID$(p$, 7, 2)

PRINT "lanefx-unit:"; PASSES; "passed,"; FAILS; "failed"
SYSTEM FAILS
