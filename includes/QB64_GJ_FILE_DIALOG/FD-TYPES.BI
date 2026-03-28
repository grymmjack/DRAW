'$INCLUDEONCE

' ============================================================================
' FD-TYPES.BI — Type definitions for QB64_GJ_FILE_DIALOG
'
' Standalone file dialog library for QB64-PE.
' No dependency on DRAW project types.
'
' (c) 2026 grymmjack — MIT License
' ============================================================================

' --- Constants ---------------------------------------------------------------

CONST FD_MAX_ENTRIES = 4096          ' Max files+dirs per directory listing
CONST FD_MAX_PATH = 260              ' Max path length (MAX_PATH)
CONST FD_MAX_FILENAME = 260          ' Max filename length
CONST FD_MAX_FAVORITES = 32          ' Max bookmark entries
CONST FD_MAX_FILTERS = 16            ' Max filter patterns
CONST FD_MAX_COLUMNS = 4             ' Name, Type, Size, Modified
CONST FD_MAX_THUMB_CACHE = 64        ' Thumbnail pool size
CONST FD_MAX_PLACES = 24             ' Max places bar entries (drives + XDG + favorites)

' Dialog modes
CONST FD_MODE_OPEN = 0
CONST FD_MODE_SAVE = 1
CONST FD_MODE_SAVE_AS = 2
CONST FD_MODE_CHOOSE_FOLDER = 3

' View modes
CONST FD_VIEW_LIST = 0
CONST FD_VIEW_DETAILS = 1
CONST FD_VIEW_THUMBNAILS = 2

' Sort fields
CONST FD_SORT_NAME = 0
CONST FD_SORT_TYPE = 1
CONST FD_SORT_SIZE = 2
CONST FD_SORT_DATE = 3

' Focus panes
CONST FD_FOCUS_PLACES = 0
CONST FD_FOCUS_PATH = 1
CONST FD_FOCUS_CONTENT = 2
CONST FD_FOCUS_FILENAME = 3

' Thumbnail states
CONST FD_THUMB_PENDING = 0
CONST FD_THUMB_LOADING = 1
CONST FD_THUMB_LOADED = 2
CONST FD_THUMB_FAILED = 3
CONST FD_THUMB_NOT_IMAGE = 4

' Places bar entry types
CONST FD_PLACE_DRIVE = 0
CONST FD_PLACE_XDG = 1
CONST FD_PLACE_FAVORITE = 2
CONST FD_PLACE_SEPARATOR = 3

' Resize edge constants
CONST FD_RESIZE_NONE = 0
CONST FD_RESIZE_N = 1
CONST FD_RESIZE_S = 2
CONST FD_RESIZE_E = 3
CONST FD_RESIZE_W = 4
CONST FD_RESIZE_NE = 5
CONST FD_RESIZE_NW = 6
CONST FD_RESIZE_SE = 7
CONST FD_RESIZE_SW = 8


' --- Type Definitions --------------------------------------------------------

TYPE FD_DIR_ENTRY
    fileName AS STRING * 260        ' File or directory name
    isDirectory AS INTEGER           ' TRUE if directory
    isHidden AS INTEGER              ' TRUE if hidden file/dir
    fileSize AS _INTEGER64           ' Size in bytes
    modifiedTime AS _INTEGER64       ' Unix epoch seconds
    extension AS STRING * 16         ' Lowercase file extension (without dot)
    thumbHandle AS LONG              ' Image handle for thumbnail (-1 = none)
    thumbState AS INTEGER            ' FD_THUMB_* constant
    selected AS INTEGER              ' TRUE if selected (for future multi-select)
END TYPE

TYPE FD_FAVORITES_ENTRY
    label AS STRING * 64             ' Display name
    path AS STRING * 260             ' Full path
    exists AS INTEGER                ' TRUE if path exists (checked on load)
END TYPE

TYPE FD_PLACES_ENTRY
    label AS STRING * 64             ' Display label
    path AS STRING * 260             ' Full path (empty for separators)
    entryType AS INTEGER             ' FD_PLACE_* constant
    iconChar AS INTEGER              ' ASCII char for simple icon rendering
END TYPE

TYPE FD_COLUMN_DEF
    label AS STRING * 32             ' Column header text
    width AS INTEGER                 ' Current width in pixels
    minWidth AS INTEGER              ' Minimum width in pixels
    sortField AS INTEGER             ' FD_SORT_* constant for this column
END TYPE

