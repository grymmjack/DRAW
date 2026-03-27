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
    CUSTOM_FONT_PATH AS STRING * 260  ' Path of the active custom font for export/replay
    CUSTOM_FONT_SIZE AS INTEGER  ' Loaded custom font size for export/replay
    CHAR_WIDTH   AS INTEGER  ' Character width (5 for Tiny5, 8 for VGA)
    LINE_HEIGHT  AS INTEGER  ' Line height (8 for Tiny5, 13 for VGA)
    ' --- Rich text layer integration (Phase 4) ---
    editingTextLayer AS INTEGER  ' Layer index being edited (0 = none, for re-edit)
    selStart     AS INTEGER  ' Selection start char index (-1 = no selection)
    selEnd       AS INTEGER  ' Selection end char index (-1 = no selection)
    selActive    AS INTEGER  ' TRUE when text selection is active
    OVERFLOW_FLASH AS INTEGER ' Countdown frames for overflow visual feedback
    cmVirtualCol AS INTEGER   ' Char mode virtual cursor column (grid position)
    cmVirtualRow AS INTEGER   ' Char mode virtual cursor row (grid position)
END TYPE

' Text buffer declared in _COMMON.BI
DIM SHARED TEXT AS TEXT_OBJ

' Cached text preview image (avoids per-frame _NEWIMAGE/_FREEIMAGE)
DIM SHARED TEXT_PREVIEW_CACHE AS LONG
DIM SHARED TEXT_PREVIEW_CACHE_W AS INTEGER
DIM SHARED TEXT_PREVIEW_CACHE_H AS INTEGER

' Internal rich clipboard — preserves per-character formatting across Cut/Copy/Paste
DIM SHARED TEXT_CLIP_COUNT AS INTEGER           ' number of chars stored
DIM SHARED TEXT_CLIP_PLAIN AS STRING            ' plain text mirror (to detect external clipboard changes)
DIM SHARED TEXT_CLIP_CHAR(0 TO TEXT_LAYER_MAX_CHARS - 1) AS STRING * 1
DIM SHARED TEXT_CLIP_FG(0 TO TEXT_LAYER_MAX_CHARS - 1) AS _UNSIGNED LONG
DIM SHARED TEXT_CLIP_BG(0 TO TEXT_LAYER_MAX_CHARS - 1) AS _UNSIGNED LONG
DIM SHARED TEXT_CLIP_FONT_IDX(0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TEXT_CLIP_FONT_SIZE(0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TEXT_CLIP_BOLD(0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TEXT_CLIP_ITALIC(0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TEXT_CLIP_UNDERLINE(0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TEXT_CLIP_STRIKE(0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TEXT_CLIP_KERN(0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TEXT_CLIP_BASELINE(0 TO TEXT_LAYER_MAX_CHARS - 1) AS INTEGER
DIM SHARED TEXT_CLIP_OUTLINE(0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE
DIM SHARED TEXT_CLIP_OUTLINE_COLOR(0 TO TEXT_LAYER_MAX_CHARS - 1) AS _UNSIGNED LONG
DIM SHARED TEXT_CLIP_OUTLINE_SIZE(0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE
DIM SHARED TEXT_CLIP_SHADOW(0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE
DIM SHARED TEXT_CLIP_SHADOW_COLOR(0 TO TEXT_LAYER_MAX_CHARS - 1) AS _UNSIGNED LONG
DIM SHARED TEXT_CLIP_SHADOW_X(0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE
DIM SHARED TEXT_CLIP_SHADOW_Y(0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE

DECLARE SUB TEXT_init ()
DECLARE SUB TEXT_reset ()
DECLARE SUB TEXT_start (x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION TEXT_get_active_text_data_idx% ()
DECLARE SUB TEXT_add_char (ch AS STRING)
DECLARE SUB TEXT_backspace ()
DECLARE SUB TEXT_newline ()
DECLARE SUB TEXT_apply ()
DECLARE SUB TEXT_cancel ()
DECLARE SUB TEXT_commit ()
DECLARE SUB TEXT_re_edit (layerIdx AS INTEGER)
DECLARE SUB TEXT_render_preview (dest AS LONG, dx AS INTEGER, dy AS INTEGER, zoom AS SINGLE)
DECLARE SUB TEXT_update_cursor ()
DECLARE SUB TEXT_clear_selection ()
DECLARE FUNCTION TEXT_has_selection% ()
DECLARE SUB TEXT_delete_selection ()
DECLARE SUB TEXT_sync_bar_to_cursor ()
DECLARE FUNCTION TEXT_char_mode_active% ()
DECLARE FUNCTION TEXT_char_mode_cursor_col% ()
DECLARE FUNCTION TEXT_char_mode_cursor_row% ()
DECLARE SUB TEXT_char_mode_sync_virtual ()
DECLARE SUB TEXT_char_mode_set_cursor (col AS INTEGER, row AS INTEGER, expand AS INTEGER)
DECLARE SUB TEXT_char_mode_move_cursor (deltaCol AS INTEGER, deltaRow AS INTEGER, expand AS INTEGER)
DECLARE FUNCTION TEXT_char_mode_grid_to_pos% (tdIdx AS INTEGER, col AS INTEGER, row AS INTEGER)
DECLARE SUB TEXT_char_mode_add_char (ch AS STRING)
DECLARE SUB TEXT_char_mode_backspace ()
DECLARE SUB TEXT_char_mode_delete ()
DECLARE SUB TEXT_char_mode_delete_selection ()
DECLARE SUB TEXT_char_mode_trim_trailing (tdIdx AS INTEGER)
DECLARE FUNCTION TEXT_char_mode_on_text_layer% ()
DECLARE SUB TEXT_char_mode_fill_cells (x1 AS INTEGER, y1 AS INTEGER, x2 AS INTEGER, y2 AS INTEGER, filled AS INTEGER)
