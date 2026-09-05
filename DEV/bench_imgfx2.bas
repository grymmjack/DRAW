$CONSOLE:ONLY
OPTION _EXPLICIT

' Tier-2 bench + correctness gate for native/imgfx.h.
' BASIC refs below are copied EXACT from GUI/IMAGE-ADJ.BM (progress ticks removed).

DECLARE LIBRARY "./native/imgfx"
    SUB gj_blur_alpha_aware (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL radius AS LONG)
    SUB gj_pixelate_alpha_aware (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL blockSize AS LONG)
    SUB gj_unsharp_combine (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL blur AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL amt AS LONG, BYVAL threshold AS LONG)
    SUB gj_median3 (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG)
    SUB gj_emboss (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL odx AS LONG, BYVAL ody AS LONG, BYVAL strength AS LONG)
    SUB gj_edgedetect (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL strength AS LONG, BYVAL invert AS LONG)
END DECLARE

CONST W = 640
CONST H = 480

DIM SHARED kms AS DOUBLE ' kernel time (ms), set by each runkernel_* wrapper

DIM src  AS LONG
src = _NEWIMAGE(W, H, 32)
DIM mSrc AS _MEM
mSrc = _MEMIMAGE(src)
DIM x    AS LONG, y AS LONG, rr AS LONG, gg AS LONG, bb AS LONG, aa AS LONG
FOR y = 0 TO H - 1
    FOR x = 0 TO W - 1
        rr = (x * 255) \ W
        gg = (y * 255) \ H
        bb = ((x * 3 + y * 7) AND 255)
        aa = 255
        IF ((x \ 20) + (y \ 20)) AND 1 THEN aa = 128
        IF x > W \ 3 AND x < W \ 3 + 80 AND y > H \ 3 AND y < H \ 3 + 80 THEN aa = 0
        _MEMPUT mSrc, mSrc.OFFSET + (y * W + x) * 4, _RGBA32(rr, gg, bb, aa) AS _UNSIGNED LONG
    NEXT x
NEXT y
_MEMFREE mSrc

DIM t0 AS DOUBLE, t1 AS DOUBLE

' ===== PIXELATE (block 8) =====
DIM rp AS LONG, cp AS LONG
t0 = TIMER(0.001): rp = REF_pixelate&(src, 8): t1 = TIMER(0.001): DIM msRp AS DOUBLE: msRp = ela(t0, t1)
cp = _COPYIMAGE(src, 32)
runkernel_pix cp, src, 8
report "pixelate (block 8)", msRp, kms, diffimg&(rp, cp)

' ===== UNSHARP COMBINE (amt 8, thr 3) =====
DIM blur AS LONG             : blur = _COPYIMAGE(src, 32)
DIM bs   AS _MEM, bd AS _MEM : bs = _MEMIMAGE(src) : bd = _MEMIMAGE(blur)
gj_blur_alpha_aware bd.OFFSET, bs.OFFSET, W, H, 3
_MEMFREE bs: _MEMFREE bd
DIM ru   AS LONG, cu AS LONG
t0 = TIMER(0.001): ru = REF_unsharp&(src, blur, 8, 3): t1 = TIMER(0.001): DIM msRu AS DOUBLE: msRu = ela(t0, t1)
cu = _NEWIMAGE(W, H, 32)
runkernel_unsharp cu, src, blur, 8, 3
report "unsharp combine (amt8,thr3)", msRu, kms, diffimg&(ru, cu)

' ===== MEDIAN 3x3 =====
DIM rm AS LONG, cm AS LONG
t0 = TIMER(0.001): rm = REF_median&(src): t1 = TIMER(0.001): DIM msRm AS DOUBLE: msRm = ela(t0, t1)
cm = _COPYIMAGE(src, 32)
runkernel_median cm, src
report "median 3x3", msRm, kms, diffimg&(rm, cm)

