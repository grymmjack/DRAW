''
' DRAW - GUI/SETTINGS.BI
' =============================================================================
' Settings dialog type definitions and declares.
' GIMP-style tabbed settings: left sidebar tabs, scrollable right content area,
' OK / Cancel / Apply button bar at bottom.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' --- Tab Constants -----------------------------------------------------------

CONST SETTINGS_TAB_GENERAL    = 0
CONST SETTINGS_TAB_GRID       = 1
CONST SETTINGS_TAB_PALETTE    = 2
CONST SETTINGS_TAB_PANELS     = 3
CONST SETTINGS_TAB_AUDIO      = 4
CONST SETTINGS_TAB_FONTS      = 5
CONST SETTINGS_TAB_APPEARANCE = 6
CONST SETTINGS_TAB_DIRS       = 7
CONST SETTINGS_TAB_COUNT      = 8

' --- Layout Constants --------------------------------------------------------

CONST SETTINGS_W         = 600 ' Dialog width (unscaled)
CONST SETTINGS_H         = 380 ' Dialog height (unscaled)
CONST SETTINGS_TAB_W     = 100 ' Tab sidebar width
CONST SETTINGS_TAB_H     = 22  ' Individual tab button height
CONST SETTINGS_TITLE_H   = 16  ' Title bar height
CONST SETTINGS_BTN_BAR_H = 28  ' OK/Cancel/Apply button bar height
CONST SETTINGS_BTN_W     = 56  ' Button width
CONST SETTINGS_BTN_H     = 20  ' Button height
CONST SETTINGS_PADDING   = 8   ' Generic inner padding
CONST SETTINGS_SCROLL_W  = 10  ' Scrollbar track width in content area

' --- Action ID ---------------------------------------------------------------

CONST ACTION_SETTINGS = 2100

' --- Settings Dialog Context -------------------------------------------------

TYPE SETTINGS_CTX
    ctx            AS DIALOG_CTX ' Wrapped DIALOG_CTX for infrastructure
    activeTab      AS INTEGER    ' Currently selected tab (0..7)
    hoverTab       AS INTEGER    ' Tab under mouse (-1 = none)
    scrollY        AS INTEGER    ' Current scroll offset for active tab
    tabScrollY0    AS INTEGER    ' Saved scroll position per tab: General
    tabScrollY1    AS INTEGER    ' Grid
    tabScrollY2    AS INTEGER    ' Palette
    tabScrollY3    AS INTEGER    ' Panels
    tabScrollY4    AS INTEGER    ' Audio
    tabScrollY5    AS INTEGER    ' Fonts
    tabScrollY6    AS INTEGER    ' Appearance
    tabScrollY7    AS INTEGER    ' Directories
    contentH       AS INTEGER    ' Total content height for active tab
    viewportH      AS INTEGER    ' Visible content viewport height
    contentX       AS INTEGER    ' Content area left X in dialog coords
    contentY       AS INTEGER    ' Content area top Y in dialog coords
    contentW       AS INTEGER    ' Content area width
    pendingChanges AS INTEGER    ' TRUE if shadow differs from CFG
    needsRedraw    AS INTEGER    ' TRUE if dialog needs repaint
    scrollDrag     AS INTEGER    ' TRUE if content scrollbar is being dragged
    scrollDragY    AS INTEGER    ' Mouse Y at drag start
    scrollDragOfs  AS INTEGER    ' Scroll offset at drag start
    reopenNeeded   AS INTEGER    ' TRUE if Apply changed display scale; dialog must close & reopen
END TYPE

DIM SHARED SETTINGS AS SETTINGS_CTX

' Shadow copy of config — edited in dialog, applied on OK/Apply
DIM SHARED SETTINGS_CFG AS DRAW_CONFIG

' --- Function Declarations ---------------------------------------------------

DECLARE SUB SETTINGS_show_dialog ()
DECLARE SUB SETTINGS_resolve_shadow_sentinels ()
