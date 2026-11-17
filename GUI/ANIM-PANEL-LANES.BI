$INCLUDEONCE
' =============================================================================
' ANIM-PANEL-LANES.BI — the Animation panel's LANES page (Rick 2026-11-16:
' "the key frame properties panel needs to exist still ... a panel gives
' people the ability to hide the xsheet and still work/adjust stuff, the panel
' would need to see all those properties like before").
'
' For the current layer, any type that can have lanes (pixel, group, clip):
' every lane on its own row - its name (click: the picked lane), a key button
' (the ease's glyph when the current frame has a key; click adds / removes
' it) and its value at the current frame (drag up / down, wheel, click to
' type, middle-click = the default). Under them the picked lane's EASE and its
' modulator (MOD chip, AMOUNT, PERIOD). The LANES chip on the status row turns
' the page on and off.
' =============================================================================

CONST ANIMPL_C_NAV = 1      ' + 0 <KEY, + 1 <, + 2 >, + 3 KEY> (ids 1..4)
CONST ANIMPL_C_NAME = 100   ' + lane
CONST ANIMPL_C_KEY = 200    ' + lane
CONST ANIMPL_C_VAL = 300    ' + lane
CONST ANIMPL_C_EASE = 400
CONST ANIMPL_C_MOD = 410
CONST ANIMPL_C_AMT = 411
CONST ANIMPL_C_PER = 412
CONST ANIMPL_C_PAGE = 500   ' the status row's LANES chip

DIM SHARED ANIMPL_PAGE AS INTEGER     ' the LANES page is on (session)
DIM SHARED ANIMPL_VL AS INTEGER       ' a value box held: its lane (0 none)
DIM SHARED ANIMPL_VY0 AS INTEGER      ' where it was pressed (viewport y)
DIM SHARED ANIMPL_VAPPLIED AS INTEGER ' steps applied so far
DIM SHARED ANIMPL_VMOVED AS INTEGER
DIM SHARED ANIMPL_VBASE AS SINGLE     ' its value at the press
DIM SHARED ANIMPL_VBEFORE AS STRING   ' the lanes at the press (one undo step)
