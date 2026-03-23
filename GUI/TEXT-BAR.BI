''
' DRAW - GUI/TEXT-BAR.BI
' =============================================================================
' Text formatting bar — context-sensitive bar below menu bar.
' Visible when text tool is active or editing a text layer.
' Contains font picker, size, style toggles, color swatches, LOAD, DONE.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Bar dimensions
CONST TEXT_BAR_HEIGHT = 14  ' Slightly taller than 12px menu bar for controls

' Preset font sizes for the size dropdown
CONST TEXT_BAR_SIZE_COUNT = 25

' Button ID constants for hit-testing
CONST TEXT_BTN_NONE       = 0
CONST TEXT_BTN_FONT       = 1   ' Font name dropdown button
CONST TEXT_BTN_SIZE       = 2   ' Size dropdown button
CONST TEXT_BTN_BOLD       = 3   ' Bold toggle [B]
CONST TEXT_BTN_ITALIC     = 4   ' Italic toggle [I]
CONST TEXT_BTN_UNDERLINE  = 5   ' Underline toggle [U]
CONST TEXT_BTN_STRIKE     = 6   ' Strikethrough toggle [S]
CONST TEXT_BTN_FG_COLOR   = 7   ' FG color swatch
CONST TEXT_BTN_BG_COLOR   = 8   ' BG color swatch
CONST TEXT_BTN_LOAD       = 9   ' Load custom font from disk
CONST TEXT_BTN_DONE       = 10  ' Commit text / exit editing
CONST TEXT_BTN_MONO       = 11  ' Monospace toggle [M]
CONST TEXT_BTN_LINE_HEIGHT = 12 ' Line height input
CONST TEXT_BTN_AUTO_LH     = 13 ' Auto line-height toggle
CONST TEXT_BTN_CHAR        = 14 ' Character Mode toggle [CHAR]

TYPE TEXT_BAR_OBJ
    visible            AS INTEGER        ' TRUE when bar should be shown
    fontDropdownOpen   AS INTEGER        ' TRUE when font list is open
    sizeDropdownOpen   AS INTEGER        ' TRUE when size list is open
    fontDropdownScroll AS INTEGER        ' Scroll offset for font dropdown
    selectedFontIdx    AS INTEGER        ' Index into FONT_LIST()
    selectedSize       AS INTEGER        ' Current font size in pixels
    boldActive         AS INTEGER        ' Bold toggle state
    italicActive       AS INTEGER        ' Italic toggle state
    underlineActive    AS INTEGER        ' Underline toggle state
    strikeActive       AS INTEGER        ' Strikethrough toggle state
    barX               AS INTEGER        ' Bar left edge (screen coords)
    barY               AS INTEGER        ' Bar top edge (screen coords)
    barW               AS INTEGER        ' Bar width
    barH               AS INTEGER        ' Bar height (TEXT_BAR_HEIGHT)
    hoverBtn           AS INTEGER        ' Currently hovered button ID (TEXT_BTN_*)
    lastPaintColor     AS _UNSIGNED LONG ' Track PAINT_COLOR~& for auto-sync
    lastPaintBgColor   AS _UNSIGNED LONG ' Track PAINT_BG_COLOR~& for auto-sync
    editingLayerIdx    AS INTEGER        ' Layer index being edited (0 = none)
    ' Hit zone X positions (set during render, used by click handler)
    fontBtnX           AS INTEGER
    fontBtnW           AS INTEGER
    sizeBtnX           AS INTEGER
    sizeBtnW           AS INTEGER
    boldBtnX           AS INTEGER
    italicBtnX         AS INTEGER
    underlineBtnX      AS INTEGER
    strikeBtnX         AS INTEGER
    styleBtnW          AS INTEGER        ' Width of each style toggle button
    fgSwatchX          AS INTEGER
    bgSwatchX          AS INTEGER
    loadBtnX           AS INTEGER
    loadBtnW           AS INTEGER
    doneBtnX           AS INTEGER
    doneBtnW           AS INTEGER
    monoActive         AS INTEGER        ' Monospace toggle state
    monoBtnX           AS INTEGER        ' Monospace button hit zone X
    lineHeightLabelX   AS INTEGER        ' Line height label X
    lineHeightBtnX     AS INTEGER        ' Line height value hit zone X
    lineHeightBtnW     AS INTEGER        ' Line height value hit zone width
    autoLineHeight     AS INTEGER        ' TRUE = auto-set line height from largest font
    autoLHBtnX         AS INTEGER        ' Auto LH checkbox hit zone X
    autoLHBtnW         AS INTEGER        ' Auto LH checkbox hit zone width
    monoBtnW           AS INTEGER        ' Monospace button width (dynamic when text, icon size when icon)
    ' Icon handles (loaded lazily on first render)
    iconsLoaded        AS INTEGER        ' TRUE after icons loaded
    iconBold           AS LONG           ' Bold icon handle (< -1 if valid)
    iconItalic         AS LONG           ' Italic icon handle
    iconUnderline      AS LONG           ' Underline icon handle
    iconStrike         AS LONG           ' Strikethrough icon handle
    iconMono           AS LONG           ' Monospace icon handle
    iconLineHeight     AS LONG           ' Line height icon handle
    ' Deselected (dimmed) icon copies
    iconBoldOff        AS LONG           ' Bold icon dimmed copy
    iconItalicOff      AS LONG           ' Italic icon dimmed copy
    iconUnderlineOff   AS LONG           ' Underline icon dimmed copy
    iconStrikeOff      AS LONG           ' Strikethrough icon dimmed copy
    iconMonoOff        AS LONG           ' Monospace icon dimmed copy
    iconLineHeightOff  AS LONG           ' Line height icon dimmed copy
    charBtnX           AS INTEGER        ' CHAR button hit zone X
    charBtnW           AS INTEGER        ' CHAR button hit zone width