TYPE FD_FILTER_ENTRY
    label AS STRING * 64             ' Display label (e.g., "Image Files")
    pattern AS STRING * 128          ' Extension pattern (e.g., "*.png|*.bmp|*.jpg")
END TYPE

' --- Persistent Configuration ------------------------------------------------

TYPE FD_CONFIG_OBJ
    ' View settings
    viewMode AS INTEGER              ' FD_VIEW_* constant
    sortField AS INTEGER             ' FD_SORT_* constant
    sortAscending AS INTEGER         ' TRUE = A-Z / smallest-first / oldest-first
    showHidden AS INTEGER            ' TRUE = show hidden files
    thumbSize AS INTEGER             ' Thumbnail pixel size (32, 48, 64, 96, 128)

    ' Dialog geometry
    dialogW AS INTEGER               ' Dialog width
    dialogH AS INTEGER               ' Dialog height

    ' Column widths (persisted)
    colWidth0 AS INTEGER             ' Name column width
    colWidth1 AS INTEGER             ' Type column width
    colWidth2 AS INTEGER             ' Size column width
    colWidth3 AS INTEGER             ' Date column width

    ' Pane widths
    placesWidth AS INTEGER           ' Places bar width
    previewWidth AS INTEGER          ' Preview pane width
    showPreview AS INTEGER           ' TRUE = show preview pane

    ' Favorites
    favCount AS INTEGER
END TYPE

' --- Runtime State -----------------------------------------------------------

TYPE FD_STATE_OBJ
    ' Operating mode
    mode AS INTEGER                  ' FD_MODE_* constant
    title AS STRING * 128            ' Dialog title bar text
    confirmLabel AS STRING * 32      ' OK button label ("Open", "Save", etc.)
    defaultExt AS STRING * 16        ' Default extension for save mode

    ' Filter state
    filterCount AS INTEGER           ' Number of filter entries
    activeFilter AS INTEGER          ' Currently selected filter index
    filterDropdownOpen AS INTEGER    ' TRUE = filter dropdown popup is visible

    ' Navigation
    currentPath AS STRING * 260      ' Current directory being displayed
    pathInput AS STRING * 260        ' Path bar text input (legacy, synced from TI)
    pathInputActive AS INTEGER       ' TRUE = path bar has focus for text entry
    pathInputCursor AS INTEGER       ' Cursor position in path input
    tiPathId AS INTEGER              ' TI widget ID for path input
    tiFileNameId AS INTEGER          ' TI widget ID for filename input

    ' Filename input (for save mode)
    fileNameInput AS STRING * 260    ' Filename text input (legacy, synced from TI)
    fileNameCursor AS INTEGER        ' Cursor position in filename input

    ' Search / type-ahead
    searchText AS STRING * 64        ' Type-ahead filter text
    searchLen AS INTEGER             ' Length of search text

    ' Content state
    entryCount AS INTEGER            ' Number of entries in current listing
    visibleCount AS INTEGER          ' Number of entries after filtering
    scrollOffset AS INTEGER          ' Pixel scroll offset
    maxScroll AS INTEGER             ' Maximum scroll offset
    selectedIndex AS INTEGER         ' Selected entry index (-1 = none)
    hoverIndex AS INTEGER            ' Hovered entry index (-1 = none)

    ' Dialog geometry (screen coordinates)
    dialogX AS INTEGER               ' Dialog X position on screen
    dialogY AS INTEGER               ' Dialog Y position on screen
    dialogW AS INTEGER               ' Dialog width
    dialogH AS INTEGER               ' Dialog height

    ' Calculated pane geometry
    titleBarH AS INTEGER             ' Title bar height
    toolBarH AS INTEGER              ' Toolbar height
    pathBarH AS INTEGER              ' Path bar height
    columnHeaderH AS INTEGER         ' Column header height (details mode)
    statusBarH AS INTEGER            ' Status bar height
    buttonBarH AS INTEGER            ' OK/Cancel button bar height
    placesX AS INTEGER               ' Places pane X
    placesW AS INTEGER               ' Places pane width
    contentX AS INTEGER              ' Content pane X
    contentW AS INTEGER              ' Content pane width
    contentY AS INTEGER              ' Content pane Y
    contentH AS INTEGER              ' Content pane height
    previewX AS INTEGER              ' Preview pane X
    previewW AS INTEGER              ' Preview pane width
    rowHeight AS INTEGER             ' Row height in list/details mode

    ' Interaction state
    dragging AS INTEGER              ' TRUE = currently dragging something
    dragType AS INTEGER              ' 0=none, 1=dialog move, 2=resize, 3=col resize, 4=splitter
    dragStartX AS INTEGER            ' Mouse X when drag started
    dragStartY AS INTEGER            ' Mouse Y when drag started
    dragOrigVal AS INTEGER           ' Original value being dragged (column width, etc.)
    resizeEdge AS INTEGER            ' FD_RESIZE_* constant
    colResizing AS INTEGER           ' Column index being resized (-1 = none)
    splitterDragging AS INTEGER      ' 0=none, 1=places/content, 2=content/preview
    lastCursor AS STRING * 24        ' Last cursor shape set (to avoid redundant _MOUSESHOW calls)

    ' Mouse state (raw screen coords)
    mouseX AS INTEGER
    mouseY AS INTEGER
    mouseB1 AS INTEGER               ' Left button state
    mouseB2 AS INTEGER               ' Right button state
    oldMouseB1 AS INTEGER            ' Previous frame left button
    oldMouseB2 AS INTEGER            ' Previous frame right button
    mouseWheel AS INTEGER            ' Scroll wheel delta

    ' Focus
    focusPane AS INTEGER             ' FD_FOCUS_* constant

    ' Places bar state
    placesCount AS INTEGER           ' Number of places entries
    placesHover AS INTEGER           ' Hovered places entry (-1 = none)
    placesScroll AS INTEGER          ' Places scroll offset

    ' Context menu
    ctxMenuVisible AS INTEGER        ' TRUE if context menu is shown
    ctxMenuX AS INTEGER
    ctxMenuY AS INTEGER
    ctxMenuIndex AS INTEGER          ' Entry index context menu was opened on

    ' Result
    done AS INTEGER                  ' TRUE if dialog should close
    confirmed AS INTEGER             ' TRUE if user confirmed (OK/Open/Save)
    resultPath AS STRING * 260       ' Full path of selected/entered file

    ' Rendering
    imgHandle AS LONG                ' Offscreen dialog image buffer
    screenShot AS LONG               ' Background screen capture
    previewImgHandle AS LONG         ' Loaded preview image of selected file
    dirty AS INTEGER                 ' TRUE = needs full redraw
    scale AS INTEGER                 ' Display scale factor

    ' Double-click detection
    lastClickTime AS DOUBLE          ' Timer value of last click
    lastClickIndex AS INTEGER        ' Index of last clicked entry

    ' Animation
    cursorBlink AS INTEGER           ' Cursor blink state
    cursorTimer AS DOUBLE            ' Cursor blink timer
