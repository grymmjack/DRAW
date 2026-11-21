''
' DRAW - GUI/UIKIT/UIP-INSPECTOR.BI
' =============================================================================
' UIKIT inspector widget (UIPI_): a devtools-style panel over the UIP registry -
' an ELEMENTS tree of the host's UI (UIP nodes) above the PROPERTIES of the
' selected part. HOST-INDEPENDENT: the host gives it a screen area, the pointer
' and keys in plain parameters, and acts on the events it queues
' (UIPI_next_event$).
'
' Units: everything the host passes and gets back (screen size, the pointer,
' UIPI.x / y, node boxes) is WINDOW px. The panel draws in its own px, UIPI.sc
' window px each (the Scale menu: Auto = UIPI.autoScale, set by the host, or
' 1x - 8x in half steps); UIPI.w / h are panel px, UIPI.scrW / scrH its size on
' screen. UIPI_draw_to puts the panel (and its open menu) on the host's image.
'
' Resizing: a floating panel by any edge or corner, a docked one by its inner
' edge (the edge lights up). UIPI_cursor_edges% tells the host which UIPI_RS_*
' edges are under the pointer / being dragged, for a resize cursor.
'
' Events (space-separated word + argument):
'   PICK 1|0        inspect mode turned on / off
'   SAVE            the SAVE button
'   OPENDIR         the DIR button (open the theme folder)
'   EDITCFG         the CFG button (edit the theme file in a text editor)
'   EDITIMG <path>  an image file's EDIT button (it may not exist yet - shown NEW: the host makes it)
'   EDITPROP <key>  an image-valued property's EDIT button (host resolves the file)
'   CHANGED <key>   a property was changed through the panel
'   TAKECOLOR <key> left-click on a colour swatch (host sets it, e.g. from its FG)
'   GIVECOLOR <key> right-click on a colour swatch (host uses it, e.g. as its FG)
'   CLOSE           the X button
'   NODE <nkey>     a tree node was selected
'   STATE           dock / scale / split / tree / IMAGES order changed (save UIPI_state$ to keep it)
'   HOSTMENU <id>   an item of the host's menu (UIPI_host_menu_add) was chosen
'
' The host menu: UIPI.hostBtn names a toolbar button ("" = none) that opens a
' menu of the host's own items (UIPI_host_menu_add text, id).
'
' The look is fixed (dark, Tiny5, measured text): it is NOT themed by the theme being
' edited, so a broken theme can never make its own editor unreadable.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST UIPI_EDGE_LEFT   = 1
CONST UIPI_EDGE_RIGHT  = 2
CONST UIPI_EDGE_TOP    = 3
CONST UIPI_EDGE_BOTTOM = 4
CONST UIPI_EDGE_FLOAT  = 5

CONST UIPI_ROW_SECTION = 1 ' a [SECTION] header
CONST UIPI_ROW_PROP    = 2 ' a property
CONST UIPI_ROW_FILE    = 3 ' an image file of the component / element
CONST UIPI_ROW_HEAD    = 4 ' a plain header (ELEMENT, IMAGES)

CONST UIPI_TITLE_H = 11
CONST UIPI_BAR_H   = 11
CONST UIPI_COMP_H  = 10
CONST UIPI_FILT_H  = 11
CONST UIPI_STAT_H  = 10
CONST UIPI_SB_W    = 4  ' list scroll bar
CONST UIPI_SPLIT   = 4  ' the tree / properties divider
CONST UIPI_INDENT  = 8  ' tree indent per level
CONST UIPI_MAX_FILES = 400
CONST UIPI_RS_L = 1 ' resize edges (UIPI_resize_at%, UIPI_cursor_edges%)
CONST UIPI_RS_R = 2
CONST UIPI_RS_T = 4
CONST UIPI_RS_B = 8
CONST UIPI_MENU_MAX  = 48

