''
' DRAW - GUI/CAPTURE.BI
' =============================================================================
' Built-in screen capture: File > Capture Screen (Ctrl+Shift+P), the command
' palette, or DRAW --capture.
'
'   hide DRAW -> wait CAPTURE_DELAY -> grab the screen -> show DRAW
'   -> new document from the grab -> switch to CAPTURE_WORKSPACE (annotate)
'
' QB64-PE's _SCREENIMAGE only works on Windows (the GLFW branch of libqb is
' a GLFW_TODO that returns a blank desktop-sized image - verified all black
' on Plasma 6 Wayland, 2026-10-06), so elsewhere an OS tool writes a PNG
' that DRAW loads back. CAPTURE_BACKEND=AUTO picks one:
'   Windows       _SCREENIMAGE
'   macOS         screencapture -x
'   KDE           spectacle -b -n -f -o   (verified Plasma 6.3 Wayland: 0.47 s, 4K)
'   GNOME         gnome-screenshot -f
'   wlroots       grim                    (sway, Hyprland; KWin refuses it)
'   X11           maim / scrot / import -window root
' CAPTURE_BACKEND=COMMAND runs CAPTURE_COMMAND with {file} replaced.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST CAP_BACKEND_AUTO    = 0
CONST CAP_BACKEND_NATIVE  = 1
CONST CAP_BACKEND_COMMAND = 2

CONST CAP_ACT_CAPTURE = 2450 ' File > Capture Screen (Ctrl+Shift+P)

DIM SHARED CAP_LAST_ERROR  AS STRING  ' why the last grab failed ("" = ok)
DIM SHARED CAP_LAST_TOOL   AS STRING  ' the command template the last grab used
DIM SHARED CAP_AUTO_CACHE  AS STRING  ' AUTO's choice, resolved once per session
DIM SHARED CAP_PENDING     AS INTEGER ' DRAW --capture: frames to wait before grabbing (0 = none)
DIM SHARED CAP_PREV_WS     AS STRING  ' workspace active before the capture (Done returns to it)
