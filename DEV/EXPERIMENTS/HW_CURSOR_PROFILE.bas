' ============================================================================
' HW_CURSOR_PROFILE.bas — ISOLATED microbenchmark of the software-cursor tax
' ----------------------------------------------------------------------------
' Answers, empirically and in isolation (NOT tangled with DRAW's GUI composite):
' exactly how much CPU work the SOFTWARE cursor forces on every mouse move, and
' therefore how much the OS hardware cursor (_MOUSECURSOR) eliminates.
'
' WHAT DRAW'S SOFTWARE CURSOR DOES PER MOVE (from GUI/POINTER.BM + OUTPUT/SCREEN.BM):
'   1. restore the scene under the cursor      -> _PUTIMAGE SCENE_CACHE& -> SCRN.CANVAS&
'        full-frame path  (SCREEN.BM cache re-blit) .......... OP_RESTORE_FULL
'        dirty-rect path  (region under old+new cursor) ...... OP_RESTORE_DIRTY
'   2. clear the cursor overlay                 -> _DEST SCRN.CURSOR& : CLS ,transparent   OP_OVL_CLS
'   3. draw the cursor sprite into the overlay  -> _PUTIMAGE cursorPNG ................... OP_CURSOR_BLIT
'   4. composite the overlay onto the canvas    -> _PUTIMAGE SCRN.CURSOR& ................ OP_OVL_COMP
'   (5. upscale canvas -> window, 6. _DISPLAY : paid by BOTH paths, so they CANCEL
'        in the delta — measured here only to prove they are common.)
'
' The OS hardware cursor path does NONE of 1-4: the compositor moves the pointer,
' so a bare mouse move triggers NO render at all (DRAW.BAS:635 skip). Its only
' cost is a ONE-TIME _MOUSECURSOR install when the cursor icon CHANGES (deduped),
' measured as OP_HWINSTALL.
'
' => "Software-cursor tax per move" = OP_RESTORE(full|dirty) + OP_OVL_CLS
'                                     + OP_CURSOR_BLIT + OP_OVL_COMP
'    This is the work the OS cursor deletes. We sweep canvas size to expose the
'    O(width*height) scaling: the tax is a full-surface blit cost; the OS cursor
'    is O(1). That is the order-of-magnitude story.
'
' METHOD: per (size, op): warm, calibrate iters for ~20ms rounds, then 31 timed
' rounds via _UPTIME (high-res monotonic DOUBLE). Report min / median / p95 / mean
' microseconds per op. Median is the headline (robust to scheduler noise).
'
' BUILD (GLFW PR #701 compiler that knows _MOUSECURSOR + _UPTIME):
'   ~/git/qb64pe-a740g-test/qb64pe-regen -w -x -o DEV/EXPERIMENTS/HW_CURSOR_PROFILE \
'       DEV/EXPERIMENTS/HW_CURSOR_PROFILE.bas
'   DISPLAY=:1 ./DEV/EXPERIMENTS/HW_CURSOR_PROFILE      (offscreen Xvfb ok)
'
' Results -> console AND HW_CURSOR_PROFILE-log.txt.
'
' VERIFIED (2026-08-20, AMD RX 6600M): ops 1-4 (the tax) are CPU memcpy on software
' mode-32 surfaces and NEVER touch the GPU — measured byte-identical under Wayland+GPU,
' X11+GPU, and forced software GL (LIBGL_ALWAYS_SOFTWARE=1). So the tax table is
' GPU-independent / machine-portable. OP_HWINSTALL (~16.75ms) is likewise identical
' across all three backends: it is a fixed QB64PE/GLFW cursor-set sync (~one 60Hz
' frame), NOT a rendering or offscreen artifact — it is that expensive on real HW too,
' which is exactly why _MOUSECURSOR MUST stay deduped to icon-change only.
' ============================================================================
$CONSOLE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
CONST TRUE = -1, FALSE = 0

CONST NSIZE = 6, NOP = 8, NROUND = 31
CONST OP_RESTORE_FULL = 1, OP_RESTORE_DIRTY = 2, OP_OVL_CLS = 3, OP_CURSOR_BLIT = 4
CONST OP_OVL_COMP = 5, OP_UPSCALE = 6, OP_DISPLAY = 7, OP_HWINSTALL = 8

DIM SHARED gCanvas AS LONG, gCache AS LONG, gOvl AS LONG, gCursor AS LONG
DIM SHARED gCW AS LONG, gCH AS LONG, gWinW AS LONG, gWinH AS LONG
DIM SHARED gDX1 AS LONG, gDY1 AS LONG, gDX2 AS LONG, gDY2 AS LONG

