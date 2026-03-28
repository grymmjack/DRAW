''
' DRAW - GUI/SETTINGS-WIDGETS.BI
' =============================================================================
' Widget type definitions and constants for the Settings dialog.
' Checkbox, radio group, dropdown, spinner, color chip, file picker, key bind.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' --- Layout Constants --------------------------------------------------------

CONST SW_ROW_H          = 22    ' Standard widget row height (checkbox, radio, spinner)
CONST SW_ROW_GAP        = 4     ' Vertical gap between widget rows
CONST SW_SECTION_GAP    = 12    ' Extra gap before section headers
CONST SW_LABEL_W        = 115   ' Width reserved for left label column
CONST SW_CHECKBOX_SIZE  = 12    ' Checkbox box dimension
CONST SW_RADIO_SIZE     = 12    ' Radio button circle dimension
CONST SW_SPINNER_BTN_W  = 18    ' Width of spinner [+]/[-] buttons
CONST SW_SPINNER_H      = 18    ' Height of spinner value display
CONST SW_SPINNER_W      = 100   ' Total spinner control width (value area + buttons)
CONST SW_COLOR_CHIP_W   = 24    ' Color chip swatch width
CONST SW_COLOR_CHIP_H   = 16    ' Color chip swatch height
CONST SW_SLIDER_H       = 14    ' Slider track height
CONST SW_BROWSE_BTN_W   = 50    ' File picker [Browse] button width
CONST SW_DROPDOWN_ITEM_H = 18   ' Dropdown item row height
CONST SW_DROPDOWN_MAX_VIS = 8   ' Max visible dropdown items before scroll
CONST SW_KEYBIND_W      = 120   ' Key binding display width

' --- Widget Result Constants -------------------------------------------------

CONST SW_NO_CHANGE      = 0     ' Widget value did not change
CONST SW_CHANGED        = -1    ' Widget value changed this frame

' --- Dropdown State (shared across all settings dropdowns) -------------------

TYPE SW_DROPDOWN_STATE
    openId       AS INTEGER     ' Which dropdown is open (-1=none)
    scroll       AS INTEGER     ' Scroll offset in open dropdown
    hoverItem    AS INTEGER     ' Currently hovered item index (-1=none)
    itemCount    AS INTEGER     ' Total items in open dropdown
END TYPE

DIM SHARED SW_DD AS SW_DROPDOWN_STATE

' --- Key Binding Capture State -----------------------------------------------

TYPE SW_KEYBIND_STATE
    capturing    AS INTEGER     ' TRUE while waiting for keypress
    captureId    AS INTEGER     ' Which keybind field is capturing (-1=none)
END TYPE

DIM SHARED SW_KB AS SW_KEYBIND_STATE

' --- Per-Widget Override State -----------------------------------------------
' Set SW_ZERO_TEXT$ before calling SW_draw_spinner to display custom text at 0.
' Set SW_TOOLTIP$ before calling any draw SUB to attach hover tooltip text.
' Both are consumed (reset to "") after each draw call.

DIM SHARED SW_ZERO_TEXT AS STRING   ' e.g., "Auto" — shown when spinner value = 0
DIM SHARED SW_TOOLTIP AS STRING     ' Tooltip text shown on hover over the widget

' --- Tooltip Rendering State -------------------------------------------------

TYPE SW_TOOLTIP_STATE
    text        AS STRING * 200    ' Current tooltip text to display
    x           AS INTEGER         ' Widget x for hit testing
    y           AS INTEGER         ' Widget y for hit testing
    w           AS INTEGER         ' Widget width for hit testing
    h           AS INTEGER         ' Widget height for hit testing
    active      AS INTEGER         ' TRUE if a tooltip should be drawn this frame
END TYPE

DIM SHARED SW_TIP AS SW_TOOLTIP_STATE

' --- Function Declarations ---------------------------------------------------

' Rendering
DECLARE SUB SW_draw_section_header (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, label AS STRING)
DECLARE SUB SW_draw_checkbox (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, label AS STRING, value AS INTEGER)
DECLARE SUB SW_draw_radio (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, label AS STRING, selected AS INTEGER)
DECLARE SUB SW_draw_spinner (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, value AS INTEGER, label AS STRING)
DECLARE SUB SW_draw_spinner_single (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, value AS SINGLE, label AS STRING)
DECLARE SUB SW_draw_slider (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, value AS INTEGER, minV AS INTEGER, maxV AS INTEGER, label AS STRING)
DECLARE SUB SW_draw_color_chip (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, clr AS _UNSIGNED LONG, label AS STRING)
DECLARE SUB SW_draw_file_picker (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, path AS STRING, label AS STRING)
DECLARE SUB SW_draw_dropdown (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, ddId AS INTEGER, items AS STRING, selected AS INTEGER, label AS STRING)
DECLARE SUB SW_draw_keybind (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, keyName AS STRING, label AS STRING)

' Input (returns SW_CHANGED or SW_NO_CHANGE; value passed BYREF is updated)
DECLARE FUNCTION SW_checkbox_input% (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, label AS STRING, value AS INTEGER)
DECLARE FUNCTION SW_radio_input% (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, label AS STRING, groupVal AS INTEGER, thisVal AS INTEGER)
DECLARE FUNCTION SW_spinner_input% (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, value AS INTEGER, minV AS INTEGER, maxV AS INTEGER)
DECLARE FUNCTION SW_spinner_single_input% (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, value AS SINGLE, minV AS SINGLE, maxV AS SINGLE, step1 AS SINGLE)
DECLARE FUNCTION SW_slider_input% (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, value AS INTEGER, minV AS INTEGER, maxV AS INTEGER)
DECLARE FUNCTION SW_color_chip_input% (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, clr AS _UNSIGNED LONG)
DECLARE FUNCTION SW_dropdown_input% (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, ddId AS INTEGER, items AS STRING, selected AS INTEGER)

' Tooltip helpers
DECLARE SUB SW_check_tooltip (ctx AS DIALOG_CTX, x AS INTEGER, y AS INTEGER, w AS INTEGER, h AS INTEGER)
DECLARE SUB SW_draw_tooltip (ctx AS DIALOG_CTX)
