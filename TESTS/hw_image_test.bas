$CONSOLE:ONLY
_DEST _CONSOLE
OPTION _EXPLICIT

' ============================================================
' Hardware Image Capabilities Test
' Tests what operations work/don't work on mode 33 images
' ============================================================

DIM sw_img AS LONG   ' software image
DIM hw_img AS LONG   ' hardware image (mode 33)
DIM result AS LONG
DIM c AS _UNSIGNED LONG
DIM oldDest AS LONG
DIM oldSource AS LONG

PRINT "=== QB64PE Hardware Image Capabilities Test ==="
PRINT

' Create a software image first
sw_img = _NEWIMAGE(100, 100, 32)
IF sw_img >= -1 THEN
    PRINT "FAIL: Could not create software image"
    SYSTEM
END IF
PRINT "Software image created: handle ="; sw_img

' Draw something on the software image
_DEST sw_img
PSET (50, 50), _RGB32(255, 0, 0)
LINE (10, 10)-(90, 90), _RGB32(0, 255, 0)
CIRCLE (50, 50), 30, _RGB32(0, 0, 255)
_DEST _CONSOLE
PRINT "Drew on software image successfully"

' Convert to hardware image
hw_img = _COPYIMAGE(sw_img, 33)
IF hw_img >= -1 THEN
    PRINT "FAIL: Could not create hardware image"
    SYSTEM
END IF
PRINT "Hardware image created: handle ="; hw_img
PRINT

' ============================================================
' TEST 1: _DEST with hardware image
' ============================================================
PRINT "--- TEST 1: _DEST hw_img ---"
ON ERROR GOTO test1_error
_DEST hw_img
PRINT "  RESULT: _DEST hw_img SUCCEEDED (no error)"
_DEST _CONSOLE
GOTO test1_done
test1_error:
PRINT "  RESULT: _DEST hw_img FAILED with error:"; ERR
_DEST _CONSOLE
RESUME test1_done
test1_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 2: PSET on hardware image
' ============================================================
PRINT "--- TEST 2: PSET on hw_img ---"
ON ERROR GOTO test2_error
_DEST hw_img
PSET (25, 25), _RGB32(255, 255, 0)
PRINT "  RESULT: PSET on hw_img SUCCEEDED"
_DEST _CONSOLE
GOTO test2_done
test2_error:
PRINT "  RESULT: PSET on hw_img FAILED with error:"; ERR
_DEST _CONSOLE
RESUME test2_done
test2_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 3: LINE on hardware image
' ============================================================
PRINT "--- TEST 3: LINE on hw_img ---"
ON ERROR GOTO test3_error
_DEST hw_img
LINE (0, 0)-(99, 99), _RGB32(255, 128, 0)
PRINT "  RESULT: LINE on hw_img SUCCEEDED"
_DEST _CONSOLE
GOTO test3_done
test3_error:
PRINT "  RESULT: LINE on hw_img FAILED with error:"; ERR
_DEST _CONSOLE
RESUME test3_done
test3_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 4: CIRCLE on hardware image
' ============================================================
PRINT "--- TEST 4: CIRCLE on hw_img ---"
ON ERROR GOTO test4_error
_DEST hw_img
CIRCLE (50, 50), 20, _RGB32(128, 0, 255)
PRINT "  RESULT: CIRCLE on hw_img SUCCEEDED"
_DEST _CONSOLE
GOTO test4_done
test4_error:
PRINT "  RESULT: CIRCLE on hw_img FAILED with error:"; ERR
_DEST _CONSOLE
RESUME test4_done
test4_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 5: _SOURCE with hardware image
' ============================================================
PRINT "--- TEST 5: _SOURCE hw_img ---"
ON ERROR GOTO test5_error
_SOURCE hw_img
PRINT "  RESULT: _SOURCE hw_img SUCCEEDED"
_SOURCE _CONSOLE
GOTO test5_done
test5_error:
PRINT "  RESULT: _SOURCE hw_img FAILED with error:"; ERR
RESUME test5_done
test5_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 6: POINT on hardware image
' ============================================================
PRINT "--- TEST 6: POINT on hw_img ---"
ON ERROR GOTO test6_error
_SOURCE hw_img
c = POINT(50, 50)
PRINT "  RESULT: POINT on hw_img SUCCEEDED, color ="; c
_SOURCE _CONSOLE
GOTO test6_done
test6_error:
PRINT "  RESULT: POINT on hw_img FAILED with error:"; ERR
RESUME test6_done
test6_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 7: _MEMIMAGE on hardware image
' ============================================================
PRINT "--- TEST 7: _MEMIMAGE on hw_img ---"
ON ERROR GOTO test7_error
DIM m AS _MEM
m = _MEMIMAGE(hw_img)
IF m.SIZE > 0 THEN
    PRINT "  RESULT: _MEMIMAGE on hw_img SUCCEEDED, size ="; m.SIZE
    _MEMFREE m
ELSE
    PRINT "  RESULT: _MEMIMAGE on hw_img returned zero size"
