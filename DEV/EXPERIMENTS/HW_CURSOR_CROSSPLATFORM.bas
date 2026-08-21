' ============================================================================
' HW_CURSOR_CROSSPLATFORM.bas
'   Cross-platform verification + mini-profile of the HARDWARE cursor
'   (_MOUSECURSOR, QB64-PE GLFW PR #701) for macOS and Windows.
'   Linux is already covered by HW_CURSOR_ZORDER_TEST.bas + HW_CURSOR_PROFILE.bas.
' ----------------------------------------------------------------------------
' TERMINOLOGY: "hardware cursor" here = the custom-image _MOUSECURSOR path
' (your own icon art placed on the OS compositor's cursor plane), distinct from
' _MOUSESHOW stock OS cursors. Both ride the same free plane; only _MOUSECURSOR
' carries custom artwork.
'
' WHAT IT PROVES / MEASURES on THIS machine, and writes to an OS-stamped log:
'   PASS/FAIL  _MOUSECURSOR sets a custom image cursor with no runtime error.
'   Z-ORDER    the cursor rides OVER a software gradient AND a hardware image
'              (_COPYIMAGE ,33) -- confirming it is composited above everything.
'   FREEZE     with the render loop frozen (no draw, no _DISPLAY) the cursor
'              still glides -> the compositor owns it; we never repaint under it.
'   PROFILE    the per-move software-cursor tax (the work the hardware cursor
'              deletes) + the ONE-TIME _MOUSECURSOR install cost, at 1280x800
'              and 1920x1080. INSTALL COST IS THE CROSS-PLATFORM UNKNOWN: on
'              Linux/GLFW it is ~16.75ms (a Wayland cursor-set sync); macOS
'              (NSCursor) and Windows (SetCursor) may be far cheaper. That number
'              decides how hard the "dedup install to icon-change only" guardrail
'              has to be on each OS.
'
' ============================ HOW TO BUILD / RUN ============================
' REQUIRES a QB64-PE GLFW (PR #701) build -- the one that knows _MOUSECURSOR and
' _UPTIME. A stock/older QB64-PE will fail to COMPILE with "Syntax error" on the
' _MOUSECURSOR line; that just means the compiler predates the keyword.
'
'   EASIEST (macOS & Windows): open this .bas in the GLFW QB64-PE IDE, press F5.
'
'   CLI macOS  :  /path/to/qb64pe-glfw/qb64pe -w -x -o HW_CURSOR_CROSSPLATFORM \
'                     DEV/EXPERIMENTS/HW_CURSOR_CROSSPLATFORM.bas
'                 ./HW_CURSOR_CROSSPLATFORM
'   CLI Windows:  \path\to\qb64pe-glfw\qb64pe.exe -w -x -o HW_CURSOR_CROSSPLATFORM ^
'                     DEV\EXPERIMENTS\HW_CURSOR_CROSSPLATFORM.bas
'                 HW_CURSOR_CROSSPLATFORM.exe
'   CLI Linux  :  ~/git/qb64pe-a740g-test/qb64pe-regen -w -x -o HW_CURSOR_CROSSPLATFORM \
'                     DEV/EXPERIMENTS/HW_CURSOR_CROSSPLATFORM.bas
'
' Results -> console AND HW_CURSOR_CROSSPLATFORM-log.txt (next to the exe).
' Send that log (+ a note whether the FREEZE test held) back for the write-up.
' ============================================================================
$CONSOLE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
CONST TRUE = -1, FALSE = 0

CONST NSIZE = 2, NOP = 6, NROUND = 21
CONST OP_RESTORE_FULL = 1, OP_RESTORE_DIRTY = 2, OP_OVL_CLS = 3
CONST OP_CURSOR_BLIT = 4, OP_OVL_COMP = 5, OP_HWINSTALL = 6

