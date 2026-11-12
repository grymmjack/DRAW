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
' The range: the frames selected in the strip when two or more are, else FROM
' (the frame the path starts in) for COUNT frames (0 = through the last).
'
' 2026-11-11 (DPaint's Move requester): while it is on, the Animation panel
' shows the move's settings instead of the frame rows (GUI/ANIM-PANEL), each a
' number box - drag, wheel, click to type, middle click = default:
'   FRAMES from count / MOVE x y z / TURN x y z (degrees over the move) /
'   SIZE start end % / OPACITY start end % / TINT start end % (toward FG) /
'   CEL EVERY n, the EASE (applies to all of them), PLAY (the ghost moves
'   through the steps), RESET, STAMP, CANCEL.
' Z moves the brush away (+) or toward you (-) with perspective: it shrinks
' and heads for the middle of the frame (the vanishing point, MVB_EYE px
' away). TURN X / Y tilt it in 3D (foreshortened, the back shows mirrored),
' TURN Z spins it flat. Typing a value with no path yet puts a still path in
' the middle of the frame (a spin or fade in place).
'
' Paths (MVB_PATH): LINE - a straight drag (typed MOVE X / Y set its end);
' DRAWN - the drag's own shape, the stamps spaced along its length;
' LIVE - AnimPaint: the drag is recorded in real time and every frame gets
' the brush where the pointer was at that frame's time (FPS and each frame's
' hold), stamped as you let go; the mode stays on for the next stroke.
' =============================================================================

CONST MVB_ACT_START   = 2576 ' ANIM > Move Brush > Start (again: cancel)
CONST MVB_ACT_EASE0   = 2577 ' Ease: none / in / out / in-out (2577-2580)
CONST MVB_ACT_EASE3   = 2580
CONST MVB_ACT_EVERY1  = 2581 ' Next cel every 1 / 2 / 3 / 4 frames (2581-2584)
CONST MVB_ACT_EVERY4  = 2584
CONST MVB_ACT_APPLY   = 2585 ' Apply (Enter)
CONST MVB_ACT_CANCEL  = 2586 ' Cancel (Esc)
CONST MVB_ACT_PATH0   = 2587 ' Path: line / drawn / live (2587-2589)
CONST MVB_ACT_PATH2   = 2589
CONST MVB_ACT_ANIMPAINT = 2590 ' ANIM > AnimPaint: Start with the live path (again: stop)
CONST MVB_ACT_PLAY    = 2591 ' Preview: play the ghost through the steps (again: stop)
CONST MVB_ACT_RESET   = 2592 ' Reset the move's settings (Z, turns, size, opacity, tint)

CONST MVB_EASE_NONE  = 0
CONST MVB_EASE_IN    = 1
CONST MVB_EASE_OUT   = 2
CONST MVB_EASE_INOUT = 3

CONST MVB_PATH_LINE  = 0
CONST MVB_PATH_DRAWN = 1
CONST MVB_PATH_LIVE  = 2

' The number boxes (MVB_box_*; the Animation panel's Move rows)
CONST MVB_BOX_FROM  = 1
CONST MVB_BOX_COUNT = 2
CONST MVB_BOX_X     = 3
CONST MVB_BOX_Y     = 4
CONST MVB_BOX_Z     = 5
CONST MVB_BOX_TX    = 6
CONST MVB_BOX_TY    = 7
CONST MVB_BOX_TZ    = 8
CONST MVB_BOX_S0    = 9
CONST MVB_BOX_S1    = 10
CONST MVB_BOX_O0    = 11
CONST MVB_BOX_O1    = 12
CONST MVB_BOX_T0    = 13
CONST MVB_BOX_T1    = 14
CONST MVB_BOX_EVERY = 15
CONST MVB_BOXES     = 15

CONST MVB_EYE     = 300  ' px from the eye to the frame (Z perspective)
CONST MVB_MAXPTS  = 4000 ' points kept of a drawn / live path

TYPE MVB_OBJ
    active   AS INTEGER ' the mode is on: a canvas drag sets the path
    dragging AS INTEGER ' the button is down, drawing the path
    hasPath  AS INTEGER ' a path is set (Enter applies it)
    fromF    AS INTEGER ' the frame the path was dragged in (FROM)
    rx0      AS LONG    ' the path, relative to fromF's cell (the brush's middle)
    ry0      AS LONG
    rx1      AS LONG
    ry1      AS LONG
    ghost    AS LONG    ' the preview: every stamp, half see-through, cell sized
    nPts     AS INTEGER ' a drawn / live path's points (MVB_PX / PY / PT)
    t0       AS DOUBLE  ' TIMER at the press (live)
    dur      AS DOUBLE  ' seconds the live drag lasted
    playing  AS INTEGER ' PLAY: the ghost shows one step at a time
    playT0   AS DOUBLE
    playStep AS INTEGER ' the step shown (MVB_tick redraws when it changes)
    openedPanel AS INTEGER ' Start opened the Animation panel (closed again at the end)
END TYPE
DIM SHARED MVB AS MVB_OBJ
DIM SHARED MVB_GHOST_KEY AS STRING ' what the ghost was built from
DIM SHARED MVB_EASE AS INTEGER  ' MVB_EASE_* (a setting, kept across documents)
DIM SHARED MVB_EVERY AS INTEGER ' next cel every N frames (1-12)
MVB_EVERY = 1
DIM SHARED MVB_PATH AS INTEGER  ' MVB_PATH_* (a setting)
DIM SHARED MVB_COUNT AS INTEGER ' frames in the move (0 = through the last)
' the move's settings, boxes MVB_BOX_Z .. MVB_BOX_T1 (kept across documents)
DIM SHARED MVB_V(1 TO MVB_BOXES) AS LONG
MVB_V(MVB_BOX_S0) = 100: MVB_V(MVB_BOX_S1) = 100: MVB_V(MVB_BOX_O0) = 100: MVB_V(MVB_BOX_O1) = 100
DIM SHARED MVB_F(1 TO ANIM_MAX_FRAMES) AS INTEGER ' the range's frames, in order
DIM SHARED MVB_PX(0 TO MVB_MAXPTS) AS SINGLE ' a drawn / live path (cell-relative)
DIM SHARED MVB_PY(0 TO MVB_MAXPTS) AS SINGLE
DIM SHARED MVB_PT(0 TO MVB_MAXPTS) AS DOUBLE ' seconds after the press
