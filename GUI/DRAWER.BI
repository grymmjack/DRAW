''
' DRAW - GUI/DRAWER.BI
' =============================================================================
' Mode drawer beneath the organizer. Provides seeded brush, pattern, and
' gradient bins plus a compact mini palette.
'
$INCLUDEONCE

CONST DRAWER_MODE_NONE     = 0
CONST DRAWER_MODE_BRUSH    = 1
CONST DRAWER_MODE_PATTERN  = 2
CONST DRAWER_MODE_GRADIENT = 3
CONST DRAWER_SLOT_COUNT    = 30
CONST DRAWER_GRID_COLS     = 3
CONST DRAWER_GRID_ROWS     = 10

' Maximum color/opacity stops per gradient definition
CONST GRADIENT_MAX_STOPS = 16

' Gradient spatial families (how t is derived from x,y)
CONST GRADIENT_FAMILY_HORIZONTAL  = 1
CONST GRADIENT_FAMILY_VERTICAL    = 2
CONST GRADIENT_FAMILY_DIAGONAL    = 3
CONST GRADIENT_FAMILY_ANTI_DIAG   = 4
CONST GRADIENT_FAMILY_RADIAL      = 5
CONST GRADIENT_FAMILY_REFLECTED_H = 6
CONST GRADIENT_FAMILY_REFLECTED_V = 7
CONST GRADIENT_FAMILY_DIAMOND     = 8

' Per-stop color source type
CONST GRAD_STOP_USER = 0 ' Fixed user-specified color
CONST GRAD_STOP_FG   = 1 ' References current foreground (PAINT_COLOR~&)
CONST GRAD_STOP_BG   = 2 ' References current background (PAINT_BG_COLOR~&)

' A drawer brush slot: image handle plus its dimensions
TYPE DRAW_BRUSH
    IMG AS LONG
    W   AS INTEGER
    H   AS INTEGER
END TYPE

' A single color stop in a gradient definition
TYPE GRADIENT_COLOR_STOP
    position AS SINGLE         ' 0.0 to 1.0
    clr      AS _UNSIGNED LONG ' RGBA color at this stop
END TYPE

' A single opacity stop in a gradient definition
TYPE GRADIENT_OPACITY_STOP
    position AS SINGLE  ' 0.0 to 1.0
    opacity  AS INTEGER ' 0 to 255
END TYPE

' Complete editable gradient definition per slot
TYPE GRADIENT_DEF
    family         AS INTEGER     ' GRADIENT_FAMILY_* constant
    colorCount     AS INTEGER     ' number of active color stops (1..GRADIENT_MAX_STOPS)
    opacityCount   AS INTEGER     ' number of active opacity stops (0..GRADIENT_MAX_STOPS)
    usesFG         AS INTEGER     ' TRUE if preset references PAINT_COLOR~&
    usesBG         AS INTEGER     ' TRUE if preset references PAINT_BG_COLOR~&
    previewDirty   AS INTEGER     ' TRUE when definition changed, preview needs rebuild
    gName          AS STRING * 32 ' user-editable gradient name
    ditherMode     AS INTEGER     ' GJ_IMGADJ_DITHER_* constant or DITHER_NONE (-1)
    ditherStrength AS SINGLE      ' 0.0 (none) to 1.0 (full)
END TYPE

' Operation-bounded gradient context for runtime sampling
TYPE GRADIENT_CONTEXT
    boundsX1 AS INTEGER ' left edge of operation area
    boundsY1 AS INTEGER ' top edge of operation area
    boundsX2 AS INTEGER ' right edge of operation area
    boundsY2 AS INTEGER ' bottom edge of operation area
    active   AS INTEGER ' TRUE when context has valid bounds
END TYPE

TYPE DRAWER_STATE
    visible            AS INTEGER
    mode               AS INTEGER
    paintMode          AS INTEGER
    panelX1            AS INTEGER
    panelY1            AS INTEGER
    panelX2            AS INTEGER
    panelY2            AS INTEGER
    miniPaletteOffset  AS INTEGER
    brushSelected      AS INTEGER
    patternSelected    AS INTEGER
    gradientSelected   AS INTEGER
    paletteFGX         AS INTEGER
    paletteFGY         AS INTEGER
    paletteBGX         AS INTEGER
    paletteBGY         AS INTEGER
    contextMenuOpen    AS INTEGER
    contextMenuSlot    AS INTEGER
    contextMenuX       AS INTEGER
    contextMenuY       AS INTEGER
    contextMenuW       AS INTEGER
    contextMenuHover   AS INTEGER
    contextMenuItems   AS INTEGER
    samplesLoaded      AS INTEGER
    loadedTheme        AS STRING * 64
    ' Bin drag-and-drop reordering state
    dragPending        AS INTEGER ' TRUE when mouse down but not yet moved threshold
    isDragging         AS INTEGER ' TRUE while actively dragging bin for reorder
    dragSourceSlot     AS INTEGER ' Slot index (1-30) being dragged
    dragTargetSlot     AS INTEGER ' Current drop target slot (0 = none)
    dragStartX         AS INTEGER ' Raw X when drag started
    dragStartY         AS INTEGER ' Raw Y when drag started
    ' Per-mode dirty tracking (TRUE when set has been modified since last load/save)
    brushSetDirty      AS INTEGER
    patternSetDirty    AS INTEGER
    gradientSetDirty   AS INTEGER
    ' Wheel tooltip state
    wheelTooltipActive AS INTEGER
    wheelTooltipTimer  AS DOUBLE
