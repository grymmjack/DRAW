''
' DRAW - GUI/STATUS.BI
' =============================================================================
' UDT for status.
'
' @todo
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

' Global variables to store swatch positions
DIM SHARED STATUS_TRANS_SWATCH_X AS INTEGER
DIM SHARED STATUS_TRANS_SWATCH_Y AS INTEGER
DIM SHARED STATUS_FG_SWATCH_X AS INTEGER
DIM SHARED STATUS_FG_SWATCH_Y AS INTEGER
DIM SHARED STATUS_BG_SWATCH_X AS INTEGER
DIM SHARED STATUS_BG_SWATCH_Y AS INTEGER

' Font handle for status bar
DIM SHARED STATUS_FONT AS LONG
CONST STATUS_FONT_SIZE = 8

DECLARE SUB STATUS_init ()
DECLARE SUB STATUS_handle_click (x AS INTEGER, y AS INTEGER)
