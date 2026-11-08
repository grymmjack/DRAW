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
    ' The Preview window's frame view: its own zoom (0 = fit) and the frame's
    ' top-left relative to the content box when zoomed (field kit: it never
    ' zoomed). The box is the last one drawn, for the wheel.
    pvZ       AS SINGLE
    pvRX      AS SINGLE
    pvRY      AS SINGLE
    pvFW      AS INTEGER ' the frame size pvZ was set for (another size = fit)
    pvFH      AS INTEGER
    pvX1      AS INTEGER
    pvY1      AS INTEGER
    pvX2      AS INTEGER
    pvY2      AS INTEGER
    boxImg    AS LONG    ' scratch: a zoomed picture is built here, clipped to its box
END TYPE
DIM SHARED ANIM_VIEW AS ANIM_VIEW_OBJ

' Frame keys (Rick's sketch: "seek bar keys are on numpad"): numpad 1 first,
' 4 previous, 5 next, 9 last (Enter play: 1.9; + append: 1.7). Read with
' INPUT/NUMPAD so the main-row digits keep setting opacity. Laptop keys:
' Alt+Home / Alt+, / Alt+. / Alt+End (INPUT bindings, same actions).
CONST ANIM_ACT_GRID  = 2500 ' View > Frame Grid
CONST ANIM_ACT_FIRST = 2501
CONST ANIM_ACT_PREV  = 2502
CONST ANIM_ACT_NEXT  = 2503
CONST ANIM_ACT_LAST  = 2504
CONST ANIM_ACT_PLAY  = 2506 ' play / stop (Num Enter, Alt+/)
CONST ANIM_ACT_PREVIEW_FRAME = 2507 ' ANIM > Preview Shows Frame
' A numpad key taken as a frame key also arrives as a plain code (INKEY$ "4",
' _KEYHIT 52): those twins are dropped (ANIM_numpad_code%).
DIM SHARED ANIM_SW_B AS INTEGER    ' numpad key whose twins are still to come
DIM SHARED ANIM_SW_MASK AS INTEGER ' which: 1 = _KEYHIT, 2 = INKEY$
DIM SHARED ANIM_SW_T AS DOUBLE
