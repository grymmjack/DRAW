''
' DRAW - CORE/SOUND.BI
' =============================================================================
' Sound system declarations.
' Manages pre-loaded, volume-adjusted sound handles for all UI sound categories.
' All sounds are loaded from the active theme's SOUNDS/ directory.
' Volume is applied at load time and re-applied via SOUND_apply_volume when
' CFG.SOUNDS_VOLUME changes.
'
' @author Rick Christy <grymmjack@gmail.com>
'

$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY

' ---------------------------------------------------------------------------
' Sound category constants (indices into SOUND_HANDLES array)
' ---------------------------------------------------------------------------
CONST SND_MENU_OPEN   = 1   ' Opening a root menu
CONST SND_MENU_SELECT = 2   ' Selecting a menu item
CONST SND_NEW_FILE    = 3   ' New file / startup
CONST SND_NEW_LAYER   = 4   ' New layer
CONST SND_LAYER_OP    = 5   ' Delete / arrange / duplicate / merge layer
CONST SND_CLIPBOARD   = 6   ' Copy / Cut / Paste
CONST SND_FILL        = 7   ' Flood fill
CONST SND_SELECTION   = 8   ' Selection operations
CONST SND_DRAW        = 9   ' Brush / dot / spray initial click
CONST SND_TRANSFORM   = 10  ' Flip / scale / rotate / Help About
CONST SND_TEXT_ENTER  = 11  ' Text tool — commit line (Enter key)
CONST SND_MENU_HOVER  = 12  ' Hovering over a new menu item (root switch or sub-item)
CONST SND_TOOL_SELECT = 13  ' Toolbox button clicked
CONST SND_TEXT_CHAR   = 14  ' Text tool — printable character typed
CONST SND_ERASER      = 15  ' Eraser stroke initial click
CONST SND_DRAW_REV    = 16  ' Reversed draw sound (played on cardinal direction change)
CONST SND_ERASER_REV  = 17  ' Reversed eraser sound (played on cardinal direction change)
CONST SND_SLIDER      = 18  ' Opacity / value slider drag
CONST SND_DRAG_DROP   = 19  ' Layer drag-and-drop reorder
CONST SND_POINT       = 20  ' Click to place a point (line / shape / poly tools)
CONST SND_ORGANIZER   = 21  ' Organizer / drawer widget click or mousewheel

CONST SND_COUNT       = 21  ' Total number of sound categories

DIM SHARED SOUND_HANDLES(1 TO SND_COUNT) AS LONG

DECLARE SUB SOUND_init ()
DECLARE SUB SOUND_play (category AS INTEGER)
DECLARE SUB SOUND_play_pitched (category AS INTEGER, speedMin AS SINGLE, speedMax AS SINGLE, vol AS SINGLE)
DECLARE SUB SOUND_loop (category AS INTEGER)
DECLARE SUB SOUND_stop (category AS INTEGER)
DECLARE SUB SOUND_apply_volume ()
DECLARE SUB SOUND_close_all ()