END TYPE

DIM SHARED TEXT_BAR AS TEXT_BAR_OBJ

' Preset size values
DIM SHARED TEXT_BAR_SIZES(0 TO TEXT_BAR_SIZE_COUNT - 1) AS INTEGER

' Function declarations
DECLARE SUB TEXT_BAR_init ()
DECLARE SUB TEXT_BAR_load_icons ()
DECLARE SUB TEXT_BAR_dim_icon (handle AS LONG, dimScale AS SINGLE)
DECLARE SUB TEXT_BAR_render ()
DECLARE SUB TEXT_BAR_render_font_dropdown ()
DECLARE SUB TEXT_BAR_render_size_dropdown ()
DECLARE FUNCTION TEXT_BAR_handle_click% (rawX AS INTEGER, rawY AS INTEGER)
DECLARE FUNCTION TEXT_BAR_handle_wheel% (rawX AS INTEGER, rawY AS INTEGER, wheel_delta AS INTEGER)
DECLARE FUNCTION TEXT_BAR_char_mode_font_is_safe% (fontIdx AS INTEGER)
DECLARE SUB TEXT_BAR_ensure_char_mode_safe_font ()
DECLARE SUB TEXT_BAR_handle_key (k AS LONG)
DECLARE SUB TEXT_BAR_sync_paint_color ()
DECLARE FUNCTION TEXT_BAR_in_bounds% (rawX AS INTEGER, rawY AS INTEGER)
DECLARE SUB TEXT_BAR_close_dropdowns ()
DECLARE SUB TEXT_BAR_apply_style_to_selection (attrName AS STRING)
DECLARE FUNCTION TEXT_BAR_get_line_height% ()
DECLARE SUB TEXT_BAR_adjust_line_height ()
DECLARE SUB TEXT_BAR_auto_update_line_height ()
DECLARE FUNCTION TEXT_BAR_font_dropdown_max_visible% ()
