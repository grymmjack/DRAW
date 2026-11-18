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

CONST POPUP_MENU_MAX_ITEMS = 64 ' (the layer menu passed 40 with the record item - 2026-11-16)

DIM SHARED POPUP_MENU_LABELS(0 TO POPUP_MENU_MAX_ITEMS - 1) AS STRING * 64
DIM SHARED POPUP_MENU_HOTKEYS(0 TO POPUP_MENU_MAX_ITEMS - 1) AS STRING * 24
DIM SHARED POPUP_MENU_VALUES(0 TO POPUP_MENU_MAX_ITEMS - 1) AS INTEGER
DIM SHARED POPUP_MENU_FLAGS(0 TO POPUP_MENU_MAX_ITEMS - 1) AS INTEGER

' Popups drawn this frame (POPUP_MENU_render notes its box): the floating /
' docked windows draw on screen 0 above SCRN.CANVAS&, so POPUP_reblit_to_screen0
' copies every open popup / menu back on top of them afterwards (windows no
' longer hide while a menu is open). Cleared at the top of SCREEN_render.
CONST POPUP_NOTE_MAX = 16
DIM SHARED POPUP_NOTE_N AS INTEGER
DIM SHARED POPUP_NOTE_X(0 TO POPUP_NOTE_MAX - 1) AS INTEGER
DIM SHARED POPUP_NOTE_Y(0 TO POPUP_NOTE_MAX - 1) AS INTEGER
DIM SHARED POPUP_NOTE_W(0 TO POPUP_NOTE_MAX - 1) AS INTEGER
DIM SHARED POPUP_NOTE_H(0 TO POPUP_NOTE_MAX - 1) AS INTEGER
' what POPUP_reblit_to_screen0 drew on top last frame (QA dump POPUP lines)
CONST POPUP_SHOWN_MAX = 24
DIM SHARED POPUP_SHOWN_N AS INTEGER
DIM SHARED POPUP_SHOWN_KIND(0 TO POPUP_SHOWN_MAX - 1) AS STRING
DIM SHARED POPUP_SHOWN_X(0 TO POPUP_SHOWN_MAX - 1) AS INTEGER
DIM SHARED POPUP_SHOWN_Y(0 TO POPUP_SHOWN_MAX - 1) AS INTEGER
DIM SHARED POPUP_SHOWN_W(0 TO POPUP_SHOWN_MAX - 1) AS INTEGER
DIM SHARED POPUP_SHOWN_H(0 TO POPUP_SHOWN_MAX - 1) AS INTEGER

''
' Resets all popup menu item slots to empty labels, no hotkeys, value -1, and flags 0.
'
''
' Populates a single popup menu slot with label text, hotkey hint, action value, and flags.
' @param itemIndex INTEGER Zero-based slot index (0 .. POPUP_MENU_MAX_ITEMS - 1)
' @param itemLabel STRING Display text for the menu item
' @param itemHotkey STRING Right-aligned hotkey hint text (may be empty)
' @param itemValue INTEGER Application-defined value returned on click
' @param itemFlags INTEGER Bitmask of POPUP_MENU_FLAG_* constants (DIVIDER, DISABLED, CHECKED)
'
''
' Measures the minimum pixel width needed to display all item labels and hotkey hints.
' @param itemCount INTEGER Number of populated menu items to measure
' @param fontHandle LONG Font handle to use for text measurement (0 for current font)
' @return INTEGER - Required popup width in pixels (minimum 90)
'
''
' Calculates the total pixel height of the popup, using itemHeight for normal rows
' and MENU_DIVIDER_HEIGHT for divider rows, plus 4px vertical padding.
' @param itemCount INTEGER Number of populated menu items
' @param itemHeight INTEGER Height in pixels for each non-divider row
' @return INTEGER - Total popup height in pixels
'
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

' ---------------------------------------------------------------------------
' The popup registry: every menu / popup DRAW opens over the screen, one id
' each. A popup is listed ONCE - a CONST here and a CASE in POPUP_k_open%,
' POPUP_k_stage%, POPUP_k_render and POPUP_k_name$ (GUI/POPUP-MENU.BM) - and
' everything that has to know about popups asks the registry:
'   POPUP_any_open%       a press is the menu's (WINZ raise, dock edges,
'                         pointer shape, picker loupe, QA dump)
'   POPUP_blocks_partial% the cursor-only redraw paths of SCREEN_render copy
'                         cached pixels over it (black boxes): off while open
'   POPUP_tips_blocked%   TOOLTIP_render holds off
'   POPUP_render_top      the popups over the GUI, scroll bars and status hints
'                         (both full-render paths of SCREEN_render)
'   POPUP_render_gui      the ones drawn into SCRN.GUI& after the menu bar
' POPUP_reblit_to_screen0 then copies every open one back over the windows.
' (2026-11-15: the hand-kept lists drifted - the color strip's size menu was
' in 2 of 9, so the strip covered it, the fast paths left black boxes on it
' and tooltips showed through.)
' The ids are the z order: a later one draws over an earlier one.
' ---------------------------------------------------------------------------
CONST POPUP_K_MENUBAR = 1      ' menu bar dropdown + flyouts + overflow (MENUBAR_render draws them with the bar)
CONST POPUP_K_PALETTE_MENU = 2 ' the palette menu (over the menu bar)
CONST POPUP_K_SUBTOOL = 3      ' the subtool flyout (held open with B1: tooltips show over it)
CONST POPUP_K_LB_MENU = 4      ' the lightbox's loop / X-sheet sound menu (TOOLS/ANIM-LB)
CONST POPUP_K_LAYER_BLEND = 5  ' the layer blend mode popup
CONST POPUP_K_LAYER_CTX = 6    ' the layer panel's context menus
CONST POPUP_K_DRAWER_CTX = 7   ' the Drawer's context menu
CONST POPUP_K_STRIP_SIZE = 8   ' the color strip's size menu (GUI/PALETTE-STRIP PSM_)
CONST POPUP_K_DOCK_MENU = 9    ' a dock handle / workflow button menu
CONST POPUP_K_CMD_PALETTE = 10 ' the command palette
CONST POPUP_K_SWATCHES = 11    ' a Swatches panel menu (on the panel's own image)
CONST POPUP_K_TEXT_BAR = 12    ' the text bar's font / size / style dropdowns (TEXT_BAR_render draws them; TBDD_ boxes)
CONST POPUP_K_COUNT = 12
CONST POPUP_STAGE_GUI = 1 ' drawn into SCRN.GUI& (composited with the chrome)
CONST POPUP_STAGE_TOP = 2 ' drawn on SCRN.CANVAS& after the GUI, scroll bars, status hints
CONST POPUP_STAGE_OWN = 3 ' drawn by its panel on the panel's own window
