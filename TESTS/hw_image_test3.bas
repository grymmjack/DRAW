$CONSOLE
OPTION _EXPLICIT

' ============================================================
' Hardware Image Capabilities Test v3 - Using _LOGINFO
' Tests what operations work/don't work on mode 33 images
' ============================================================

DIM sw_img AS LONG
DIM hw_img AS LONG
DIM c AS _UNSIGNED LONG

SCREEN _NEWIMAGE(640, 480, 32)
_TITLE "Hardware Image Test"

_LOGINFO "=== QB64PE Hardware Image Capabilities Test ==="

' Create a software image
sw_img = _NEWIMAGE(100, 100, 32)
IF sw_img >= -1 THEN _LOGINFO "FAIL: Could not create software image": SYSTEM

' Draw on software image
DIM oldD AS LONG: oldD = _DEST
_DEST sw_img
PSET (50, 50), _RGB32(255, 0, 0)
LINE (10, 10)-(90, 90), _RGB32(0, 255, 0)
CIRCLE (50, 50), 30, _RGB32(0, 0, 255)
_DEST oldD
_LOGINFO "Software image created: handle =" + STR$(sw_img)

' Convert to hardware image
hw_img = _COPYIMAGE(sw_img, 33)
IF hw_img >= -1 THEN _LOGINFO "FAIL: Could not create hardware image": SYSTEM
_LOGINFO "Hardware image created: handle =" + STR$(hw_img)

' --- TEST 1: _DEST ---
ON ERROR GOTO err1
_DEST hw_img
_LOGINFO "TEST 1: _DEST hw_img => SUCCEEDED"
_DEST 0
GOTO t2
err1:
_LOGINFO "TEST 1: _DEST hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
_DEST 0
RESUME t2

' --- TEST 2: PSET ---
t2:
ON ERROR GOTO err2
_DEST hw_img
PSET (25, 25), _RGB32(255, 255, 0)
_LOGINFO "TEST 2: PSET on hw_img => SUCCEEDED"
_DEST 0
GOTO t3
err2:
_LOGINFO "TEST 2: PSET on hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
_DEST 0
RESUME t3

' --- TEST 3: LINE ---
t3:
ON ERROR GOTO err3
_DEST hw_img
LINE (0, 0)-(99, 99), _RGB32(255, 128, 0)
_LOGINFO "TEST 3: LINE on hw_img => SUCCEEDED"
_DEST 0
GOTO t4
err3:
_LOGINFO "TEST 3: LINE on hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
_DEST 0
RESUME t4

' --- TEST 4: CIRCLE ---
t4:
ON ERROR GOTO err4
_DEST hw_img
CIRCLE (50, 50), 20, _RGB32(128, 0, 255)
_LOGINFO "TEST 4: CIRCLE on hw_img => SUCCEEDED"
_DEST 0
GOTO t5
err4:
_LOGINFO "TEST 4: CIRCLE on hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
_DEST 0
RESUME t5

' --- TEST 5: _SOURCE ---
t5:
ON ERROR GOTO err5
_SOURCE hw_img
_LOGINFO "TEST 5: _SOURCE hw_img => SUCCEEDED"
_SOURCE 0
GOTO t6
err5:
_LOGINFO "TEST 5: _SOURCE hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME t6

' --- TEST 6: POINT ---
t6:
ON ERROR GOTO err6
_SOURCE hw_img
c = POINT(50, 50)
_LOGINFO "TEST 6: POINT on hw_img => SUCCEEDED, color=" + STR$(c)
_SOURCE 0
GOTO t7
err6:
_LOGINFO "TEST 6: POINT on hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME t7

' --- TEST 7: _MEMIMAGE ---
t7:
ON ERROR GOTO err7
DIM m AS _MEM
m = _MEMIMAGE(hw_img)
IF m.SIZE > 0 THEN
    _LOGINFO "TEST 7: _MEMIMAGE hw_img => SUCCEEDED, size=" + STR$(m.SIZE)
    _MEMFREE m
ELSE
    _LOGINFO "TEST 7: _MEMIMAGE hw_img => ZERO SIZE"
END IF
GOTO t8
err7:
_LOGINFO "TEST 7: _MEMIMAGE hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME t8

' --- TEST 8: _PUTIMAGE hw -> screen (dest 0) ---
t8:
ON ERROR GOTO err8
_PUTIMAGE (10, 10)-(110, 110), hw_img, 0
_LOGINFO "TEST 8: _PUTIMAGE hw->screen(0) => SUCCEEDED"
GOTO t9
err8:
_LOGINFO "TEST 8: _PUTIMAGE hw->screen(0) => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME t9

