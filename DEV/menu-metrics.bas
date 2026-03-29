$CONSOLE:ONLY
_DEST _CONSOLE

DIM fh AS LONG
DIM labels(10) AS STRING
labels(0) = "FILE"
labels(1) = "EDIT"
labels(2) = "VIEW"
labels(3) = "SELECT"
labels(4) = "TOOLS"
labels(5) = "BRUSH"
labels(6) = "LAYER"
labels(7) = "PALETTE"
labels(8) = "IMAGE"
labels(9) = "HELP"
labels(10) = "AUDIO"

' Create a temp image to measure on
DIM tmpImg AS LONG
tmpImg& = _NEWIMAGE(800, 100, 32)
_DEST tmpImg&

fh& = _LOADFONT("ASSETS/THEMES/DEFAULT/FONTS/Tiny5-Regular.ttf", 8, "DONTBLEND")
IF fh& <= 0 THEN
    _DEST _CONSOLE
    PRINT "ERROR: Could not load Tiny5-Regular.ttf at size 8"
    SYSTEM
END IF
_FONT fh&

CONST MENU_PAD_LEFT = 4
CONST MENU_ROOT_GAP = 8

' Assume menuBarLeftEdge = 100 (default: layers panel LEFT @ 100px)
DIM barX AS INTEGER
barX% = 100

DIM x AS INTEGER
x% = barX% + MENU_PAD_LEFT

_DEST _CONSOLE
PRINT "=== Menu Bar Label Metrics ==="
PRINT "Font: Tiny5-Regular.ttf @ 8px with DONTBLEND"
PRINT "MENU_PAD_LEFT="; MENU_PAD_LEFT; "  MENU_ROOT_GAP="; MENU_ROOT_GAP
PRINT "Assuming menuBarLeftEdge = 100 (layers panel LEFT, width 100)"
PRINT ""
PRINT "Idx  Label      _PRINTWIDTH  X_pos  X_center  W_slot  Next_X"
PRINT "---  ---------  -----------  -----  --------  ------  ------"

_DEST tmpImg&
DIM i AS INTEGER, pw AS INTEGER
FOR i% = 0 TO 8  ' Skip HELP(9) — it's right-justified; skip AUDIO(10) — same
    pw% = _PRINTWIDTH(labels(i%))
    DIM slotW AS INTEGER
    slotW% = pw% + MENU_ROOT_GAP
    DIM centerX AS INTEGER
    centerX% = x% + pw% \ 2
    _DEST _CONSOLE
    PRINT USING "##   \        \  ###          ###    ###       ###     ###"; i%; labels(i%); pw%; x%; centerX%; slotW%; x% + slotW%
    _DEST tmpImg&
    x% = x% + slotW%
NEXT i%

' HELP is right-justified
DIM helpPW AS INTEGER
_DEST tmpImg&
helpPW% = _PRINTWIDTH("HELP")
_DEST _CONSOLE
PRINT ""
PRINT "HELP is right-justified from right edge"
PRINT "HELP _PRINTWIDTH ="; helpPW%
PRINT ""

' AUDIO comes after HELP in registration but before HELP visually
' Actually re-read: root order is 0-10, HELP=9, AUDIO=10
' The loop puts 0..8 left-to-right, then 9=HELP right-justified
' AUDIO(10) would be index 10, but helpIdx% = MENU_ROOT_COUNT%-1 = 10
' Wait — let me re-check. The code says helpIdx% = MENU_ROOT_COUNT% - 1
' which would be 10 (AUDIO). So AUDIO is right-justified as the "last" item?

' Actually re-reading the code: "HELP is always last" — but AUDIO is registered
' after HELP. So AUDIO is index 10 and helpIdx = 10 = AUDIO.
' That means AUDIO is right-justified, not HELP!

' Let me re-check the root indices from code comment:
' 0=FILE, 1=EDIT, 2=VIEW, 3=SELECT, 4=TOOLS, 5=BRUSH, 6=LAYER,
' 7=PALETTE, 8=IMAGE, 9=HELP, 10=AUDIO
' helpIdx% = MENU_ROOT_COUNT% - 1 = 10 → AUDIO is right-justified!

_DEST tmpImg&
DIM audioPW AS INTEGER
audioPW% = _PRINTWIDTH("AUDIO")
_DEST _CONSOLE

PRINT "AUDIO is right-justified (helpIdx = MENU_ROOT_COUNT-1 = 10)"
PRINT "AUDIO _PRINTWIDTH ="; audioPW%
PRINT ""

' Compute positions with HELP as a normal left-to-right item (index 9)
PRINT "=== Final Positions (all items left-to-right except AUDIO right-justified) ==="
PRINT ""

x% = barX% + MENU_PAD_LEFT
_DEST tmpImg&

FOR i% = 0 TO 9  ' FILE through HELP
    pw% = _PRINTWIDTH(labels(i%))
    slotW% = pw% + MENU_ROOT_GAP
    centerX% = x% + pw% \ 2
    _DEST _CONSOLE
    PRINT USING "##   \        \  pw=###  X=###  centerX=###"; i%; labels(i%); pw%; x%; centerX%
    _DEST tmpImg&
    x% = x% + slotW%
NEXT i%

' For menuBarRightEdge, assume screen width 800, toolbox on RIGHT
' toolboxW = TB_COLS * (TB_BTN_W * scale) + (TB_COLS-1) * (TB_BTN_PADDING * scale) + 2
' At scale=1: 4 * 11 + 3 * 1 + 2 = 44 + 3 + 2 = 49
' rightX = 799 - 49 = 750 → menuBarRightEdge = 750
DIM rightEdge AS INTEGER
rightEdge% = 750
audioPW% = _PRINTWIDTH("AUDIO")
DIM audioX AS INTEGER
audioX% = rightEdge% - audioPW% - 4  ' MENU_PAD_RIGHT = 4
DIM audioCenterX AS INTEGER
audioCenterX% = audioX% + audioPW% \ 2

_DEST _CONSOLE
PRINT ""
PRINT "AUDIO: pw="; audioPW%; " X="; audioX%; " centerX="; audioCenterX%; " (right-justified, rightEdge="; rightEdge%; ")"
PRINT ""

' Also compute for menuBarLeftEdge = 0 (no layers panel visible)
PRINT "=== Alt: menuBarLeftEdge = 0 (no left-docked panels) ==="
x% = 0 + MENU_PAD_LEFT
_DEST tmpImg&
FOR i% = 0 TO 9
    pw% = _PRINTWIDTH(labels(i%))
    slotW% = pw% + MENU_ROOT_GAP
    centerX% = x% + pw% \ 2
    _DEST _CONSOLE
    PRINT USING "##   \        \  pw=###  X=###  centerX=###"; i%; labels(i%); pw%; x%; centerX%
    _DEST tmpImg&
    x% = x% + slotW%
NEXT i%

_DEST _CONSOLE
PRINT ""
PRINT "Done."

_FREEIMAGE tmpImg&
IF fh& > 0 THEN _FREEFONT fh&
SYSTEM
