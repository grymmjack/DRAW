OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' =============================================================================
' test-alt-keys.bas — Comprehensive Keyboard Tester for QB64-PE
' =============================================================================
' Tests ALL key detection methods used in DRAW:
'   - _KEYHIT (press/release events)
'   - _KEYDOWN (polled state)
'   - Modifier tracking (Ctrl, Shift, Alt — left/right)
'   - Function keys F1-F12
'   - Navigation keys (arrows, PgUp/PgDn, Home/End, Ins/Del)
'   - Numpad keys (with/without NumLock)
'   - Letter/number/symbol keys
'   - Multi-modifier combos (Ctrl+Shift, Ctrl+Alt, Shift+Alt, Ctrl+Shift+Alt)
'   - macOS Alt/Option key workaround via _KEYHIT tracking
'   - Held-key repeat detection
'   - Tab key between pages
'
' @author Rick Christy <grymmjack@gmail.com>
' =============================================================================

' ---- Screen setup ----
CONST TRUE = -1
CONST FALSE = 0
CONST SCREEN_W& = 1024
CONST SCREEN_H& = 720
SCREEN _NEWIMAGE(SCREEN_W&, SCREEN_H&, 32)
_TITLE "QB64-PE Keyboard Tester (Tab=next page, Ctrl+Q=quit)"

' ---- Modifier physical key codes ----
CONST KEY_LSHIFT& = 100304
CONST KEY_RSHIFT& = 100303
CONST KEY_LCTRL& = 100306  ' Note: SDL2 swaps L/R ctrl codes vs docs
CONST KEY_RCTRL& = 100305
CONST KEY_LALT& = 100308
CONST KEY_RALT& = 100307
CONST KEY_CAPSLOCK& = 100301
CONST KEY_NUMLOCK& = 100300
CONST KEY_SCROLLLOCK& = 100302

' ---- Function key codes ----
CONST KEY_F1& = 15104
CONST KEY_F2& = 15360
CONST KEY_F3& = 15616
CONST KEY_F4& = 15872
CONST KEY_F5& = 16128
CONST KEY_F6& = 16384
CONST KEY_F7& = 16640
CONST KEY_F8& = 16896
CONST KEY_F9& = 17152
CONST KEY_F10& = 17408
CONST KEY_F11& = 17664
CONST KEY_F12& = 17920

' ---- Navigation key codes ----
CONST KEY_UP& = 18432
CONST KEY_DOWN& = 20480
CONST KEY_LEFT& = 19200
CONST KEY_RIGHT& = 19712
CONST KEY_PGUP& = 18688
CONST KEY_PGDN& = 20736
CONST KEY_HOME& = 18176
CONST KEY_ENDK& = 20224
CONST KEY_INSERT& = 20992
CONST KEY_DELETE& = 21248

' ---- Common ASCII ----
CONST KEY_ESC& = 27
CONST KEY_ENTER& = 13
CONST KEY_TAB& = 9
CONST KEY_BACKSPACE& = 8
CONST KEY_SPACE& = 32

' ---- Numpad codes (when NumLock ON these produce ASCII; when OFF, nav codes) ----
' SDL2 numpad scancodes for _KEYDOWN
CONST KP_0& = 100256
CONST KP_1& = 100257
CONST KP_2& = 100258
CONST KP_3& = 100259
CONST KP_4& = 100260
CONST KP_5& = 100261
CONST KP_6& = 100262
CONST KP_7& = 100263
CONST KP_8& = 100264
CONST KP_9& = 100265
CONST KP_PERIOD& = 100266
CONST KP_DIVIDE& = 100267
CONST KP_MULTIPLY& = 100268
CONST KP_MINUS& = 100269
CONST KP_PLUS& = 100270
CONST KP_ENTER& = 100271

' ---- Colors (initialized at runtime via _RGB32) ----
DIM SHARED C_BG AS _UNSIGNED LONG
DIM SHARED C_WHITE AS _UNSIGNED LONG
DIM SHARED C_GRAY AS _UNSIGNED LONG
DIM SHARED C_DIMM AS _UNSIGNED LONG
DIM SHARED C_GREEN AS _UNSIGNED LONG
DIM SHARED C_RED AS _UNSIGNED LONG
DIM SHARED C_YELLOW AS _UNSIGNED LONG
DIM SHARED C_CYAN AS _UNSIGNED LONG
DIM SHARED C_ORANGE AS _UNSIGNED LONG
DIM SHARED C_BLUE AS _UNSIGNED LONG
DIM SHARED C_MAGENTA AS _UNSIGNED LONG
DIM SHARED C_HEADER AS _UNSIGNED LONG

C_BG~& = _RGB32(30, 30, 30)
C_WHITE~& = _RGB32(255, 255, 255)
C_GRAY~& = _RGB32(153, 153, 153)
C_DIMM~& = _RGB32(102, 102, 102)
C_GREEN~& = _RGB32(0, 255, 0)
C_RED~& = _RGB32(255, 80, 80)
C_YELLOW~& = _RGB32(255, 255, 102)
C_CYAN~& = _RGB32(102, 255, 255)
C_ORANGE~& = _RGB32(255, 160, 64)
C_BLUE~& = _RGB32(102, 153, 255)
C_MAGENTA~& = _RGB32(255, 102, 255)
C_HEADER~& = _RGB32(255, 204, 0)

