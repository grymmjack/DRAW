SCREEN _NEWIMAGE(800, 100, 32)

DIM fh AS LONG
DIM labels(10) AS STRING
labels(0)  = "FILE"
labels(1)  = "EDIT"
labels(2)  = "VIEW"
labels(3)  = "SELECT"
labels(4)  = "TOOLS"
labels(5)  = "BRUSH"
labels(6)  = "LAYER"
labels(7)  = "PALETTE"
labels(8)  = "IMAGE"
labels(9)  = "HELP"
labels(10) = "AUDIO"

fh& = _LOADFONT("ASSETS/THEMES/DEFAULT/FONTS/Tiny5-Regular.ttf", 8, "DONTBLEND")
IF fh& <= 0 THEN
    fh& = _LOADFONT("ASSETS/FONTS/Tiny5-Regular.ttf", 8, "DONTBLEND")
END IF
IF fh& <= 0 THEN
    OPEN "DEV/menu-metrics-out.txt" FOR OUTPUT AS #1
    PRINT #1, "ERROR: Could not load font"
    CLOSE #1
    SYSTEM
END IF
_FONT fh&

CONST MENU_PAD_LEFT  = 4
CONST MENU_PAD_RIGHT = 4
CONST MENU_ROOT_GAP  = 8

OPEN "DEV/menu-metrics-out.txt" FOR OUTPUT AS #1

PRINT #1, "=== Menu Bar Label Metrics ==="
PRINT #1, "Font: Tiny5-Regular.ttf @ 8px DONTBLEND"
PRINT #1, "MENU_PAD_LEFT=4  MENU_ROOT_GAP=8  MENU_PAD_RIGHT=4"
PRINT #1, ""

' Measure all labels
DIM i AS INTEGER, pw AS INTEGER
PRINT #1, "Label       _PRINTWIDTH"
PRINT #1, "----------  -----------"
FOR i% = 0 TO 10
    pw% = _PRINTWIDTH(labels(i%))
    PRINT #1, labels(i%); TAB(13); pw%
NEXT i%

PRINT #1, ""
PRINT #1, "=== Positions with menuBarLeftEdge = 100 (Layers LEFT@100) ==="
PRINT #1, "Idx  Label      pw   X_left  center_X"
PRINT #1, "---  ---------  ---  ------  --------"

DIM x AS INTEGER, centerX AS INTEGER, slotW AS INTEGER
x% = 100 + MENU_PAD_LEFT ' barX + MENU_PAD_LEFT

' Items 0-8 (FILE..IMAGE) go left-to-right
' Item 9 = HELP also goes left-to-right
' Item 10 = AUDIO is right-justified (helpIdx = MENU_ROOT_COUNT-1 = 10)
FOR i% = 0 TO 9
    pw%      = _PRINTWIDTH(labels(i%))
    slotW%   = pw% + MENU_ROOT_GAP
    centerX% = x% + pw% \ 2
    PRINT #1, USING "##   \        \  ###  ###     ###"; i%; labels(i%); pw%; x%; centerX%
    x% = x% + slotW%
NEXT i%

' AUDIO right-justified: assume rightEdge = 750
DIM rightEdge AS INTEGER
rightEdge% = 750
pw%        = _PRINTWIDTH("AUDIO")
DIM audioX    AS INTEGER
audioX%  = rightEdge% - pw% - MENU_PAD_RIGHT
centerX% = audioX% + pw% \ 2
PRINT #1, USING "##   \        \  ###  ###     ###   (right-justified, rightEdge=750)"; 10; "AUDIO"; pw%; audioX%; centerX%

PRINT #1, ""
PRINT #1, "=== Positions with menuBarLeftEdge = 0 (no left panels) ==="
PRINT #1, "Idx  Label      pw   X_left  center_X"
PRINT #1, "---  ---------  ---  ------  --------"
x% = 0 + MENU_PAD_LEFT
FOR i% = 0 TO 9
    pw%      = _PRINTWIDTH(labels(i%))
    slotW%   = pw% + MENU_ROOT_GAP
    centerX% = x% + pw% \ 2
    PRINT #1, USING "##   \        \  ###  ###     ###"; i%; labels(i%); pw%; x%; centerX%
    x% = x% + slotW%
NEXT i%
pw% = _PRINTWIDTH("AUDIO")
DIM rEdge2 AS INTEGER
rEdge2%  = 799           ' screen width - 1 with no right panel
audioX%  = rEdge2% - pw% - MENU_PAD_RIGHT
centerX% = audioX% + pw% \ 2
PRINT #1, USING "##   \        \  ###  ###     ###   (right-justified, rightEdge=799)"; 10; "AUDIO"; pw%; audioX%; centerX%

PRINT #1, ""
PRINT #1, "=== Click coordinates (Y=6) ==="
PRINT #1, "Use center_X for the X coordinate, Y=6 for the Y coordinate."

CLOSE #1
IF fh& > 0 THEN _FREEFONT fh&
SYSTEM
