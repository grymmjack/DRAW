' fullscreen-modes.BAS — probe which _FULLSCREEN modes actually engage + look good
' on THIS machine's display (esp. Retina/HiDPI). Standalone, no DRAW includes.
'
' Build:  qb64pe -w -x -o fullscreen-modes.run DEV/EXPERIMENTS/fullscreen-modes.BAS
' Run it, then press:
'   1  windowed  (_FULLSCREEN _OFF)
'   2  _STRETCH
'   3  _STRETCH , _SMOOTH
'   4  _SQUAREPIXELS
'   5  _SQUAREPIXELS , _SMOOTH
'   ESC  quit
'
' The on-screen readout shows the _FULLSCREEN() return value after each request:
'   0 = did NOT engage (mode unsupported on this display — stays windowed)
'   1 = _STRETCH engaged
'   2 = _SQUAREPIXELS engaged
' Judge the checkerboard + diagonals (pixel-art proxy) and the text for jaggies vs smooth.

OPTION _EXPLICIT

CONST TRUE = -1, FALSE = 0

DIM SHARED lastReq AS STRING
DIM SHARED lastRet AS INTEGER

SCREEN _NEWIMAGE(640, 480, 32)
_TITLE "fullscreen mode probe"
lastReq$ = "windowed (startup)"
lastRet% = _FULLSCREEN

DIM k AS LONG
DO
    DrawScene
    _DISPLAY
    k& = _KEYHIT
    SELECT CASE k&
        CASE 49 ' 1
            _FULLSCREEN _OFF
            lastReq$ = "1: _FULLSCREEN _OFF (windowed)"
            lastRet% = _FULLSCREEN
        CASE 50 ' 2
            _FULLSCREEN _STRETCH
            lastReq$ = "2: _STRETCH"
            lastRet% = _FULLSCREEN
        CASE 51 ' 3
            _FULLSCREEN _STRETCH, _SMOOTH
            lastReq$ = "3: _STRETCH, _SMOOTH"
            lastRet% = _FULLSCREEN
        CASE 52 ' 4
            _FULLSCREEN _SQUAREPIXELS
            lastReq$ = "4: _SQUAREPIXELS"
            lastRet% = _FULLSCREEN
        CASE 53 ' 5
            _FULLSCREEN _SQUAREPIXELS, _SMOOTH
            lastReq$ = "5: _SQUAREPIXELS, _SMOOTH"
            lastRet% = _FULLSCREEN
        CASE 27 ' ESC
            EXIT DO
    END SELECT
    _LIMIT 60
LOOP

_FULLSCREEN _OFF
SYSTEM

SUB DrawScene
    CLS , _RGB32(24, 24, 32)

    ' Checkerboard (pixel-art proxy): crisp squares should stay crisp; smoothing blurs edges.
    DIM x AS INTEGER, y AS INTEGER, c AS INTEGER
    FOR y% = 0 TO 15
        FOR x% = 0 TO 31
            c% = ((x% + y%) AND 1)
            IF c% THEN
                LINE (x% * 8, 120 + y% * 8)-STEP(7, 7), _RGB32(230, 230, 230), BF
            END IF
        NEXT
    NEXT

    ' Diagonal 1px lines — jaggies show clearly here.
    DIM i AS INTEGER
    FOR i% = 0 TO 31
        PSET (256 + i% * 4, 120 + i% * 4), _RGB32(120, 220, 255)
    NEXT
    LINE (280, 130)-(460, 250), _RGB32(255, 180, 80)

    ' Text at a couple of sizes.
    COLOR _RGB32(255, 255, 255), _RGB32(24, 24, 32)
    _PRINTSTRING (8, 8), "FULLSCREEN MODE PROBE  -  1 win  2 stretch  3 stretch+smooth  4 square  5 square+smooth  ESC quit"
    _PRINTSTRING (8, 28), "last request : " + lastReq$
    _PRINTSTRING (8, 44), "_FULLSCREEN() = " + _TRIM$(STR$(lastRet%)) + "   (0=did NOT engage, 1=stretch, 2=squarepixels)"
    _PRINTSTRING (8, 60), "logical size : " + _TRIM$(STR$(_WIDTH)) + " x " + _TRIM$(STR$(_HEIGHT)) + _
                          "   desktop : " + _TRIM$(STR$(_DESKTOPWIDTH)) + " x " + _TRIM$(STR$(_DESKTOPHEIGHT))
    _PRINTSTRING (8, 300), "Judge: do the checkerboard squares / diagonals / this text look JAGGED or SMOOTH?"
    _PRINTSTRING (8, 316), "Tell me which numbers ENGAGED (return>0) and which looked good."
END SUB