DIM SHARED gCanvas AS LONG, gCache AS LONG, gOvl AS LONG, gCursor AS LONG
DIM SHARED gCW AS LONG, gCH AS LONG
DIM SHARED gDX1 AS LONG, gDY1 AS LONG, gDX2 AS LONG, gDY2 AS LONG
DIM SHARED medUs(1 TO NSIZE, 1 TO NOP) AS DOUBLE
DIM SHARED szW(1 TO NSIZE) AS LONG, szH(1 TO NSIZE) AS LONG, szTag(1 TO NSIZE) AS STRING

szW(1) = 1280: szH(1) = 800: szTag(1) = "1280x800"
szW(2) = 1920: szH(2) = 1080: szTag(2) = "1920x1080"

CONST WINW = 920, WINH = 600
SCREEN _NEWIMAGE(WINW, WINH, 32)
_TITLE "Hardware Cursor - Cross-Platform Verify (PR #701)"
_DISPLAY

' ---- build the custom cursor (28x28: magenta diamond + yellow cross). 28px is
'      inside the Windows small-cursor clamp, so it is not silently downscaled.
gCursor = _NEWIMAGE(28, 28, 32)
DIM od AS LONG: od = _DEST
_DEST gCursor
CLS , _RGBA32(0, 0, 0, 0)
LINE (14, 1)-(27, 14), _RGB32(255, 0, 255)
LINE (27, 14)-(14, 27), _RGB32(255, 0, 255)
LINE (14, 27)-(1, 14), _RGB32(255, 0, 255)
LINE (1, 14)-(14, 1), _RGB32(255, 0, 255)
LINE (14, 6)-(14, 22), _RGB32(255, 255, 0)
LINE (6, 14)-(22, 14), _RGB32(255, 255, 0)
_DEST od

' ---- functional check: install once, no runtime error -> PASS
DIM installOK AS INTEGER: installOK = FALSE
_MOUSECURSOR gCursor, (14, 14)
installOK = TRUE ' if _MOUSECURSOR raised, we would not reach here (traps abort/RESUME)

' ---- open log
DIM fh AS INTEGER: fh = FREEFILE
OPEN "HW_CURSOR_CROSSPLATFORM-log.txt" FOR OUTPUT AS #fh
LOGLINE fh, "=== HW_CURSOR_CROSSPLATFORM ==="
LOGLINE fh, "OS      = " + _OS$
LOGLINE fh, "session = " + ENVIRON$("XDG_SESSION_TYPE") + "  (blank on macOS/Windows)"
LOGLINE fh, "clock   = _UPTIME (high-res)   rounds/op = " + _TRIM$(STR$(NROUND))
LOGLINE fh, "_MOUSECURSOR install: " + _IIF(installOK, "PASS (no runtime error)", "FAIL")
LOGLINE fh, ""

' ---- mini profile (shows progress on screen)
DIM si AS INTEGER, oi AS INTEGER
FOR si = 1 TO NSIZE
    CLS , _RGB32(18, 20, 40)
    COLOR _RGB32(180, 220, 255), 0
    _PRINTSTRING (30, 40), "Profiling " + szTag(si) + " ... (a few seconds)"
    _DISPLAY
    gCW = szW(si): gCH = szH(si)
    ALLOC_SURFACES
    gDX1 = 100: gDY1 = 100: gDX2 = 148: gDY2 = 148
    IF gDX2 > gCW - 1 THEN gDX2 = gCW - 1
    IF gDY2 > gCH - 1 THEN gDY2 = gCH - 1
    FOR oi = 1 TO NOP
        TIME_OP si, oi
    NEXT
    FREE_SURFACES
NEXT

