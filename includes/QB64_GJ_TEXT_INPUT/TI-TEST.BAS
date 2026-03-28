OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ============================================================================
' TI-TEST.BAS — Standalone test for QB64_GJ_TEXT_INPUT
'
' Demonstrates the text input widget independently from any other library.
' ============================================================================

SCREEN _NEWIMAGE(800, 700, 32)
_TITLE "Text Input Widget Test"

'$INCLUDE:'TEXT-INPUT.BI'

' --- Create some test inputs ---
DIM pathInput AS INTEGER
DIM nameInput AS INTEGER
DIM passInput AS INTEGER
DIM readOnlyInput AS INTEGER

pathInput = TI_create%(10, 40, 780, 24)
TI_inputs(pathInput).placeholder = "Enter a file path here (try ~, Ctrl+A, Ctrl+C/V)..."
TI_set_text pathInput, "/home/user/documents"

nameInput = TI_create%(10, 100, 400, 24)
TI_inputs(nameInput).placeholder = "Filename..."

passInput = TI_create%(10, 160, 300, 24)
TI_inputs(passInput).placeholder = "Password (masked)..."
TI_inputs(passInput).password = -1

readOnlyInput = TI_create%(10, 220, 780, 24)
TI_inputs(readOnlyInput).readOnly = -1
TI_set_text readOnlyInput, "This is read-only. You can select and copy (Ctrl+C) but not edit."

' Custom themed input
DIM customInput AS INTEGER
customInput = TI_create%(10, 280, 400, 28)
TI_inputs(customInput).placeholder = "Custom themed input..."
TI_inputs(customInput).theme.bgColor = &HFF1A1A2E
TI_inputs(customInput).theme.focusBgColor = &HFF16213E
TI_inputs(customInput).theme.borderColor = &HFF0F3460
TI_inputs(customInput).theme.focusBorderColor = &HFF533483
TI_inputs(customInput).theme.textColor = &HFFE94560
TI_inputs(customInput).theme.cursorColor = &HFFE94560
TI_inputs(customInput).theme.selectionColor = &HFF533483

' --- Multiline text areas ---
DIM textArea AS INTEGER
textArea = TI_create%(10, 345, 380, 160)
TI_inputs(textArea).multiline = -1
TI_inputs(textArea).placeholder = "Type or paste multiline text here..."
TI_set_text textArea, "Line one - hello world" + CHR$(10) + "Line two - arrows Up/Down navigate" + CHR$(10) + "Line three - Home/End per line" + CHR$(10) + "Line four - Ctrl+Home/End for doc edges" + CHR$(10) + "Line five - selection with Shift" + CHR$(10) + "Line six - Enter inserts new lines" + CHR$(10) + "Line seven - scrolls vertically too" + CHR$(10) + "Line eight - try Ctrl+A then Ctrl+C"

DIM readOnlyArea AS INTEGER
readOnlyArea = TI_create%(400, 345, 390, 160)
TI_inputs(readOnlyArea).multiline = -1
TI_inputs(readOnlyArea).readOnly = -1
TI_inputs(readOnlyArea).theme.bgColor = &HFF2D2D30
TI_inputs(readOnlyArea).theme.borderColor = &HFF444444
TI_set_text readOnlyArea, "=== Read-Only Text Area ===" + CHR$(10) + CHR$(10) + "This area is read-only." + CHR$(10) + "You can select text and copy it," + CHR$(10) + "but you cannot edit content." + CHR$(10) + CHR$(10) + "Useful for log output, code" + CHR$(10) + "preview, or info display." + CHR$(10) + CHR$(10) + "Scroll with Up/Down/PgUp/PgDn."

DIM totalInputs AS INTEGER
totalInputs = 7

' Focus the first input
TI_set_focus pathInput

' --- Main loop ---
DIM k AS LONG
DIM focusedId AS INTEGER
DIM oldMB1 AS INTEGER
oldMB1 = 0

