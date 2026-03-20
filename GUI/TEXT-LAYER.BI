''
' DRAW - GUI/TEXT-LAYER.BI
' =============================================================================
' Non-destructive text layer data structures.
' Per-character parallel arrays for rich text formatting + typography controls.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Limits
CONST TEXT_LAYER_MAX_CHARS = 4096  ' Max characters per text layer
CONST TEXT_LAYER_MAX_LINES = 256   ' Max lines per text layer
CONST TEXT_LAYER_POOL_SIZE = 64    ' One slot per possible layer

TYPE TEXT_LAYER_OBJ
    used         AS INTEGER    ' TRUE if this pool slot is in use
    startX       AS INTEGER    ' Canvas X origin of text block
    startY       AS INTEGER    ' Canvas Y origin of text block
    charCount    AS INTEGER    ' Number of characters in this text layer
    lineCount    AS INTEGER    ' Number of lines (>= 1 when used)
    fontIdx      AS INTEGER    ' Default font index for new chars
    fontSize     AS INTEGER    ' Default font size for new chars
    defaultLeading AS INTEGER  ' Default line spacing in px (default = fontSize + 4)
    cursorPos    AS INTEGER    ' Cursor position (0-based char index)
    dirty        AS INTEGER    ' TRUE when text data changed, triggers re-render
END TYPE

' Pool of text layer data (indexed by DRAW_LAYER.textDataIdx)
DIM SHARED TEXT_LAYER_DATA(1 TO TEXT_LAYER_POOL_SIZE) AS TEXT_LAYER_OBJ

' Line break positions (char index where each line starts)
DIM SHARED TL_LINE_BREAK(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_LINES - 1) AS INTEGER

' Per-character attribute parallel arrays
' (pool slot index, char index) — 64 slots × 4096 chars each
DIM SHARED TL_CHAR(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS STRING * 1
DIM SHARED TL_FG(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS _UNSIGNED LONG
DIM SHARED TL_BG(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS _UNSIGNED LONG
DIM SHARED TL_FONT_IDX(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TL_FONT_SIZE(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TL_BOLD(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TL_ITALIC(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TL_UNDERLINE(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TL_STRIKE(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TL_KERN(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TL_BASELINE(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER

' Per-line leading (line spacing override per line)
DIM SHARED TL_LEADING(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_LINES - 1) AS INTEGER

' Function declarations
DECLARE FUNCTION TEXT_LAYER_alloc% ()
DECLARE SUB TEXT_LAYER_free (idx AS INTEGER)
DECLARE SUB TEXT_LAYER_render (idx AS INTEGER, destImg AS LONG)
DECLARE SUB TEXT_LAYER_add_char (idx AS INTEGER, ch AS STRING)
DECLARE SUB TEXT_LAYER_delete_char (idx AS INTEGER)
DECLARE SUB TEXT_LAYER_newline (idx AS INTEGER)
DECLARE SUB TEXT_LAYER_set_selection_attr (idx AS INTEGER, startChar AS INTEGER, endChar AS INTEGER, attrName AS STRING, value AS LONG)
DECLARE FUNCTION TEXT_LAYER_get_char_at_pos% (idx AS INTEGER, canvasX AS INTEGER, canvasY AS INTEGER)
DECLARE SUB TEXT_LAYER_rasterize (layerIdx AS INTEGER)
DECLARE FUNCTION TEXT_LAYER_get_line_y% (idx AS INTEGER, lineNum AS INTEGER)
DECLARE FUNCTION TEXT_LAYER_get_char_x% (idx AS INTEGER, charIdx AS INTEGER)
DECLARE FUNCTION TEXT_LAYER_get_line_for_char% (idx AS INTEGER, charIdx AS INTEGER)
DECLARE SUB TEXT_LAYER_copy_data (srcIdx AS INTEGER, destIdx AS INTEGER)
