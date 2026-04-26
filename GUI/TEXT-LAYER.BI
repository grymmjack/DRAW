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
CONST TEXT_LAYER_MAX_CHARS = 4096 ' Max characters per text layer
CONST TEXT_LAYER_MAX_LINES = 256  ' Max lines per text layer
CONST TEXT_LAYER_POOL_SIZE = 64   ' One slot per possible layer

' Text alignment constants
CONST TEXT_ALIGN_LEFT   = 0
CONST TEXT_ALIGN_CENTER = 1
CONST TEXT_ALIGN_RIGHT  = 2

TYPE TEXT_LAYER_OBJ
    used             AS INTEGER ' TRUE if this pool slot is in use
    startX           AS INTEGER ' Canvas X origin of text block
    startY           AS INTEGER ' Canvas Y origin of text block
    charCount        AS INTEGER ' Number of characters in this text layer
    lineCount        AS INTEGER ' Number of lines (>= 1 when used)
    fontIdx          AS INTEGER ' Default font index for new chars
    fontSize         AS INTEGER ' Default font size for new chars
    defaultLeading   AS INTEGER ' Default line spacing in px (default = fontSize + 1)
    cursorPos        AS INTEGER ' Cursor position (0-based char index)
    dirty            AS INTEGER ' TRUE when text data changed, triggers re-render
    monospace        AS INTEGER ' TRUE to load all fonts with MONOSPACE flag
    alignment        AS INTEGER ' 0 = LEFT, 1 = CENTER, 2 = RIGHT (per-layer)
    antialias        AS _BYTE   ' 0 = OFF (crisp pixels), 1 = ON (smooth). Default ON.
    outlineCharCount AS INTEGER ' Pre-counted : chars with outline = 1 (CPU : skip pass when 0)
    shadowCharCount  AS INTEGER ' Pre-counted : chars with shadow = 1 (CPU : skip pass when 0)
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

' Per-character outline attributes
DIM SHARED TL_OUTLINE(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE
DIM SHARED TL_OUTLINE_COLOR(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS _UNSIGNED LONG
DIM SHARED TL_OUTLINE_SIZE(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE

' Per-character shadow attributes
DIM SHARED TL_SHADOW(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE
DIM SHARED TL_SHADOW_COLOR(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS _UNSIGNED LONG
DIM SHARED TL_SHADOW_X(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE
DIM SHARED TL_SHADOW_Y(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_CHARS - 1) AS _BYTE

' Per-line leading (line spacing override per line)
DIM SHARED TL_LEADING(1 TO TEXT_LAYER_POOL_SIZE, 0 TO TEXT_LAYER_MAX_LINES - 1) AS INTEGER

' Faux italic shear: set by TEXT_LAYER_render before calling draw_bitmap_char
' When > 0, draw_bitmap_char applies horizontal shear for faux italic
DIM SHARED TEXT_LAYER_FAUX_ITALIC_SHEAR AS INTEGER

' Force tint mode: when TRUE, CBF fonts use fgColor tinting instead of original colors.
' Set by shadow/outline passes to ensure they render in the chosen shadow/outline color.
DIM SHARED TEXT_LAYER_FORCE_TINT AS INTEGER

' Function declarations
