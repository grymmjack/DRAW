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
    mb1          AS INTEGER ' Current left button state
    omb1         AS INTEGER ' Previous left button state
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
END TYPE

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
