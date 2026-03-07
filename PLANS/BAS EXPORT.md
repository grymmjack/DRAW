# BAS EXPORT

DOT Tool = PSET
BRUSH = PSET
SPRAY = PSET
RECT = LINE B
RECT FILLED = LINE BF
CIRCLE = CIRCLE
CIRCLE FILLED = CIRCLE + PAINT inside
LINE = LINE
POLY LINE = LINE (all lines)
POLY LINE FILL = LINE (all lines) then PAINT inside
FILL = CLS
IMAGE SIZE = _NEWIMAGE(w, h)
COLOR CHANGES = RGBA COLOR CHANGES with _RGB32 or _RGBA32

CUSTOM BRUSH = BUILD A SUB using BRUSH_N where N=00-99 or whatever. that 
reproduces the brush using primitives.

EACH LAYER = IT'S OWN SUB if using only primitives name the SUB DRAW_LayerName

ORDER for LAYERs in BAS export = call of SUBs.

TEXT = _PRINTSTRING, LOADING FONTS USED

etc.

ANYTHING NOT IN THIS LIST:
- IMPORT IMAGES
- PASTEs

do NOT include in BAS

this means you need to mark things "BASIC COMPATIBLE", as we go through the history
and that our history also needs a reproduction that stays with the file.

YOU CAN write the code as it's built, and that was the original idea see shot,
so user can see literally what is being drawn to BASIC as they are drawing with
the primitive tools.

See screenshot for explanation. 

AS user is drawing a line, append to whatever.bas LINE ....
AS user is using DOT/paint, append to whatever.bas PSETs , etc.
this happens in realtime to show how to build with basic.

For now we can output to a WIP.bas file or something and I can just watch/tail
that with -f in a console, but long term I want to show the user in the program
with a CODE view, like I show you in screenshot.
