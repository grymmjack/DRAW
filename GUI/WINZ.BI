''
' DRAW - GUI/WINZ.BI
' =============================================================================
' One front-to-back order for every floating window: the floating dock panels
' (toolbox, organizer, drawer, layers, edit bar, advanced bar, charmap - by
' their DP_ id) and the native windows (Preview, Color Mixer, Advanced Color
' Picker, 3D Color Space, Pen, Browser, Animation - DP_ ids too - and Customize Toolbars,
' WZ_TBED). A press on a window brings it to the front, like an OS window;
' the window pressed keeps the mouse until the buttons are up.
'
' Render: the floating dock panels draw back to front into SCRN.GUI&, each
' whole (window, content, frame) - DOCK_render_float_stack. The native windows
' draw on screen 0 back to front; a floating dock panel above one of them is
' copied back over it from SCRN.CANVAS& (SCREEN_render_windows).
' Input: a panel / window answers the mouse only where no window above it
' covers the point (WZ_blocked%): every *_is_over_area% / hit gate asks it.
'
' Rick, 2026-11-06: overlapping floating panels drew their grips and borders
' over each other, and clicking a window behind another did not bring it up.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST WZ_TBED  = 15 ' Customize Toolbars (no DP_ id: it never docks)
CONST WZ_COUNT = 15 ' DP_COUNT + 1

DIM SHARED WZ_Z(1 TO WZ_COUNT) AS LONG ' higher = nearer the front
DIM SHARED WZ_TOP AS LONG               ' the frontmost z handed out so far
DIM SHARED WZ_CAP AS INTEGER            ' the window the held press began on (0 = none)

' the order they always drew in: the dock panels, then the native windows
' Preview < Mixer < Advanced Color Picker < 3D < Pen < Browser < Animation < Customize Toolbars
DIM WZ_i AS INTEGER
FOR WZ_i = 1 TO WZ_COUNT: WZ_Z(WZ_i) = WZ_i: NEXT WZ_i
WZ_TOP = WZ_COUNT