' ---- Log constants ----
CONST LOG_MAX& = 28  ' visible log lines
CONST LOG_TOTAL& = 256 ' ring buffer size
CONST NUM_PAGES& = 3

' ---- State ----
DIM k AS LONG
DIM currentPage AS INTEGER: currentPage% = 1
DIM frameCount AS LONG: frameCount& = 0

' Modifier state
DIM ctrl AS INTEGER, shift AS INTEGER, alt AS INTEGER
DIM lctrl AS INTEGER, rctrl AS INTEGER
DIM lshift AS INTEGER, rshift AS INTEGER
DIM lalt AS INTEGER, ralt AS INTEGER
DIM capsLock AS INTEGER, numLock AS INTEGER, scrollLock AS INTEGER

' Modifier combo precomputes (matches DRAW MODIFIERS_OBJ)
DIM ctrlOnly AS INTEGER, shiftOnly AS INTEGER, altOnly AS INTEGER
DIM ctrlShift AS INTEGER, ctrlAlt AS INTEGER, shiftAlt AS INTEGER
DIM ctrlShiftAlt AS INTEGER, modNone AS INTEGER

' macOS Alt tracking via _KEYHIT (same as DRAW's MODIFIERS_track_alt_keyhit)
DIM macAltHeld AS INTEGER: macAltHeld% = FALSE

' _KEYHIT event log (ring buffer)
DIM logLines(LOG_TOTAL& - 1) AS STRING
DIM logColors(LOG_TOTAL& - 1) AS _UNSIGNED LONG
DIM logHead AS LONG: logHead& = 0
DIM logCount AS LONG: logCount& = 0

' Held-key tracking for all testable keys
CONST TRACK_MAX& = 120
DIM trackName(TRACK_MAX& - 1) AS STRING
DIM trackCode(TRACK_MAX& - 1) AS LONG
DIM trackDown(TRACK_MAX& - 1) AS INTEGER
DIM trackHeldFrames(TRACK_MAX& - 1) AS LONG
DIM trackLastDetected(TRACK_MAX& - 1) AS DOUBLE
DIM trackCount AS INTEGER: trackCount% = 0

' Combo test results
CONST COMBO_MAX& = 30
DIM comboName(COMBO_MAX& - 1) AS STRING
DIM comboActive(COMBO_MAX& - 1) AS INTEGER
DIM comboLastDetected(COMBO_MAX& - 1) AS DOUBLE
DIM comboCount AS INTEGER: comboCount% = 0

' Tab key debounce
DIM tabPressed AS INTEGER: tabPressed% = FALSE

' ---- Initialize tracked keys ----
SUB_trackInit

' ---- Initialize combo tests ----
SUB_comboInit

