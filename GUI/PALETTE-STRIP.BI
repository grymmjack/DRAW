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

' Palette strip constants
CONST PALETTE_STRIP_SWATCH_SIZE = 5       ' Tiny chips to fit 64+ colors
CONST PALETTE_STRIP_ARROW_WIDTH = 10
CONST PALETTE_STRIP_ROW_HEIGHT = 7        ' Height per row (swatch + 2px gap)
' PALETTE_STRIP_HEIGHT is now calculated dynamically based on palette size
CONST PALETTE_MENU_MIN_WIDTH = 180        ' Minimum menu width for full names

' Palette menu state
DIM SHARED PALETTE_MENU_VISIBLE%
DIM SHARED PALETTE_MENU_X%
DIM SHARED PALETTE_MENU_Y%
DIM SHARED PALETTE_MENU_W%
DIM SHARED PALETTE_MENU_H%
DIM SHARED PALETTE_MENU_SCROLL%
DIM SHARED PALETTE_MENU_HOVER%

' State
DIM SHARED PALETTE_STRIP_VISIBLE%
DIM SHARED PALETTE_STRIP_Y%
DIM SHARED PALETTE_STRIP_HOVER_IDX%
DIM SHARED PALETTE_STRIP_SCROLL_OFFSET%
DIM SHARED PALETTE_STRIP_FONT&

' Declarations
DECLARE SUB PALETTE_STRIP_init ()
DECLARE SUB PALETTE_STRIP_render ()
DECLARE SUB PALETTE_STRIP_handle_click (x AS INTEGER, y AS INTEGER)
DECLARE SUB PALETTE_STRIP_handle_wheel (direction AS INTEGER)
DECLARE FUNCTION PALETTE_STRIP_in_bounds% (x AS INTEGER, y AS INTEGER)
DECLARE SUB PALETTE_MENU_show ()
DECLARE SUB PALETTE_MENU_hide ()
DECLARE SUB PALETTE_MENU_render ()
DECLARE SUB PALETTE_MENU_handle_click (x AS INTEGER, y AS INTEGER)
DECLARE SUB PALETTE_MENU_handle_wheel (direction AS INTEGER)
DECLARE FUNCTION PALETTE_MENU_in_bounds% (x AS INTEGER, y AS INTEGER)
