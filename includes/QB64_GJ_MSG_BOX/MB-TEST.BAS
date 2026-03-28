OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ============================================================================
' MB-TEST.BAS — Standalone test for QB64_GJ_MSG_BOX
'
' Tests all message box types: alert, confirm, warning, error, input box.
' Each dialog is shown immediately — interact with it, then see the result.
' ============================================================================

SCREEN _NEWIMAGE(1024, 768, 32)
_TITLE "Message Box / Input Box Test"

'$INCLUDE:'MSG-BOX.BI'

DIM result AS INTEGER
DIM inputResult AS STRING

' --- Draw background gradient ---
DIM i AS INTEGER
FOR i = 0 TO 767
    LINE (0, i)-(1023, i), _RGB32(20 + i \ 8, 30 + i \ 12, 50 + i \ 6)
NEXT i
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (20, 20), "QB64_GJ_MSG_BOX Test Harness"
_PRINTSTRING (20, 50), "Running 7 tests sequentially..."
_DISPLAY

' ==========================================================================
' Test 1: Simple Alert
' ==========================================================================
MB_alert "Welcome", "This is a simple alert message box." + CHR$(10) + CHR$(10) + "It supports line breaks and word wrapping for longer text that needs to flow across multiple lines in the dialog."
PRINT "Test 1 (Alert): Dismissed."
_DISPLAY

' ==========================================================================
' Test 2: Confirm (Yes/No)
' ==========================================================================
DIM confirmed AS INTEGER
confirmed = MB_confirm%("Save Changes?", "You have unsaved changes." + CHR$(10) + "Do you want to save before closing?")
IF confirmed THEN
    PRINT "Test 2 (Confirm): YES"
ELSE
    PRINT "Test 2 (Confirm): NO / cancelled"
END IF
_DISPLAY

' ==========================================================================
' Test 3: Warning (OK/Cancel)
' ==========================================================================
DIM proceed AS INTEGER
proceed = MB_warning%("Delete File", "Are you sure you want to delete this file?" + CHR$(10) + "This action cannot be undone.")
IF proceed THEN
    PRINT "Test 3 (Warning): OK"
ELSE
    PRINT "Test 3 (Warning): Cancel"
END IF
_DISPLAY

' ==========================================================================
' Test 4: Error
' ==========================================================================
MB_error "Load Failed", "Could not load file: image.png" + CHR$(10) + CHR$(10) + "The file format is not supported or the file is corrupted."
PRINT "Test 4 (Error): Dismissed."
_DISPLAY

' ==========================================================================
' Test 5: Yes/No/Cancel
' ==========================================================================
result = MB_message_box%("Unsaved Work", "Save changes to 'untitled.drw'?", MB_BTN_YES_NO_CANCEL, MB_ICON_QUESTION)
SELECT CASE result
    CASE MB_RESULT_1: PRINT "Test 5 (Yes/No/Cancel): YES"
    CASE MB_RESULT_2: PRINT "Test 5 (Yes/No/Cancel): NO"
    CASE MB_RESULT_3: PRINT "Test 5 (Yes/No/Cancel): CANCEL"
    CASE ELSE:        PRINT "Test 5 (Yes/No/Cancel): Closed"
END SELECT
_DISPLAY

' ==========================================================================
' Test 6: Input Box
' ==========================================================================
inputResult = MB_input_box$("Rename Layer", "Enter new layer name:", "Layer 1", "Type a name...")
IF LEN(inputResult) > 0 THEN
    PRINT "Test 6 (Input): "; CHR$(34); inputResult; CHR$(34)
ELSE
    PRINT "Test 6 (Input): Cancelled."
END IF
_DISPLAY

' ==========================================================================
' Test 7: Retry/Cancel
' ==========================================================================
result = MB_message_box%("Connection Error", "Failed to connect to the server." + CHR$(10) + "Check your network connection and try again.", MB_BTN_RETRY_CANCEL, MB_ICON_ERROR)
SELECT CASE result
    CASE MB_RESULT_1: PRINT "Test 7 (Retry/Cancel): RETRY"
    CASE MB_RESULT_2: PRINT "Test 7 (Retry/Cancel): CANCEL"
    CASE ELSE:        PRINT "Test 7 (Retry/Cancel): Closed"
END SELECT
_DISPLAY

PRINT
PRINT "All 7 tests complete. Press any key to exit."
_DISPLAY
SLEEP

SYSTEM

'$INCLUDE:'MSG-BOX.BM'
