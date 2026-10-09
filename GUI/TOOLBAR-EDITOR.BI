''
' DRAW - GUI/TOOLBAR-EDITOR.BI
' =============================================================================
' Customize Toolbars: a non-modal floating window that edits what the toolbox,
' the edit bar and the advanced bar show (plan: PLANS/_/TOOLBAR-EDITOR-PLAN.md).
'
'   [ TOOLBOX | EDIT BAR | ADVANCED BAR ]               SAVES TO: <workspace>
'   Available (tools + commands by category,   ->  <-   The panel's buttons,
'   search filter)                             up dn    in order
'                                              +DIV +GAP RESET
'   COLUMNS [-] n [+]                                                  DONE
'
' The tab is the panel. Its buttons are a button list (GUI/BUTTON-LIST): the
' bars draw straight from theirs; the toolbox's is copied from / written back
' to TOOLBAR_BUTTON_ORDER (TBED_tb_load / TBED_apply). Every change is saved
' into the active workspace at once; in Default the first change asks for a
' name and makes a workspace based on Default (TBED_save).
' Look and placement come from GUI/FLOAT-PANEL (Tiny5, title bar, snapping).
' Toggle: View > Customize Toolbars (action 2460), the command palette, or
' right-click a toolbox / bar grip -> Customize Buttons...
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST TBED_ACTION = 2460 ' View > Customize Toolbars

' Controls (TBED_hit% ids)
CONST TBED_CTL_NONE    = 0
CONST TBED_CTL_TAB     = 1  ' + panel (1..3): TBED_CTL_TAB + BL_TOOLBOX - 1 ...
CONST TBED_CTL_SEARCH  = 5
CONST TBED_CTL_AVAIL   = 6  ' the Available list
CONST TBED_CTL_LIST    = 7  ' the panel's list
CONST TBED_CTL_ADD     = 8  ' middle buttons
CONST TBED_CTL_REMOVE  = 9
CONST TBED_CTL_UP      = 10
CONST TBED_CTL_DOWN    = 11
CONST TBED_CTL_DIV     = 12
CONST TBED_CTL_GAP     = 13
CONST TBED_CTL_RESET   = 14
CONST TBED_CTL_COLS_DN = 15
CONST TBED_CTL_COLS_UP = 16
CONST TBED_CTL_DONE    = 17
CONST TBED_BTN_FIRST   = 8
CONST TBED_BTN_LAST    = 14

' The Available list: rows of tools / commands under category headers
CONST TBED_AV_MAX    = 700
CONST TBED_AV_HEADER = 0 ' row kind for a header (id = category, -1 = TOOLS)

' Toolbox buttons by default slot (TOOLBAR_default_slot%): names + hotkeys
CONST TBED_TOOL_LABELS$ = "MOVE,PAN,ZOOM,CROP,RECTANGLE MARQUEE,FREEHAND MARQUEE,POLYGON MARQUEE,ELLIPSE MARQUEE,MAGIC WAND,COLOR PICKER,TEXT,ERASER,DOT,BRUSH,SPRAY,FILL,LINE,POLYGON,FILLED POLYGON,SAVE,BEZIER CURVE,RECTANGLE,FILLED RECTANGLE,EXPORT SELECTION,SMART SHAPES,ELLIPSE,FILLED ELLIPSE,OPEN BROWSER"
' Tool commands that only pick a toolbox tool (the TOOLS group offers those)
CONST TBED_TOOL_ACTS$   = ",101,102,103,104,105,106,107,108,109,110,111,112,113,114,117,118,119,120,121,122,1701,1702,1706,"
CONST TBED_TOOL_KEYS$   = "M,SPACE,Z,,M,,,,W,I,T,E,D,B,K,F,L,P,SHIFT+P,CTRL+S,Q,R,SHIFT+R,,S,C,SHIFT+C,"

