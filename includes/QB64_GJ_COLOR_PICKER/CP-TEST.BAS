OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' ============================================================================
' CP-TEST.BAS — Standalone test for QB64_GJ_COLOR_PICKER
'
' Shows color picker with different initial colors.
' Interact with the picker, then see the chosen color printed to console.
' ============================================================================

SCREEN _NEWIMAGE(1024, 768, 32)
_TITLE "Color Picker Test"

'$INCLUDE:'COLOR-PICKER.BI'

' --- Draw background gradient ---
DIM i AS INTEGER
FOR i = 0 TO 767
    LINE (0, i)-(1023, i), _RGB32(20 + i \ 8, 30 + i \ 12, 50 + i \ 6)
NEXT i
COLOR _RGB32(255, 255, 255), _RGBA32(0, 0, 0, 0)
_PRINTSTRING (20, 20), "QB64_GJ_COLOR_PICKER Test Harness"
_PRINTSTRING (20, 50), "Running 3 color picker tests..."
_DISPLAY

DIM chosenColor AS _UNSIGNED LONG

' ==========================================================================
' Test 1: Start with red
' ==========================================================================
chosenColor = CP_pick_color&("Pick a Color", _RGB32(255, 0, 0))
IF CP_STATE.result = CP_RESULT_OK THEN
    PRINT "Test 1: Chose R="; _RED32(chosenColor); " G="; _GREEN32(chosenColor); " B="; _BLUE32(chosenColor)
ELSE
    PRINT "Test 1: Cancelled"
END IF
_DISPLAY

' ==========================================================================
' Test 2: Start with a nice teal, posterize = 8
' ==========================================================================
CP_set_posterize 8
chosenColor = CP_pick_color&("Pick a Color", _RGB32(0, 180, 180))
IF CP_STATE.result = CP_RESULT_OK THEN
    PRINT "Test 2: Chose R="; _RED32(chosenColor); " G="; _GREEN32(chosenColor); " B="; _BLUE32(chosenColor)
ELSE
    PRINT "Test 2: Cancelled"
END IF
_DISPLAY

' ==========================================================================
' Test 3: Start with a warm orange (options reset, no posterize)
' ==========================================================================
CP_reset_options
chosenColor = CP_pick_color&("Pick a Color", _RGB32(255, 140, 0))
IF CP_STATE.result = CP_RESULT_OK THEN
    PRINT "Test 3: Chose R="; _RED32(chosenColor); " G="; _GREEN32(chosenColor); " B="; _BLUE32(chosenColor)
ELSE
    PRINT "Test 3: Cancelled"
END IF
_DISPLAY

PRINT
PRINT "All tests complete. Press any key to exit."
_DISPLAY
SLEEP

'$INCLUDE:'COLOR-PICKER.BM'
