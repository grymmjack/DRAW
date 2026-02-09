OPTION _EXPLICIT

' ============================================================
' Hardware Image Capabilities Test v2 - WITH GRAPHICS SCREEN
' Tests what operations work/don't work on mode 33 images
' ============================================================

DIM sw_img AS LONG   ' software image
DIM hw_img AS LONG   ' hardware image (mode 33)
DIM c AS _UNSIGNED LONG
DIM y AS INTEGER

' Create a graphics screen (needed for OpenGL/hardware context)
SCREEN _NEWIMAGE(640, 480, 32)
_TITLE "Hardware Image Test"

y = 10

' Create a software image first
sw_img = _NEWIMAGE(100, 100, 32)
IF sw_img >= -1 THEN
    _PRINTSTRING (10, y), "FAIL: Could not create software image": SYSTEM
END IF

' Draw something on the software image
DIM oldD AS LONG: oldD = _DEST
_DEST sw_img
PSET (50, 50), _RGB32(255, 0, 0)
LINE (10, 10)-(90, 90), _RGB32(0, 255, 0)
CIRCLE (50, 50), 30, _RGB32(0, 0, 255)
_DEST oldD

_PRINTSTRING (10, y), "Software image created, handle = " + STR$(sw_img)
y = y + 20

' Convert to hardware image
hw_img = _COPYIMAGE(sw_img, 33)
IF hw_img >= -1 THEN
    _PRINTSTRING (10, y), "FAIL: Could not create hardware image": SYSTEM
END IF
_PRINTSTRING (10, y), "Hardware image created, handle = " + STR$(hw_img)
y = y + 30

' ============================================================
' TEST 1: _DEST with hardware image
' ============================================================
ON ERROR GOTO err_handler
DIM test_name AS STRING
DIM test_result AS STRING

test_name = "TEST 1: _DEST hw_img"
test_result = ""
ON ERROR GOTO err_handler
_DEST hw_img
test_result = "SUCCEEDED"
_DEST 0
GOTO show1
err_handler:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
_DEST 0
RESUME show1
show1:
_PRINTSTRING (10, y), test_name + " => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 2: PSET on hardware image
' ============================================================
test_result = ""
ON ERROR GOTO err2
_DEST hw_img
PSET (25, 25), _RGB32(255, 255, 0)
test_result = "SUCCEEDED"
_DEST 0
GOTO show2
err2:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
_DEST 0
RESUME show2
show2:
_PRINTSTRING (10, y), "TEST 2: PSET on hw_img => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 3: _SOURCE with hardware image
' ============================================================
test_result = ""
ON ERROR GOTO err3
_SOURCE hw_img
test_result = "SUCCEEDED"
_SOURCE 0
GOTO show3
err3:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME show3
show3:
_PRINTSTRING (10, y), "TEST 3: _SOURCE hw_img => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 4: POINT on hardware image
' ============================================================
test_result = ""
ON ERROR GOTO err4
_SOURCE hw_img
c = POINT(50, 50)
test_result = "SUCCEEDED, color=" + STR$(c)
_SOURCE 0
GOTO show4
err4:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME show4
show4:
_PRINTSTRING (10, y), "TEST 4: POINT on hw_img => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 5: _MEMIMAGE on hardware image
' ============================================================
test_result = ""
ON ERROR GOTO err5
DIM m AS _MEM
m = _MEMIMAGE(hw_img)
IF m.SIZE > 0 THEN
    test_result = "SUCCEEDED, size=" + STR$(m.SIZE)
    _MEMFREE m
ELSE
    test_result = "RETURNED ZERO SIZE"
END IF
GOTO show5
err5:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME show5
show5:
_PRINTSTRING (10, y), "TEST 5: _MEMIMAGE hw_img => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 6: _PUTIMAGE hw src -> screen (dest 0)
' ============================================================
test_result = ""
ON ERROR GOTO err6
_PUTIMAGE (400, 10)-(500, 110), hw_img, 0
test_result = "SUCCEEDED"
GOTO show6
err6:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME show6
show6:
_PRINTSTRING (10, y), "TEST 6: _PUTIMAGE hw->screen => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 7: _PUTIMAGE hw src -> sw dest
' ============================================================
test_result = ""
DIM sw_dest AS LONG
sw_dest = _NEWIMAGE(100, 100, 32)
ON ERROR GOTO err7
_PUTIMAGE , hw_img, sw_dest
test_result = "SUCCEEDED"
IF sw_dest < -1 THEN _FREEIMAGE sw_dest
GOTO show7
err7:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
IF sw_dest < -1 THEN _FREEIMAGE sw_dest
RESUME show7
show7:
_PRINTSTRING (10, y), "TEST 7: _PUTIMAGE hw->sw => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 8: _PUTIMAGE sw src -> hw dest
' ============================================================
test_result = ""
ON ERROR GOTO err8
_PUTIMAGE , sw_img, hw_img
test_result = "SUCCEEDED"
GOTO show8
err8:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME show8
show8:
_PRINTSTRING (10, y), "TEST 8: _PUTIMAGE sw->hw => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 9: _SETALPHA on hardware image
' ============================================================
test_result = ""
ON ERROR GOTO err9
_SETALPHA 128, , hw_img
test_result = "SUCCEEDED"
GOTO show9
err9:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME show9
show9:
_PRINTSTRING (10, y), "TEST 9: _SETALPHA hw_img => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 10: _CLEARCOLOR on hardware image
' ============================================================
test_result = ""
ON ERROR GOTO err10
_CLEARCOLOR _RGB32(0, 0, 0), hw_img
test_result = "SUCCEEDED"
GOTO show10
err10:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME show10
show10:
_PRINTSTRING (10, y), "TEST 10: _CLEARCOLOR hw_img => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 11: _COPYIMAGE hw -> sw (mode 32)
' ============================================================
test_result = ""
ON ERROR GOTO err11
DIM sw_copy AS LONG
sw_copy = _COPYIMAGE(hw_img, 32)
IF sw_copy < -1 THEN
    test_result = "SUCCEEDED, new handle=" + STR$(sw_copy)
    _FREEIMAGE sw_copy
ELSE
    test_result = "INVALID HANDLE=" + STR$(sw_copy)
END IF
GOTO show11
err11:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME show11
show11:
_PRINTSTRING (10, y), "TEST 11: _COPYIMAGE hw->sw32 => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 12: _WIDTH/_HEIGHT on hardware image
' ============================================================
test_result = ""
ON ERROR GOTO err12
test_result = "w=" + STR$(_WIDTH(hw_img)) + " h=" + STR$(_HEIGHT(hw_img))
GOTO show12
err12:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME show12
show12:
_PRINTSTRING (10, y), "TEST 12: _WIDTH/_HEIGHT hw => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' TEST 13: LINE on hardware image
' ============================================================
test_result = ""
ON ERROR GOTO err13
_DEST hw_img
LINE (0, 0)-(99, 99), _RGB32(255, 128, 0)
test_result = "SUCCEEDED"
_DEST 0
GOTO show13
err13:
test_result = "FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
_DEST 0
RESUME show13
show13:
_PRINTSTRING (10, y), "TEST 13: LINE on hw_img => " + test_result
y = y + 20
ON ERROR GOTO 0

' ============================================================
' SUMMARY
' ============================================================
y = y + 10
_PRINTSTRING (10, y), "=== TESTS COMPLETE - press any key ==="

_DISPLAY
SLEEP
' Cleanup
IF sw_img < -1 THEN _FREEIMAGE sw_img
IF hw_img < -1 THEN _FREEIMAGE hw_img
SYSTEM