' ===== EMBOSS (strength 3, angle 135) =====
DIM re AS LONG, ce AS LONG
t0 = TIMER(0.001): re = REF_emboss&(src, 3, 135): t1 = TIMER(0.001): DIM msRe AS DOUBLE: msRe = ela(t0, t1)
ce = _COPYIMAGE(src, 32)
runkernel_emboss ce, src, 3, 135
report "emboss (str3,ang135)", msRe, kms, diffimg&(re, ce)

' ===== EDGE DETECT (strength 100, invert 0) =====
DIM rd AS LONG, cd2 AS LONG
t0  = TIMER(0.001): rd = REF_edge&(src, 100, 0): t1 = TIMER(0.001): DIM msRd AS DOUBLE: msRd = ela(t0, t1)
cd2 = _COPYIMAGE(src, 32)
runkernel_edge cd2, src, 100, 0
report "edgedetect (str100)", msRd, kms, diffimg&(rd, cd2)

SYSTEM

SUB report (nm AS STRING, refMs AS DOUBLE, cppMs AS DOUBLE, mism AS LONG)
    PRINT "-- "; nm; " --"
    PRINT USING "   BASIC -O0: #####.### ms"; refMs
    PRINT USING "   C++   -O3: #####.### ms"; cppMs
    IF cppMs > 0 THEN PRINT USING "   speedup  : #####.## x"; refMs / cppMs
    PRINT "   mismatches:"; mism;
    IF mism = 0 THEN PRINT " -> IDENTICAL" ELSE PRINT " *** FAIL ***"
END SUB

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

' ---------- kernel wrappers (map images -> offsets, time the call) ----------
SUB runkernel_pix (dst AS LONG, srcI AS LONG, bs AS INTEGER)
    DIM ms AS _MEM, md AS _MEM, t0 AS DOUBLE, t1 AS DOUBLE
    ms  = _MEMIMAGE(srcI) : md = _MEMIMAGE(dst)
    t0  = TIMER(0.001)    : gj_pixelate_alpha_aware md.OFFSET, ms.OFFSET, W, H, bs : t1 = TIMER(0.001)
    kms = ela(t0, t1)     : _MEMFREE ms                                            : _MEMFREE md
END SUB
SUB runkernel_unsharp (dst AS LONG, srcI AS LONG, blurI AS LONG, amt AS INTEGER, thr AS INTEGER)
    DIM ms AS _MEM, mb AS _MEM, md AS _MEM, t0 AS DOUBLE, t1 AS DOUBLE
    ms  = _MEMIMAGE(srcI) : mb = _MEMIMAGE(blurI)                                              : md = _MEMIMAGE(dst)
    t0  = TIMER(0.001)    : gj_unsharp_combine md.OFFSET, ms.OFFSET, mb.OFFSET, W, H, amt, thr : t1 = TIMER(0.001)
    kms = ela(t0, t1)     : _MEMFREE ms                                                        : _MEMFREE mb : _MEMFREE md
END SUB
SUB runkernel_median (dst AS LONG, srcI AS LONG)
    DIM ms AS _MEM, md AS _MEM, t0 AS DOUBLE, t1 AS DOUBLE
    ms  = _MEMIMAGE(srcI) : md = _MEMIMAGE(dst)
    t0  = TIMER(0.001)    : gj_median3 md.OFFSET, ms.OFFSET, W, H : t1 = TIMER(0.001)
    kms = ela(t0, t1)     : _MEMFREE ms                           : _MEMFREE md
END SUB
SUB runkernel_emboss (dst AS LONG, srcI AS LONG, strength AS INTEGER, angleDeg AS INTEGER)
    DIM ms    AS _MEM, md AS _MEM, t0 AS DOUBLE, t1 AS DOUBLE
    DIM emRad AS SINGLE                : emRad! = angleDeg% * 3.14159265 / 180.0
    DIM lcx   AS SINGLE, lcy AS SINGLE : lcx! = COS(emRad!) : lcy! = -SIN(emRad!)
    DIM odx   AS INTEGER, ody AS INTEGER
    odx% = 0 : IF lcx! > 0.35 THEN odx% = 1 ELSE IF lcx! < -0.35 THEN odx% = -1
    ody% = 0 : IF lcy! > 0.35 THEN ody% = 1 ELSE IF lcy! < -0.35 THEN ody% = -1
    IF odx% = 0 AND ody% = 0 THEN ody% = -1
    ms  = _MEMIMAGE(srcI) : md = _MEMIMAGE(dst)
    t0  = TIMER(0.001)    : gj_emboss md.OFFSET, ms.OFFSET, W, H, odx%, ody%, strength% : t1 = TIMER(0.001)
    kms = ela(t0, t1)     : _MEMFREE ms                                                 : _MEMFREE md
