$CONSOLE:ONLY
OPTION _EXPLICIT

' Bench + correctness gate for native/blend.h gj_blend_composite.
' REF_blend_region below is an EXACT copy of LAYER_blend_composite_region
' (GUI/LAYERS.BM). Tests all 19 blend modes over varying-alpha dst+src.

CONST BLEND_NORMAL      = 0, BLEND_MULTIPLY = 1, BLEND_SCREEN = 2, BLEND_OVERLAY = 3
CONST BLEND_ADD         = 4, BLEND_SUBTRACT = 5, BLEND_DIFFERENCE = 6, BLEND_DARKEN = 7
CONST BLEND_LIGHTEN     = 8, BLEND_COLOR_DODGE = 9, BLEND_COLOR_BURN = 10
CONST BLEND_HARD_LIGHT  = 11, BLEND_SOFT_LIGHT = 12, BLEND_EXCLUSION = 13
CONST BLEND_VIVID_LIGHT = 14, BLEND_LINEAR_LIGHT = 15, BLEND_PIN_LIGHT = 16
CONST BLEND_COLOR       = 17, BLEND_LUMINOSITY = 18

DECLARE LIBRARY "./native/blend"
    SUB gj_blend_composite (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL mode AS LONG, BYVAL opacity AS LONG, BYVAL rx1 AS LONG, BYVAL ry1 AS LONG, BYVAL rx2 AS LONG, BYVAL ry2 AS LONG)
END DECLARE

CONST W    = 512
CONST H    = 512
CONST OPAC = 180

DIM baseDst AS LONG, src AS LONG
baseDst = _NEWIMAGE(W, H, 32)
src     = _NEWIMAGE(W, H, 32)
DIM mb      AS _MEM, ms AS _MEM
mb = _MEMIMAGE(baseDst): ms = _MEMIMAGE(src)
DIM x       AS LONG, y AS LONG, da AS LONG, sa AS LONG
FOR y = 0 TO H - 1
    FOR x = 0 TO W - 1
        ' dest: gradient, some fully-transparent (dA=0) region
        da = 255
        IF x < 60 AND y < 60 THEN da = 0
        _MEMPUT mb, mb.OFFSET + (y * W + x) * 4, _RGBA32((x * 255) \ W, (y * 255) \ H, (x + y) AND 255, da) AS _UNSIGNED LONG
        ' src: different gradient, transparent hole + partial band
        sa = 255
        IF ((x \ 16) + (y \ 16)) AND 1 THEN sa = 100
        IF x > 200 AND x < 300 AND y > 200 AND y < 300 THEN sa = 0
        _MEMPUT ms, ms.OFFSET + (y * W + x) * 4, _RGBA32(255 - (x * 255) \ W, (x * 2 + y) AND 255, (y * 255) \ H, sa) AS _UNSIGNED LONG
    NEXT x
NEXT y
_MEMFREE mb: _MEMFREE ms

DIM mode AS INTEGER, totalMis AS LONG, worstMode AS INTEGER, worstMis AS LONG
DIM t0   AS DOUBLE, t1 AS DOUBLE, refMs AS DOUBLE, cppMs AS DOUBLE
totalMis = 0 : worstMis = -1
refMs    = 0 : cppMs = 0

FOR mode% = 0 TO 18
    DIM refImg AS LONG, cppImg AS LONG
    refImg = _COPYIMAGE(baseDst, 32)
    t0     = TIMER(0.001)
    REF_blend_region refImg, src, mode%, OPAC, 0, 0, W - 1, H - 1
    t1 = TIMER(0.001): refMs = refMs + ela(t0, t1)

    cppImg = _COPYIMAGE(baseDst, 32)
    DIM cd AS _MEM, cs AS _MEM
    cd = _MEMIMAGE(cppImg): cs = _MEMIMAGE(src)
    t0 = TIMER(0.001)
    gj_blend_composite cd.OFFSET, cs.OFFSET, W, H, mode%, OPAC, 0, 0, W - 1, H - 1
    t1 = TIMER(0.001) : cppMs = cppMs + ela(t0, t1)
    _MEMFREE cd       : _MEMFREE cs

    DIM mis AS LONG
    mis = diffimg&(refImg, cppImg)
    totalMis = totalMis + mis
    IF mis > worstMis THEN worstMis = mis: worstMode = mode%
    IF mis > 0 THEN PRINT "  mode"; mode%; " MISMATCHES:"; mis
    _FREEIMAGE refImg: _FREEIMAGE cppImg