' --- TEST 9: _PUTIMAGE hw -> sw ---
t9:
DIM sw_dest AS LONG
sw_dest = _NEWIMAGE(100, 100, 32)
ON ERROR GOTO err9
_PUTIMAGE , hw_img, sw_dest
_LOGINFO "TEST 9: _PUTIMAGE hw->sw => SUCCEEDED"
IF sw_dest < -1 THEN _FREEIMAGE sw_dest
GOTO t10
err9:
_LOGINFO "TEST 9: _PUTIMAGE hw->sw => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
IF sw_dest < -1 THEN _FREEIMAGE sw_dest
RESUME t10

' --- TEST 10: _PUTIMAGE sw -> hw ---
t10:
ON ERROR GOTO err10
_PUTIMAGE , sw_img, hw_img
_LOGINFO "TEST 10: _PUTIMAGE sw->hw => SUCCEEDED"
GOTO t11
err10:
_LOGINFO "TEST 10: _PUTIMAGE sw->hw => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME t11

' --- TEST 11: _SETALPHA ---
t11:
ON ERROR GOTO err11
_SETALPHA 128, , hw_img
_LOGINFO "TEST 11: _SETALPHA hw_img => SUCCEEDED"
GOTO t12
err11:
_LOGINFO "TEST 11: _SETALPHA hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME t12

' --- TEST 12: _CLEARCOLOR ---
t12:
ON ERROR GOTO err12
_CLEARCOLOR _RGB32(0, 0, 0), hw_img
_LOGINFO "TEST 12: _CLEARCOLOR hw_img => SUCCEEDED"
GOTO t13
err12:
_LOGINFO "TEST 12: _CLEARCOLOR hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME t13

' --- TEST 13: _COPYIMAGE hw -> sw (mode 32) ---
t13:
ON ERROR GOTO err13
DIM sw_copy AS LONG
sw_copy = _COPYIMAGE(hw_img, 32)
IF sw_copy < -1 THEN
    _LOGINFO "TEST 13: _COPYIMAGE hw->sw32 => SUCCEEDED, handle=" + STR$(sw_copy)
    _FREEIMAGE sw_copy
ELSE
    _LOGINFO "TEST 13: _COPYIMAGE hw->sw32 => INVALID HANDLE=" + STR$(sw_copy)
END IF
GOTO t14
err13:
_LOGINFO "TEST 13: _COPYIMAGE hw->sw32 => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME t14

' --- TEST 14: _WIDTH/_HEIGHT ---
t14:
ON ERROR GOTO err14
_LOGINFO "TEST 14: _WIDTH=" + STR$(_WIDTH(hw_img)) + " _HEIGHT=" + STR$(_HEIGHT(hw_img))
GOTO t15
err14:
_LOGINFO "TEST 14: _WIDTH/_HEIGHT => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
RESUME t15

' --- TEST 15: PAINT ---
t15:
ON ERROR GOTO err15
_DEST hw_img
PAINT (50, 50), _RGB32(128, 128, 128)
_LOGINFO "TEST 15: PAINT on hw_img => SUCCEEDED"
_DEST 0
GOTO t16
err15:
_LOGINFO "TEST 15: PAINT on hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
_DEST 0
RESUME t16

' --- TEST 16: _PRINTSTRING ---
t16:
ON ERROR GOTO err16
_DEST hw_img
_PRINTSTRING (10, 10), "Hello"
_LOGINFO "TEST 16: _PRINTSTRING on hw_img => SUCCEEDED"
_DEST 0
GOTO t17
err16:
_LOGINFO "TEST 16: _PRINTSTRING on hw_img => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
_DEST 0
RESUME t17

' --- TEST 17: _PUTIMAGE hw -> hw (second hw image) ---
t17:
ON ERROR GOTO err17
DIM hw2 AS LONG
DIM sw2 AS LONG
sw2 = _NEWIMAGE(100, 100, 32)
hw2 = _COPYIMAGE(sw2, 33)
IF sw2 < -1 THEN _FREEIMAGE sw2
_PUTIMAGE , hw_img, hw2
_LOGINFO "TEST 17: _PUTIMAGE hw->hw => SUCCEEDED"
IF hw2 < -1 THEN _FREEIMAGE hw2
GOTO done
err17:
_LOGINFO "TEST 17: _PUTIMAGE hw->hw => FAILED err=" + STR$(ERR) + " " + _ERRORMESSAGE$
IF hw2 < -1 THEN _FREEIMAGE hw2
RESUME done

done:
ON ERROR GOTO 0
_LOGINFO "=== ALL TESTS COMPLETE ==="

' Cleanup
IF sw_img < -1 THEN _FREEIMAGE sw_img
IF hw_img < -1 THEN _FREEIMAGE hw_img
SYSTEM