END SUB
SUB runkernel_edge (dst AS LONG, srcI AS LONG, strength AS INTEGER, invert AS INTEGER)
    DIM ms AS _MEM, md AS _MEM, t0 AS DOUBLE, t1 AS DOUBLE
    ms  = _MEMIMAGE(srcI) : md = _MEMIMAGE(dst)
    t0  = TIMER(0.001)    : gj_edgedetect md.OFFSET, ms.OFFSET, W, H, strength%, invert% : t1 = TIMER(0.001)
    kms = ela(t0, t1)     : _MEMFREE ms                                                  : _MEMFREE md
END SUB

' ================= FAITHFUL BASIC REFS (exact copies) =================
FUNCTION REF_pixelate& (sourceImg AS LONG, pixelSize AS INTEGER)
    DIM paaBlockSize AS INTEGER: paaBlockSize% = pixelSize%
    IF paaBlockSize% < 1 THEN paaBlockSize% = 1
    IF paaBlockSize% > 50 THEN paaBlockSize% = 50
    DIM paaW         AS LONG, paaH AS LONG   : paaW& = _WIDTH(sourceImg&)     : paaH& = _HEIGHT(sourceImg&)
    DIM paaResult    AS LONG                 : paaResult& = _COPYIMAGE(sourceImg&, 32)
    DIM paaSrc       AS _MEM, paaRes AS _MEM : paaSrc = _MEMIMAGE(sourceImg&) : paaRes = _MEMIMAGE(paaResult&)
    DIM paaBlockX    AS LONG, paaBlockY AS LONG, paaX AS LONG, paaY AS LONG
    DIM paaSumR      AS LONG, paaSumG AS LONG, paaSumB AS LONG, paaSumW AS LONG
    DIM paaPx        AS _UNSIGNED LONG, paaA AS INTEGER, paaAvgColor AS _UNSIGNED LONG
    DIM paaEndX      AS LONG, paaEndY AS LONG
    FOR paaBlockY& = 0 TO paaH& - 1 STEP paaBlockSize%
        FOR paaBlockX& = 0 TO paaW& - 1 STEP paaBlockSize%
            paaSumR& = 0                              : paaSumG& = 0 : paaSumB& = 0 : paaSumW& = 0
            paaEndY& = paaBlockY& + paaBlockSize% - 1 : IF paaEndY& > paaH& - 1 THEN paaEndY& = paaH& - 1
            paaEndX& = paaBlockX& + paaBlockSize% - 1 : IF paaEndX& > paaW& - 1 THEN paaEndX& = paaW& - 1
            FOR paaY& = paaBlockY& TO paaEndY&
                FOR paaX& = paaBlockX& TO paaEndX&
                    _MEMGET paaSrc, paaSrc.OFFSET + (paaY& * paaW& + paaX&) * 4, paaPx~&
                    paaA% = _ALPHA32(paaPx~&)
                    IF paaA% > 0 THEN
                        paaSumR& = paaSumR& + _RED32(paaPx~&)  : paaSumG& = paaSumG& + _GREEN32(paaPx~&)
                        paaSumB& = paaSumB& + _BLUE32(paaPx~&) : paaSumW& = paaSumW& + 1
                    END IF
                NEXT paaX&
            NEXT paaY&
            IF paaSumW& > 0 THEN
                paaAvgColor~& = _RGB32(paaSumR& \ paaSumW&, paaSumG& \ paaSumW&, paaSumB& \ paaSumW&)
                FOR paaY& = paaBlockY& TO paaEndY&
                    FOR paaX& = paaBlockX& TO paaEndX&
                        _MEMPUT paaRes, paaRes.OFFSET + (paaY& * paaW& + paaX&) * 4, paaAvgColor~& AS _UNSIGNED LONG
                    NEXT paaX&
                NEXT paaY&
            END IF
        NEXT paaBlockX&
    NEXT paaBlockY&
    _MEMFREE paaSrc: _MEMFREE paaRes: REF_pixelate& = paaResult&
