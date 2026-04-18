'
' DRAW - TOOLS/PICKER-LOUPE.BI
' =============================================================================
' Runtime state and declarations for the picker loupe overlay.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE PICKER_LOUPE_OBJ
    ACTIVE         AS INTEGER
    BUFFER         AS LONG
    BUFFER_W       AS INTEGER
    BUFFER_H       AS INTEGER
    TEXT_BUFFER    AS LONG
    TEXT_BUFFER_W  AS INTEGER
    TEXT_BUFFER_H  AS INTEGER
    FONT_HANDLE    AS LONG
    LAST_FONT_SIZE AS INTEGER
    SAMPLE_COLOR   AS _UNSIGNED LONG
END TYPE

DIM SHARED PICKER_LOUPE AS PICKER_LOUPE_OBJ
DIM SHARED PICKER_LOUPE_LAST_FONT$

DECLARE SUB PICKER_LOUPE_init ()
DECLARE SUB PICKER_LOUPE_activate ()
DECLARE SUB PICKER_LOUPE_deactivate ()
DECLARE SUB PICKER_LOUPE_render (dest AS LONG)

PICKER_LOUPE_init