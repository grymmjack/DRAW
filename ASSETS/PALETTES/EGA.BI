''
' DRAW - ASSETS/PALLETES/EGA.BI
' =============================================================================
' EGA color palette.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

DIM AS INTEGER i, num_palettes
DIM AS LONG r, g, b
DIM s AS STRING

DIM PAL_EGA AS PAL_OBJ
PAL_EGA.name$     = "EGA"
PAL_EGA.filename$ = "EGA.BI"
PAL_EGA.author$   = "IBM"
PAL_EGA.url$      = "n/a"

num_palettes% = UBOUND(PALS)
REDIM _PRESERVE SHARED PALS(0 TO num_palettes%+1) AS PAL_OBJ
PALS(UBOUND(PALS)) = PAL_EGA

i% = 0
READ s$
DO UNTIL s$ = "":
    READ r&, g&, b&
    PAL(i%).name$   = s$
    PAL(i%).value~& = _RGB32(r&, g&, b&)
    READ s$
    i% = i% + 1
LOOP
REDIM _PRESERVE SHARED PAL(0 TO i%-1) AS COLOR_OBJ

DATA "Black",           0,   0,   0
DATA "Blue",            0,   0,   170
DATA "Green",           0,   170, 0
DATA "Cyan",            0,   170, 170
DATA "Red",             170, 0,   0
DATA "Magenta",         170, 0,   170
DATA "Brown",           170, 85,  0
DATA "White",           170, 170, 170
DATA "Bright Black",    85,  85,  85
DATA "Bright Blue",     85,  85,  250
DATA "Bright Green",    85,  250, 85
DATA "Bright Cyan",     85,  250, 250
DATA "Bright Red",      250, 85,  85
DATA "Bright Magenta",  250, 85,  250
DATA "Bright Yellow",   250, 250, 85
DATA "Bright White",    250, 250, 250
DATA "" :' END OF DATA
