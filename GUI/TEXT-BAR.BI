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

' Bar dimensions — dynamic, computed from theme
' (TEXT_BAR_HEIGHT CONST removed — use TEXT_BAR.barH% instead)

' Preset font sizes for the size dropdown
CONST TEXT_BAR_SIZE_COUNT = 25

' Button ID constants for hit-testing
CONST TEXT_BTN_NONE          = 0
CONST TEXT_BTN_FONT          = 1  ' Font name dropdown button
CONST TEXT_BTN_SIZE          = 2  ' Size dropdown button
CONST TEXT_BTN_BOLD          = 3  ' Bold toggle [B]
CONST TEXT_BTN_ITALIC        = 4  ' Italic toggle [I]
CONST TEXT_BTN_UNDERLINE     = 5  ' Underline toggle [U]
CONST TEXT_BTN_STRIKE        = 6  ' Strikethrough toggle [S]
CONST TEXT_BTN_FG_COLOR      = 7  ' FG color swatch
CONST TEXT_BTN_BG_COLOR      = 8  ' BG color swatch
CONST TEXT_BTN_LOAD          = 9  ' Load custom font from disk
CONST TEXT_BTN_DONE          = 10 ' Commit text / exit editing
CONST TEXT_BTN_MONO          = 11 ' Monospace toggle [M]
CONST TEXT_BTN_LINE_HEIGHT   = 12 ' Line height input
CONST TEXT_BTN_AUTO_LH       = 13 ' Auto line-height toggle
CONST TEXT_BTN_CHAR          = 14 ' Character Mode toggle [CHAR]
CONST TEXT_BTN_STYLE_DD      = 15 ' Style preset dropdown
CONST TEXT_BTN_STYLE_UPDATE  = 16 ' Style preset [U] update
CONST TEXT_BTN_STYLE_SAVE    = 17 ' Style preset [S] save/export
CONST TEXT_BTN_STYLE_DELETE  = 18 ' Style preset [X] delete
CONST TEXT_BTN_OUTLINE       = 19 ' Outline toggle
CONST TEXT_BTN_OUTLINE_COLOR = 20 ' Outline color swatch
CONST TEXT_BTN_OUTLINE_SIZE  = 21 ' Outline size dropdown
CONST TEXT_BTN_SHADOW        = 22 ' Shadow toggle
CONST TEXT_BTN_SHADOW_COLOR  = 23 ' Shadow color swatch
CONST TEXT_BTN_SHADOW_X      = 24 ' Shadow X offset dropdown
CONST TEXT_BTN_SHADOW_Y      = 25 ' Shadow Y offset dropdown
CONST TEXT_BTN_ALIGN_L       = 26 ' Align left
CONST TEXT_BTN_ALIGN_C       = 27 ' Align center
CONST TEXT_BTN_ALIGN_R       = 28 ' Align right
CONST TEXT_BTN_AA            = 29 ' Antialias toggle

