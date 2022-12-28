''
' DRAW - ASSETS/PALLETES/EGA.BI
' =============================================================================
' EGA color palette.
'
' @author Rick Christy <grymmjack@gmail.com>
'

DIM AS INTEGER i, r, g, b, num_palettes
DIM s AS STRING

DIM PAL_EGA AS PALETTE_OBJ
PAL_EGA.name$     = "EGA"
PAL_EGA.filename$ = "EGA.BI"
PAL_EGA.author$   = "IBM"
PAL_EGA.url$      = "n/a"

num_palettes% = UBOUND(PALETTES)
REDIM SHARED PALETTES(0 TO num_palettes%+1) AS PALETTE_OBJ
PALETTES(UBOUND(PALETTES)) = PAL_EGA

REDIM SHARED PAL_EGA_COL(0 TO 255) AS COLOR_OBJ
i% = 0
DO UNTIL s$ = "":
    READ s$, r%, g%, b%
    PAL_EGA_COL(i%).name$  = s$
    PAL_EGA_COL(i%).value& = _RGB32(r%, g%, b%)
    i% = i% + 1
LOOP
REDIM _PRESERVE SHARED PAL_EGA_COL(i%) AS COLOR_OBJ

EGA_PALETTE:
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
