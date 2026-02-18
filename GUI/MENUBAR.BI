''
' DRAW - GUI/MENUBAR.BI
' =============================================================================
' Menu bar declarations - provides a traditional top-of-screen menu bar with
' dropdown submenus, checkboxes, dividers, hotkey display, and full keyboard
' navigation.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Menu bar constants
CONST MENU_MAX_ITEMS = 200         ' Max menu items across all menus
CONST MENU_MAX_ROOT = 10           ' Max root-level menu entries
CONST MENU_BAR_HEIGHT = 12         ' 8px Tiny5 font + 4px padding
CONST MENU_ITEM_HEIGHT = 12        ' Height of each submenu item row
CONST MENU_DIVIDER_HEIGHT = 5      ' Height of a divider row
CONST MENU_PAD_LEFT = 4            ' Left padding for root labels
CONST MENU_PAD_RIGHT = 4           ' Right padding for root labels
CONST MENU_ROOT_GAP = 8            ' Gap between root menu labels
CONST MENU_SUB_PAD_LEFT = 16       ' Left padding in submenu (room for checkbox)
CONST MENU_SUB_PAD_RIGHT = 8       ' Right padding after hotkey text
CONST MENU_SUB_HOTKEY_GAP = 16     ' Gap between label and hotkey column
CONST MENU_CHECK_WIDTH = 12        ' Width reserved for checkbox area

' Menu item structure
TYPE MENU_ITEM_OBJ
    label       AS STRING * 32     ' Display name ("---" = divider)
    hotkey      AS STRING * 24     ' Hotkey display string
    statusText  AS STRING * 48     ' Status bar text (optional)
    parentIdx   AS INTEGER         ' -1 = root item, else index of parent root
    actionId    AS INTEGER         ' Links to CMD_execute_action
    hasCheckbox AS INTEGER         ' Show checkbox
    checked     AS INTEGER         ' Checkbox state
    enabled     AS INTEGER         ' Greyed out if FALSE
    isDivider   AS INTEGER         ' Is a divider line
END TYPE

' Menu bar state
TYPE MENU_BAR_OBJ
    visible     AS INTEGER         ' Show/hide the entire menu bar
    openMenu    AS INTEGER         ' Index of currently open root menu (-1 = none)
    hoverRoot   AS INTEGER         ' Currently hovered root item (-1 = none)
    hoverSub    AS INTEGER         ' Currently hovered submenu item idx (-1 = none)
    subScroll   AS INTEGER         ' Submenu scroll offset
    fontHandle  AS LONG            ' Tiny5 font handle
    ' Bar geometry (recalculated each render)
    barX        AS INTEGER
    barY        AS INTEGER
    barW        AS INTEGER
    barH        AS INTEGER
    ' Current submenu geometry
    subX        AS INTEGER
    subY        AS INTEGER
    subW        AS INTEGER
    subH        AS INTEGER
    subItemCount AS INTEGER        ' Number of items in current open submenu
    ' State
    stayOpen    AS INTEGER         ' Keep menu open after click (click-to-open mode)
    altWasDown  AS INTEGER         ' Track ALT key for tap detection
    altTapped   AS INTEGER         ' ALT was tapped (no other key pressed while held)
    kbActive    AS INTEGER         ' Keyboard navigation active (ignore mouse until it moves)
    lastMouseX  AS INTEGER         ' Last mouse X for detecting actual movement
    lastMouseY  AS INTEGER         ' Last mouse Y for detecting actual movement
    ' Recent files submenu state
    recentOpen  AS INTEGER         ' TRUE when Recent Files submenu is showing
    recentHover AS INTEGER         ' Hovered item in Recent submenu (-1 = none)
    recentX     AS INTEGER         ' Recent submenu X position
    recentY     AS INTEGER         ' Recent submenu Y position
    recentW     AS INTEGER         ' Recent submenu width
    recentH     AS INTEGER         ' Recent submenu height
    recentItemIdx AS INTEGER       ' Child index of "RECENT" item in parent dropdown
END TYPE

DIM SHARED MENU_BAR AS MENU_BAR_OBJ
DIM SHARED MENU_ITEMS(MENU_MAX_ITEMS) AS MENU_ITEM_OBJ
DIM SHARED MENU_ITEM_COUNT AS INTEGER

' Precomputed root label positions
DIM SHARED MENU_ROOT_X(MENU_MAX_ROOT) AS INTEGER       ' X position of each root label
DIM SHARED MENU_ROOT_W(MENU_MAX_ROOT) AS INTEGER       ' Width of each root label area
DIM SHARED MENU_ROOT_LABEL(MENU_MAX_ROOT) AS STRING * 16 ' Cached trimmed root labels
DIM SHARED MENU_ROOT_COUNT AS INTEGER                   ' Number of root items
DIM SHARED MENU_ROOT_IDX(MENU_MAX_ROOT) AS INTEGER      ' Index into MENU_ITEMS for each root
DIM SHARED MENU_ROOT_ENABLED(MENU_MAX_ROOT) AS INTEGER  ' Whether each root menu is enabled

' Sub declarations
DECLARE SUB MENUBAR_init ()
DECLARE SUB MENUBAR_register_all ()
DECLARE SUB MENUBAR_register_item (label AS STRING, hotkey AS STRING, parentIdx AS INTEGER, actionId AS INTEGER, hasCheckbox AS INTEGER, isDivider AS INTEGER)
DECLARE SUB MENUBAR_render ()
DECLARE SUB MENUBAR_render_submenu (rootIdx AS INTEGER)
DECLARE SUB MENUBAR_update_bar_geometry ()
DECLARE SUB MENUBAR_update_checkboxes ()
DECLARE SUB MENUBAR_handle_click (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB MENUBAR_handle_mouse_move (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB MENUBAR_close_all ()
DECLARE FUNCTION MENUBAR_handle_key% (k AS LONG)
DECLARE FUNCTION MENUBAR_in_bounds% (rawX AS INTEGER, rawY AS INTEGER)
DECLARE FUNCTION MENUBAR_submenu_in_bounds% (rawX AS INTEGER, rawY AS INTEGER)
DECLARE FUNCTION MENUBAR_is_open% ()
DECLARE FUNCTION MENUBAR_get_submenu_item_at% (rawY AS INTEGER)
DECLARE SUB MENUBAR_render_recent_submenu ()
DECLARE SUB MENUBAR_handle_recent_click (rawX AS INTEGER, rawY AS INTEGER)
DECLARE FUNCTION MENUBAR_recent_in_bounds% (rawX AS INTEGER, rawY AS INTEGER)