TYPE TEXT_BAR_OBJ
    visible               AS INTEGER        ' TRUE when bar should be shown
    fontDropdownOpen      AS INTEGER        ' TRUE when font list is open
    sizeDropdownOpen      AS INTEGER        ' TRUE when size list is open
    fontDropdownScroll    AS INTEGER        ' Scroll offset for font dropdown
    selectedFontIdx       AS INTEGER        ' Index into FONT_LIST()
    selectedSize          AS INTEGER        ' Current font size in pixels
    boldActive            AS INTEGER        ' Bold toggle state
    italicActive          AS INTEGER        ' Italic toggle state
    underlineActive       AS INTEGER        ' Underline toggle state
    strikeActive          AS INTEGER        ' Strikethrough toggle state
    barX                  AS INTEGER        ' Bar left edge (screen coords)
    barY                  AS INTEGER        ' Bar top edge (screen coords)
    barW                  AS INTEGER        ' Bar width
    barH                  AS INTEGER        ' Bar height (TEXT_BAR_HEIGHT)
    hoverBtn              AS INTEGER        ' Currently hovered button ID (TEXT_BTN_*)
    lastPaintColor        AS _UNSIGNED LONG ' Track PAINT_COLOR~& for auto-sync
    lastPaintBgColor      AS _UNSIGNED LONG ' Track PAINT_BG_COLOR~& for auto-sync
    editingLayerIdx       AS INTEGER        ' Layer index being edited (0 = none)
    ' Hit zone X positions (set during render, used by click handler)
    fontBtnX              AS INTEGER
    fontBtnW              AS INTEGER
    sizeBtnX              AS INTEGER
    sizeBtnW              AS INTEGER
    boldBtnX              AS INTEGER
    italicBtnX            AS INTEGER
    underlineBtnX         AS INTEGER
    strikeBtnX            AS INTEGER
    styleBtnW             AS INTEGER        ' Width of each style toggle button
    fgSwatchX             AS INTEGER
    bgSwatchX             AS INTEGER
    loadBtnX              AS INTEGER
    loadBtnW              AS INTEGER
    doneBtnX              AS INTEGER
    doneBtnW              AS INTEGER
    monoActive            AS INTEGER        ' Monospace toggle state
    monoBtnX              AS INTEGER        ' Monospace button hit zone X
    lineHeightLabelX      AS INTEGER        ' Line height label X
    lineHeightBtnX        AS INTEGER        ' Line height value hit zone X
    lineHeightBtnW        AS INTEGER        ' Line height value hit zone width
    autoLineHeight        AS INTEGER        ' TRUE = auto-set line height from largest font
    autoLHBtnX            AS INTEGER        ' Auto LH checkbox hit zone X
    autoLHBtnW            AS INTEGER        ' Auto LH checkbox hit zone width
    monoBtnW              AS INTEGER        ' Monospace button width (dynamic when text, icon size when icon)
    ' Icon handles (loaded lazily on first render)
    iconsLoaded           AS INTEGER        ' TRUE after icons loaded
    iconBold              AS LONG           ' Bold icon handle (< -1 if valid)
    iconItalic            AS LONG           ' Italic icon handle
    iconUnderline         AS LONG           ' Underline icon handle
    iconStrike            AS LONG           ' Strikethrough icon handle
    iconMono              AS LONG           ' Monospace icon handle
    iconLineHeight        AS LONG           ' Line height icon handle
    ' Deselected (dimmed) icon copies
    iconBoldOff           AS LONG           ' Bold icon dimmed copy
    iconItalicOff         AS LONG           ' Italic icon dimmed copy
    iconUnderlineOff      AS LONG           ' Underline icon dimmed copy
    iconStrikeOff         AS LONG           ' Strikethrough icon dimmed copy
    iconMonoOff           AS LONG           ' Monospace icon dimmed copy
    iconLineHeightOff     AS LONG           ' Line height icon dimmed copy
    charBtnX              AS INTEGER        ' CHAR button hit zone X
    charBtnW              AS INTEGER        ' CHAR button hit zone width
    ' --- Row 2: Outline/Shadow/Alignment/Style/AA state ---
    outlineActive         AS INTEGER        ' Outline toggle state
    outlineColor          AS _UNSIGNED LONG ' Current outline color
    outlineSize           AS INTEGER        ' Outline size (1-10)
    shadowActive          AS INTEGER        ' Shadow toggle state
    shadowColor           AS _UNSIGNED LONG ' Current shadow color
    shadowOffsetX         AS INTEGER        ' Shadow X offset (1-10)
    shadowOffsetY         AS INTEGER        ' Shadow Y offset (1-10)
    alignMode             AS INTEGER        ' 0 = LEFT, 1 = CENTER, 2 = RIGHT
    aaActive              AS INTEGER        ' Antialias toggle state
    defaultKern           AS INTEGER        ' Default kern for newly typed characters
    styleDropdownOpen     AS INTEGER        ' TRUE when style list is open
    styleDropdownScroll   AS INTEGER        ' Scroll offset for style dropdown
    fontDropdownHoverRow  AS INTEGER        ' Hovered row in font dropdown (-1 = none)
    sizeDropdownHoverRow  AS INTEGER        ' Hovered row in size dropdown (-1 = none)
    styleDropdownHoverRow AS INTEGER        ' Hovered row in style dropdown (-1 = none)
    fontSubOpen           AS INTEGER        ' TRUE when subfolder popup is visible
    fontSubFolderIdx      AS INTEGER        ' Which folder is open (index into FONT_FOLDER_NAME)
    fontSubScroll         AS INTEGER        ' Scroll offset in subfolder popup
    fontSubHoverRow       AS INTEGER        ' Hovered row in subfolder popup (-1 = none)
    needsRedraw           AS INTEGER        ' Dirty flag — skip render when FALSE (CPU frugality)
    ' --- Row 2 hit zones ---
    outlineBtnX           AS INTEGER
    outlineColorBtnX      AS INTEGER
    outlineSizeBtnX       AS INTEGER
    outlineSizeBtnW       AS INTEGER
    shadowBtnX            AS INTEGER
    shadowColorBtnX       AS INTEGER
    shadowXBtnX           AS INTEGER
    shadowXBtnW           AS INTEGER
    shadowYBtnX           AS INTEGER
    shadowYBtnW           AS INTEGER
    alignLBtnX            AS INTEGER
    alignCBtnX            AS INTEGER
    alignRBtnX            AS INTEGER
    aaBtnX                AS INTEGER
    aaBtnW                AS INTEGER
    styleDDBtnX           AS INTEGER
    styleDDBtnW           AS INTEGER
    styleUpdateBtnX       AS INTEGER
    styleSaveBtnX         AS INTEGER
    styleDeleteBtnX       AS INTEGER
    styleBtnRowW          AS INTEGER        ' Width of style action buttons
    ' --- Icon handles for row 2 ---
    iconOutline           AS LONG
    iconOutlineOff        AS LONG
    iconShadow            AS LONG
    iconShadowOff         AS LONG
    iconAlignL            AS LONG
    iconAlignLOff         AS LONG
    iconAlignC            AS LONG
    iconAlignCOff         AS LONG
    iconAlignR            AS LONG
    iconAlignROff         AS LONG
    iconStyleU            AS LONG
    iconStyleS            AS LONG
    iconStyleX            AS LONG
    iconAuto              AS LONG
    iconAutoOff           AS LONG
    iconChar              AS LONG
    iconCharOff           AS LONG
    iconAA                AS LONG
    iconAAOff             AS LONG