' ===== MAIN LOOP =====
DO
    frameCount& = frameCount& + 1

    ' ---- Capture _KEYHIT events ----
    DO
        k& = _KEYHIT
        IF k& = 0 THEN EXIT DO

        ' macOS Alt/Option key tracking via _KEYHIT
        IF k& = KEY_LALT& OR k& = KEY_RALT& THEN macAltHeld% = TRUE
        IF k& = -KEY_LALT& OR k& = -KEY_RALT& THEN macAltHeld% = FALSE

        ' Quit: Ctrl+Q
        IF k& = 17 THEN SYSTEM ' Ctrl+Q = ASCII 17

        ' Tab to switch pages (debounced)
        IF k& = KEY_TAB& THEN
            IF NOT tabPressed% THEN
                currentPage% = currentPage% + 1
                IF currentPage% > NUM_PAGES& THEN currentPage% = 1
                tabPressed% = TRUE
            END IF
        END IF
        IF k& = -KEY_TAB& THEN tabPressed% = FALSE

        ' Log the event
        DIM logStr AS STRING
        DIM logClr AS _UNSIGNED LONG
        IF k& > 0 THEN
            ' Key press
            logClr~& = C_GREEN~&
            logStr$ = "PRESS   k=" + LPAD$(LTRIM$(STR$(k&)), 8) + "  "
            IF k& > 0 AND k& < 127 THEN
                IF k& >= 32 THEN
                    logStr$ = logStr$ + "chr=" + CHR$(34) + CHR$(k&) + CHR$(34) + " (ASCII " + LTRIM$(STR$(k&)) + ")"
                ELSE
                    logStr$ = logStr$ + "ctrl-chr (ASCII " + LTRIM$(STR$(k&)) + ")"
                END IF
            ELSEIF k& >= 256 AND k& < 65536 THEN
                logStr$ = logStr$ + "unicode U+" + HEX$(k&)
            ELSE
                logStr$ = logStr$ + KEYNAME$(k&)
            END IF
        ELSEIF k& < 0 THEN
            ' Key release
            logClr~& = C_RED~&
            DIM absK AS LONG: absK& = ABS(k&)
            logStr$ = "RELEASE k=" + LPAD$(LTRIM$(STR$(absK&)), 8) + "  "
            IF absK& > 0 AND absK& < 127 THEN
                IF absK& >= 32 THEN
                    logStr$ = logStr$ + "chr=" + CHR$(34) + CHR$(absK&) + CHR$(34)
                ELSE
                    logStr$ = logStr$ + "ctrl-chr (ASCII " + LTRIM$(STR$(absK&)) + ")"
                END IF
            ELSEIF absK& >= 256 AND absK& < 65536 THEN
                logStr$ = logStr$ + "unicode U+" + HEX$(absK&)
            ELSE
                logStr$ = logStr$ + KEYNAME$(absK&)
            END IF
        END IF

        ' Add modifier context
        IF ctrl% OR shift% OR alt% THEN
            logStr$ = logStr$ + "  ["
            IF ctrl% THEN logStr$ = logStr$ + "Ctrl+"
            IF shift% THEN logStr$ = logStr$ + "Shift+"
            IF alt% THEN logStr$ = logStr$ + "Alt+"
            ' Trim trailing +
            logStr$ = LEFT$(logStr$, LEN(logStr$) - 1)
            logStr$ = logStr$ + "]"
        END IF

        logLines$(logHead&) = logStr$
        logColors~&(logHead&) = logClr~&
        logHead& = (logHead& + 1) MOD LOG_TOTAL&
        IF logCount& < LOG_TOTAL& THEN logCount& = logCount& + 1
    LOOP

    ' ---- Poll modifier keys via _KEYDOWN ----
    lctrl% = _KEYDOWN(KEY_LCTRL&)
    rctrl% = _KEYDOWN(KEY_RCTRL&)
    ctrl% = lctrl% OR rctrl%
    lshift% = _KEYDOWN(KEY_LSHIFT&)
    rshift% = _KEYDOWN(KEY_RSHIFT&)
    shift% = lshift% OR rshift%
    lalt% = _KEYDOWN(KEY_LALT&)
    ralt% = _KEYDOWN(KEY_RALT&)
    alt% = lalt% OR ralt%
    capsLock% = _KEYDOWN(KEY_CAPSLOCK&)
    numLock% = _KEYDOWN(KEY_NUMLOCK&)
    scrollLock% = _KEYDOWN(KEY_SCROLLLOCK&)

    ' Precompute combo states (same as DRAW's MODIFIERS_update)
    ctrlOnly% = (ctrl% AND NOT shift% AND NOT alt%)
    shiftOnly% = (shift% AND NOT ctrl% AND NOT alt%)
    altOnly% = (alt% AND NOT ctrl% AND NOT shift%)
    ctrlShift% = (ctrl% AND shift% AND NOT alt%)
    ctrlAlt% = (ctrl% AND alt% AND NOT shift%)
    shiftAlt% = (shift% AND alt% AND NOT ctrl%)
    ctrlShiftAlt% = (ctrl% AND shift% AND alt%)
    modNone% = (NOT ctrl% AND NOT shift% AND NOT alt%)

    ' ---- Update tracked key states ----
    DIM ti AS INTEGER
    FOR ti% = 0 TO trackCount% - 1
        DIM isDown AS INTEGER
        isDown% = _KEYDOWN(trackCode&(ti%))
        IF isDown% THEN
            trackDown%(ti%) = TRUE
            trackHeldFrames&(ti%) = trackHeldFrames&(ti%) + 1
            trackLastDetected#(ti%) = TIMER(.001)
        ELSE
            trackDown%(ti%) = FALSE
            trackHeldFrames&(ti%) = 0
        END IF
    NEXT ti%

    ' ---- Update combo test results ----
    DIM ci AS INTEGER
    DIM now AS DOUBLE: now# = TIMER(.001)
    FOR ci% = 0 TO comboCount% - 1
        comboActive%(ci%) = FALSE
    NEXT ci%
    ' Check combos dynamically
    SUB_comboUpdate

    ' ---- RENDER ----
    CLS , C_BG~&
    COLOR C_WHITE~&, _RGBA32(0, 0, 0, 0)

    ' Header bar
    LINE (0, 0)-(SCREEN_W& - 1, 22), &HFF333333, BF
    COLOR C_HEADER~&
    _PRINTSTRING (8, 4), "QB64-PE KEYBOARD TESTER"
    COLOR C_GRAY~&
    _PRINTSTRING (250, 4), "Page " + LTRIM$(STR$(currentPage%)) + "/" + LTRIM$(STR$(NUM_PAGES&)) + " [Tab=next]  [Ctrl+Q=quit]  Frame:" + STR$(frameCount&)

    ' ---- Always show: Modifier indicator bar ----
    DIM modY AS INTEGER: modY% = 28
    LINE (0, modY%)-(SCREEN_W& - 1, modY% + 52), &HFF282828, BF
    COLOR C_WHITE~&
    _PRINTSTRING (8, modY% + 2), "MODIFIERS"

    ' Individual modifier L/R indicators
    DIM mx AS INTEGER: mx% = 120
    CALL drawModBox(mx%, modY% + 2, "L-Ctrl", lctrl%)
    CALL drawModBox(mx% + 72, modY% + 2, "R-Ctrl", rctrl%)
    CALL drawModBox(mx% + 144, modY% + 2, "L-Shift", lshift%)
    CALL drawModBox(mx% + 222, modY% + 2, "R-Shift", rshift%)
    CALL drawModBox(mx% + 300, modY% + 2, "L-Alt", lalt%)
    CALL drawModBox(mx% + 368, modY% + 2, "R-Alt", ralt%)
    CALL drawModBox(mx% + 436, modY% + 2, "CapsLk", capsLock%)
    CALL drawModBox(mx% + 510, modY% + 2, "NumLk", numLock%)
    CALL drawModBox(mx% + 578, modY% + 2, "ScrLk", scrollLock%)

    ' Combo indicators
    DIM cy AS INTEGER: cy% = modY% + 22
    CALL drawModBox(mx%, cy%, "Ctrl", ctrl%)
    CALL drawModBox(mx% + 56, cy%, "Shift", shift%)
    CALL drawModBox(mx% + 118, cy%, "Alt", alt%)
    CALL drawModBox(mx% + 168, cy%, "C+S", ctrlShift%)
    CALL drawModBox(mx% + 216, cy%, "C+A", ctrlAlt%)
    CALL drawModBox(mx% + 264, cy%, "S+A", shiftAlt%)
    CALL drawModBox(mx% + 312, cy%, "C+S+A", ctrlShiftAlt%)
    CALL drawModBox(mx% + 370, cy%, "None", modNone%)
    ' macOS alt tracking
    COLOR C_CYAN~&
    _PRINTSTRING (mx% + 440, cy% + 2), "macAlt=" + IIF$(macAltHeld%, "YES", "no ")

    ' ---- Page content ----
    DIM contentY AS INTEGER: contentY% = 86

    SELECT CASE currentPage%
        CASE 1: SUB_drawPage1_KeyLog contentY%
        CASE 2: SUB_drawPage2_AllKeys contentY%
        CASE 3: SUB_drawPage3_Combos contentY%
    END SELECT

    _DISPLAY
    _LIMIT 60
