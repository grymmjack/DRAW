''
' DRAW - GUI/COMMAND.BI
' =============================================================================
' Command palette declarations - provides searchable command list with hotkey
' reference, inspired by VS Code's CTRL+SHIFT+P command palette.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Maximum number of commands and search results
CONST CMD_MAX_COMMANDS = 200
CONST CMD_MAX_VISIBLE = 15
CONST CMD_MAX_SEARCH = 64

' Command categories
CONST CMD_CAT_TOOL = 1
CONST CMD_CAT_FILE = 2
CONST CMD_CAT_EDIT = 3
CONST CMD_CAT_VIEW = 4
CONST CMD_CAT_COLOR = 5
CONST CMD_CAT_BRUSH = 6
CONST CMD_CAT_LAYER = 7
CONST CMD_CAT_CANVAS = 8
CONST CMD_CAT_ASSIST = 9
CONST CMD_CAT_CUSTOM = 10
CONST CMD_CAT_GRID = 11
CONST CMD_CAT_SYMM = 12
CONST CMD_CAT_SELECT = 13
CONST CMD_CAT_HELP = 14

' Command structure
TYPE CMD_OBJ
    name AS STRING * 48          ' Display name
    hotkey AS STRING * 24        ' Hotkey display (e.g., "Ctrl+S")
    category AS INTEGER          ' Category constant
    action_id AS INTEGER         ' Unique action ID for execution
    enabled AS INTEGER           ' Whether command is currently available
END TYPE

' Command palette state
TYPE CMD_PALETTE_OBJ
    visible AS INTEGER           ' Is palette visible?
    search AS STRING * 64        ' Current search string
    search_len AS INTEGER        ' Length of search string
    hover AS INTEGER             ' Currently hovered item
    scroll AS INTEGER            ' Scroll offset
    result_count AS INTEGER      ' Number of filtered results
    mode AS INTEGER              ' 0=command palette, 1=quick reference (no search)
END TYPE

DIM SHARED CMD_PALETTE AS CMD_PALETTE_OBJ
DIM SHARED CMD_LIST(CMD_MAX_COMMANDS) AS CMD_OBJ
DIM SHARED CMD_RESULTS(CMD_MAX_COMMANDS) AS INTEGER    ' Indices into CMD_LIST
DIM SHARED CMD_COUNT AS INTEGER                        ' Total registered commands
DIM SHARED CMD_FONT_HANDLE AS LONG                     ' Tiny5 font handle

' Palette positioning
DIM SHARED CMD_PALETTE_X AS INTEGER
DIM SHARED CMD_PALETTE_Y AS INTEGER
DIM SHARED CMD_PALETTE_W AS INTEGER
DIM SHARED CMD_PALETTE_H AS INTEGER

' Function declarations
DECLARE SUB CMD_init ()
DECLARE SUB CMD_register (cmd_name AS STRING, cmd_hotkey AS STRING, cmd_category AS INTEGER, cmd_action_id AS INTEGER)
DECLARE SUB CMD_show_palette ()
DECLARE SUB CMD_show_quick_ref ()
DECLARE SUB CMD_hide ()
DECLARE SUB CMD_render (dest AS LONG)
DECLARE SUB CMD_handle_key (keypress AS STRING)
DECLARE SUB CMD_handle_click (x AS INTEGER, y AS INTEGER)
DECLARE SUB CMD_navigate_up ()
DECLARE SUB CMD_navigate_down ()
DECLARE SUB CMD_navigate_page_up ()
DECLARE SUB CMD_navigate_page_down ()
DECLARE SUB CMD_execute_selected ()
DECLARE SUB CMD_execute_action (action_id AS INTEGER)
DECLARE SUB CMD_update_search ()
DECLARE FUNCTION CMD_fuzzy_match% (searchStr AS STRING, targetStr AS STRING)
DECLARE FUNCTION CMD_in_bounds% (x AS INTEGER, y AS INTEGER)
DECLARE FUNCTION CMD_category_name$ (cat AS INTEGER)