' menu item values
CONST UIPI_MV_SCALE = 1000 ' + half steps (0 = Auto, 2 = 1x, 3 = 1.5x ...)
CONST UIPI_MV_DOCK  = 2000 ' + UIPI_EDGE_*
CONST UIPI_MV_TREE  = 3000
CONST UIPI_MV_FSORT = 3001 ' IMAGES order: screen / A-Z
CONST UIPI_MV_CLOSE = 4000
CONST UIPI_MV_HOST  = 5000 ' + the host item's index

' Colours (fixed devtools look)
CONST UIPI_C_BG = &HFF202226~&
CONST UIPI_C_TITLE = &HFF33363D~&
CONST UIPI_C_BAR = &HFF2A2D33~&
CONST UIPI_C_BORDER = &HFF5A5F6B~&
CONST UIPI_C_TEXT = &HFFD7DAE0~&
CONST UIPI_C_DIM = &HFF8A8F9A~&
CONST UIPI_C_KEY = &HFF9CDCFE~&
CONST UIPI_C_VAL = &HFFCE9178~&
CONST UIPI_C_NUM = &HFFB5CEA8~&
CONST UIPI_C_SECT = &HFFC586C0~&
CONST UIPI_C_SEL = &HFF094771~&
CONST UIPI_C_HOVER = &HFF2C3E50~&
CONST UIPI_C_CHANGED = &HFFE5C07B~&
CONST UIPI_C_BTN = &HFF3B4048~&
CONST UIPI_C_BTN_ON = &HFF0E639C~&
CONST UIPI_C_PICK = &HFF00B4FF~&
CONST UIPI_C_ERR = &HFFF48771~&

TYPE UIPI_OBJ
    ready      AS INTEGER
    visible    AS INTEGER
    edge       AS INTEGER ' UIPI_EDGE_*
    x          AS INTEGER ' on screen (window px), set by UIPI_layout
    y          AS INTEGER
    w          AS INTEGER ' size in panel px
    h          AS INTEGER
    scrW       AS INTEGER ' size on screen (window px) = w * sc
    scrH       AS INTEGER
    sc         AS SINGLE  ' window px per panel px (UIPI_scale!)
    scaleSet   AS SINGLE  ' the Scale menu's choice, 0 = Auto
    autoScale  AS SINGLE  ' what Auto is (the host's UI scale)
    scrnW      AS INTEGER ' the host's screen and band (window px), from UIPI_layout
    bandTop    AS INTEGER
    bandBot    AS INTEGER
    dockW      AS INTEGER ' width when docked left / right (panel px)
    dockH      AS INTEGER ' height when docked top / bottom (panel px)
    fx         AS INTEGER ' floating position (window px) and size (panel px)
    fy         AS INTEGER
    fw         AS INTEGER
    fh         AS INTEGER
    ax         AS INTEGER ' the properties pane (panel px): left, top, width, bottom
    ay         AS INTEGER
    aw         AS INTEGER
    ab         AS INTEGER
    tx         AS INTEGER ' the tree pane (tw = 0: not shown)
    ty         AS INTEGER
    tw         AS INTEGER
    th         AS INTEGER
    side       AS INTEGER ' tree left of the properties (a wide panel) instead of above
    showTree   AS INTEGER
    treeH      AS INTEGER ' tree height (above) / width (beside), panel px
    treeW      AS INTEGER
    treeScroll AS INTEGER
    treeSel    AS STRING  ' selected node's id
    treeHover  AS INTEGER ' node under the pointer in the tree (0 = none)
    treeFocus  AS INTEGER ' the tree takes the arrow keys
    treeFlip   AS STRING  ' " id id " nodes opened / closed against their default
    treeRows   AS INTEGER ' rows need rebuilding
    splitDrag  AS INTEGER ' dragging the divider
    resizing   AS INTEGER ' dragging edges: UIPI_RS_* bits (0 = not)
    edgeHover  AS INTEGER ' resize edges under the pointer (lit)
    rsX        AS INTEGER ' resize start: pointer (window px), size (panel px), float spot
    rsY        AS INTEGER
    rsW        AS INTEGER
    rsH        AS INTEGER
    rsFX       AS INTEGER
    rsFY       AS INTEGER
    menuOpen   AS INTEGER
    menuX      AS INTEGER ' window px
    menuY      AS INTEGER
    menuW      AS INTEGER ' panel px
    menuH      AS INTEGER
    menuHover  AS INTEGER
    menuImg    AS LONG
    img        AS LONG    ' the rendered panel
    fnt       AS LONG
    meas       AS LONG    ' small image carrying the font, for _PRINTWIDTH
    fontW      AS INTEGER ' width of "W" (title buttons)
    fontH      AS INTEGER
    rowH       AS INTEGER
    title      AS STRING  ' "THEME: NAME"
    info       AS STRING  ' status-line text when nothing else is shown
    root       AS STRING  ' theme root folder (component image folders are under it)
    dirty      AS INTEGER ' host: unsaved changes (title shows *)
    picking    AS INTEGER ' inspect mode
    comp       AS INTEGER ' the component shown (0 = none / all)
    hoverComp  AS INTEGER ' while picking: the component under the pointer
    hoverLabel AS STRING  ' while picking: what the host says is under the pointer
    elemLabel  AS STRING  ' element of the shown component ("BUTTON BRUSH")
    elemFiles  AS STRING  ' its files, "|"-separated full paths
    showAll    AS INTEGER ' every section, not just the component's
    fileAZ     AS INTEGER ' IMAGES rows A-Z (else screen order: where the nodes using them sit)
    scroll     AS INTEGER ' first list row shown
    sel        AS INTEGER ' selected row (0 = none)
    hoverRow   AS INTEGER
    wheelRow   AS INTEGER ' the value row a click armed for the wheel (0 = none: the wheel scrolls)
    editRow    AS INTEGER ' row being typed into (0 = none)
    editTi     AS INTEGER ' its TEXT_INPUT id
    filtTi     AS INTEGER ' the filter box
    filter     AS STRING
    msg        AS STRING  ' a transient status message
    msgErr     AS INTEGER
    msgT       AS DOUBLE
    oldB1      AS INTEGER
    oldB2      AS INTEGER
    oldB3      AS INTEGER
    clickT     AS DOUBLE  ' double-click detection
    clickRow   AS INTEGER
    dragging   AS INTEGER ' moving the floating panel
    dragDX     AS INTEGER
    dragDY     AS INTEGER
    changed    AS INTEGER ' needs a repaint
    rebuild    AS INTEGER ' rows need rebuilding
    hostBtn    AS STRING  ' the host menu's toolbar button ("" = none)
    menuKind   AS INTEGER ' the open menu: 0 = the panel's, 1 = the host's
