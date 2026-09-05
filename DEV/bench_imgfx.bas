$CONSOLE:ONLY
OPTION _EXPLICIT

' Bench + correctness gate for native/imgfx.h Tier-1 blur kernels.
' BASIC refs below are copied EXACT from GUI/IMAGE-ADJ.BM (progress ticks removed).
' Test image has varying alpha (0 / partial / 255) to exercise premul + alpha-gate.

DECLARE LIBRARY "./native/imgfx"
    SUB gj_blur_premul (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL radius AS LONG)
    SUB gj_blur_alpha_aware (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL radius AS LONG)
END DECLARE

CONST W      = 640
CONST H      = 480
CONST RADIUS = 6

DIM src AS LONG
src = _NEWIMAGE(W, H, 32)

' --- deterministic content w/ varying alpha, no RNG ---
DIM mSrc AS _MEM
mSrc = _MEMIMAGE(src)
DIM x    AS LONG, y AS LONG, rr AS LONG, gg AS LONG, bb AS LONG, aa AS LONG
FOR y = 0 TO H - 1
    FOR x = 0 TO W - 1
        rr = (x * 255) \ W
        gg = (y * 255) \ H
        bb = ((x + y) AND 63) * 4
        ' alpha: a big transparent hole, a partial band, else opaque
        aa = 255
        IF ((x \ 20) + (y \ 20)) AND 1 THEN aa = 128
        IF x > W \ 3 AND x < W \ 3 + 80 AND y > H \ 3 AND y < H \ 3 + 80 THEN aa = 0
        _MEMPUT mSrc, mSrc.OFFSET + (y * W + x) * 4, _RGBA32(rr, gg, bb, aa) AS _UNSIGNED LONG
    NEXT x
NEXT y
_MEMFREE mSrc

DIM t0     AS DOUBLE, t1 AS DOUBLE
DIM refA   AS LONG, refB AS LONG, cA AS LONG, cB AS LONG
DIM msRefP AS DOUBLE, msCppP AS DOUBLE, msRefA AS DOUBLE, msCppA AS DOUBLE

' ===================== PREMUL: BASIC ref =====================
t0   = TIMER(0.001)
refA = REF_blur_premul&(src, RADIUS)
t1   = TIMER(0.001): msRefP = ela(t0, t1)

' ===================== PREMUL: C++ =====================
cA = _NEWIMAGE(W, H, 32)
DIM cs AS _MEM, cd AS _MEM
cs = _MEMIMAGE(src): cd = _MEMIMAGE(cA)
t0 = TIMER(0.001)
gj_blur_premul cd.OFFSET, cs.OFFSET, W, H, RADIUS
t1 = TIMER(0.001) : msCppP = ela(t0, t1)
_MEMFREE cs       : _MEMFREE cd

DIM mm1 AS LONG
mm1 = diffimg&(refA, cA)

' ===================== ALPHA-AWARE: BASIC ref =====================
t0   = TIMER(0.001)
refB = REF_blur_alpha_aware&(src, RADIUS)
t1   = TIMER(0.001): msRefA = ela(t0, t1)

' ===================== ALPHA-AWARE: C++ =====================
cB = _COPYIMAGE(src, 32)
DIM es AS _MEM, ed AS _MEM
es = _MEMIMAGE(src): ed = _MEMIMAGE(cB)
t0 = TIMER(0.001)
gj_blur_alpha_aware ed.OFFSET, es.OFFSET, W, H, RADIUS
t1 = TIMER(0.001) : msCppA = ela(t0, t1)
_MEMFREE es       : _MEMFREE ed

DIM mm2 AS LONG
mm2 = diffimg&(refB, cB)

