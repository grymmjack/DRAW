''
' DRAW - GUI/ABOUT.BI
' =============================================================================
' About screen declarations — animated logo, checkers, hyperlinks.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' --- About screen dimensions ---
CONST ABOUT_SW = 560
CONST ABOUT_SH = 480

' --- About background ---
CONST ABOUT_BG~& = &HFF0000AA

' --- Checker strip config ---
CONST ABOUT_CHK_SIZE       = 10
CONST ABOUT_CHK_ROWS       = 3
CONST ABOUT_CHK_NUM_COLORS = 7

' --- Logo pixel scale ---
CONST ABOUT_LOGO_PX_W = 5
CONST ABOUT_LOGO_PX_H = 10

' --- Logo grid ---
CONST ABOUT_LOGO_COLS = 48
CONST ABOUT_LOGO_ROWS = 6
CONST ABOUT_BAR_ROWS  = 2

' --- Glint config ---
CONST ABOUT_GLINT_WIDTH = 80
CONST ABOUT_GLINT_PAUSE = 120

' --- Crayon color constants ---
CONST ABOUT_LOGO_WHITE~&  = &HFFFFFFFF
CONST ABOUT_LOGO_SHADOW~& = &HFF606060

' --- State ---
TYPE ABOUT_OBJ
    initialized AS INTEGER
    logoPixelW  AS INTEGER
END TYPE
DIM SHARED ABOUT AS ABOUT_OBJ

DIM SHARED ABOUT_logoStr(ABOUT_LOGO_ROWS - 1) AS STRING
DIM SHARED ABOUT_barStr(ABOUT_BAR_ROWS - 1) AS STRING
DIM SHARED ABOUT_chkBright(ABOUT_CHK_NUM_COLORS - 1) AS _UNSIGNED LONG
DIM SHARED ABOUT_chkDark(ABOUT_CHK_NUM_COLORS - 1) AS _UNSIGNED LONG