END IF
GOTO test7_done
test7_error:
PRINT "  RESULT: _MEMIMAGE on hw_img FAILED with error:"; ERR
RESUME test7_done
test7_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 8: _PUTIMAGE with hw source to sw dest
' ============================================================
PRINT "--- TEST 8: _PUTIMAGE hw_src -> sw_dest ---"
DIM sw_dest AS LONG
sw_dest = _NEWIMAGE(100, 100, 32)
ON ERROR GOTO test8_error
_PUTIMAGE , hw_img, sw_dest
PRINT "  RESULT: _PUTIMAGE hw->sw SUCCEEDED"
IF sw_dest < -1 THEN _FREEIMAGE sw_dest
GOTO test8_done
test8_error:
PRINT "  RESULT: _PUTIMAGE hw->sw FAILED with error:"; ERR
RESUME test8_done
test8_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 9: _PUTIMAGE with sw source to hw dest
' ============================================================
PRINT "--- TEST 9: _PUTIMAGE sw_src -> hw_dest ---"
ON ERROR GOTO test9_error
_PUTIMAGE , sw_img, hw_img
PRINT "  RESULT: _PUTIMAGE sw->hw SUCCEEDED"
GOTO test9_done
test9_error:
PRINT "  RESULT: _PUTIMAGE sw->hw FAILED with error:"; ERR
RESUME test9_done
test9_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 10: _WIDTH/_HEIGHT on hardware image
' ============================================================
PRINT "--- TEST 10: _WIDTH/_HEIGHT on hw_img ---"
ON ERROR GOTO test10_error
DIM w AS LONG, h AS LONG
w = _WIDTH(hw_img)
h = _HEIGHT(hw_img)
PRINT "  RESULT: _WIDTH ="; w; " _HEIGHT ="; h
GOTO test10_done
test10_error:
PRINT "  RESULT: _WIDTH/_HEIGHT FAILED with error:"; ERR
RESUME test10_done
test10_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 11: _SETALPHA on hardware image
' ============================================================
PRINT "--- TEST 11: _SETALPHA on hw_img ---"
ON ERROR GOTO test11_error
_SETALPHA 128, , hw_img
PRINT "  RESULT: _SETALPHA on hw_img SUCCEEDED"
GOTO test11_done
test11_error:
PRINT "  RESULT: _SETALPHA on hw_img FAILED with error:"; ERR
RESUME test11_done
test11_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 12: _CLEARCOLOR on hardware image
' ============================================================
PRINT "--- TEST 12: _CLEARCOLOR on hw_img ---"
ON ERROR GOTO test12_error
_CLEARCOLOR _RGB32(0, 0, 0), hw_img
PRINT "  RESULT: _CLEARCOLOR on hw_img SUCCEEDED"
GOTO test12_done
test12_error:
PRINT "  RESULT: _CLEARCOLOR on hw_img FAILED with error:"; ERR
RESUME test12_done
test12_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 13: PAINT on hardware image
' ============================================================
PRINT "--- TEST 13: PAINT on hw_img ---"
ON ERROR GOTO test13_error
_DEST hw_img
PAINT (50, 50), _RGB32(128, 128, 128)
PRINT "  RESULT: PAINT on hw_img SUCCEEDED"
_DEST _CONSOLE
GOTO test13_done
test13_error:
PRINT "  RESULT: PAINT on hw_img FAILED with error:"; ERR
_DEST _CONSOLE
RESUME test13_done
test13_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 14: _PRINTSTRING on hardware image
' ============================================================
PRINT "--- TEST 14: _PRINTSTRING on hw_img ---"
ON ERROR GOTO test14_error
_DEST hw_img
_PRINTSTRING (10, 10), "Hello"
PRINT "  RESULT: _PRINTSTRING on hw_img SUCCEEDED"
_DEST _CONSOLE
GOTO test14_done
test14_error:
PRINT "  RESULT: _PRINTSTRING on hw_img FAILED with error:"; ERR
_DEST _CONSOLE
RESUME test14_done
test14_done:
ON ERROR GOTO 0
PRINT

' ============================================================
' TEST 15: _COPYIMAGE hw->sw (mode 32)
' ============================================================
PRINT "--- TEST 15: _COPYIMAGE hw_img to sw (mode 32) ---"
ON ERROR GOTO test15_error
DIM sw_from_hw AS LONG
sw_from_hw = _COPYIMAGE(hw_img, 32)
IF sw_from_hw < -1 THEN
    PRINT "  RESULT: _COPYIMAGE hw->sw32 SUCCEEDED, handle ="; sw_from_hw
    _FREEIMAGE sw_from_hw
ELSE
    PRINT "  RESULT: _COPYIMAGE hw->sw32 returned invalid handle:"; sw_from_hw
END IF
GOTO test15_done
test15_error:
PRINT "  RESULT: _COPYIMAGE hw->sw32 FAILED with error:"; ERR
RESUME test15_done
test15_done:
ON ERROR GOTO 0
PRINT

' Cleanup
PRINT "=== Cleanup ==="
IF sw_img < -1 THEN _FREEIMAGE sw_img
IF hw_img < -1 THEN _FREEIMAGE hw_img
PRINT "Done."
PRINT
PRINT "Press any key to exit..."
SLEEP
SYSTEM
