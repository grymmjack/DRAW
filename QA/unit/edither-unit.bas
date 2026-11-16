' =============================================================================
' QA/unit/edither-unit.bas - headless unit test for the error-diffusion dithers
' in GUI/IMGADJ.BM (Posterize's FS / JJN / Stucki / ... / Shiau-Fan). Build + run:
'   ~/git/qb64pe/qb64pe -w -x -o edither-unit.run edither-unit.bas && ./edither-unit.run
' Exit code 0 = all pass.
'
' The bug (2026-11-15): Fan, Stevenson-Arce, Two-Row Sierra and Shiau-Fan all
' fell back to Floyd-Steinberg; JJN / Stucki / Sierra lost their third row;
' False FS was grayscale black and white.
' =============================================================================
$CONSOLE:ONLY
OPTION _EXPLICIT
CONST TRUE = -1, FALSE = 0
'$INCLUDE:'../../GUI/IMGADJ.BI'
DIM SHARED FAILS AS INTEGER, PASSES AS INTEGER
DIM nm(0 TO 11) AS STRING
nm(0) = "FS": nm(1) = "JJN": nm(2) = "Stucki": nm(3) = "Burkes": nm(4) = "Sierra": nm(5) = "Sierra Lite"
nm(6) = "Atkinson": nm(7) = "False FS": nm(8) = "Fan": nm(9) = "Stevenson-Arce": nm(10) = "Two-Row Sierra": nm(11) = "Shiau-Fan"
DIM tdx(0 TO 11) AS INTEGER, tdy(0 TO 11) AS INTEGER, tw(0 TO 11) AS SINGLE, n AS INTEGER
DIM ntaps(0 TO 11) AS INTEGER
ntaps(0) = 4: ntaps(1) = 12: ntaps(2) = 12: ntaps(3) = 7: ntaps(4) = 10: ntaps(5) = 3
ntaps(6) = 6: ntaps(7) = 3: ntaps(8) = 4: ntaps(9) = 12: ntaps(10) = 7: ntaps(11) = 5
DIM AS INTEGER k, t, ok, x, y
DIM sm AS SINGLE
DIM AS LONG src, res, d, white, o
DIM sig(0 TO 11) AS STRING

FOR k = 0 TO 11
    GJ_IMGADJ_EDKernel k, tdx(), tdy(), tw(), n
    check n = ntaps(k), nm(k) + ":" + STR$(n) + " taps (want" + STR$(ntaps(k)) + ")"
    sm = 0: ok = TRUE
    FOR t = 0 TO n - 1
        sm = sm + tw(t)
        IF tdy(t) < 0 _ORELSE tdy(t) > 3 _ORELSE (tdy(t) = 0 _ANDALSO tdx(t) <= 0) THEN ok = FALSE
    NEXT t
    check ok, nm(k) + ": every tap is a pixel not yet visited"
    IF k = 6 THEN
        check ABS(sm - .75) < .001, nm(k) + ": spreads 6/8 of the error"
    ELSE
        check ABS(sm - 1) < .001, nm(k) + ": weights sum to 1 (got" + STR$(sm) + ")"
    END IF
NEXT k

' a flat 50% gray to 2 levels comes out about half white, and each kernel
' makes its own pattern (none silently falls back to another)
src = _NEWIMAGE(64, 64, 32)
d = _DEST: _DEST src: CLS , _RGBA32(128, 128, 128, 200): _DEST d
GJ_IMGADJ_DITHER_LEVELS = 2
FOR k = 0 TO 11
    res = GJ_IMGADJ_ApplyErrorDiffusion(src, k, 1)
    white = 0: sig(k) = ""
    _SOURCE res
    FOR y = 0 TO 63
        FOR x = 0 TO 63
            o = POINT(x, y)
            IF _RED32(o) = 255 THEN white = white + 1
            IF _ALPHA32(o) <> 200 THEN ok = FALSE
            IF y < 16 _ANDALSO x < 16 THEN sig(k) = sig(k) + CHR$(48 - (_RED32(o) = 255))
        NEXT x
    NEXT y
    _SOURCE 0
    check white > 64 * 64 * .40 _ANDALSO white < 64 * 64 * .60, nm(k) + ": 50% gray is about half white (" + STR$(white) + " of 4096)"
    _FREEIMAGE res
NEXT k
' a ramp (a flat 50% makes a checkerboard under every kernel)
d = _DEST: _DEST src
FOR x = 0 TO 63: LINE (x, 0)-(x, 63), _RGB32(x * 4, x * 4, x * 4): NEXT x
_DEST d
FOR k = 0 TO 11
    res = GJ_IMGADJ_ApplyErrorDiffusion(src, k, 1)
    sig(k) = "": _SOURCE res
    FOR y = 0 TO 31: FOR x = 0 TO 63: sig(k) = sig(k) + CHR$(48 - (_RED32(POINT(x, y)) = 255)): NEXT x, y
    _SOURCE 0: _FREEIMAGE res
NEXT k
FOR k = 0 TO 11
    FOR t = k + 1 TO 11
        check sig(k) <> sig(t), nm(k) + " and " + nm(t) + ": different patterns"
    NEXT t
NEXT k
' colour stays colour: pure red at 2 levels never turns gray
d = _DEST: _DEST src: CLS , _RGB32(200, 0, 0): _DEST d
res = GJ_IMGADJ_ApplyErrorDiffusion(src, 7, 1)
_SOURCE res: o = POINT(5, 5): _SOURCE 0
check _GREEN32(o) = 0 _ANDALSO _BLUE32(o) = 0, "False FS keeps colour (red stays red)"
_FREEIMAGE res

PRINT "edither-unit:"; PASSES; "passed,"; FAILS; "failed"
IF FAILS THEN SYSTEM 1 ELSE SYSTEM 0

SUB check (ok AS INTEGER, what AS STRING)
    IF ok THEN
        PASSES = PASSES + 1
    ELSE
        FAILS = FAILS + 1
        PRINT "FAIL: "; what
    END IF
END SUB

'$INCLUDE:'../../GUI/IMGADJ.BM'

SUB SAFE_FREEIMAGE (handle AS LONG)
    IF handle < -1 THEN _FREEIMAGE handle
    handle = 0
END SUB
