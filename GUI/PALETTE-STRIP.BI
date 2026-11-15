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
DIM SHARED PALETTE_STRIP_HIDDEN AS INTEGER ' a workspace hid the strip (status bar stays): 0 height, no render/input
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
DIM SHARED PALETTE_STRIP_ALL_FIT%  ' TRUE when every color is on screen: no scroll arrows (set by render)
DIM SHARED PALETTE_STRIP_FONT&

' Declarations

' The strip's size menu (Rick 2026-11-14): right-click a blank part of the
' strip - MAX ROWS / MAX COLUMNS / CHIP HEIGHT / CHIP WIDTH, each a submenu of
' values (PSM_*, GUI/PALETTE-STRIP.BM). The values are DRAW.cfg's
' PALETTE_MAX_ROWS / _MAX_CHIPS_PER_ROW / _CHIP_HEIGHT / _CHIP_WIDTH (Settings
' has them too), kept per workspace like every panel setting.
TYPE PSM_OBJ
    isOpen  AS INTEGER
    rx      AS INTEGER ' the root box (viewport px)
    ry      AS INTEGER
    rw      AS INTEGER
    rHover  AS INTEGER ' root row under the pointer (-1)
    subRow  AS INTEGER ' the root row whose submenu shows (-1)
    sbX     AS INTEGER ' the submenu's box
    sbY     AS INTEGER
    sbW     AS INTEGER
    sbN     AS INTEGER
    sbHover AS INTEGER
END TYPE
DIM SHARED PSM AS PSM_OBJ
CONST PSM_ITEM_H = 12
CONST PSM_ROOT_N = 16 ' 4 size rows (flyouts) + divider, "COLOR CYCLING:", divider + 9 cycling actions
CONST PSM_SIZE_ROWS = 4 ' rows 0..3 open a value flyout; the rest run an action
CONST PSM_ACT_BASE = 10000 ' root value of a cycling row = PSM_ACT_BASE + action id
PSM.subRow = -1: PSM.rHover = -1: PSM.sbHover = -1