' ---- derive tax + report
DIM taxF(1 TO NSIZE) AS DOUBLE, taxD(1 TO NSIZE) AS DOUBLE
FOR si = 1 TO NSIZE
    taxF(si) = (medUs(si, OP_RESTORE_FULL) + medUs(si, OP_OVL_CLS) + medUs(si, OP_CURSOR_BLIT) + medUs(si, OP_OVL_COMP)) / 1000#
    taxD(si) = (medUs(si, OP_RESTORE_DIRTY) + medUs(si, OP_OVL_CLS) + medUs(si, OP_CURSOR_BLIT) + medUs(si, OP_OVL_COMP)) / 1000#
NEXT
LOGLINE fh, "PER-OP MEDIAN (microseconds):"
LOGLINE fh, "  " + PADR$("op", 23) + PADR$(szTag(1), 14) + PADR$(szTag(2), 14)
REPORT_OP fh, OP_RESTORE_FULL, "restore scene (FULL)"
REPORT_OP fh, OP_RESTORE_DIRTY, "restore scene (DIRTY)"
REPORT_OP fh, OP_OVL_CLS, "overlay CLS"
REPORT_OP fh, OP_CURSOR_BLIT, "cursor sprite blit"
REPORT_OP fh, OP_OVL_COMP, "overlay composite"
REPORT_OP fh, OP_HWINSTALL, "_MOUSECURSOR install"
LOGLINE fh, ""
LOGLINE fh, "SOFTWARE-CURSOR TAX PER MOVE (hardware cursor deletes this; its bare-move cost = 0):"
FOR si = 1 TO NSIZE
    LOGLINE fh, "  " + PADR$(szTag(si), 12) + "full " + FMT3$(taxF(si)) + "ms   dirty " + FMT3$(taxD(si)) + "ms" + _
                "   | %core@60 full " + FMT1$(taxF(si) * 6#) + "%  @240 full " + FMT1$(taxF(si) * 24#) + "%"
NEXT
LOGLINE fh, ""
LOGLINE fh, "_MOUSECURSOR install cost (CROSS-PLATFORM KEY NUMBER): " + FMT3$(medUs(1, OP_HWINSTALL) / 1000#) + "ms"
LOGLINE fh, "  Linux/GLFW baseline ~16.75ms (Wayland cursor-set sync). If this OS is much"
LOGLINE fh, "  lower, the per-icon-change install is cheap here and the dedup guardrail relaxes."
CLOSE #fh

' ---- CI / headless: env HWCUR_CI set => skip the interactive visual and exit.
'      The functional PASS/FAIL + profile (above) are already in the log; the
'      z-order/freeze proof needs a human, so CI stops here.
IF LEN(ENVIRON$("HWCUR_CI")) > 0 THEN
    PRINT "HWCUR_CI set -> headless run complete, exiting."
    IF gCursor < -1 THEN _FREEIMAGE gCursor
    SYSTEM
END IF

' ---- build the hardware-image panel for the visual z-order proof
CONST PANW = 300, PANH = 200
DIM panelSrc AS LONG, hwPanel AS LONG
panelSrc = _NEWIMAGE(PANW, PANH, 32)
_DEST panelSrc
DIM bx AS INTEGER, by AS INTEGER, cc AS _UNSIGNED LONG
FOR by = 0 TO PANH - 1 STEP 20
    FOR bx = 0 TO PANW - 1 STEP 20
        IF ((bx \ 20) + (by \ 20)) MOD 2 = 0 THEN cc = _RGB32(40, 90, 160) ELSE cc = _RGB32(80, 150, 230)
        LINE (bx, by)-(bx + 19, by + 19), cc, BF
    NEXT
NEXT
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (14, 12), "HARDWARE IMAGE LAYER"
_PRINTSTRING (14, 30), "_COPYIMAGE(h, 33)"
_PRINTSTRING (14, 150), "hover the diamond here"
_DEST od
hwPanel = _COPYIMAGE(panelSrc, 33)
IF panelSrc < -1 THEN _FREEIMAGE panelSrc

' re-assert the visual cursor (profile's install loop left an arbitrary one set)
_MOUSECURSOR gCursor, (14, 14)

' ---- interactive z-order + freeze proof
DIM frozen AS INTEGER: frozen = FALSE
DIM spaceLatch AS INTEGER: spaceLatch = FALSE
DIM renders AS LONG: renders = 0
DIM frames AS LONG: frames = 0
DIM py AS INTEGER, gcol AS _UNSIGNED LONG
DO
    frames = frames + 1
    IF _KEYDOWN(32) THEN
        IF NOT spaceLatch THEN frozen = NOT frozen: spaceLatch = TRUE
    ELSE
        spaceLatch = FALSE
    END IF

    IF NOT frozen THEN
        FOR py = 0 TO WINH - 1
            gcol = _RGB32(16 + py \ 9, 20, 42 + py \ 7)
            LINE (0, py)-(WINW - 1, py), gcol
        NEXT
        COLOR _RGB32(120, 255, 160), _RGBA32(0, 0, 0, 0)
        _PRINTSTRING (30, 22), "HARDWARE CURSOR - CROSS-PLATFORM VERIFY   OS=" + _OS$
        COLOR _RGB32(230, 230, 230), _RGBA32(0, 0, 0, 0)
        _PRINTSTRING (30, 52), "_MOUSECURSOR install: " + _IIF(installOK, "PASS", "FAIL") + _
                               "   (see HW_CURSOR_CROSSPLATFORM-log.txt for numbers)"
        _PRINTSTRING (30, 74), "tax/move @1080p: full " + FMT3$(taxF(2)) + "ms  dirty " + FMT3$(taxD(2)) + "ms   -> hardware cursor = 0ms"
        _PRINTSTRING (30, 96), "_MOUSECURSOR install: " + FMT3$(medUs(1, OP_HWINSTALL) / 1000#) + "ms per icon change"
        COLOR _RGB32(255, 220, 120), _RGBA32(0, 0, 0, 0)
        _PRINTSTRING (30, 128), "The magenta DIAMOND is the hardware cursor. It must ride OVER the"
        _PRINTSTRING (30, 146), "gradient AND the checkerboard panel below."
        COLOR _RGB32(255, 150, 150), _RGBA32(0, 0, 0, 0)
        _PRINTSTRING (30, 178), "SPACE = FREEZE render loop (cursor must keep moving)   ESC = quit"
        ' hardware panel on top of the software surface (z-order seam)
        _PUTIMAGE (300, 320), hwPanel
        renders = renders + 1
        COLOR _RGB32(160, 200, 255), _RGBA32(0, 0, 0, 0)
        _PRINTSTRING (30, WINH - 40), "STATE: LIVE   renders=" + _TRIM$(STR$(renders)) + "   frames=" + _TRIM$(STR$(frames))
        _PRINTSTRING (30, WINH - 22), "mouse: " + _TRIM$(STR$(_MOUSEX)) + " , " + _TRIM$(STR$(_MOUSEY))
        _DISPLAY
    ELSE
        ' frozen: no draw, no _DISPLAY. Window shows last frame; cursor should
        ' still glide over it. renders/frames diverge -> CLAIM proven.
    END IF
    _LIMIT 60
LOOP UNTIL _KEYDOWN(27)

IF gCursor < -1 THEN _FREEIMAGE gCursor
IF hwPanel < -1 THEN _FREEIMAGE hwPanel
SYSTEM

' ============================================================================
SUB ALLOC_SURFACES
    gCanvas = _NEWIMAGE(gCW, gCH, 32)
    gCache = _NEWIMAGE(gCW, gCH, 32)
    gOvl = _NEWIMAGE(gCW, gCH, 32)
    DIM od AS LONG: od = _DEST
    _DEST gCache: CLS , _RGB32(30, 40, 60)
    DIM k AS INTEGER
    FOR k = 0 TO 40: LINE (k * (gCW \ 40), 0)-(gCW - 1, gCH - 1), _RGB32(60 + k, 90, 160 - k): NEXT
    _DEST gOvl: CLS , _RGBA32(0, 0, 0, 0)
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
            DIM oa AS LONG: oa = _DEST: _DEST gOvl
            FOR i = 1 TO iters: CLS , _RGBA32(0, 0, 0, 0): NEXT
            _DEST oa
        CASE OP_CURSOR_BLIT
            DIM ob AS LONG: ob = _DEST: _DEST gOvl
            FOR i = 1 TO iters: _PUTIMAGE (100, 100), gCursor, gOvl: NEXT
            _DEST ob
        CASE OP_OVL_COMP
            FOR i = 1 TO iters: _PUTIMAGE , gOvl, gCanvas: NEXT
        CASE OP_HWINSTALL
            FOR i = 1 TO iters: _MOUSECURSOR gCursor, (14, 14): NEXT
    END SELECT
END SUB

SUB TIME_OP (szIdx AS INTEGER, opk AS INTEGER)
    DIM t0 AS DOUBLE, t1 AS DOUBLE, perOp AS DOUBLE, itn AS LONG, r AS INTEGER
    DO_OP opk, 2
    t0 = _UPTIME: DO_OP opk, 4: t1 = _UPTIME
    perOp = (t1 - t0) / 4#
    IF perOp <= 0# THEN perOp = 0.0000001#
    itn = 0.02# / perOp
    IF itn < 3 THEN itn = 3
    IF itn > 20000 THEN itn = 20000
    DIM samp(1 TO NROUND) AS DOUBLE
    FOR r = 1 TO NROUND
        t0 = _UPTIME: DO_OP opk, itn: t1 = _UPTIME
        samp(r) = (t1 - t0) / itn * 1000000#
    NEXT
    SORT_D samp(), NROUND
    medUs(szIdx, opk) = samp((NROUND + 1) \ 2)
END SUB

SUB SORT_D (a() AS DOUBLE, n AS INTEGER)
    DIM i AS INTEGER, j AS INTEGER, v AS DOUBLE
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
    LOGLINE fh, "  " + PADR$(lbl, 23) + PADR$(FMTUS$(medUs(1, opk)), 14) + PADR$(FMTUS$(medUs(2, opk)), 14)
END SUB

FUNCTION FMTUS$ (us AS DOUBLE)
    IF us >= 1000# THEN FMTUS$ = FMT0$(us) + "us" ELSE FMTUS$ = FMT1$(us) + "us"
END FUNCTION

FUNCTION FMT0$ (x AS DOUBLE)
    FMT0$ = _TRIM$(STR$(INT(x + 0.5#)))
END FUNCTION

FUNCTION FMT1$ (x AS DOUBLE)
    DIM sc AS _INTEGER64: sc = INT(x * 10# + 0.5#)
    DIM w AS _INTEGER64, f AS _INTEGER64: w = sc \ 10: f = sc MOD 10
    FMT1$ = _TRIM$(STR$(w)) + "." + _TRIM$(STR$(f))
END FUNCTION

FUNCTION FMT3$ (x AS DOUBLE)
    DIM sc AS _INTEGER64: sc = INT(x * 1000# + 0.5#)
    DIM w AS _INTEGER64, f AS _INTEGER64: w = sc \ 1000: f = sc MOD 1000
    DIM fs AS STRING: fs = _TRIM$(STR$(f))
    DO WHILE LEN(fs) < 3: fs = "0" + fs: LOOP
    FMT3$ = _TRIM$(STR$(w)) + "." + fs
END FUNCTION

FUNCTION PADR$ (s AS STRING, n AS INTEGER)
    IF LEN(s) >= n THEN PADR$ = LEFT$(s, n) ELSE PADR$ = s + SPACE$(n - LEN(s))
END FUNCTION

SUB LOGLINE (fh AS INTEGER, s AS STRING)
    PRINT s
    PRINT #fh, s
END SUB