END FUNCTION

FUNCTION REF_unsharp& (sourceImg AS LONG, blurred AS LONG, amt AS INTEGER, threshold AS INTEGER)
    DIM result  AS LONG: result& = _COPYIMAGE(sourceImg, 32)
    DIM mSrc    AS _MEM, mBlur AS _MEM, mRes AS _MEM
    mSrc = _MEMIMAGE(sourceImg) : mBlur = _MEMIMAGE(blurred&) : mRes = _MEMIMAGE(result&)
    DIM totalPx AS LONG         : totalPx& = _WIDTH(sourceImg) * _HEIGHT(sourceImg)
    DIM i       AS LONG, px AS _UNSIGNED LONG, bpx AS _UNSIGNED LONG
    DIM r       AS INTEGER, g AS INTEGER, bl AS INTEGER, a AS INTEGER
    DIM br      AS INTEGER, bg2 AS INTEGER, bb2 AS INTEGER, nr AS INTEGER, ng AS INTEGER, nb AS INTEGER
    DIM ddr     AS INTEGER, ddg AS INTEGER, ddb AS INTEGER, outPx AS _UNSIGNED LONG
    FOR i& = 0 TO totalPx& - 1
        _MEMGET mSrc, mSrc.OFFSET + i& * 4, px~&
        _MEMGET mBlur, mBlur.OFFSET + i& * 4, bpx~&
        r   = _RED32(px~&)       : g = _GREEN32(px~&)      : bl = _BLUE32(px~&) : a = _ALPHA32(px~&)
        br  = _RED32(bpx~&)      : bg2 = _GREEN32(bpx~&)   : bb2 = _BLUE32(bpx~&)
        ddr = r - br             : IF ABS(ddr) <= threshold% THEN ddr = 0
        ddg = g - bg2            : IF ABS(ddg) <= threshold% THEN ddg = 0
        ddb = bl - bb2           : IF ABS(ddb) <= threshold% THEN ddb = 0
        nr  = r + ddr * amt% \ 5 : ng = g + ddg * amt% \ 5 : nb = bl + ddb * amt% \ 5
        IF nr < 0 THEN nr = 0
        IF nr > 255 THEN nr = 255
        IF ng < 0 THEN ng = 0
        IF ng > 255 THEN ng = 255
        IF nb < 0 THEN nb = 0
        IF nb > 255 THEN nb = 255
        outPx~& = _RGBA32(nr, ng, nb, a)
        _MEMPUT mRes, mRes.OFFSET + i& * 4, outPx~&
    NEXT i&
    _MEMFREE mSrc: _MEMFREE mBlur: _MEMFREE mRes: REF_unsharp& = result&
END FUNCTION