PRINT "==== imgfx kernels ("; LTRIM$(STR$(W)); "x"; LTRIM$(STR$(H)); ", radius"; RADIUS; ") ===="
PRINT "-- blur_premul (separable) --"
PRINT USING "  BASIC -O0: #####.### ms"; msRefP
PRINT USING "  C++   -O3: #####.### ms"; msCppP
IF msCppP > 0 THEN PRINT USING "  speedup  : #####.## x"; msRefP / msCppP
PRINT "  mismatches:"; mm1;
IF mm1 = 0 THEN PRINT " -> IDENTICAL" ELSE PRINT " *** FAIL ***"
PRINT "-- blur_alpha_aware (naive 2D) --"
PRINT USING "  BASIC -O0: #####.### ms"; msRefA
PRINT USING "  C++   -O3: #####.### ms"; msCppA
IF msCppA > 0 THEN PRINT USING "  speedup  : #####.## x"; msRefA / msCppA
PRINT "  mismatches:"; mm2;
IF mm2 = 0 THEN PRINT " -> IDENTICAL" ELSE PRINT " *** FAIL ***"
SYSTEM

FUNCTION ela# (t0 AS DOUBLE, t1 AS DOUBLE)
    DIM d AS DOUBLE: d = (t1 - t0) * 1000
    IF d < 0 THEN d = d + 86400000
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
    _MEMFREE ma: _MEMFREE mb
    diffimg = n
END FUNCTION