DO
    k = _KEYHIT

    ' Let the text input handle keys
    IF k <> 0 THEN
        focusedId = TI_process_key%(k)

        ' Check callback hints
        IF focusedId > 0 THEN
            IF TI_inputs(focusedId).submitted THEN
                _TITLE "Submitted: " + TI_get_text$(focusedId)
            END IF
            IF TI_inputs(focusedId).escaped THEN
                _TITLE "Escaped from input #" + LTRIM$(STR$(focusedId))
                TI_clear_focus
            END IF
            IF TI_inputs(focusedId).tabbed = 1 THEN
                ' Tab to next input
                DIM nextId AS INTEGER
                nextId = focusedId + 1
                IF nextId > totalInputs THEN nextId = 1
                TI_set_focus nextId
            ELSEIF TI_inputs(focusedId).tabbed = -1 THEN
                ' Shift+Tab to previous
                DIM prevId AS INTEGER
                prevId = focusedId - 1
                IF prevId < 1 THEN prevId = totalInputs
                TI_set_focus prevId
            END IF
        END IF
    END IF

    ' Handle mouse clicks and wheel
    DIM mWheel AS INTEGER
    mWheel = 0
    DO WHILE _MOUSEINPUT
        mWheel = mWheel + _MOUSEWHEEL
    LOOP
    IF _MOUSEBUTTON(1) THEN
        IF NOT oldMB1 THEN
            TI_process_mouse _MOUSEX, _MOUSEY, -1
        END IF
        oldMB1 = -1
    ELSE
        oldMB1 = 0
    END IF
    IF mWheel <> 0 THEN
        TI_process_mousewheel _MOUSEX, _MOUSEY, mWheel
    END IF

    ' Tick cursor blink
    TI_tick

    ' Render
    CLS , &HFF1E1E1E

    COLOR &HFFCCCCCC, &HFF1E1E1E

    _PRINTSTRING (10, 15), "Path (normal input with default text):"
    _PRINTSTRING (10, 75), "Filename (empty, placeholder):"
    _PRINTSTRING (10, 135), "Password (masked with *):"
    _PRINTSTRING (10, 195), "Read-only (select+copy only):"
    _PRINTSTRING (10, 255), "Custom themed:"
    _PRINTSTRING (10, 325), "Multiline text area:"
    _PRINTSTRING (400, 325), "Read-only text area:"

    ' Draw all inputs (0,0 offset since we're drawing to screen)
    TI_render_all 0, 0

    ' Status line
    COLOR &HFF808080, &HFF1E1E1E
    DIM statusLine AS STRING
    IF TI_focusedId > 0 THEN
        statusLine = "Focused: #" + LTRIM$(STR$(TI_focusedId))
        statusLine = statusLine + "  Cursor: " + LTRIM$(STR$(TI_inputs(TI_focusedId).cursorPos))
        statusLine = statusLine + "  Len: " + LTRIM$(STR$(TI_inputs(TI_focusedId).textLen))
        IF TI_inputs(TI_focusedId).selStart >= 0 THEN
            statusLine = statusLine + "  Sel: " + LTRIM$(STR$(TI_inputs(TI_focusedId).selStart))
            statusLine = statusLine + "-" + LTRIM$(STR$(TI_inputs(TI_focusedId).selEnd))
        END IF
        IF TI_inputs(TI_focusedId).multiline THEN
            statusLine = statusLine + "  Row: " + LTRIM$(STR$(TI__cursor_row%(TI_focusedId)))
            statusLine = statusLine + "  Col: " + LTRIM$(STR$(TI__cursor_col%(TI_focusedId)))
            statusLine = statusLine + "  Lines: " + LTRIM$(STR$(TI__line_count%(TI_focusedId)))
        END IF
    ELSE
        statusLine = "No input focused. Click an input or press Tab."
    END IF
    _PRINTSTRING (10, 520), statusLine

    DIM helpLine AS STRING
    helpLine = "Tab/Shift+Tab=cycle  Ctrl+A=select all  Ctrl+C/X/V=clipboard  Ctrl+Left/Right=word jump"
    COLOR &HFF606060, &HFF1E1E1E
    _PRINTSTRING (10, 540), helpLine

    _DISPLAY
    _LIMIT 60
LOOP UNTIL k = 27 AND TI_focusedId = 0  ' Escape when nothing focused = quit

' Clean up
TI_destroy pathInput
TI_destroy nameInput
TI_destroy passInput
TI_destroy readOnlyInput
TI_destroy customInput
TI_destroy textArea
TI_destroy readOnlyArea

SYSTEM

'$INCLUDE:'TEXT-INPUT.BM'
