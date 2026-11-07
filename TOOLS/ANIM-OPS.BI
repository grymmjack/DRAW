''
' DRAW - TOOLS/ANIM-OPS.BI
' =============================================================================
' Frame operations (Animation 1.7, PLANS/ANIMATION.md R-03 / R-04): add (a
' copy of the last frame; Shift = blank), insert before / after, duplicate,
' delete, move earlier / later, reverse. The sheet is always in play order, so
' each one moves cell pixels on every pixel layer (TOOLS/ANIM ANIM_plan% says
' which old cell lands where) and adding past the last cell grows the canvas
' by a row. One undo step each: HISTORY_KIND_ANIM_FRAMES keeps the whole sheet
' before and after (canvas size, every layer's pixels, the frame data).
'
' Text and linked symbol layers keep their pixels where they are (text is
' redrawn from its words, a linked copy from its parent); groups have none.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

OPTION _EXPLICIT
OPTION _EXPLICITARRAY

' Actions (ANIM menu, Animation panel, numpad +): action = ANIM_ACT_OP0 + ANIM_OP_*
CONST ANIM_ACT_OP0            = 2509
CONST ANIM_ACT_APPEND         = 2510 ' Num +
CONST ANIM_ACT_APPEND_BLANK   = 2511 ' Shift + Num +
CONST ANIM_ACT_INSERT_BEFORE  = 2512
CONST ANIM_ACT_INSERT_AFTER   = 2513
CONST ANIM_ACT_DUPLICATE      = 2514
CONST ANIM_ACT_DELETE         = 2515
CONST ANIM_ACT_MOVE_EARLIER   = 2516
CONST ANIM_ACT_MOVE_LATER     = 2517
CONST ANIM_ACT_REVERSE        = 2518

DIM SHARED ANIM_OPS_LAST_KEY AS LONG    ' the panel press whose undo step is on top (ANIM_OPS_record)
DIM SHARED ANIM_OPS_LAST_REC AS INTEGER ' and that step's record