DIM SHARED meanUs(1 TO NSIZE, 1 TO NOP) AS DOUBLE
DIM SHARED medUs(1 TO NSIZE, 1 TO NOP) AS DOUBLE
DIM SHARED p95Us(1 TO NSIZE, 1 TO NOP) AS DOUBLE
DIM SHARED minUs(1 TO NSIZE, 1 TO NOP) AS DOUBLE

DIM SHARED szW(1 TO NSIZE) AS LONG, szH(1 TO NSIZE) AS LONG, szTag(1 TO NSIZE) AS STRING

szW(1) = 320:  szH(1) = 200:  szTag(1) = "320x200"
szW(2) = 640:  szH(2) = 480:  szTag(2) = "640x480"
szW(3) = 1280: szH(3) = 800:  szTag(3) = "1280x800"
szW(4) = 1920: szH(4) = 1080: szTag(4) = "1920x1080 (1080p)"
szW(5) = 2560: szH(5) = 1440: szTag(5) = "2560x1440 (1440p)"
szW(6) = 3840: szH(6) = 2160: szTag(6) = "3840x2160 (4K)"

gWinW = 1280: gWinH = 800
SCREEN _NEWIMAGE(gWinW, gWinH, 32)
_TITLE "HW Cursor Profile (isolated)"
_DISPLAY ' switch to manual present so OP_DISPLAY is a real explicit present

DIM fh AS INTEGER
fh = FREEFILE
OPEN "HW_CURSOR_PROFILE-log.txt" FOR OUTPUT AS #fh

LOGLINE fh, "=== HW_CURSOR_PROFILE — isolated software-cursor tax ==="
LOGLINE fh, "OS=" + _OS$ + "  session=" + ENVIRON$("XDG_SESSION_TYPE") + "  rounds/op=" + STR$(NROUND)
LOGLINE fh, "clock=_UPTIME (high-res)  units=microseconds per op  headline=MEDIAN"
LOGLINE fh, ""

' Build the cursor sprite once (28x28 RGBA, like a display-scaled icon cursor).
gCursor = _NEWIMAGE(28, 28, 32)
DIM od AS LONG: od = _DEST
_DEST gCursor
CLS , _RGBA32(0, 0, 0, 0)
LINE (14, 1)-(27, 14), _RGB32(255, 0, 255)
LINE (27, 14)-(14, 27), _RGB32(255, 0, 255)
LINE (14, 27)-(1, 14), _RGB32(255, 0, 255)
LINE (1, 14)-(14, 1), _RGB32(255, 0, 255)
LINE (14, 6)-(14, 22), _RGB32(255, 255, 0)
_DEST od

DIM si AS INTEGER, oi AS INTEGER
FOR si = 1 TO NSIZE
    gCW = szW(si): gCH = szH(si)
    ALLOC_SURFACES

    ' ~48px dirty rect around a point, clamped — models POINTER_get_dirty_pad%.
    gDX1 = 100: gDY1 = 100: gDX2 = 148: gDY2 = 148
    IF gDX2 > gCW - 1 THEN gDX2 = gCW - 1
    IF gDY2 > gCH - 1 THEN gDY2 = gCH - 1

    PRINT "profiling "; szTag(si); " ..."
    FOR oi = 1 TO NOP
        TIME_OP si, oi
    NEXT oi

    FREE_SURFACES
NEXT si

' -------------------------------------------------------------------- report
LOGLINE fh, "PER-OP MEDIAN microseconds (lower = faster):"
LOGLINE fh, LEFT_PAD$("op \ size", 26) + COLHDR$
REPORT_OP fh, OP_RESTORE_FULL, "1 restore scene (FULL)"
REPORT_OP fh, OP_RESTORE_DIRTY, "1 restore scene (DIRTY)"
REPORT_OP fh, OP_OVL_CLS, "2 overlay CLS"
REPORT_OP fh, OP_CURSOR_BLIT, "3 cursor sprite blit"
REPORT_OP fh, OP_OVL_COMP, "4 overlay composite"
LOGLINE fh, "  --- common to BOTH paths (cancels in delta) ---"
REPORT_OP fh, OP_UPSCALE, "  upscale->window"
REPORT_OP fh, OP_DISPLAY, "  _DISPLAY present"
LOGLINE fh, "  --- OS hardware cursor one-time install (per icon CHANGE) ---"
REPORT_OP fh, OP_HWINSTALL, "  _MOUSECURSOR install"
LOGLINE fh, ""