FUNCTION REF_median& (sourceImg AS LONG)
    DIM mdW    AS LONG, mdH AS LONG  : mdW& = _WIDTH(sourceImg&)    : mdH& = _HEIGHT(sourceImg&)
    DIM result AS LONG               : result& = _COPYIMAGE(sourceImg&, 32)
    DIM srcM   AS _MEM, resM AS _MEM : srcM = _MEMIMAGE(sourceImg&) : resM = _MEMIMAGE(result&)
    DIM mx     AS LONG, my AS LONG, dx AS INTEGER, dy AS INTEGER, nx AS LONG, ny AS LONG
    DIM rV(0 TO 8) AS INTEGER, gV(0 TO 8) AS INTEGER, bV(0 TO 8) AS INTEGER
    DIM n      AS INTEGER, j AS INTEGER, tmp AS INTEGER, px AS _UNSIGNED LONG, aHere AS _UNSIGNED _BYTE
    FOR my& = 0 TO mdH& - 1
        FOR mx& = 0 TO mdW& - 1
            n% = 0
            FOR dy% = -1 TO 1
                ny& = my& + dy%: IF ny& < 0 THEN ny& = 0 ELSE IF ny& >= mdH& THEN ny& = mdH& - 1
                FOR dx% = -1 TO 1
                    nx& = mx& + dx%: IF nx& < 0 THEN nx& = 0 ELSE IF nx& >= mdW& THEN nx& = mdW& - 1
                    _MEMGET srcM, srcM.OFFSET + (ny& * mdW& + nx&) * 4, px~&
                    rV(n%) = _RED32(px~&): gV(n%) = _GREEN32(px~&): bV(n%) = _BLUE32(px~&): n% = n% + 1
                NEXT dx%
            NEXT dy%
            FOR n% = 1 TO 8
                tmp% = rV(n%)    : j% = n% - 1
                DO WHILE j% >= 0 : IF rV(j%) <= tmp% THEN EXIT DO
                    rV(j% + 1) = rV(j%): j% = j% - 1
                LOOP
                rV(j% + 1) = tmp%
                tmp%       = gV(n%) : j% = n% - 1
                DO WHILE j% >= 0    : IF gV(j%) <= tmp% THEN EXIT DO
                    gV(j% + 1) = gV(j%): j% = j% - 1
                LOOP
                gV(j% + 1) = tmp%
                tmp%       = bV(n%) : j% = n% - 1
                DO WHILE j% >= 0    : IF bV(j%) <= tmp% THEN EXIT DO
                    bV(j% + 1) = bV(j%): j% = j% - 1
                LOOP
                bV(j% + 1) = tmp%
            NEXT n%
            _MEMGET srcM, srcM.OFFSET + (my& * mdW& + mx&) * 4 + 3, aHere~%%
            _MEMPUT resM, resM.OFFSET + (my& * mdW& + mx&) * 4, _RGBA32(rV(4), gV(4), bV(4), aHere~%%) AS _UNSIGNED LONG
        NEXT mx&
    NEXT my&
    _MEMFREE srcM: _MEMFREE resM: REF_median& = result&
END FUNCTION

FUNCTION REF_emboss& (sourceImg AS LONG, strength AS INTEGER, angleDeg AS INTEGER)
    DIM emW    AS LONG, emH AS LONG     : emW& = _WIDTH(sourceImg&)    : emH& = _HEIGHT(sourceImg&)
    DIM result AS LONG                  : result& = _COPYIMAGE(sourceImg&, 32)
    DIM srcM   AS _MEM, resM AS _MEM    : srcM = _MEMIMAGE(sourceImg&) : resM = _MEMIMAGE(result&)
    DIM emRad  AS SINGLE                : emRad! = angleDeg% * 3.14159265 / 180.0
    DIM lcx    AS SINGLE, lcy AS SINGLE : lcx! = COS(emRad!)           : lcy! = -SIN(emRad!)
    DIM odx    AS INTEGER, ody AS INTEGER
    odx% = 0 : IF lcx! > 0.35 THEN odx% = 1 ELSE IF lcx! < -0.35 THEN odx% = -1
    ody% = 0 : IF lcy! > 0.35 THEN ody% = 1 ELSE IF lcy! < -0.35 THEN ody% = -1
    IF odx% = 0 AND ody% = 0 THEN ody% = -1
    REDIM lum(0 TO emW& * emH& - 1) AS INTEGER
    DIM i      AS LONG, px AS _UNSIGNED LONG
    FOR i& = 0 TO emW& * emH& - 1
        _MEMGET srcM, srcM.OFFSET + i& * 4, px~&
        lum(i&) = (_RED32(px~&) * 30 + _GREEN32(px~&) * 59 + _BLUE32(px~&) * 11) \ 100
    NEXT i&
    DIM ex     AS LONG, ey AS LONG, pxm AS LONG, pym AS LONG, dLum AS LONG, outv AS INTEGER
    FOR ey& = 0 TO emH& - 1
        pym& = ey& + ody%: IF pym& < 0 THEN pym& = 0 ELSE IF pym& >= emH& THEN pym& = emH& - 1
        FOR ex& = 0 TO emW& - 1
            pxm&  = ex& + odx%: IF pxm& < 0 THEN pxm& = 0 ELSE IF pxm& >= emW& THEN pxm& = emW& - 1
            dLum& = lum(ey& * emW& + ex&) - lum(pym& * emW& + pxm&)
            outv% = 128 + dLum& * strength%
            IF outv% < 0 THEN outv% = 0 ELSE IF outv% > 255 THEN outv% = 255
            _MEMPUT resM, resM.OFFSET + (ey& * emW& + ex&) * 4, _RGB32(outv%, outv%, outv%) AS _UNSIGNED LONG
        NEXT ex&
    NEXT ey&
    _MEMFREE srcM: _MEMFREE resM: REF_emboss& = result&
