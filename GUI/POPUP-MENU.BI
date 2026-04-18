''
' DRAW - GUI/POPUP-MENU.BI
' =============================================================================
' Shared popup menu helpers used by lightweight context menus and popup overlays.
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

CONST POPUP_MENU_FLAG_DIVIDER  = 1
CONST POPUP_MENU_FLAG_DISABLED = 2
CONST POPUP_MENU_FLAG_CHECKED  = 4

CONST POPUP_MENU_MAX_ITEMS = 40

DIM SHARED POPUP_MENU_LABELS(0 TO POPUP_MENU_MAX_ITEMS - 1) AS STRING * 64
DIM SHARED POPUP_MENU_HOTKEYS(0 TO POPUP_MENU_MAX_ITEMS - 1) AS STRING * 24
DIM SHARED POPUP_MENU_VALUES(0 TO POPUP_MENU_MAX_ITEMS - 1) AS INTEGER
DIM SHARED POPUP_MENU_FLAGS(0 TO POPUP_MENU_MAX_ITEMS - 1) AS INTEGER

''
' Resets all popup menu item slots to empty labels, no hotkeys, value -1, and flags 0.
'
DECLARE SUB POPUP_MENU_clear_items ()
''
' Populates a single popup menu slot with label text, hotkey hint, action value, and flags.
' @param itemIndex INTEGER Zero-based slot index (0 .. POPUP_MENU_MAX_ITEMS - 1)
' @param itemLabel STRING Display text for the menu item
' @param itemHotkey STRING Right-aligned hotkey hint text (may be empty)
' @param itemValue INTEGER Application-defined value returned on click
' @param itemFlags INTEGER Bitmask of POPUP_MENU_FLAG_* constants (DIVIDER, DISABLED, CHECKED)
'
DECLARE SUB POPUP_MENU_set_item (itemIndex AS INTEGER, itemLabel AS STRING, itemHotkey AS STRING, itemValue AS INTEGER, itemFlags AS INTEGER)
''
' Measures the minimum pixel width needed to display all item labels and hotkey hints.
' @param itemCount INTEGER Number of populated menu items to measure
' @param fontHandle LONG Font handle to use for text measurement (0 for current font)
' @return INTEGER - Required popup width in pixels (minimum 90)
'
DECLARE FUNCTION POPUP_MENU_measure_width% (itemCount AS INTEGER, fontHandle AS LONG)
''
' Calculates the total pixel height of the popup, using itemHeight for normal rows
' and MENU_DIVIDER_HEIGHT for divider rows, plus 4px vertical padding.
' @param itemCount INTEGER Number of populated menu items
' @param itemHeight INTEGER Height in pixels for each non-divider row
' @return INTEGER - Total popup height in pixels
'
DECLARE FUNCTION POPUP_MENU_total_height% (itemCount AS INTEGER, itemHeight AS INTEGER)
''
' Positions the popup menu starting at the anchor point, clamping to viewport bounds.
' If the popup overflows right or bottom, it shifts left or flips above the anchor.
' @param anchorX INTEGER Desired left X in screen pixels
' @param anchorY INTEGER Desired top Y in screen pixels
' @param popupW INTEGER Popup width in pixels
' @param itemCount INTEGER Number of populated menu items
' @param itemHeight INTEGER Height in pixels for each non-divider row
' @param popupX INTEGER (out) Clamped left X position
' @param popupY INTEGER (out) Clamped top Y position
' @param popupH INTEGER (out) Computed popup height
'
DECLARE SUB POPUP_MENU_place (anchorX AS INTEGER, anchorY AS INTEGER, popupW AS INTEGER, itemCount AS INTEGER, itemHeight AS INTEGER, popupX AS INTEGER, popupY AS INTEGER, popupH AS INTEGER)
''
' Returns the action value of the menu item at the given screen coordinates.
' Returns -2 if the point is outside the popup entirely, or -1 if over a
' divider or disabled item.
' @param popupX INTEGER Popup left X
' @param popupY INTEGER Popup top Y
' @param popupW INTEGER Popup width
' @param itemCount INTEGER Number of populated menu items
' @param itemHeight INTEGER Height in pixels for each non-divider row
' @param rawX INTEGER Mouse X in screen pixels
' @param rawY INTEGER Mouse Y in screen pixels
' @return INTEGER - Item value, -1 (non-clickable), or -2 (outside popup)
'
DECLARE FUNCTION POPUP_MENU_hit_value% (popupX AS INTEGER, popupY AS INTEGER, popupW AS INTEGER, itemCount AS INTEGER, itemHeight AS INTEGER, rawX AS INTEGER, rawY AS INTEGER)
''
' Returns the zero-based row index of the enabled, non-divider menu item under the
' given screen coordinates, or -1 if the point is outside the popup or over a
' divider/disabled item.
' @param popupX INTEGER Popup left X
' @param popupY INTEGER Popup top Y
' @param popupW INTEGER Popup width
' @param itemCount INTEGER Number of populated menu items
' @param itemHeight INTEGER Height in pixels for each non-divider row
' @param rawX INTEGER Mouse X in screen pixels
' @param rawY INTEGER Mouse Y in screen pixels
' @return INTEGER - Row index (0-based), or -1 if no valid hover target
'
DECLARE FUNCTION POPUP_MENU_hover_row% (popupX AS INTEGER, popupY AS INTEGER, popupW AS INTEGER, itemCount AS INTEGER, itemHeight AS INTEGER, rawX AS INTEGER, rawY AS INTEGER)
''
' Renders the popup menu onto the given image destination, drawing background, border,
' dividers, hover highlight, checkmarks, labels, and right-aligned hotkey hints.
' Uses theme colors (MENU_SUB_*) for all visual elements.
' @param dest LONG Target image handle to draw on
' @param popupX INTEGER Popup left X
' @param popupY INTEGER Popup top Y
' @param popupW INTEGER Popup width
' @param itemCount INTEGER Number of populated menu items
' @param itemHeight INTEGER Height in pixels for each non-divider row
' @param hoverRow INTEGER Row index to highlight (-1 for none)
' @param fontHandle LONG Font handle to use for text rendering (0 for current font)
'
DECLARE SUB POPUP_MENU_render (dest AS LONG, popupX AS INTEGER, popupY AS INTEGER, popupW AS INTEGER, itemCount AS INTEGER, itemHeight AS INTEGER, hoverRow AS INTEGER, fontHandle AS LONG)