END TYPE

DIM SHARED UIPI AS UIPI_OBJ
DIM SHARED UIPI_RN AS INTEGER
DIM SHARED UIPI_ROW_KIND(1 TO 1) AS INTEGER
DIM SHARED UIPI_ROW_PROP(1 TO 1) AS INTEGER  ' UIP_P index for PROP rows; FILE rows: 1 on screen, -1 not (0 = not known)
DIM SHARED UIPI_ROW_TEXT(1 TO 1) AS STRING   ' header text / file path
DIM SHARED UIPI_EVENTS AS STRING             ' queued events, LF-separated
DIM SHARED UIPI_TRN AS INTEGER                ' visible tree rows
DIM SHARED UIPI_TROW(1 TO 1) AS INTEGER       ' their UIP_N indices
DIM SHARED UIPI_MENU_N AS INTEGER
DIM SHARED UIPI_MENU_TXT(1 TO UIPI_MENU_MAX) AS STRING ' "---" = a divider
DIM SHARED UIPI_MENU_VAL(1 TO UIPI_MENU_MAX) AS INTEGER
DIM SHARED UIPI_MENU_ON(1 TO UIPI_MENU_MAX) AS INTEGER ' checked
DIM SHARED UIPI_HOST_N AS INTEGER                     ' the host menu (UIPI_host_menu_add)
DIM SHARED UIPI_HOST_TXT(1 TO UIPI_MENU_MAX) AS STRING ' "---" = a divider
DIM SHARED UIPI_HOST_ID(1 TO UIPI_MENU_MAX) AS INTEGER
