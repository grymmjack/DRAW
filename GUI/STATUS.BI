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
DIM SHARED STATUS_FG_SWATCH_X    AS INTEGER
DIM SHARED STATUS_WS_BADGE_X1    AS INTEGER ' [WS: name] badge bounds (click = workspace switcher); X2 < X1 = none
DIM SHARED STATUS_WS_BADGE_X2    AS INTEGER
DIM SHARED STATUS_FG_SWATCH_Y    AS INTEGER
DIM SHARED STATUS_BG_SWATCH_X    AS INTEGER
DIM SHARED STATUS_BG_SWATCH_Y    AS INTEGER

' Transient status message (STATUS_flash): shown after the tool name until
' STATUS_FLASH_UNTIL (TIMER seconds); DRAW.BAS clears it and repaints on expiry.
DIM SHARED STATUS_FLASH_MSG   AS STRING
DIM SHARED STATUS_FLASH_UNTIL AS DOUBLE

' Font handle for status bar
DIM SHARED STATUS_FONT AS LONG
CONST STATUS_FONT_SIZE = 8