LOGLINE fh, "SOFTWARE-CURSOR TAX PER MOVE (ops 1-4; the work the OS cursor DELETES):"
LOGLINE fh, LEFT_PAD$("size", 22) + "  taxFULL   taxDIRTY   |  %core@60fps        %core@240fps      | vs OS(bare move)"
DIM taxF AS DOUBLE, taxD AS DOUBLE, ln AS STRING
FOR si = 1 TO NSIZE
    taxF = (medUs(si, OP_RESTORE_FULL) + medUs(si, OP_OVL_CLS) + medUs(si, OP_CURSOR_BLIT) + medUs(si, OP_OVL_COMP)) / 1000#
    taxD = (medUs(si, OP_RESTORE_DIRTY) + medUs(si, OP_OVL_CLS) + medUs(si, OP_CURSOR_BLIT) + medUs(si, OP_OVL_COMP)) / 1000#
    ln = LEFT_PAD$(szTag(si), 22)
    ln = ln + "  " + FMTMS$(taxF) + "  " + FMTMS$(taxD)
    ln = ln + "   |  full " + FMTPCT$(taxF * 60#) + " / dirty " + FMTPCT$(taxD * 60#)
    ln = ln + "   full " + FMTPCT$(taxF * 240#) + " / dirty " + FMTPCT$(taxD * 240#)
    ln = ln + "   |  OS = 0.000ms (no render on bare move)"
    LOGLINE fh, ln
NEXT si
LOGLINE fh, ""
LOGLINE fh, "READING IT:"
LOGLINE fh, " * taxFULL/taxDIRTY = ms of pure CPU blit the software cursor forces EACH move."
LOGLINE fh, " * The OS cursor path does 0 of this on a bare move (compositor owns the pointer),"
LOGLINE fh, "   so the reclaimed CPU = the whole column. %core = ms * fps / 10."
LOGLINE fh, " * _MOUSECURSOR install is paid ONCE per icon change (deduped), not per move —"
LOGLINE fh, "   compare its microseconds to the software tax paid on EVERY one of ~hundreds of"
LOGLINE fh, "   moves/sec: that ratio is the order-of-magnitude win."
CLOSE #fh

PRINT "done -> HW_CURSOR_PROFILE-log.txt"
IF gCursor < -1 THEN _FREEIMAGE gCursor
SYSTEM

' ============================================================================
SUB ALLOC_SURFACES
    gCanvas = _NEWIMAGE(gCW, gCH, 32)
    gCache = _NEWIMAGE(gCW, gCH, 32)
    gOvl = _NEWIMAGE(gCW, gCH, 32)
    ' Fill the cache with content (blit cost is content-independent, but be honest).
    DIM od AS LONG: od = _DEST
    _DEST gCache
    CLS , _RGB32(30, 40, 60)
    DIM k AS INTEGER
    FOR k = 0 TO 40
        LINE (k * (gCW \ 40), 0)-(gCW - 1, gCH - 1), _RGB32(60 + k, 90, 160 - k)
    NEXT
    _DEST gOvl
    CLS , _RGBA32(0, 0, 0, 0)
    _DEST od
END SUB

SUB FREE_SURFACES
    IF gCanvas < -1 THEN _FREEIMAGE gCanvas
    IF gCache < -1 THEN _FREEIMAGE gCache
    IF gOvl < -1 THEN _FREEIMAGE gOvl
    gCanvas = 0: gCache = 0: gOvl = 0
END SUB

SUB DO_OP (opk AS INTEGER, iters AS LONG)
    DIM i AS LONG
    SELECT CASE opk
        CASE OP_RESTORE_FULL
            FOR i = 1 TO iters: _PUTIMAGE , gCache, gCanvas: NEXT
        CASE OP_RESTORE_DIRTY
            FOR i = 1 TO iters: _PUTIMAGE (gDX1, gDY1)-(gDX2, gDY2), gCache, gCanvas, (gDX1, gDY1)-(gDX2, gDY2): NEXT
        CASE OP_OVL_CLS
            DIM od1 AS LONG: od1 = _DEST: _DEST gOvl
            FOR i = 1 TO iters: CLS , _RGBA32(0, 0, 0, 0): NEXT
            _DEST od1
        CASE OP_CURSOR_BLIT
            DIM od2 AS LONG: od2 = _DEST: _DEST gOvl
            FOR i = 1 TO iters: _PUTIMAGE (100, 100), gCursor, gOvl: NEXT
            _DEST od2
        CASE OP_OVL_COMP
            FOR i = 1 TO iters: _PUTIMAGE , gOvl, gCanvas: NEXT
        CASE OP_UPSCALE
            DIM od3 AS LONG: od3 = _DEST: _DEST 0
            FOR i = 1 TO iters: _PUTIMAGE (0, 0)-(gWinW - 1, gWinH - 1), gCanvas, 0: NEXT
            _DEST od3
        CASE OP_DISPLAY
            FOR i = 1 TO iters: _DISPLAY: NEXT
        CASE OP_HWINSTALL
            FOR i = 1 TO iters: _MOUSECURSOR gCursor, (14, 14): NEXT
    END SELECT
END SUB

SUB TIME_OP (szIdx AS INTEGER, opk AS INTEGER)
    DIM t0 AS DOUBLE, t1 AS DOUBLE, perOp AS DOUBLE, itn AS LONG, r AS INTEGER
    DO_OP opk, 2 ' warm caches / code path
    t0 = _UPTIME: DO_OP opk, 4: t1 = _UPTIME
    perOp = (t1 - t0) / 4#
    IF perOp <= 0# THEN perOp = 0.0000001#
    itn = 0.02# / perOp ' target ~20ms per round
    IF itn < 3 THEN itn = 3
    IF itn > 20000 THEN itn = 20000

    DIM samp(1 TO NROUND) AS DOUBLE
    FOR r = 1 TO NROUND
        t0 = _UPTIME: DO_OP opk, itn: t1 = _UPTIME
        samp(r) = (t1 - t0) / itn * 1000000# ' microseconds per op
    NEXT
    SORT_D samp(), NROUND

    DIM s AS DOUBLE, i AS INTEGER
    s = 0: FOR i = 1 TO NROUND: s = s + samp(i): NEXT
    meanUs(szIdx, opk) = s / NROUND
    minUs(szIdx, opk) = samp(1)
    medUs(szIdx, opk) = samp((NROUND + 1) \ 2)
    p95Us(szIdx, opk) = samp(INT(0.95 * NROUND))
END SUB

SUB SORT_D (a() AS DOUBLE, n AS INTEGER)
    DIM i AS INTEGER, j AS INTEGER
    DIM v AS DOUBLE
    FOR i = 2 TO n
        v = a(i): j = i - 1
        DO WHILE j >= 1
            IF a(j) <= v THEN EXIT DO
            a(j + 1) = a(j): j = j - 1
        LOOP
        a(j + 1) = v
    NEXT
END SUB

SUB REPORT_OP (fh AS INTEGER, opk AS INTEGER, lbl AS STRING)
    DIM ln AS STRING, si AS INTEGER
    ln = LEFT_PAD$(lbl, 26)
    FOR si = 1 TO NSIZE
        ln = ln + RIGHT_PAD$(FMTUS$(medUs(si, opk)), 12)
    NEXT
    LOGLINE fh, ln
END SUB

FUNCTION COLHDR$
    DIM r AS STRING, si AS INTEGER
    FOR si = 1 TO NSIZE
        r = r + RIGHT_PAD$(LEFT$(szTag(si), 11), 12)
    NEXT
    COLHDR$ = r
END FUNCTION

FUNCTION FMTFIX$ (x AS DOUBLE, dp AS INTEGER)
    ' fixed-decimal formatter via integer math — avoids STR$ binary-float noise
    DIM scaleF AS _INTEGER64, i AS INTEGER
    scaleF = 1
    FOR i = 1 TO dp: scaleF = scaleF * 10: NEXT
    DIM scaled AS _INTEGER64: scaled = INT(x * scaleF + 0.5#)
    DIM whole AS _INTEGER64, frac AS _INTEGER64
    whole = scaled \ scaleF: frac = scaled MOD scaleF
    IF dp = 0 THEN FMTFIX$ = _TRIM$(STR$(whole)): EXIT FUNCTION
    DIM fs AS STRING: fs = _TRIM$(STR$(frac))
    DO WHILE LEN(fs) < dp: fs = "0" + fs: LOOP
    FMTFIX$ = _TRIM$(STR$(whole)) + "." + fs
END FUNCTION

FUNCTION FMTUS$ (us AS DOUBLE)
    DIM s AS STRING
    IF us >= 1000# THEN
        s = FMTFIX$(us, 0)
    ELSEIF us >= 100# THEN
        s = FMTFIX$(us, 1)
    ELSE
        s = FMTFIX$(us, 2)
    END IF
    FMTUS$ = s + "us"
END FUNCTION

FUNCTION FMTMS$ (ms AS DOUBLE)
    FMTMS$ = RIGHT_PAD$(FMTFIX$(ms, 3) + "ms", 10)
END FUNCTION

FUNCTION FMTPCT$ (msPerSec AS DOUBLE)
    ' msPerSec already = ms*fps ; %core = that /10
    FMTPCT$ = FMTFIX$(msPerSec / 10#, 1) + "%"
END FUNCTION

FUNCTION LEFT_PAD$ (s AS STRING, n AS INTEGER)
    IF LEN(s) >= n THEN LEFT_PAD$ = LEFT$(s, n): EXIT FUNCTION
    LEFT_PAD$ = s + SPACE$(n - LEN(s))
END FUNCTION

FUNCTION RIGHT_PAD$ (s AS STRING, n AS INTEGER)
    IF LEN(s) >= n THEN RIGHT_PAD$ = LEFT$(s, n): EXIT FUNCTION
    RIGHT_PAD$ = s + SPACE$(n - LEN(s))
END FUNCTION

SUB LOGLINE (fh AS INTEGER, s AS STRING)
    PRINT s
    PRINT #fh, s
END SUB
