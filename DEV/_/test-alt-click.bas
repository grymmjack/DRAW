OPTION _EXPLICIT
'$DYNAMIC
$CONSOLE
' =============================================================================
' test-alt-click.bas — DISPOSABLE macOS Option(Alt)+mouse-click probe
' =============================================================================
' Isolates the exact question behind DRAW's "Alt+left-click doesn't pick FG on
' macOS" bug: when you HOLD Option and click, does QB64/SDL2 give the app the
' Option modifier state AND a clean left-button press?
'
' It reports Alt via BOTH methods DRAW uses:
'   * _KEYDOWN(LALT/RALT)            — direct poll (DRAW says unreliable on macOS)
'   * _KEYHIT-tracked "MAC_ALT_HELD" — the workaround DRAW actually relies on
' and edge-detects the three mouse buttons the way DRAW does.
'
' HOW TO RUN (standalone, no DRAW deps):
'   qb64pe -x DEV/_/test-alt-click.bas -o /tmp/test-alt-click
'   /tmp/test-alt-click
' Then: hold Option, LEFT-click in the window; hold Option, RIGHT-click. Watch
' the on-screen readout AND the console lines. Compare the two CLICK lines.
'
' WHAT TO LOOK FOR on the CLICK line for a LEFT click with Option held:
'   * keydownAlt=OFF and keyhitAlt=OFF  → macOS/SDL2 never gave DRAW the Option
'                                          state (the modifier is the problem).
'   * either alt=ON but btn shows 2/3 instead of 1 → the OS remapped the button.
'   * alt=ON and btn=1 → DRAW *should* work; the bug is elsewhere in DRAW.
' Press ESC to quit.
' =============================================================================

CONST TRUE = -1
CONST FALSE = 0
CONST KEY_LALT& = 100308
CONST KEY_RALT& = 100307
CONST KEY_ESC& = 27

SCREEN _NEWIMAGE(900, 560, 32)
_TITLE "Option+Click probe — hold Option, click L/R. ESC to quit."

DIM SHARED macAltHeld AS INTEGER            ' _KEYHIT-tracked Option state
DIM b1 AS INTEGER, b2 AS INTEGER, b3 AS INTEGER
DIM ob1 AS INTEGER, ob2 AS INTEGER, ob3 AS INTEGER
DIM mb1 AS INTEGER, mb2 AS INTEGER, mb3 AS INTEGER
DIM k AS LONG, kdAlt AS INTEGER, khAlt AS INTEGER
DIM clickLog(1 TO 12) AS STRING
DIM logCount AS INTEGER, i AS INTEGER
DIM lastKeyhit AS LONG

macAltHeld = FALSE
logCount = 0

DO
    ' --- drain keyboard, track Option via _KEYHIT (mirrors DRAW MAC path) ---
    k& = _KEYHIT
    IF k& <> 0 THEN
        lastKeyhit& = k&
        IF k& = KEY_LALT& OR k& = KEY_RALT& THEN
            macAltHeld = TRUE
        ELSEIF k& = -KEY_LALT& OR k& = -KEY_RALT& THEN
            macAltHeld = FALSE
        END IF
        IF k& = KEY_ESC& THEN EXIT DO
    END IF

    ' --- drain mouse, accumulate button presses (mirrors DRAW MAC path) ---
    mb1 = FALSE: mb2 = FALSE: mb3 = FALSE
    DO WHILE _MOUSEINPUT
        IF _MOUSEBUTTON(1) THEN mb1 = TRUE
        IF _MOUSEBUTTON(2) THEN mb2 = TRUE
        IF _MOUSEBUTTON(3) THEN mb3 = TRUE
    LOOP
    b1 = mb1 OR _MOUSEBUTTON(1)
    b2 = mb2 OR _MOUSEBUTTON(2)
    b3 = mb3 OR _MOUSEBUTTON(3)

    ' --- current Alt readings, both ways ---
    kdAlt = (_KEYDOWN(KEY_LALT&) OR _KEYDOWN(KEY_RALT&))
    khAlt = macAltHeld

    ' --- on a button-DOWN edge, record a CLICK line with the alt state ---
    IF (b1 AND NOT ob1) OR (b2 AND NOT ob2) OR (b3 AND NOT ob3) THEN
        DIM which AS STRING
        which$ = ""
        IF b1 AND NOT ob1 THEN which$ = which$ + "1 "
        IF b2 AND NOT ob2 THEN which$ = which$ + "2 "
        IF b3 AND NOT ob3 THEN which$ = which$ + "3 "
        DIM logLine AS STRING
        logLine$ = "CLICK btn=" + _TRIM$(which$) + _
                "  keydownAlt=" + onoff$(kdAlt) + _
                "  keyhitAlt=" + onoff$(khAlt) + _
                "  (B1=" + yn$(b1) + " B2=" + yn$(b2) + " B3=" + yn$(b3) + ")"
        PRINT logLine$   ' to console
        ' scroll on-screen log
        IF logCount < 12 THEN logCount = logCount + 1
        FOR i = logCount TO 2 STEP -1
            clickLog(i) = clickLog(i - 1)
        NEXT i
        clickLog(1) = logLine$
    END IF

    ob1 = b1: ob2 = b2: ob3 = b3

    ' --- draw live readout ---
    CLS , _RGB32(20, 20, 28)
    COLOR _RGB32(255, 255, 255)
    _PRINTSTRING (16, 12), "Option (Alt) + mouse-click probe   —   hold Option, then click LEFT / RIGHT"
    _PRINTSTRING (16, 40), "Live Option state:"
    COLOR _IIF(kdAlt, _RGB32(80, 255, 120), _RGB32(255, 110, 110))
    _PRINTSTRING (200, 40), "_KEYDOWN(Option) = " + onoff$(kdAlt)
    COLOR _IIF(khAlt, _RGB32(80, 255, 120), _RGB32(255, 110, 110))
    _PRINTSTRING (200, 64), "_KEYHIT-tracked  = " + onoff$(khAlt)
    COLOR _RGB32(180, 180, 200)
    _PRINTSTRING (16, 96), "Live buttons: B1=" + yn$(b1) + "  B2=" + yn$(b2) + "  B3=" + yn$(b3) + "    lastKeyhit=" + _TRIM$(STR$(lastKeyhit&))
    COLOR _RGB32(255, 230, 150)
    _PRINTSTRING (16, 132), "Recent clicks (newest first):"
    COLOR _RGB32(200, 220, 255)
    FOR i = 1 TO logCount
        _PRINTSTRING (16, 132 + i * 22), clickLog(i)
    NEXT i
    COLOR _RGB32(150, 150, 160)
    _PRINTSTRING (16, 520), "Interpretation: for a LEFT click with Option held, keydownAlt/keyhitAlt should be ON and btn=1."
    _DISPLAY
    _LIMIT 60
LOOP

SYSTEM

FUNCTION onoff$ (v AS INTEGER)
    IF v THEN onoff$ = "ON " ELSE onoff$ = "OFF"
END FUNCTION

FUNCTION yn$ (v AS INTEGER)
    IF v THEN yn$ = "Y" ELSE yn$ = "n"
END FUNCTION
