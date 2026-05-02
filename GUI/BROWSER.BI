''
' DRAW - GUI/BROWSER.BI
' =============================================================================
' Browser panel declarations.
' Floating non-modal panel scaffold for the upcoming image browser.
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

CONST BROWSER_DEFAULT_W = 320
CONST BROWSER_DEFAULT_H = 220
CONST BROWSER_MIN_W     = 180
CONST BROWSER_MIN_H     = 120
CONST BROWSER_TITLE_H   = 16

TYPE BROWSER_OBJ
    visible        AS INTEGER
    positioned     AS INTEGER
    initialized    AS INTEGER
    settingsLoaded AS INTEGER   ' TRUE after first-ever defaults load; survives suspend/resume
    needReClamp    AS INTEGER   ' TRUE until first render after startup (deferred work-area clamp)
    autoHidden     AS INTEGER

    dispW        AS INTEGER
    dispH        AS INTEGER
    dispX        AS INTEGER
    dispY        AS INTEGER
    renderScale  AS SINGLE

    dragging     AS INTEGER
    dragStartMX  AS INTEGER
    dragStartMY  AS INTEGER
    dragStartDX  AS INTEGER
    dragStartDY  AS INTEGER
    resizing     AS INTEGER
    resizeEdge   AS INTEGER
    resizeStartMX AS INTEGER
    resizeStartMY AS INTEGER
    resizeStartX  AS INTEGER
    resizeStartY  AS INTEGER
    resizeStartW  AS INTEGER
    resizeStartH  AS INTEGER
    maximized     AS INTEGER
    restoreX      AS INTEGER
    restoreY      AS INTEGER
    restoreW      AS INTEGER
    restoreH      AS INTEGER
    titleClickTime AS DOUBLE
    suspendDepth  AS INTEGER
    suspendWasVisible AS INTEGER

    imgHandle    AS LONG
    fontHandle   AS LONG

    lastDir      AS STRING
    viewMode     AS INTEGER
    zoomLevel    AS INTEGER
    sortType     AS INTEGER
    sortOrder    AS INTEGER
    previewOpen  AS INTEGER

    ' File drag-out state (drag file from browser onto canvas/layers/bins)
    fileDragActive   AS INTEGER      ' TRUE while dragging a file outside the panel
    fileDragStarted  AS INTEGER      ' B1 pressed on a file entry; drag not yet committed
    fileDragStartMX  AS INTEGER      ' Raw mouse X when B1 pressed on file
    fileDragStartMY  AS INTEGER      ' Raw mouse Y when B1 pressed on file
    fileDragPath     AS STRING * 260 ' Full path of the dragged file
    fileDragCount    AS INTEGER      ' Number of files selected for drag (multi-select)
END TYPE

DIM SHARED BROWSER AS BROWSER_OBJ