NEXT mode%

PRINT "==== blend compositor, all 19 modes ("; LTRIM$(STR$(W)); "x"; LTRIM$(STR$(H)); ", opac"; OPAC; ") ===="
PRINT USING "  BASIC -O0 (19 modes): #####.### ms"; refMs
PRINT USING "  C++   -O3 (19 modes): #####.### ms"; cppMs
IF cppMs > 0 THEN PRINT USING "  speedup             : #####.## x"; refMs / cppMs
PRINT "  total mismatches across all modes:"; totalMis;
IF totalMis = 0 THEN PRINT " -> ALL MODES IDENTICAL" ELSE PRINT " *** FAIL (worst mode"; worstMode; ") ***"
SYSTEM

FUNCTION ela# (t0 AS DOUBLE, t1 AS DOUBLE)
    DIM d AS DOUBLE: d = (t1 - t0) * 1000: IF d < 0 THEN d = d + 86400000
    ela = d
END FUNCTION

FUNCTION diffimg& (a AS LONG, b AS LONG)
    DIM ma AS _MEM, mb AS _MEM, i AS _OFFSET, pa AS _UNSIGNED LONG, pb AS _UNSIGNED LONG, n AS LONG
    ma = _MEMIMAGE(a): mb = _MEMIMAGE(b): n = 0
    FOR i = 0 TO ma.SIZE - 4 STEP 4
        _MEMGET ma, ma.OFFSET + i, pa
        _MEMGET mb, mb.OFFSET + i, pb
        IF pa <> pb THEN n = n + 1
    NEXT i
    _MEMFREE ma: _MEMFREE mb: diffimg = n
END FUNCTION

