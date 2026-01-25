''
' DRAW - ASSETS/PALETTES/EGA.BI
' =============================================================================
' HW CGA color palette.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM AS INTEGER i, num_palettes
DIM AS LONG r, g, b
DIM s AS STRING

DIM PAL_HW_CGA AS PAL_OBJ
PAL_HW_CGA.name$     = "HW CGA"
PAL_HW_CGA.filename$ = "EGA.BI"
PAL_HW_CGA.author$   = "Unknown"
PAL_HW_CGA.url$      = "https://en.wikipedia.org/wiki/List_of_8-bit_computer_hardware_palettes#CGA"

num_palettes% = UBOUND(PALS)
REDIM _PRESERVE SHARED PALS(0 TO num_palettes%+1) AS PAL_OBJ
PALS(UBOUND(PALS)) = PAL_HW_CGA

i% = 0
READ s$
DO UNTIL s$ = "":
    READ r&, g&, b&
    PAL(i%).name$   = s$
    PAL(i%).value~& = _RGB32(r&, g&, b&)
    READ s$
    i% = i% + 1
LOOP
' NOTE: Do NOT REDIM PAL here - it's already sized 0 TO 255 in PALETTE.BI
' and we want to allow dynamic palette loading of larger palettes

DATA "BLACK",   0,   0,   0
DATA "BLUE",   0,   0, 170
DATA "GREEN",   0, 170,   0
DATA "CYAN",   0, 170, 170
DATA "RED", 170,   0,   0
DATA "MAGENTA", 170,   0, 170
DATA "BROWN", 170,  85,   0
DATA "WHITE", 170, 170, 170
DATA "BRIGHT BLACK",  85,  85,  85
DATA "BRIGHT BLUE",  85,  85, 255
DATA "BRIGHT GREEN",  85, 255,  85
DATA "BRIGHT CYAN",  85, 255, 255
DATA "BRIGHT RED", 255,  85,  85
DATA "BRIGHT MAGENTA", 255,  85, 255
DATA "BRIGHT YELLOW", 255, 255,  85
DATA "BRIGHT WHITE", 255, 255, 255
DATA "" :' END OF DATA

' Set initial paint color from palette after loading
PAINT_COLOR~& = PAL(PAL_FG_IDX%).value~&