' ============ FAITHFUL COPY of IMAGE_ADJ_blur_premul_rgba (IMAGE-ADJ.BM:715) ============
FUNCTION REF_blur_premul& (sourceImg AS LONG, radius AS INTEGER)
    DIM bprW AS LONG, bprH AS LONG
    bprW& = _WIDTH(sourceImg&)                                         : bprH& = _HEIGHT(sourceImg&)
    IF radius% <= 0 THEN REF_blur_premul& = _COPYIMAGE(sourceImg&, 32) : EXIT FUNCTION

    DIM bprPremul AS LONG : bprPremul& = _NEWIMAGE(bprW&, bprH&, 32)
    DIM bprHBlur  AS LONG : bprHBlur& = _NEWIMAGE(bprW&, bprH&, 32)
    DIM bprResult AS LONG : bprResult& = _NEWIMAGE(bprW&, bprH&, 32)
    DIM bprSrcM   AS _MEM, bprPMM AS _MEM, bprHM AS _MEM, bprResM AS _MEM
    bprSrcM = _MEMIMAGE(sourceImg&) : bprPMM = _MEMIMAGE(bprPremul&)
    bprHM   = _MEMIMAGE(bprHBlur&)  : bprResM = _MEMIMAGE(bprResult&)

    DIM bprOff AS _OFFSET, bprPx AS _UNSIGNED LONG
    DIM bprR   AS INTEGER, bprG AS INTEGER, bprB AS INTEGER, bprA AS INTEGER
    FOR bprOff = 0 TO bprSrcM.SIZE - 4 STEP 4
        _MEMGET bprSrcM, bprSrcM.OFFSET + bprOff, bprPx~&
        bprA% = _ALPHA32(bprPx~&)
        IF bprA% > 0 THEN
            bprR% = _RED32(bprPx~&) * bprA% \ 255
            bprG% = _GREEN32(bprPx~&) * bprA% \ 255
            bprB% = _BLUE32(bprPx~&) * bprA% \ 255
        ELSE
            bprR% = 0: bprG% = 0: bprB% = 0
        END IF
        _MEMPUT bprPMM, bprPMM.OFFSET + bprOff, _RGBA32(bprR%, bprG%, bprB%, bprA%) AS _UNSIGNED LONG
    NEXT bprOff
    _MEMFREE bprSrcM

    DIM bprX AS LONG, bprY AS LONG
    DIM sumR AS LONG, sumG AS LONG, sumB AS LONG, sumA AS LONG, cnt AS LONG
    DIM lo   AS LONG, hi AS LONG, smp AS _UNSIGNED LONG, rowBase AS _OFFSET

    FOR bprY& = 0 TO bprH& - 1
        rowBase = bprY& * bprW& * 4
        sumR&   = 0       : sumG& = 0 : sumB& = 0 : sumA& = 0 : cnt& = 0
        hi&     = radius% : IF hi& > bprW& - 1 THEN hi& = bprW& - 1
        FOR bprX& = 0 TO hi&
            _MEMGET bprPMM, bprPMM.OFFSET + rowBase + bprX& * 4, smp~&
            sumR& = sumR& + _RED32(smp~&)  : sumG& = sumG& + _GREEN32(smp~&)
            sumB& = sumB& + _BLUE32(smp~&) : sumA& = sumA& + _ALPHA32(smp~&) : cnt& = cnt& + 1
        NEXT bprX&
        FOR bprX& = 0 TO bprW& - 1
            IF cnt& > 0 THEN _MEMPUT bprHM, bprHM.OFFSET + rowBase + bprX& * 4, _RGBA32(sumR& \ cnt&, sumG& \ cnt&, sumB& \ cnt&, sumA& \ cnt&) AS _UNSIGNED LONG
            lo& = bprX& - radius%
            IF lo& >= 0 THEN
                _MEMGET bprPMM, bprPMM.OFFSET + rowBase + lo& * 4, smp~&
                sumR& = sumR& - _RED32(smp~&)  : sumG& = sumG& - _GREEN32(smp~&)
                sumB& = sumB& - _BLUE32(smp~&) : sumA& = sumA& - _ALPHA32(smp~&) : cnt& = cnt& - 1
            END IF
            hi& = bprX& + radius% + 1
            IF hi& < bprW& THEN
                _MEMGET bprPMM, bprPMM.OFFSET + rowBase + hi& * 4, smp~&
                sumR& = sumR& + _RED32(smp~&)  : sumG& = sumG& + _GREEN32(smp~&)
                sumB& = sumB& + _BLUE32(smp~&) : sumA& = sumA& + _ALPHA32(smp~&) : cnt& = cnt& + 1
            END IF
        NEXT bprX&
    NEXT bprY&

    DIM ba AS INTEGER, fr AS INTEGER, fg AS INTEGER, fb AS INTEGER
    FOR bprX& = 0 TO bprW& - 1
        sumR& = 0       : sumG& = 0 : sumB& = 0 : sumA& = 0 : cnt& = 0
        hi&   = radius% : IF hi& > bprH& - 1 THEN hi& = bprH& - 1
        FOR bprY& = 0 TO hi&
            _MEMGET bprHM, bprHM.OFFSET + (bprY& * bprW& + bprX&) * 4, smp~&
            sumR& = sumR& + _RED32(smp~&)  : sumG& = sumG& + _GREEN32(smp~&)
            sumB& = sumB& + _BLUE32(smp~&) : sumA& = sumA& + _ALPHA32(smp~&) : cnt& = cnt& + 1
        NEXT bprY&
        FOR bprY& = 0 TO bprH& - 1
            IF cnt& > 0 THEN
                ba% = sumA& \ cnt&
                IF ba% > 0 THEN
                    fr% = (sumR& \ cnt&) * 255 \ ba% : IF fr% > 255 THEN fr% = 255
                    fg% = (sumG& \ cnt&) * 255 \ ba% : IF fg% > 255 THEN fg% = 255
                    fb% = (sumB& \ cnt&) * 255 \ ba% : IF fb% > 255 THEN fb% = 255
                    _MEMPUT bprResM, bprResM.OFFSET + (bprY& * bprW& + bprX&) * 4, _RGBA32(fr%, fg%, fb%, ba%) AS _UNSIGNED LONG
                END IF
            END IF
            lo& = bprY& - radius%
            IF lo& >= 0 THEN
                _MEMGET bprHM, bprHM.OFFSET + (lo& * bprW& + bprX&) * 4, smp~&
                sumR& = sumR& - _RED32(smp~&)  : sumG& = sumG& - _GREEN32(smp~&)
                sumB& = sumB& - _BLUE32(smp~&) : sumA& = sumA& - _ALPHA32(smp~&) : cnt& = cnt& - 1
            END IF
            hi& = bprY& + radius% + 1
            IF hi& < bprH& THEN
                _MEMGET bprHM, bprHM.OFFSET + (hi& * bprW& + bprX&) * 4, smp~&
                sumR& = sumR& + _RED32(smp~&)  : sumG& = sumG& + _GREEN32(smp~&)
                sumB& = sumB& + _BLUE32(smp~&) : sumA& = sumA& + _ALPHA32(smp~&) : cnt& = cnt& + 1
            END IF
        NEXT bprY&
    NEXT bprX&

    _MEMFREE bprPMM      : _MEMFREE bprHM : _MEMFREE bprResM
    SAFE_FREE bprPremul& : SAFE_FREE bprHBlur&
    REF_blur_premul& = bprResult&