LOOP

SYSTEM

' =============================================================================
' PAGE 1: _KEYHIT Event Log
' =============================================================================
SUB SUB_drawPage1_KeyLog (startY%)
    SHARED logLines() AS STRING, logColors() AS _UNSIGNED LONG
    SHARED logHead AS LONG, logCount AS LONG

    COLOR C_HEADER~&
    _PRINTSTRING (8, startY%), "PAGE 1: _KEYHIT EVENT LOG (press/release history)"
    COLOR C_DIMM~&
    _PRINTSTRING (8, startY% + 16), "Shows every _KEYHIT event with code, character, and active modifiers."

    DIM y AS INTEGER: y% = startY% + 38
    DIM visCount AS INTEGER
    IF logCount& < LOG_MAX& THEN visCount% = logCount& ELSE visCount% = LOG_MAX&
    IF visCount% = 0 THEN
        COLOR C_DIMM~&
        _PRINTSTRING (20, y%), "(press any key to see events)"
        EXIT SUB
    END IF

    ' Draw from newest to oldest
    DIM idx AS LONG
    DIM li AS INTEGER
    FOR li% = 0 TO visCount% - 1
        idx& = (logHead& - 1 - li% + LOG_TOTAL&) MOD LOG_TOTAL&
        COLOR logColors~&(idx&)
        _PRINTSTRING (20, y% + li% * 18), logLines$(idx&)
    NEXT li%

    COLOR C_DIMM~&
    _PRINTSTRING (20, y% + visCount% * 18 + 6), "(" + LTRIM$(STR$(logCount&)) + " total events captured)"
END SUB