END FUNCTION

FUNCTION REF_edge& (sourceImg AS LONG, strength AS INTEGER, invert AS INTEGER)
    DIM edW    AS LONG, edH AS LONG  : edW& = _WIDTH(sourceImg&)    : edH& = _HEIGHT(sourceImg&)
    DIM result AS LONG               : result& = _COPYIMAGE(sourceImg&, 32)
    DIM srcM   AS _MEM, resM AS _MEM : srcM = _MEMIMAGE(sourceImg&) : resM = _MEMIMAGE(result&)
    REDIM lum(0 TO edW& * edH& - 1) AS INTEGER
    DIM i      AS LONG, px AS _UNSIGNED LONG
    FOR i& = 0 TO edW& * edH& - 1
        _MEMGET srcM, srcM.OFFSET + i& * 4, px~&
        lum(i&) = (_RED32(px~&) * 30 + _GREEN32(px~&) * 59 + _BLUE32(px~&) * 11) \ 100
    NEXT i&
    DIM ex     AS LONG, ey AS LONG, xm AS LONG, xp AS LONG, ym AS LONG, yp AS LONG
    DIM tl     AS LONG, tm AS LONG, tr AS LONG, ml AS LONG, mr AS LONG, bl AS LONG, bm AS LONG, br AS LONG
    DIM gx     AS LONG, gy AS LONG, mag AS LONG, outv AS INTEGER
    DIM sf     AS SINGLE: sf! = strength% / 100.0
    FOR ey& = 0 TO edH& - 1
        ym& = ey& - 1 : IF ym& < 0 THEN ym& = 0
        yp& = ey& + 1 : IF yp& >= edH& THEN yp& = edH& - 1
        FOR ex& = 0 TO edW& - 1
            xm&  = ex& - 1               : IF xm& < 0 THEN xm& = 0
            xp&  = ex& + 1               : IF xp& >= edW& THEN xp& = edW& - 1
            tl&  = lum(ym& * edW& + xm&) : tm& = lum(ym& * edW& + ex&) : tr& = lum(ym& * edW& + xp&)
            ml&  = lum(ey& * edW& + xm&) : mr& = lum(ey& * edW& + xp&)
            bl&  = lum(yp& * edW& + xm&) : bm& = lum(yp& * edW& + ex&) : br& = lum(yp& * edW& + xp&)
            gx&  = (tr& + 2 * mr& + br&) - (tl& + 2 * ml& + bl&)
            gy&  = (bl& + 2 * bm& + br&) - (tl& + 2 * tm& + tr&)
            mag& = INT(SQR(gx& * gx& + gy& * gy&) * sf!)
            IF mag& > 255 THEN mag& = 255
            outv% = mag&
            IF invert% THEN outv% = 255 - outv%
            _MEMPUT resM, resM.OFFSET + (ey& * edW& + ex&) * 4, _RGB32(outv%, outv%, outv%) AS _UNSIGNED LONG
        NEXT ex&
    NEXT ey&
    _MEMFREE srcM: _MEMFREE resM: REF_edge& = result&
END FUNCTION
