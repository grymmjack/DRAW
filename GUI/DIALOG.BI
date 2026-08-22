''
' DRAW - GUI/DIALOG.BI
' =============================================================================
' Shared modal dialog infrastructure - TYPE, init/poll/draw/cleanup helpers.
' Used by STROKE-SEL and IMAGE-ADJ dialogs to avoid boilerplate duplication.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
OPTION _EXPLICIT
OPTION _EXPLICITARRAY
'$DYNAMIC

' Dialog context - carries all per-dialog state needed by helpers
' Set when a dialog absorbs a window-close request; DRAW.BAS acts on it once
' the modal loop has unwound.
DIM SHARED DIALOG_EXIT_PENDING%

TYPE DIALOG_CTX
    imgHandle    AS LONG    ' Offscreen buffer (_NEWIMAGE)
    x            AS INTEGER ' Dialog screen position (logical pixels)
    y            AS INTEGER
    w            AS INTEGER ' Buffer dimensions
    h            AS INTEGER
    scale        AS INTEGER ' Copy of SCRN.displayScale%
    fontH        AS LONG    ' Loaded font handle
    mx           AS INTEGER ' Mouse X relative to dialog top-left
    my           AS INTEGER ' Mouse Y relative to dialog top-left
    mb1          AS INTEGER ' Current left button state (consumable: widgets/swallows may zero it)
    omb1         AS INTEGER ' Previous RAW left button state (for edge detection)
    mb1raw       AS INTEGER ' Current RAW physical button, immune to swallows — feeds omb1 next frame
    justClicked  AS INTEGER ' mb1 transitioned 0->1 this frame
    mwheel       AS INTEGER ' Accumulated mouse wheel delta this frame
    done         AS INTEGER ' TRUE when loop should exit
    result       AS INTEGER ' TRUE = OK, FALSE = Cancel
    ' ---- Live preview / split view ----
    origThumb    AS LONG    ' Thumbnail of layer at open (created by IMAGE_ADJ_setup_preview)
    previewThumb AS LONG    ' Thumbnail of current adjusted result
    prevH        AS INTEGER ' Preview pane height; 0 = no preview
    splitX       AS INTEGER ' Split bar X position in dialog pixels
    previewDirty AS INTEGER ' TRUE = > recompute previewThumb this frame
    loupeDirty   AS INTEGER ' TRUE = > dialog moved, re-capture loupe region
    ' ---- Movable dialog ----
    moveDrag     AS INTEGER ' TRUE while user is dragging dialog via title bar
    moveDragOX   AS INTEGER ' Mouse-to-dialog-left offset at drag start
    moveDragOY   AS INTEGER ' Mouse-to-dialog-top offset at drag start
    splitDrag    AS INTEGER ' TRUE while user is dragging the split bar
    screenShot   AS LONG    ' Copy of screen at dialog open — restored each frame as bg
    inputArmed   AS INTEGER ' FALSE until mb1 is seen released once — swallows a button
                            ' still held from the menu click that opened the dialog, so
                            ' it can't drag a control the dialog opened underneath it
END TYPE

' ---- Dropdown (popup select) shared state -----------------------------------
' Immediate-mode single-open-at-a-time dropdown. Only one modal dialog runs at a
' time, so module globals are safe. DIALOG_init clears DIALOG_DD_OPEN.
DIM SHARED DIALOG_DD_OPEN%        ' id of the currently-open dropdown (0 = none)
DIM SHARED DIALOG_DD_X%, DIALOG_DD_Y%, DIALOG_DD_W%, DIALOG_DD_COUNT%
DIM SHARED DIALOG_DD_SEL%        ' live selection while open (round-tripped to caller)
DIM SHARED DIALOG_DD_SCROLL%     ' first visible row when list is taller than MAXVIS
DIM SHARED DIALOG_DD_RESULT_ID%  ' dropdown id that was picked THIS frame (0 = none)
DIM SHARED DIALOG_DD_RESULT_VAL% ' value picked for DIALOG_DD_RESULT_ID
REDIM SHARED DIALOG_DD_LABELS$(0 TO 0) ' labels of the open dropdown (snapshot at open)
CONST DIALOG_DD_BOXH% = 14       ' closed-box height (matches slider row height)
CONST DIALOG_DD_ROWH% = 12       ' open-list row height
CONST DIALOG_DD_MAXVIS% = 8      ' rows shown before the list scrolls

' ---- Lifecycle ---------------------------------------------------------------

' ---- Input -------------------------------------------------------------------

' ---- Drawing -----------------------------------------------------------------

' ---- Hit-testing / input helpers --------------------------------------------

''
' Returns TRUE (and clears justClicked) when the dialog was clicked inside a rect.
' Must be called during the input-dispatch phase, NOT the draw phase.

''
' Draw the live split-preview pane. Call _DEST ctx.imgHandle before invoking.
' Does nothing when ctx.prevH = 0. Expects origThumb and previewThumb to be valid.

''
' Returns updated slider value when mb1 is held over the slider track.
' Pass current value; returns new value (clamped to minV..maxV).

''
' Returns updated slider value when mouse wheel scrolled over the slider row.
' Scroll up increases, scroll down decreases by 1 per detent.
' Hit zone: full slider width, 20px above track top to 4px below bottom.