' =============================================================================
' PAGE 2: All Keys Grid — live _KEYDOWN state
' =============================================================================
SUB SUB_drawPage2_AllKeys (startY%)
    SHARED trackName() AS STRING, trackCode() AS LONG
    SHARED trackDown() AS INTEGER, trackHeldFrames() AS LONG
    SHARED trackCount AS INTEGER

    COLOR C_HEADER~&
    _PRINTSTRING (8, startY%), "PAGE 2: ALL KEYS — LIVE _KEYDOWN() STATE"
    COLOR C_DIMM~&
    _PRINTSTRING (8, startY% + 16), "Green=held now, held frame count shown. Every key DRAW cares about."

    DIM y AS INTEGER: y% = startY% + 40
    DIM x AS INTEGER: x% = 8
    DIM col AS INTEGER: col% = 0
    DIM colW AS INTEGER: colW% = 200
    DIM maxCols AS INTEGER: maxCols% = 5
    DIM rowH AS INTEGER: rowH% = 16

    ' Group headers and keys
    DIM prevGroup AS STRING: prevGroup$ = ""
    DIM gi AS INTEGER

    FOR gi% = 0 TO trackCount% - 1
        ' Detect group change by prefix before ":"
        DIM groupName AS STRING
        DIM colonPos AS INTEGER: colonPos% = INSTR(trackName$(gi%), ":")
        IF colonPos% > 0 THEN
            groupName$ = LEFT$(trackName$(gi%), colonPos% - 1)
        ELSE
            groupName$ = ""
        END IF

        IF groupName$ <> prevGroup$ AND LEN(groupName$) > 0 THEN
            ' New group — move to next column if not at row start
            IF y% > startY% + 40 THEN
                col% = col% + 1
                IF col% >= maxCols% THEN
                    col% = 0
                    ' We'd need scrolling here but shouldn't overflow
                END IF
                y% = startY% + 40
                x% = 8 + col% * colW%
            END IF
            COLOR C_ORANGE~&
            _PRINTSTRING (x%, y%), groupName$
            y% = y% + rowH% + 2
            prevGroup$ = groupName$
        END IF

        ' Key entry
        DIM displayName AS STRING
        IF colonPos% > 0 THEN
            displayName$ = MID$(trackName$(gi%), colonPos% + 1)
        ELSE
            displayName$ = trackName$(gi%)
        END IF

        IF trackDown%(gi%) THEN
            COLOR C_GREEN~&
            DIM heldStr AS STRING
            heldStr$ = LPAD$(LTRIM$(STR$(trackHeldFrames&(gi%))), 5)
            _PRINTSTRING (x%, y%), displayName$ + " " + heldStr$
        ELSE
            COLOR C_DIMM~&
            _PRINTSTRING (x%, y%), displayName$
        END IF

        y% = y% + rowH%
        ' Column overflow
        IF y% > SCREEN_H& - 20 THEN
            col% = col% + 1
            y% = startY% + 40
            x% = 8 + col% * colW%
        END IF
    NEXT gi%
END SUB

