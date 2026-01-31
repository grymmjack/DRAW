''
' DRAW - TOOLS/TEXT.BI
' =============================================================================
' Text tool - places text on the canvas.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE TEXT_OBJ
    ACTIVE       AS INTEGER  ' Whether text tool is active and editing
    START_X      AS INTEGER  ' Initial click X position (left margin)
    START_Y      AS INTEGER  ' Initial click Y position (first line)
    CURSOR_X     AS INTEGER  ' Current cursor X position
    CURSOR_Y     AS INTEGER  ' Current cursor Y position
    TEXT_SIZE    AS INTEGER  ' Text size multiplier (1 = default)
    MAX_LINES    AS INTEGER  ' Maximum number of lines
    LINE_COUNT   AS INTEGER  ' Current number of lines
    CURSOR_BLINK AS INTEGER  ' Cursor blink state (0 or 1)
    BLINK_TIMER  AS SINGLE   ' Timer for cursor blinking
    USE_TINY5    AS INTEGER  ' Whether to use Tiny5 font (vs VGA default)
    FONT_HANDLE  AS LONG     ' Handle to loaded Tiny5 font
    USE_CUSTOM   AS INTEGER  ' Whether to use custom font loaded from disk
    CUSTOM_FONT_HANDLE AS LONG  ' Handle to custom font loaded via middle-click
    CHAR_WIDTH   AS INTEGER  ' Character width (5 for Tiny5, 8 for VGA)
    LINE_HEIGHT  AS INTEGER  ' Line height (8 for Tiny5, 13 for VGA)
END TYPE

' Text buffer declared in _COMMON.BI
DIM SHARED TEXT AS TEXT_OBJ

DECLARE SUB TEXT_init ()
DECLARE SUB TEXT_reset ()
DECLARE SUB TEXT_start (x AS INTEGER, y AS INTEGER)
DECLARE SUB TEXT_add_char (ch AS STRING)
DECLARE SUB TEXT_backspace ()
DECLARE SUB TEXT_newline ()
DECLARE SUB TEXT_apply ()
DECLARE SUB TEXT_cancel ()
DECLARE SUB TEXT_render_preview (dest AS LONG)
DECLARE SUB TEXT_update_cursor ()
