''
' DRAW - CFG/BINDINGS-STICK.BM
' =============================================================================
' Configure custom joystick bindings here.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' &=STICK DPU|DPD|DPL|DPR|TSLY|TSLX|TSLC|TSRY|TSRX|TSRC|B1|B2|B3|B4|B5|B6|B7|B8
' DP=DPad TSL=Thumbstick L TSR=Thumbstick R UDRL=Directions C=Click B#=Button
' MOUSE EMULATION -------------------------------------------------------------
SB.MOUSE_L$         = "&DPL"    'DPad left
SB.MOUSE_R$         = "&DPR"    'DPad right
SB.MOUSE_U$         = "&DPU"    'DPad up
SB.MOUSE_D$         = "&DPD"    'DPad down
SB.MOUSE_L_N$       = "&TSLX-"  'Left thumbstick X axis in negative direction
SB.MOUSE_R_N$       = "&TSLX+"  'Left thumbstick X axis in positive direction
SB.MOUSE_U_N$       = "&TSLY-"  'Left thumbstick Y axis in negative direction
SB.MOUSE_D_N$       = "&TSLY+"  'Left thumbstick Y axis in positive direction
SB.MOUSE_CLICK_L$   = "&B1"     'A button
SB.MOUSE_CLICK_M$   = "&B2"     'B button
SB.MOUSE_CLICK_R$   = "&B3"     'X button
SB.MOUSE_SCROLL_U$  = "&B8"     'Left trigger button
SB.MOUSE_SCROLL_D$  = "&B9"     'Right trigger button
    