END TYPE

DIM SHARED TEXT_BAR AS TEXT_BAR_OBJ

' Preset size values
DIM SHARED TEXT_BAR_SIZES(0 TO TEXT_BAR_SIZE_COUNT - 1) AS INTEGER

' --- Text Style Presets ---
CONST TEXT_STYLE_MAX = 32

TYPE TEXT_STYLE_OBJ
    name       AS STRING * 32 ' Style name ("Heading 1", etc.)
    used       AS INTEGER     ' TRUE if this slot is in use
    fontName   AS STRING * 64 ' Font name (portable, not index)
    fontSize   AS INTEGER
    bold       AS INTEGER
    italic     AS INTEGER
    underline  AS INTEGER
    strike     AS INTEGER
    mono       AS INTEGER
    lineHeight AS INTEGER
    autoLH     AS INTEGER
    charMode   AS INTEGER
    fgColor    AS _UNSIGNED LONG
    bgColor    AS _UNSIGNED LONG
    outline    AS INTEGER
    outColor   AS _UNSIGNED LONG
    outSize    AS INTEGER
    shadow     AS INTEGER
    shdColor   AS _UNSIGNED LONG
    shdX       AS INTEGER
    shdY       AS INTEGER
    antialias  AS INTEGER
    kern       AS INTEGER
END TYPE

DIM SHARED TEXT_STYLES(1 TO TEXT_STYLE_MAX) AS TEXT_STYLE_OBJ
DIM SHARED TEXT_STYLE_COUNT    AS INTEGER
DIM SHARED TEXT_STYLE_SELECTED AS INTEGER

' Function declarations