' =============================================================================
' PAGE 3: Modifier Combos Test
' =============================================================================
SUB SUB_drawPage3_Combos (startY%)
    SHARED comboName() AS STRING, comboActive() AS INTEGER
    SHARED comboLastDetected() AS DOUBLE, comboCount AS INTEGER

    COLOR C_HEADER~&
    _PRINTSTRING (8, startY%), "PAGE 3: MODIFIER COMBO TESTS"
    COLOR C_DIMM~&
    _PRINTSTRING (8, startY% + 16), "Every modifier+key combo used in DRAW. Green=active, shows last detection time."

    DIM y AS INTEGER: y% = startY% + 40
    DIM x AS INTEGER: x% = 8
    DIM col AS INTEGER: col% = 0
    DIM colW AS INTEGER: colW% = 340
    DIM now AS DOUBLE: now# = TIMER(.001)

    DIM cbi AS INTEGER
    FOR cbi% = 0 TO comboCount% - 1
        IF comboActive%(cbi%) THEN
            COLOR C_GREEN~&
            _PRINTSTRING (x%, y%), CHR$(254) + " " + comboName$(cbi%) + "  ACTIVE"
        ELSE
            DIM age AS DOUBLE
            age# = now# - comboLastDetected#(cbi%)
            IF comboLastDetected#(cbi%) > 0 AND age# < 3 THEN
                COLOR C_YELLOW~&
                _PRINTSTRING (x%, y%), CHR$(254) + " " + comboName$(cbi%) + "  (detected " + FMT_TIME$(age#) + " ago)"
            ELSE
                COLOR C_DIMM~&
                _PRINTSTRING (x%, y%), CHR$(250) + " " + comboName$(cbi%)
            END IF
        END IF

        y% = y% + 18
        IF y% > SCREEN_H& - 20 THEN
            col% = col% + 1
            y% = startY% + 40
            x% = 8 + col% * colW%
        END IF
    NEXT cbi%
END SUB

' =============================================================================
' Initialize trackable keys (every key DRAW uses)
' =============================================================================
SUB SUB_trackInit ()
    SHARED trackName() AS STRING, trackCode() AS LONG, trackCount AS INTEGER

    trackCount% = 0

    ' Function Keys
    addTrack "FKeys:F1", KEY_F1&
    addTrack "FKeys:F2", KEY_F2&
    addTrack "FKeys:F3", KEY_F3&
    addTrack "FKeys:F4", KEY_F4&
    addTrack "FKeys:F5", KEY_F5&
    addTrack "FKeys:F6", KEY_F6&
    addTrack "FKeys:F7", KEY_F7&
    addTrack "FKeys:F8", KEY_F8&
    addTrack "FKeys:F9", KEY_F9&
    addTrack "FKeys:F10", KEY_F10&
    addTrack "FKeys:F11", KEY_F11&
    addTrack "FKeys:F12", KEY_F12&

    ' Navigation
    addTrack "Nav:Up", KEY_UP&
    addTrack "Nav:Down", KEY_DOWN&
    addTrack "Nav:Left", KEY_LEFT&
    addTrack "Nav:Right", KEY_RIGHT&
    addTrack "Nav:PgUp", KEY_PGUP&
    addTrack "Nav:PgDn", KEY_PGDN&
    addTrack "Nav:Home", KEY_HOME&
    addTrack "Nav:End", KEY_ENDK&
    addTrack "Nav:Ins", KEY_INSERT&
    addTrack "Nav:Del", KEY_DELETE&

    ' Special
    addTrack "Spec:Esc", KEY_ESC&
    addTrack "Spec:Enter", KEY_ENTER&
    addTrack "Spec:Tab", KEY_TAB&
    addTrack "Spec:BkSpc", KEY_BACKSPACE&
    addTrack "Spec:Space", KEY_SPACE&

    ' Letters A-Z (lowercase codes — _KEYDOWN treats upper/lower same)
    DIM letter AS INTEGER
    FOR letter% = 97 TO 122 ' a-z
        addTrack "Alpha:" + CHR$(letter% - 32), letter%
    NEXT letter%

    ' Numbers 0-9
    DIM digit AS INTEGER
    FOR digit% = 48 TO 57
        addTrack "Digit:" + CHR$(digit%), digit%
    NEXT digit%

    ' Symbols used in DRAW
    addTrack "Sym:` ~", 96      ' grave/tilde
    addTrack "Sym:- _", 45      ' minus/underscore
    addTrack "Sym:= +", 61      ' equals/plus
    addTrack "Sym:[ {", 91      ' left bracket
    addTrack "Sym:] }", 93      ' right bracket
    addTrack "Sym:\ |", 92      ' backslash/pipe
    addTrack "Sym:; :", 59      ' semicolon/colon
    addTrack "Sym:' " + CHR$(34), 39  ' apostrophe/quote
    addTrack "Sym:, <", 44      ' comma/less-than
    addTrack "Sym:. >", 46      ' period/greater-than
    addTrack "Sym:/ ?", 47      ' slash/question

    ' Numpad
    addTrack "KP:KP0", KP_0&
    addTrack "KP:KP1", KP_1&
    addTrack "KP:KP2", KP_2&
    addTrack "KP:KP3", KP_3&
    addTrack "KP:KP4", KP_4&
    addTrack "KP:KP5", KP_5&
    addTrack "KP:KP6", KP_6&
    addTrack "KP:KP7", KP_7&
    addTrack "KP:KP8", KP_8&
    addTrack "KP:KP9", KP_9&
    addTrack "KP:KP.", KP_PERIOD&
    addTrack "KP:KP/", KP_DIVIDE&
    addTrack "KP:KP*", KP_MULTIPLY&
    addTrack "KP:KP-", KP_MINUS&
    addTrack "KP:KP+", KP_PLUS&
    addTrack "KP:KPEnt", KP_ENTER&
END SUB

SUB addTrack (n$, code&)
    SHARED trackName() AS STRING, trackCode() AS LONG
    SHARED trackDown() AS INTEGER, trackHeldFrames() AS LONG
    SHARED trackLastDetected() AS DOUBLE, trackCount AS INTEGER

    IF trackCount% >= TRACK_MAX& THEN EXIT SUB
    trackName$(trackCount%) = n$
    trackCode&(trackCount%) = code&
    trackDown%(trackCount%) = FALSE
    trackHeldFrames&(trackCount%) = 0
    trackLastDetected#(trackCount%) = 0
    trackCount% = trackCount% + 1
END SUB

' =============================================================================
' Initialize combo tests — every modifier+key combo DRAW uses
' =============================================================================
SUB SUB_comboInit ()
    SHARED comboCount AS INTEGER
    comboCount% = 0

    ' Ctrl combos (most frequent in DRAW)
    addCombo "Ctrl+Z (Undo)"
    addCombo "Ctrl+Y (Redo)"
    addCombo "Ctrl+S (Save)"
    addCombo "Ctrl+C (Copy)"
    addCombo "Ctrl+V (Paste)"
    addCombo "Ctrl+X (Cut)"
    addCombo "Ctrl+A (Select All)"
    addCombo "Ctrl+D (Deselect)"
    addCombo "Ctrl+N (New)"
    addCombo "Ctrl+O (Open)"
    addCombo "Ctrl+Q (Quit)"
    addCombo "Ctrl+B (Bold)"
    addCombo "Ctrl+I (Italic)"
    addCombo "Ctrl+U (Underline)"

    ' Ctrl+Shift combos
    addCombo "Ctrl+Shift+S (Save As)"
    addCombo "Ctrl+Shift+Z (Redo alt)"
    addCombo "Ctrl+Shift+E (Export)"

    ' Alt combos (menu access in DRAW)
    addCombo "Alt+F (File menu)"
    addCombo "Alt+E (Edit menu)"
    addCombo "Alt+V (View menu)"
    addCombo "Alt+T (Tools menu)"
    addCombo "Alt+L (Layers menu)"
    addCombo "Alt+H (Help menu)"

    ' Ctrl+Alt combos (used in DRAW for advanced ops)
    addCombo "Ctrl+Alt+PgUp"
    addCombo "Ctrl+Alt+PgDn"
    addCombo "Ctrl+Alt+. (period)"
    addCombo "Ctrl+Alt+, (comma)"
    addCombo "Ctrl+Alt+/ (slash)"

    ' Shift+key combos
    addCombo "Shift+F5"
    addCombo "Shift+Del"
END SUB

SUB addCombo (n$)
    SHARED comboName() AS STRING, comboActive() AS INTEGER
    SHARED comboLastDetected() AS DOUBLE, comboCount AS INTEGER

    IF comboCount% >= COMBO_MAX& THEN EXIT SUB
    comboName$(comboCount%) = n$
    comboActive%(comboCount%) = FALSE
    comboLastDetected#(comboCount%) = 0
    comboCount% = comboCount% + 1
END SUB

' =============================================================================
' Update combo test results — called every frame
' =============================================================================
SUB SUB_comboUpdate ()
    SHARED comboActive() AS INTEGER, comboLastDetected() AS DOUBLE
    SHARED comboCount AS INTEGER
    SHARED ctrl AS INTEGER, shift AS INTEGER, alt AS INTEGER
    SHARED ctrlOnly AS INTEGER, ctrlShift AS INTEGER, ctrlAlt AS INTEGER
    SHARED shiftOnly AS INTEGER, altOnly AS INTEGER

    DIM now AS DOUBLE: now# = TIMER(.001)
    DIM idx AS INTEGER: idx% = 0

    ' Ctrl combos
    checkCombo idx%, ctrlOnly%, 122, now#  ' Ctrl+Z
    checkCombo idx%, ctrlOnly%, 121, now#  ' Ctrl+Y
    checkCombo idx%, ctrlOnly%, 115, now#  ' Ctrl+S
    checkCombo idx%, ctrlOnly%, 99, now#   ' Ctrl+C
    checkCombo idx%, ctrlOnly%, 118, now#  ' Ctrl+V
    checkCombo idx%, ctrlOnly%, 120, now#  ' Ctrl+X
    checkCombo idx%, ctrlOnly%, 97, now#   ' Ctrl+A
    checkCombo idx%, ctrlOnly%, 100, now#  ' Ctrl+D
    checkCombo idx%, ctrlOnly%, 110, now#  ' Ctrl+N
    checkCombo idx%, ctrlOnly%, 111, now#  ' Ctrl+O
    checkCombo idx%, ctrlOnly%, 113, now#  ' Ctrl+Q
    checkCombo idx%, ctrlOnly%, 98, now#   ' Ctrl+B
    checkCombo idx%, ctrlOnly%, 105, now#  ' Ctrl+I
    checkCombo idx%, ctrlOnly%, 117, now#  ' Ctrl+U

    ' Ctrl+Shift combos
    checkCombo idx%, ctrlShift%, 115, now#  ' Ctrl+Shift+S
    checkCombo idx%, ctrlShift%, 122, now#  ' Ctrl+Shift+Z
    checkCombo idx%, ctrlShift%, 101, now#  ' Ctrl+Shift+E

    ' Alt combos
    checkCombo idx%, altOnly%, 102, now#    ' Alt+F
    checkCombo idx%, altOnly%, 101, now#    ' Alt+E
    checkCombo idx%, altOnly%, 118, now#    ' Alt+V
    checkCombo idx%, altOnly%, 116, now#    ' Alt+T
    checkCombo idx%, altOnly%, 108, now#    ' Alt+L
    checkCombo idx%, altOnly%, 104, now#    ' Alt+H

    ' Ctrl+Alt combos
    checkCombo idx%, ctrlAlt%, KEY_PGUP&, now# ' Ctrl+Alt+PgUp
    checkCombo idx%, ctrlAlt%, KEY_PGDN&, now# ' Ctrl+Alt+PgDn
    checkCombo idx%, ctrlAlt%, 46, now#         ' Ctrl+Alt+.
    checkCombo idx%, ctrlAlt%, 44, now#         ' Ctrl+Alt+,
    checkCombo idx%, ctrlAlt%, 47, now#         ' Ctrl+Alt+/

    ' Shift combos
    checkCombo idx%, shiftOnly%, KEY_F5&, now#      ' Shift+F5
    checkCombo idx%, shiftOnly%, KEY_DELETE&, now#   ' Shift+Del
END SUB

SUB checkCombo (idx%, modState%, keyCode&, now#)
    SHARED comboActive() AS INTEGER, comboLastDetected() AS DOUBLE

    IF modState% AND _KEYDOWN(keyCode&) THEN
        comboActive%(idx%) = TRUE
        comboLastDetected#(idx%) = now#
    END IF
    idx% = idx% + 1
END SUB

' =============================================================================
' Draw a modifier indicator box
' =============================================================================
SUB drawModBox (x%, y%, label$, isDown%)
    DIM boxW AS INTEGER: boxW% = 8 * LEN(label$) + 8
    IF isDown% THEN
        LINE (x%, y%)-(x% + boxW%, y% + 16), &HFF005500, BF
        LINE (x%, y%)-(x% + boxW%, y% + 16), C_GREEN~&, B
        COLOR C_GREEN~&
    ELSE
        LINE (x%, y%)-(x% + boxW%, y% + 16), &HFF222222, BF
        LINE (x%, y%)-(x% + boxW%, y% + 16), &HFF444444, B
        COLOR C_DIMM~&
    END IF
    _PRINTSTRING (x% + 4, y% + 2), label$
END SUB

' =============================================================================
' Utility: human-readable key name for extended codes
' =============================================================================
FUNCTION KEYNAME$ (code&)
    SELECT CASE code&
        CASE KEY_F1&: KEYNAME$ = "F1"
        CASE KEY_F2&: KEYNAME$ = "F2"
        CASE KEY_F3&: KEYNAME$ = "F3"
        CASE KEY_F4&: KEYNAME$ = "F4"
        CASE KEY_F5&: KEYNAME$ = "F5"
        CASE KEY_F6&: KEYNAME$ = "F6"
        CASE KEY_F7&: KEYNAME$ = "F7"
        CASE KEY_F8&: KEYNAME$ = "F8"
        CASE KEY_F9&: KEYNAME$ = "F9"
        CASE KEY_F10&: KEYNAME$ = "F10"
        CASE KEY_F11&: KEYNAME$ = "F11"
        CASE KEY_F12&: KEYNAME$ = "F12"
        CASE KEY_UP&: KEYNAME$ = "Up"
        CASE KEY_DOWN&: KEYNAME$ = "Down"
        CASE KEY_LEFT&: KEYNAME$ = "Left"
        CASE KEY_RIGHT&: KEYNAME$ = "Right"
        CASE KEY_PGUP&: KEYNAME$ = "PgUp"
        CASE KEY_PGDN&: KEYNAME$ = "PgDn"
        CASE KEY_HOME&: KEYNAME$ = "Home"
        CASE KEY_ENDK&: KEYNAME$ = "End"
        CASE KEY_INSERT&: KEYNAME$ = "Insert"
        CASE KEY_DELETE&: KEYNAME$ = "Delete"
        CASE KEY_LSHIFT&: KEYNAME$ = "LShift"
        CASE KEY_RSHIFT&: KEYNAME$ = "RShift"
        CASE KEY_LCTRL&: KEYNAME$ = "LCtrl"
        CASE KEY_RCTRL&: KEYNAME$ = "RCtrl"
        CASE KEY_LALT&: KEYNAME$ = "LAlt"
        CASE KEY_RALT&: KEYNAME$ = "RAlt"
        CASE KEY_CAPSLOCK&: KEYNAME$ = "CapsLock"
        CASE KEY_NUMLOCK&: KEYNAME$ = "NumLock"
        CASE KEY_SCROLLLOCK&: KEYNAME$ = "ScrollLock"
        CASE KP_0&: KEYNAME$ = "KP_0"
        CASE KP_1&: KEYNAME$ = "KP_1"
        CASE KP_2&: KEYNAME$ = "KP_2"
        CASE KP_3&: KEYNAME$ = "KP_3"
        CASE KP_4&: KEYNAME$ = "KP_4"
        CASE KP_5&: KEYNAME$ = "KP_5"
        CASE KP_6&: KEYNAME$ = "KP_6"
        CASE KP_7&: KEYNAME$ = "KP_7"
        CASE KP_8&: KEYNAME$ = "KP_8"
        CASE KP_9&: KEYNAME$ = "KP_9"
        CASE KP_PERIOD&: KEYNAME$ = "KP_."
        CASE KP_DIVIDE&: KEYNAME$ = "KP_/"
        CASE KP_MULTIPLY&: KEYNAME$ = "KP_*"
        CASE KP_MINUS&: KEYNAME$ = "KP_-"
        CASE KP_PLUS&: KEYNAME$ = "KP_+"
        CASE KP_ENTER&: KEYNAME$ = "KP_Enter"
        CASE ELSE: KEYNAME$ = "ext:" + LTRIM$(STR$(code&))
    END SELECT
END FUNCTION

' =============================================================================
' Utility: left-pad string
' =============================================================================
FUNCTION LPAD$ (s$, width%)
    IF LEN(s$) >= width% THEN
        LPAD$ = s$
    ELSE
        LPAD$ = SPACE$(width% - LEN(s$)) + s$
    END IF
END FUNCTION

' =============================================================================
' Utility: conditional string
' =============================================================================
FUNCTION IIF$ (condition AS INTEGER, trueVal AS STRING, falseVal AS STRING)
    IF condition THEN IIF$ = trueVal ELSE IIF$ = falseVal
END FUNCTION

' =============================================================================
' Utility: format elapsed time
' =============================================================================
FUNCTION FMT_TIME$ (seconds#)
    IF seconds# < 1 THEN
        FMT_TIME$ = LTRIM$(STR$(INT(seconds# * 1000))) + "ms"
    ELSE
        FMT_TIME$ = LEFT$(LTRIM$(STR$(seconds#)), 4) + "s"
    END IF
END FUNCTION
