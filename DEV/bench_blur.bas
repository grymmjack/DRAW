$CONSOLE:ONLY
OPTION _EXPLICIT

' Benchmark: box blur, BASIC (-O0, this program's TU) vs C++ (-O3, native/blur_kernel.h).
' Same algorithm both ways; outputs diffed pixel-for-pixel to prove the port is faithful.

DECLARE LIBRARY "./native/blur_kernel"
    SUB gj_box_blur (BYVAL dst AS _OFFSET, BYVAL src AS _OFFSET, BYVAL w AS LONG, BYVAL h AS LONG, BYVAL radius AS LONG)
END DECLARE

CONST W      = 1280
CONST H      = 720
CONST RADIUS = 6

DIM src AS LONG, dstBAS AS LONG, dstCPP AS LONG
src    = _NEWIMAGE(W, H, 32)
dstBAS = _NEWIMAGE(W, H, 32)
dstCPP = _NEWIMAGE(W, H, 32)

DIM x AS LONG, y AS LONG, r AS LONG, g AS LONG, b AS LONG, p AS _UNSIGNED LONG

' --- deterministic test content: two gradients + a checker, no RNG ---
DIM mSrc AS _MEM
mSrc = _MEMIMAGE(src)
FOR y = 0 TO H - 1
    FOR x = 0 TO W - 1
        r = (x * 255) \ W
        g = (y * 255) \ H
        b = ((x + y) AND 63) * 4
        IF ((x \ 16) + (y \ 16)) AND 1 THEN b = 255 - b
        p = _RGB32(r, g, b)
        _MEMPUT mSrc, mSrc.OFFSET + (y * W + x) * 4, p AS _UNSIGNED LONG
    NEXT x
NEXT y
_MEMFREE mSrc

' =====================================================================
' BASIC reference (-O0) -- identical math to native/blur_kernel.h
' =====================================================================
DIM mS AS _MEM, mD AS _MEM
mS = _MEMIMAGE(src)
mD = _MEMIMAGE(dstBAS)

DIM t0  AS DOUBLE, t1 AS DOUBLE
DIM sy  AS LONG, sx AS LONG, y0 AS LONG, y1 AS LONG, x0 AS LONG, x1 AS LONG
DIM sr  AS _UNSIGNED LONG, sg AS _UNSIGNED LONG, sb AS _UNSIGNED LONG, cnt AS LONG
DIM pix AS _UNSIGNED LONG, rowOff AS _OFFSET

t0 = TIMER(0.001)
FOR y = 0 TO H - 1
    y0 = y - RADIUS : IF y0 < 0 THEN y0 = 0
    y1 = y + RADIUS : IF y1 > H - 1 THEN y1 = H - 1
    FOR x = 0 TO W - 1
        x0 = x - RADIUS : IF x0 < 0 THEN x0 = 0
        x1 = x + RADIUS : IF x1 > W - 1 THEN x1 = W - 1
        sr = 0          : sg = 0 : sb = 0 : cnt = 0
        FOR sy = y0 TO y1
            rowOff = mS.OFFSET + (sy * W) * 4
            FOR sx = x0 TO x1
                _MEMGET mS, rowOff + sx * 4, pix
                sr = sr + ((pix \ 65536) AND 255)
                sg = sg + ((pix \ 256) AND 255)
                sb = sb + (pix AND 255)
                cnt = cnt + 1
            NEXT sx
        NEXT sy
        pix = _RGB32(sr \ cnt, sg \ cnt, sb \ cnt)
        _MEMPUT mD, mD.OFFSET + (y * W + x) * 4, pix AS _UNSIGNED LONG
    NEXT x
NEXT y
t1 = TIMER(0.001)
DIM basMs AS DOUBLE
basMs = (t1 - t0) * 1000
IF basMs < 0 THEN basMs = basMs + 86400000

' =====================================================================
' C++ kernel (-O3)
' =====================================================================
DIM cS    AS _MEM, cD AS _MEM
cS = _MEMIMAGE(src)
cD = _MEMIMAGE(dstCPP)
t0 = TIMER(0.001)
gj_box_blur cD.OFFSET, cS.OFFSET, W, H, RADIUS
t1 = TIMER(0.001)
DIM cppMs AS DOUBLE
cppMs = (t1 - t0) * 1000
IF cppMs < 0 THEN cppMs = cppMs + 86400000

' =====================================================================
' Correctness: diff every pixel of the two dst buffers (both still mapped)
' =====================================================================
DIM mismatches AS LONG, firstX AS LONG, firstY AS LONG, pa AS _UNSIGNED LONG, pb AS _UNSIGNED LONG
mismatches = 0: firstX = -1: firstY = -1
FOR y = 0 TO H - 1
    FOR x = 0 TO W - 1
        _MEMGET mD, mD.OFFSET + (y * W + x) * 4, pa
        _MEMGET cD, cD.OFFSET + (y * W + x) * 4, pb
        IF pa <> pb THEN
            IF mismatches = 0 THEN firstX = x: firstY = y
            mismatches = mismatches + 1
        END IF
    NEXT x
NEXT y

_MEMFREE mS: _MEMFREE mD: _MEMFREE cS: _MEMFREE cD

PRINT "==== Box blur benchmark ("; LTRIM$(STR$(W)); "x"; LTRIM$(STR$(H)); ", radius"; RADIUS; ") ===="
PRINT USING "BASIC (-O0): ####.### ms"; basMs
PRINT USING "C++   (-O3): ####.### ms"; cppMs
IF cppMs > 0 THEN PRINT USING "Speedup    : ####.## x"; basMs / cppMs
PRINT "Pixel mismatches:"; mismatches;
IF mismatches > 0 THEN PRINT " (first at"; firstX; ","; firstY; ")" ELSE PRINT " -> outputs IDENTICAL"
SYSTEM
