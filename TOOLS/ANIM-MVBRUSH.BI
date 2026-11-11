$INCLUDEONCE
' =============================================================================
' ANIM-MVBRUSH.BI — ANIM > Move Brush: one stamp per frame along a path.
'
' Choose ANIM > Move Brush > Start, drag a path on the canvas (in a frame's
' cell, or a lightbox pane): a ghost of every stamp shows along it, all in the
' frame you dragged in. Enter stamps the brush once in each frame of the range
' - frame 1 of the range at the start of the path, the last at its end, the
' rest spaced by the ease - each in its own cell, at the same spot relative to
' the cell. An AnimBrush moves on one cel every N frames; a plain brush works
' too. One undo step. Esc cancels.
'
' The range: the frames selected in the strip when two or more are, else the
' frame the path starts in through the last frame.
' =============================================================================

CONST MVB_ACT_START   = 2576 ' ANIM > Move Brush > Start (again: cancel)
CONST MVB_ACT_EASE0   = 2577 ' Ease: none / in / out / in-out (2577-2580)
CONST MVB_ACT_EASE3   = 2580
CONST MVB_ACT_EVERY1  = 2581 ' Next cel every 1 / 2 / 3 / 4 frames (2581-2584)
CONST MVB_ACT_EVERY4  = 2584
CONST MVB_ACT_APPLY   = 2585 ' Apply (Enter)
CONST MVB_ACT_CANCEL  = 2586 ' Cancel (Esc)

CONST MVB_EASE_NONE  = 0
CONST MVB_EASE_IN    = 1
CONST MVB_EASE_OUT   = 2
CONST MVB_EASE_INOUT = 3

TYPE MVB_OBJ
    active   AS INTEGER ' the mode is on: a canvas drag sets the path
    dragging AS INTEGER ' the button is down, drawing the path
    hasPath  AS INTEGER ' a path is set (Enter applies it)
    fromF    AS INTEGER ' the frame the path was dragged in
    rx0      AS LONG    ' the path, relative to fromF's cell (the brush's middle)
    ry0      AS LONG
    rx1      AS LONG
    ry1      AS LONG
    ghost    AS LONG    ' the preview: every stamp, half see-through, cell sized
END TYPE
DIM SHARED MVB AS MVB_OBJ
DIM SHARED MVB_GHOST_KEY AS STRING ' what the ghost was built from
DIM SHARED MVB_EASE AS INTEGER  ' MVB_EASE_* (a setting, kept across documents)
DIM SHARED MVB_EVERY AS INTEGER ' next cel every N frames (1-4)
MVB_EVERY = 1
DIM SHARED MVB_F(1 TO ANIM_MAX_FRAMES) AS INTEGER ' the range's frames, in order
