''
' DRAW - GUI/SCROLLBAR.BI
' =============================================================================
' Overlay scrollbar widgets for navigating canvases larger than the viewport.
' Shows horizontal/vertical scrollbars when zoomed canvas exceeds viewport.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST SCROLLBAR_THICKNESS = 8     ' Width (V) / Height (H) of scrollbar in pixels
CONST SCROLLBAR_MIN_THUMB = 16    ' Minimum thumb size in pixels
CONST SCROLLBAR_GAP = 2           ' Gap between scrollbar and adjacent GUI element

TYPE SCROLLBAR_OBJ
    ' Horizontal scrollbar state
    hVisible       AS INTEGER     ' TRUE if H scrollbar should show
    hTrackX        AS INTEGER     ' Track left edge (screen coords)
    hTrackY        AS INTEGER     ' Track top edge (screen coords)
    hTrackW        AS INTEGER     ' Track width
    hTrackH        AS INTEGER     ' Track height (= SCROLLBAR_THICKNESS)
    hThumbX        AS INTEGER     ' Thumb left edge (screen coords)
    hThumbW        AS INTEGER     ' Thumb width
    hDragging      AS INTEGER     ' TRUE if user is dragging H thumb
    hDragOffset    AS INTEGER     ' Mouse offset from thumb left when drag started
    ' Vertical scrollbar state
    vVisible       AS INTEGER     ' TRUE if V scrollbar should show
    vTrackX        AS INTEGER     ' Track left edge (screen coords)
    vTrackY        AS INTEGER     ' Track top edge (screen coords)
    vTrackW        AS INTEGER     ' Track width (= SCROLLBAR_THICKNESS)
    vTrackH        AS INTEGER     ' Track height
    vThumbY        AS INTEGER     ' Thumb top edge (screen coords)
    vThumbH        AS INTEGER     ' Thumb height
    vDragging      AS INTEGER     ' TRUE if user is dragging V thumb
    vDragOffset    AS INTEGER     ' Mouse offset from thumb top when drag started
    ' Common
    active         AS INTEGER     ' TRUE if any scrollbar is currently interactive
END TYPE

DIM SHARED SCROLLBAR AS SCROLLBAR_OBJ

DECLARE SUB SCROLLBAR_update ()
DECLARE SUB SCROLLBAR_render ()
DECLARE FUNCTION SCROLLBAR_handle_mouse% (mx AS INTEGER, my AS INTEGER, b1 AS INTEGER, oldB1 AS INTEGER)
DECLARE FUNCTION SCROLLBAR_in_bounds% (mx AS INTEGER, my AS INTEGER)