END FUNCTION

' ============ FAITHFUL COPY of IMAGE_ADJ_blur_alpha_aware (IMAGE-ADJ.BM:876) ============
FUNCTION REF_blur_alpha_aware& (sourceImg AS LONG, radius AS INTEGER)
    DIM baaResult AS LONG                                   : baaResult& = _COPYIMAGE(sourceImg&, 32)
    IF radius% <= 0 THEN REF_blur_alpha_aware& = baaResult& : EXIT FUNCTION

    DIM baaSrc AS _MEM, baaRes AS _MEM
    baaSrc = _MEMIMAGE(sourceImg&): baaRes = _MEMIMAGE(baaResult&)
    DIM baaW   AS LONG, baaH AS LONG
    baaW& = _WIDTH(sourceImg&): baaH& = _HEIGHT(sourceImg&)

    DIM baaX     AS LONG, baaY AS LONG, baaDX AS INTEGER, baaDY AS INTEGER
    DIM baaSX    AS LONG, baaSY AS LONG
    DIM baaSumR  AS LONG, baaSumG AS LONG, baaSumB AS LONG, baaSumW AS LONG
    DIM baaPx    AS _UNSIGNED LONG, baaA AS INTEGER
    DIM baaCurPx AS _UNSIGNED LONG, baaOutPx AS _UNSIGNED LONG

    FOR baaY& = 0 TO baaH& - 1
        FOR baaX& = 0 TO baaW& - 1
            baaCurPx~& = _MEMGET(baaSrc, baaSrc.OFFSET + (baaY& * baaW& + baaX&) * 4, _UNSIGNED LONG)
            IF _ALPHA32(baaCurPx~&) > 0 THEN
                baaSumR& = 0: baaSumG& = 0: baaSumB& = 0: baaSumW& = 0
                FOR baaDY% = -radius% TO radius%
                    baaSY& = baaY& + baaDY%
                    IF baaSY& >= 0 AND baaSY& < baaH& THEN
                        FOR baaDX% = -radius% TO radius%
                            baaSX& = baaX& + baaDX%
                            IF baaSX& >= 0 AND baaSX& < baaW& THEN
                                baaPx~& = _MEMGET(baaSrc, baaSrc.OFFSET + (baaSY& * baaW& + baaSX&) * 4, _UNSIGNED LONG)
                                baaA%   = _ALPHA32(baaPx~&)
                                IF baaA% > 0 THEN
                                    baaSumR& = baaSumR& + _RED32(baaPx~&)
                                    baaSumG& = baaSumG& + _GREEN32(baaPx~&)
                                    baaSumB& = baaSumB& + _BLUE32(baaPx~&)
                                    baaSumW& = baaSumW& + 1
                                END IF
                            END IF
                        NEXT baaDX%
                    END IF
                NEXT baaDY%
                IF baaSumW& > 0 THEN
                    baaOutPx~& = _RGB32(baaSumR& \ baaSumW&, baaSumG& \ baaSumW&, baaSumB& \ baaSumW&)
                    _MEMPUT baaRes, baaRes.OFFSET + (baaY& * baaW& + baaX&) * 4, baaOutPx~& AS _UNSIGNED LONG
                END IF
            ELSE
                baaOutPx~& = _RGB32(0, 0, 0)
                _MEMPUT baaRes, baaRes.OFFSET + (baaY& * baaW& + baaX&) * 4, baaOutPx~& AS _UNSIGNED LONG
            END IF
        NEXT baaX&
    NEXT baaY&

    _MEMFREE baaSrc: _MEMFREE baaRes
    REF_blur_alpha_aware& = baaResult&
END FUNCTION

SUB SAFE_FREE (h AS LONG)
    IF h& < -1 THEN _FREEIMAGE h&
END SUB