' ========= EXACT COPY of LAYER_blend_composite_region (GUI/LAYERS.BM) =========
SUB REF_blend_region (dst AS LONG, src AS LONG, blendMode AS INTEGER, opacity AS INTEGER, rx1 AS INTEGER, ry1 AS INTEGER, rx2 AS INTEGER, ry2 AS INTEGER)
    IF dst& = 0 OR src& = 0 THEN EXIT SUB
    DIM imgW     AS INTEGER, imgH AS INTEGER
    imgW% = _WIDTH(dst&): imgH% = _HEIGHT(dst&)
    IF imgW% <> _WIDTH(src&) OR imgH% <> _HEIGHT(src&) THEN EXIT SUB
    DIM cx1      AS INTEGER, cy1 AS INTEGER, cx2 AS INTEGER, cy2 AS INTEGER
    cx1% = rx1%: cy1% = ry1%: cx2% = rx2%: cy2% = ry2%
    IF cx1% < 0 THEN cx1% = 0
    IF cy1% < 0 THEN cy1% = 0
    IF cx2% >= imgW% THEN cx2% = imgW% - 1
    IF cy2% >= imgH% THEN cy2% = imgH% - 1
    IF cx2% < cx1% OR cy2% < cy1% THEN EXIT SUB
    DIM dstMem   AS _MEM, srcMem AS _MEM, pixOff AS _OFFSET
    DIM dstPix   AS _UNSIGNED LONG, srcPix AS _UNSIGNED LONG
    DIM sA       AS LONG, sR AS LONG, sG AS LONG, sB AS LONG
    DIM dA       AS LONG, dR AS LONG, dG AS LONG, dB AS LONG
    DIM bR       AS LONG, bG AS LONG, bB AS LONG
    DIM rR       AS LONG, rG AS LONG, rB AS LONG, rA AS LONG
    DIM effAlpha AS LONG, rowY AS INTEGER, colX AS INTEGER, rowOff AS _OFFSET, stride AS _OFFSET
    dstMem = _MEMIMAGE(dst&): srcMem = _MEMIMAGE(src&)
    stride = CLNG(imgW%) * 4
    FOR rowY% = cy1% TO cy2%
        rowOff = CLNG(rowY%) * stride
        FOR colX% = cx1% TO cx2%
            pixOff = rowOff + CLNG(colX%) * 4
            _MEMGET srcMem, srcMem.OFFSET + pixOff, srcPix~&
            sA& = _ALPHA32(srcPix~&)
            IF sA& = 0 THEN _CONTINUE
            effAlpha& = (sA& * opacity%) \ 255
            IF effAlpha& < = 0 THEN _CONTINUE
            sR& = _RED32(srcPix~&): sG& = _GREEN32(srcPix~&): sB& = _BLUE32(srcPix~&)
            _MEMGET dstMem, dstMem.OFFSET + pixOff, dstPix~&
            dA& = _ALPHA32(dstPix~&)
            dR& = _RED32(dstPix~&): dG& = _GREEN32(dstPix~&): dB& = _BLUE32(dstPix~&)
            SELECT CASE blendMode%
                CASE BLEND_MULTIPLY
                    bR& = (dR& * sR&) \ 255: bG& = (dG& * sG&) \ 255: bB& = (dB& * sB&) \ 255
                CASE BLEND_SCREEN
                    bR& = 255 - ((255 - dR&) * (255 - sR&)) \ 255: bG& = 255 - ((255 - dG&) * (255 - sG&)) \ 255: bB& = 255 - ((255 - dB&) * (255 - sB&)) \ 255
                CASE BLEND_OVERLAY
                    IF dR& < 128 THEN bR& = (2 * dR& * sR&) \ 255 ELSE bR& = 255 - (2 * (255 - dR&) * (255 - sR&)) \ 255
                    IF dG& < 128 THEN bG& = (2 * dG& * sG&) \ 255 ELSE bG& = 255 - (2 * (255 - dG&) * (255 - sG&)) \ 255
                    IF dB& < 128 THEN bB& = (2 * dB& * sB&) \ 255 ELSE bB& = 255 - (2 * (255 - dB&) * (255 - sB&)) \ 255
                CASE BLEND_ADD
                    bR& = dR& + sR& : IF bR& > 255 THEN bR& = 255
                    bG& = dG& + sG& : IF bG& > 255 THEN bG& = 255
                    bB& = dB& + sB& : IF bB& > 255 THEN bB& = 255
                CASE BLEND_SUBTRACT
                    bR& = dR& - sR& : IF bR& < 0 THEN bR& = 0
                    bG& = dG& - sG& : IF bG& < 0 THEN bG& = 0
                    bB& = dB& - sB& : IF bB& < 0 THEN bB& = 0
                CASE BLEND_DIFFERENCE
                    bR& = ABS(dR& - sR&): bG& = ABS(dG& - sG&): bB& = ABS(dB& - sB&)
                CASE BLEND_DARKEN
                    IF dR& < sR& THEN bR& = dR& ELSE bR& = sR&
                    IF dG& < sG& THEN bG& = dG& ELSE bG& = sG&
                    IF dB& < sB& THEN bB& = dB& ELSE bB& = sB&
                CASE BLEND_LIGHTEN
                    IF dR& > sR& THEN bR& = dR& ELSE bR& = sR&
                    IF dG& > sG& THEN bG& = dG& ELSE bG& = sG&
                    IF dB& > sB& THEN bB& = dB& ELSE bB& = sB&
                CASE BLEND_COLOR_DODGE
                    IF sR& >= 255 THEN bR& = 255 ELSE bR& = (dR& * 255) \ (255 - sR&) : IF bR& > 255 THEN bR& = 255
                    IF sG& >= 255 THEN bG& = 255 ELSE bG& = (dG& * 255) \ (255 - sG&) : IF bG& > 255 THEN bG& = 255
                    IF sB& >= 255 THEN bB& = 255 ELSE bB& = (dB& * 255) \ (255 - sB&) : IF bB& > 255 THEN bB& = 255
                CASE BLEND_COLOR_BURN
                    IF sR& < = 0 THEN bR& = 0 ELSE bR& = 255 - ((255 - dR&) * 255) \ sR& : IF bR& < 0 THEN bR& = 0
                    IF sG& < = 0 THEN bG& = 0 ELSE bG& = 255 - ((255 - dG&) * 255) \ sG& : IF bG& < 0 THEN bG& = 0
                    IF sB& < = 0 THEN bB& = 0 ELSE bB& = 255 - ((255 - dB&) * 255) \ sB& : IF bB& < 0 THEN bB& = 0
                CASE BLEND_HARD_LIGHT
                    IF sR& < 128 THEN bR& = (2 * sR& * dR&) \ 255 ELSE bR& = 255 - (2 * (255 - sR&) * (255 - dR&)) \ 255
                    IF sG& < 128 THEN bG& = (2 * sG& * dG&) \ 255 ELSE bG& = 255 - (2 * (255 - sG&) * (255 - dG&)) \ 255
                    IF sB& < 128 THEN bB& = (2 * sB& * dB&) \ 255 ELSE bB& = 255 - (2 * (255 - sB&) * (255 - dB&)) \ 255
                CASE BLEND_SOFT_LIGHT
                    bR& = ((255 - 2 * sR&) * dR& * dR&) \ 65025 + (2 * sR& * dR&) \ 255
                    bG& = ((255 - 2 * sG&) * dG& * dG&) \ 65025 + (2 * sG& * dG&) \ 255
                    bB& = ((255 - 2 * sB&) * dB& * dB&) \ 65025 + (2 * sB& * dB&) \ 255
                    IF bR& < 0 THEN bR& = 0 ELSE IF bR& > 255 THEN bR& = 255
                    IF bG& < 0 THEN bG& = 0 ELSE IF bG& > 255 THEN bG& = 255
                    IF bB& < 0 THEN bB& = 0 ELSE IF bB& > 255 THEN bB& = 255
                CASE BLEND_EXCLUSION
                    bR& = dR& + sR& - (2 * dR& * sR&) \ 255
                    bG& = dG& + sG& - (2 * dG& * sG&) \ 255
                    bB& = dB& + sB& - (2 * dB& * sB&) \ 255
                CASE BLEND_VIVID_LIGHT
                    IF sR& > 128 THEN
                        DIM vrr  AS LONG: vrr& = 2 * (sR& - 128): IF vrr& >= 255 THEN bR& = 255 ELSE bR& = (dR& * 255) \ (255 - vrr&): IF bR& > 255 THEN bR& = 255
                    ELSE
                        DIM vrr2 AS LONG: vrr2& = 2 * sR&: IF vrr2& < = 0 THEN bR& = 0 ELSE bR& = 255 - ((255 - dR&) * 255) \ vrr2&: IF bR& < 0 THEN bR& = 0
                    END IF
                    IF sG& > 128 THEN
                        DIM vgr  AS LONG: vgr& = 2 * (sG& - 128): IF vgr& >= 255 THEN bG& = 255 ELSE bG& = (dG& * 255) \ (255 - vgr&): IF bG& > 255 THEN bG& = 255
                    ELSE
                        DIM vgr2 AS LONG: vgr2& = 2 * sG&: IF vgr2& < = 0 THEN bG& = 0 ELSE bG& = 255 - ((255 - dG&) * 255) \ vgr2&: IF bG& < 0 THEN bG& = 0
                    END IF
                    IF sB& > 128 THEN
                        DIM vbr  AS LONG: vbr& = 2 * (sB& - 128): IF vbr& >= 255 THEN bB& = 255 ELSE bB& = (dB& * 255) \ (255 - vbr&): IF bB& > 255 THEN bB& = 255
                    ELSE
                        DIM vbr2 AS LONG: vbr2& = 2 * sB&: IF vbr2& < = 0 THEN bB& = 0 ELSE bB& = 255 - ((255 - dB&) * 255) \ vbr2&: IF bB& < 0 THEN bB& = 0
                    END IF
                CASE BLEND_LINEAR_LIGHT
                    bR& = dR& + 2 * sR& - 255 : IF bR& < 0 THEN bR& = 0 ELSE IF bR& > 255 THEN bR& = 255
                    bG& = dG& + 2 * sG& - 255 : IF bG& < 0 THEN bG& = 0 ELSE IF bG& > 255 THEN bG& = 255
                    bB& = dB& + 2 * sB& - 255 : IF bB& < 0 THEN bB& = 0 ELSE IF bB& > 255 THEN bB& = 255
                CASE BLEND_PIN_LIGHT
                    IF sR& > 128 THEN
                        DIM psr  AS LONG: psr& = 2 * sR& - 255: IF dR& > psr& THEN bR& = dR& ELSE bR& = psr&
                    ELSE
                        psr& = 2 * sR&: IF dR& < psr& THEN bR& = dR& ELSE bR& = psr&
                    END IF
                    IF sG& > 128 THEN
                        psr& = 2 * sG& - 255: IF dG& > psr& THEN bG& = dG& ELSE bG& = psr&
                    ELSE
                        psr& = 2 * sG&: IF dG& < psr& THEN bG& = dG& ELSE bG& = psr&
                    END IF
                    IF sB& > 128 THEN
                        psr& = 2 * sB& - 255: IF dB& > psr& THEN bB& = dB& ELSE bB& = psr&
                    ELSE
                        psr& = 2 * sB&: IF dB& < psr& THEN bB& = dB& ELSE bB& = psr&
                    END IF
                CASE BLEND_COLOR
                    DIM srcLumR  AS LONG, dstLumR AS LONG, deltaLumR AS LONG
                    srcLumR&   = (sR& * 77 + sG& * 150 + sB& * 29) \ 256
                    dstLumR&   = (dR& * 77 + dG& * 150 + dB& * 29) \ 256
                    deltaLumR& = dstLumR& - srcLumR&
                    bR&        = sR& + deltaLumR& : IF bR& < 0 THEN bR& = 0 ELSE IF bR& > 255 THEN bR& = 255
                    bG&        = sG& + deltaLumR& : IF bG& < 0 THEN bG& = 0 ELSE IF bG& > 255 THEN bG& = 255
                    bB&        = sB& + deltaLumR& : IF bB& < 0 THEN bB& = 0 ELSE IF bB& > 255 THEN bB& = 255
                CASE BLEND_LUMINOSITY
                    DIM srcLumR2 AS LONG, dstLumR2 AS LONG, deltaLumR2 AS LONG
                    srcLumR2&   = (sR& * 77 + sG& * 150 + sB& * 29) \ 256
                    dstLumR2&   = (dR& * 77 + dG& * 150 + dB& * 29) \ 256
                    deltaLumR2& = srcLumR2& - dstLumR2&
                    bR&         = dR& + deltaLumR2& : IF bR& < 0 THEN bR& = 0 ELSE IF bR& > 255 THEN bR& = 255
                    bG&         = dG& + deltaLumR2& : IF bG& < 0 THEN bG& = 0 ELSE IF bG& > 255 THEN bG& = 255
                    bB&         = dB& + deltaLumR2& : IF bB& < 0 THEN bB& = 0 ELSE IF bB& > 255 THEN bB& = 255
                CASE ELSE
                    bR& = sR&: bG& = sG&: bB& = sB&
            END SELECT
            IF dA& = 0 THEN
                rR& = bR&: rG& = bG&: rB& = bB&: rA& = effAlpha&
            ELSE
                rR& = dR& + ((bR& - dR&) * effAlpha&) \ 255
                rG& = dG& + ((bG& - dG&) * effAlpha&) \ 255
                rB& = dB& + ((bB& - dB&) * effAlpha&) \ 255
                rA& = dA& + effAlpha& - (dA& * effAlpha&) \ 255
                IF rA& > 255 THEN rA& = 255
            END IF
            _MEMPUT dstMem, dstMem.OFFSET + pixOff, _RGBA32(rR&, rG&, rB&, rA&) AS _UNSIGNED LONG
        NEXT colX%
    NEXT rowY%
    _MEMFREE srcMem: _MEMFREE dstMem
END SUB