TYPE TBED_OBJ
    visible           AS INTEGER
    initialized       AS INTEGER
    positioned        AS INTEGER
    autoHidden        AS INTEGER ' hidden while drawing over it
    hiddenByToggleAll AS INTEGER ' F11 hid it

    dispX       AS INTEGER ' viewport coords
    dispY       AS INTEGER
    dispW       AS INTEGER
    dispH       AS INTEGER
    renderScale AS SINGLE  ' native -> viewport (ts / ds)
    panelImg    AS LONG
    panelW      AS INTEGER ' native size (TBED_layout)
    panelH      AS INTEGER

    tab         AS INTEGER ' BL_TOOLBOX / BL_EDITBAR / BL_ADVBAR
    hoverCtl    AS INTEGER
    hoverRow    AS INTEGER ' row under the pointer in the hovered list (-1 = none)
    closeHover  AS INTEGER
    focus       AS INTEGER ' the window was clicked last (Delete removes)
    searchFocus AS INTEGER ' typing goes to the search field

    ' title-bar drag
    dragging    AS INTEGER
    dragStartMX AS INTEGER
    dragStartMY AS INTEGER
    dragStartDX AS INTEGER
    dragStartDY AS INTEGER

    ' lists: selection + first visible row
    avSel       AS INTEGER ' Available row (-1 = none)
    avTop       AS INTEGER
    avN         AS INTEGER
    avDirty     AS INTEGER ' rebuild the Available rows (search / tab / list changed)
    lsSel       AS INTEGER ' panel list entry (-1 = none)
    lsTop       AS INTEGER

    ' an entry dragged out of a list (1 = Available, 2 = panel list)
    itemDrag    AS INTEGER ' 1 = an Available row, 2 = a panel's entry
    itemPanel   AS INTEGER ' (2) its panel
    itemIdx     AS INTEGER
    itemFromPanel AS INTEGER ' (2) picked up on the real panel (edit mode): dropped nowhere = removed
    itemPX      AS INTEGER ' press point (viewport)
    itemPY      AS INTEGER
    itemMoved   AS INTEGER ' left the press point: it is a drag, not a click
    dropList    AS INTEGER ' under the pointer while dragging: 0 nothing, 1 Available, 2 the editor's list, 3 a real panel
    dropPanel   AS INTEGER ' (3) which
    dropAt      AS INTEGER ' insertion index (2, 3)
    markX1      AS INTEGER ' (3) the insertion line on the panel (viewport px)
    markY1      AS INTEGER
    markX2      AS INTEGER
    markY2      AS INTEGER

    lastClickT  AS DOUBLE  ' double-click on the Available list
    lastClickR  AS INTEGER

    ' layout (native px, TBED_layout)
    rowH        AS INTEGER ' list row height
    rows        AS INTEGER ' visible list rows
    yTabs       AS INTEGER
    yHead       AS INTEGER ' list captions
    ySearch     AS INTEGER
    yList       AS INTEGER ' top of both lists' rows
    yBottom     AS INTEGER
    listW       AS INTEGER
    avX         AS INTEGER
    midX        AS INTEGER
    midW        AS INTEGER
    lsX         AS INTEGER
    lsY         AS INTEGER ' the panel list starts at the search row (no search there)
    lsRows      AS INTEGER
    btnH        AS INTEGER

    sig         AS LONG    ' the tab's list when Available was built (rebuild when it changes)

    ' Default: the change waiting for a workspace name (TBED_save)
    saving      AS INTEGER
END TYPE

DIM SHARED TBED AS TBED_OBJ
DIM SHARED TBED_AV_KIND(0 TO TBED_AV_MAX - 1) AS INTEGER ' BL_TOOL / BL_CMD / TBED_AV_HEADER
DIM SHARED TBED_AV_ID(0 TO TBED_AV_MAX - 1) AS INTEGER
DIM SHARED TBED_SEARCH AS STRING
DIM SHARED TBED_UNDO_CSV(1 TO 3) AS STRING ' each panel's list before the change being made (TBED_begin)
DIM SHARED TBED_UNDO_COLS(1 TO 3) AS INTEGER
