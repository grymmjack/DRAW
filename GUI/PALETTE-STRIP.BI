''
' DRAW - GUI/PALETTE-STRIP.BI
' =============================================================================
' Palette strip GUI component - shows current palette colors with arrows to 
' scroll colors. Click palette name to open palette selection menu.
' Displayed at the bottom of the screen above the status bar.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Palette strip constants (deprecated - use CFG values instead)
' These are kept for backward compatibility but will use CFG values at runtime
CONST PALETTE_STRIP_ARROW_WIDTH = 12
' PALETTE_STRIP_HEIGHT is now calculated dynamically based on palette size and config
CONST PALETTE_MENU_MIN_WIDTH = 180  ' Minimum menu width for full names

' Color-chip preview columns in the palette dropdown (CFG.PALETTE_MENU_SHOW_CHIPS)
CONST PALETTE_MENU_NAME_COL_W = 180 ' Width reserved for the palette name text
CONST PALETTE_MENU_CHIP_W_MAX = 4   ' Preferred chip width; shrinks to fit narrow screens
CONST PALETTE_MENU_CHIP_H_MAX = 4   ' Chip height cap so chips stay square, not tall ribbons
CONST PALETTE_MENU_CHIP_W_MIN = 2   ' Below this the chip column is dropped entirely
CONST PALETTE_MENU_MORE_COL_W = 76  ' Width reserved for the "...and N more" label
CONST PALETTE_MENU_CHIP_GAP   = 4   ' Gap between the name column and the chips

' Palette menu state
DIM SHARED PALETTE_MENU_VISIBLE%
DIM SHARED PALETTE_MENU_X%
DIM SHARED PALETTE_MENU_Y%
DIM SHARED PALETTE_MENU_W%
DIM SHARED PALETTE_MENU_H%
DIM SHARED PALETTE_MENU_SCROLL%
DIM SHARED PALETTE_MENU_HOVER%
DIM SHARED PALETTE_MENU_PREV_HOVER%

' State
DIM SHARED PALETTE_STRIP_VISIBLE%
DIM SHARED PALETTE_STRIP_Y%
DIM SHARED PALETTE_STRIP_HOVER_IDX%
DIM SHARED PALETTE_STRIP_PREV_HOVER_IDX%
DIM SHARED PALETTE_STRIP_SCROLL_OFFSET%
DIM SHARED PALETTE_STRIP_FONT&

' Declarations