END TYPE

' --- Thumbnail Cache ---------------------------------------------------------

TYPE FD_THUMB_SLOT
    filePath AS STRING * 260         ' Full path of cached file
    imgHandle AS LONG                ' Image handle (< -1 = valid)
    lastUsed AS DOUBLE               ' Timer value when last accessed (LRU)
    inUse AS INTEGER                 ' TRUE if slot is occupied
END TYPE

TYPE FD_THUMB_CACHE_OBJ
    loadQueue AS INTEGER             ' Index of next entry to attempt loading
    loadActive AS INTEGER            ' TRUE if currently loading a batch
    cacheHits AS LONG                ' Stats: cache hits
    cacheMisses AS LONG              ' Stats: cache misses
END TYPE

' --- Shared state arrays (DIM SHARED in the BI, filled in BM) ---------------

DIM SHARED FD_CFG AS FD_CONFIG_OBJ
DIM SHARED FD_STATE AS FD_STATE_OBJ
DIM SHARED FD_THUMB_CACHE AS FD_THUMB_CACHE_OBJ

' Entry arrays
DIM SHARED FD_entries(FD_MAX_ENTRIES) AS FD_DIR_ENTRY
DIM SHARED FD_filtered(FD_MAX_ENTRIES) AS INTEGER  ' Indices into FD_entries after filter

' Favorites
DIM SHARED FD_favorites(FD_MAX_FAVORITES) AS FD_FAVORITES_ENTRY

' Places bar
DIM SHARED FD_places(FD_MAX_PLACES) AS FD_PLACES_ENTRY

' Column definitions
DIM SHARED FD_columns(FD_MAX_COLUMNS - 1) AS FD_COLUMN_DEF

' Filters
DIM SHARED FD_filters(FD_MAX_FILTERS - 1) AS FD_FILTER_ENTRY

' Thumbnail cache pool
DIM SHARED FD_thumbs(FD_MAX_THUMB_CACHE - 1) AS FD_THUMB_SLOT
