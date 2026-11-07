''
' DRAW - TOOLS/ANIM-VIEW.BI
' =============================================================================
' Animation views over the sheet (see TOOLS/ANIM.BI). Sheet view: the frame
' grid overlay - cell borders, frame numbers, the current frame - drawn in
' SCREEN_render before the scene cache (it only changes when the layout, the
' current frame or the view does, and each of those dirties the scene).
' Shown when the document has frames and CFG.FRAME_GRID% (View > Frame Grid,
' action 2500). Colors: THEME.ANIM_FRAME_*.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

TYPE ANIM_VIEW_OBJ
    font      AS LONG    ' frame number font (Tiny5, loaded on first use); 0 = built-in 8x8
    fontTried AS INTEGER
    drawn     AS INTEGER ' the grid was drawn last render (QA dump)
    dx        AS LONG    ' viewport px of canvas (0,0) on that render
    dy        AS LONG
END TYPE
DIM SHARED ANIM_VIEW AS ANIM_VIEW_OBJ
