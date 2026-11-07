''
' DRAW - INPUT/NUMPAD.BI
' =============================================================================
' Telling the numpad from the rest of the keyboard. Ported from bu1ld0r
' (~/git/bu1ld0r UI/UI.BM "the numpad: views"; Rick: "it has great numpad
' handling").
'
' _KEYHIT and INKEY$ give numpad 4 the same code as main-row 4 (52), or Left
' (19200) with Num Lock off, and _KEYDOWN(52) / _KEYDOWN(19200) are TRUE while
' it is held - the input dispatcher would fire main-row 4's binding. Only
' _KEYDOWN(100256 + n) (Num Lock on) / _KEYDOWN(200000 + n) (off) are the
' numpad's own. [Linux] probed 2026-11-07 under Xvfb + xdotool, QB64-PE GLFW.
'
' Numpad keys b: 1-9, 10 = 0, 11 = ., 12 = +, 13 = -, 14 = *, 15 = /, 16 = Enter.
' NUMPAD_of%(k&)    the numpad key a plain code could have come from (0 = none)
' NUMPAD_held%(b)   that numpad key is down now (either Num Lock state)
' NUMPAD_sent%(k&)  code k& came from the numpad: its key is held, or was
'                   pressed < .25 s ago (a tap quicker than a frame)
' NUMPAD_poll       once a frame (DRAW.BAS): each new press sets NP_T(b) for
'                   a user to take (TOOLS/ANIM-VIEW ANIM_numpad_tick)
' DRAW reads keys through INKEY$ and _KEYDOWN: _KEYHIT is drained after every
' render (KEYBOARD_input_handler_loop), so a press is caught from _KEYDOWN
' edges and the device queue, never from _KEYHIT.
' [Linux] taps are also caught from the keyboard device queue (_DEVICEINPUT,
' X11 key code + 1 ids); elsewhere _KEYDOWN alone (a sub-frame tap can be
' missed there). DRAW reads _DEVICEINPUT nowhere else.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST NP_N = 16
DIM SHARED NP_HELD(1 TO NP_N) AS INTEGER  ' held last poll
DIM SHARED NP_T(1 TO NP_N) AS DOUBLE      ' TIMER of a press not yet used; -1 = none
DIM SHARED NP_DEVT(1 TO NP_N) AS DOUBLE   ' [Linux] TIMER of the device queue's last press
DIM SHARED NP_READY AS INTEGER            ' _DEVICES enumerated
DIM SHARED NP_I AS INTEGER
FOR NP_I = 1 TO NP_N: NP_T(NP_I) = -1: NP_DEVT(NP_I) = -1: NEXT NP_I