END TYPE

' Per-mode path of currently loaded .dset file (empty = no file loaded / theme defaults)
DIM SHARED DRAWER_BRUSH_SET_PATH    AS STRING
DIM SHARED DRAWER_PATTERN_SET_PATH  AS STRING
DIM SHARED DRAWER_GRADIENT_SET_PATH AS STRING

' Wheel tooltip text (stripped filename, no path/extension)
DIM SHARED DRAWER_WHEEL_TOOLTIP_TEXT AS STRING

DIM SHARED DRAWER                      AS DRAWER_STATE
DIM SHARED DRAWER_BRUSH_SLOTS(1 TO DRAWER_SLOT_COUNT) AS DRAW_BRUSH
DIM SHARED DRAWER_PATTERN_SLOTS(1 TO DRAWER_SLOT_COUNT) AS LONG
DIM SHARED DRAWER_PATTERN_HAS(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED DRAWER_PATTERN_1BIT(1 TO DRAWER_SLOT_COUNT) AS INTEGER           ' TRUE if pattern is 1-bit
DIM SHARED DRAWER_PATTERN_1BIT_FG(1 TO DRAWER_SLOT_COUNT) AS _UNSIGNED LONG ' Original opaque color in 1-bit pattern
DIM SHARED DRAWER_PATTERN_1BIT_HAS_BG(1 TO DRAWER_SLOT_COUNT) AS INTEGER    ' TRUE if 1-bit pattern has opaque BG (2 colors, not just FG+transparent)
DIM SHARED DRAWER_GRADIENT_SLOTS(1 TO DRAWER_SLOT_COUNT) AS LONG
DIM SHARED DRAWER_GRADIENT_HAS(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED DRAWER_GRADIENT_CUSTOM(1 TO DRAWER_SLOT_COUNT) AS INTEGER
DIM SHARED DRAWER_DEFERRED_IMPORT_SLOT AS INTEGER
DIM SHARED DRAWER_DEFERRED_IMPORT_MODE AS INTEGER

' Dset file list cache for wheel cycling
CONST DRAWER_MAX_DSET_FILES = 200
DIM SHARED DRAWER_DSET_LIST(1 TO DRAWER_MAX_DSET_FILES) AS STRING
DIM SHARED DRAWER_DSET_COUNT      AS INTEGER
DIM SHARED DRAWER_DSET_CACHE_MODE AS INTEGER                                ' mode the cache was built for (0 = invalid)

' Gradient definition arrays — parallel to DRAWER_GRADIENT_SLOTS
DIM SHARED GRAD_DEFS(1 TO DRAWER_SLOT_COUNT) AS GRADIENT_DEF
DIM SHARED GRAD_COLOR_STOPS(1 TO DRAWER_SLOT_COUNT, 1 TO GRADIENT_MAX_STOPS) AS GRADIENT_COLOR_STOP
DIM SHARED GRAD_OPACITY_STOPS(1 TO DRAWER_SLOT_COUNT, 1 TO GRADIENT_MAX_STOPS) AS GRADIENT_OPACITY_STOP
DIM SHARED GRAD_STOP_TYPES(1 TO DRAWER_SLOT_COUNT, 1 TO GRADIENT_MAX_STOPS) AS INTEGER

' Shared gradient context for operation-bounded sampling
DIM SHARED GRAD_CTX AS GRADIENT_CONTEXT


' Context menu constants
CONST DRAWER_CONTEXT_ITEM_H         = 12                                    ' Must match MENU_ITEM_HEIGHT in MENUBAR.BI
CONST DRAWER_CONTEXT_MAX_ITEMS      = 14
CONST DRAWER_CONTEXT_LOAD_SET       = 1
CONST DRAWER_CONTEXT_SAVE_SET       = 2
CONST DRAWER_CONTEXT_CLEAR_SET      = 3
CONST DRAWER_CONTEXT_EXPLORE_FOLDER = 4
CONST DRAWER_CONTEXT_EDIT_GRADIENT  = 5
CONST DRAWER_CONTEXT_LOAD_IMAGES    = 6

' Forward declarations for internal helpers

' Palette/gradient rendering state (lazily initialized)
DIM SHARED DRAWER_PALETTE_IMG       AS LONG
DIM SHARED DRAWER_PALETTE_LEFT_IMG  AS LONG
DIM SHARED DRAWER_PALETTE_RIGHT_IMG AS LONG
DIM SHARED DRAWER_GRADIENT_LAST_FG  AS _UNSIGNED LONG
DIM SHARED DRAWER_GRADIENT_LAST_BG  AS _UNSIGNED LONG

DRAWER_init