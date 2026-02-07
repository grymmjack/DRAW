''
' DRAW - GUI/TOOLBAR.BI
' =============================================================================
' UDT for toolbar.
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE
 
CONST TB_PSET          = 0
CONST TB_PAINT         = 1
CONST TB_LINE          = 2
CONST TB_RECT          = 3
CONST TB_CIRCLE        = 4
CONST TB_RECT_FILLED   = 5
CONST TB_CIRCLE_FILLED = 6
CONST TB_SELECT        = 7
CONST TB_MOVE          = 8
CONST TB_POLYGON       = 9
CONST TB_TEXT          = 10
CONST TB_SAVE          = 11
CONST TB_OPEN          = 12
CONST TB_QB64          = 13
CONST TB_BTN_W         = 11
CONST TB_BTN_H         = 11
CONST TB_BTN_PADDING   = 1
CONST TB_TOP           = 0
' TB_RIGHT and TB_LEFT are now calculated dynamically in TOOLBAR_render()
' to align toolbar to the right edge of the screen

' Map toolbar button positions to actual button constants (from screenshot order)
' Position 0 (L): marquee/select | Position 1 (R): dot/pset
' Position 2 (L): move          | Position 3 (R): fill/paint
' Position 4 (L): polygon       | Position 5 (R): line
' Position 6 (L): text          | Position 7 (R): rect
' Position 8 (L): save          | Position 9 (R): ellipse
' Position 10 (L): open         | Position 11 (R): rect filled
' Position 12 (L): show code    | Position 13 (R): ellipse filled
DIM SHARED TOOLBAR_BUTTON_ORDER(13) AS INTEGER
TOOLBAR_BUTTON_ORDER(0) = TB_SELECT
TOOLBAR_BUTTON_ORDER(1) = TB_PSET
TOOLBAR_BUTTON_ORDER(2) = TB_MOVE
TOOLBAR_BUTTON_ORDER(3) = TB_PAINT
TOOLBAR_BUTTON_ORDER(4) = TB_POLYGON
TOOLBAR_BUTTON_ORDER(5) = TB_LINE
TOOLBAR_BUTTON_ORDER(6) = TB_TEXT
TOOLBAR_BUTTON_ORDER(7) = TB_RECT
TOOLBAR_BUTTON_ORDER(8) = TB_SAVE
TOOLBAR_BUTTON_ORDER(9) = TB_CIRCLE
TOOLBAR_BUTTON_ORDER(10) = TB_OPEN
TOOLBAR_BUTTON_ORDER(11) = TB_RECT_FILLED
TOOLBAR_BUTTON_ORDER(12) = TB_QB64
TOOLBAR_BUTTON_ORDER(13) = TB_CIRCLE_FILLED

' Map toolbar button positions to tool constants
DIM SHARED TOOLBAR_BUTTON_TO_TOOL(13) AS INTEGER
TOOLBAR_BUTTON_TO_TOOL(0) = TOOL_MARQUEE
TOOLBAR_BUTTON_TO_TOOL(1) = TOOL_DOT     ' PSET button = dot/paint tool
TOOLBAR_BUTTON_TO_TOOL(2) = TOOL_MOVE
TOOLBAR_BUTTON_TO_TOOL(3) = TOOL_FILL    ' PAINT button = fill bucket tool
TOOLBAR_BUTTON_TO_TOOL(4) = TOOL_POLYGON
TOOLBAR_BUTTON_TO_TOOL(5) = TOOL_LINE
TOOLBAR_BUTTON_TO_TOOL(6) = TOOL_TEXT
TOOLBAR_BUTTON_TO_TOOL(7) = TOOL_RECT
TOOLBAR_BUTTON_TO_TOOL(8) = TOOL_SAVE
TOOLBAR_BUTTON_TO_TOOL(9) = TOOL_ELLIPSE
TOOLBAR_BUTTON_TO_TOOL(10) = TOOL_OPEN
TOOLBAR_BUTTON_TO_TOOL(11) = TOOL_RECT_FILLED
TOOLBAR_BUTTON_TO_TOOL(12) = TOOL_CODE
TOOLBAR_BUTTON_TO_TOOL(13) = TOOL_ELLIPSE_FILLED

GUI_TB(TB_PSET).iSrc$          = "pset.png"
GUI_TB(TB_PSET).tip$           = "Draw using points (PSET)"
GUI_TB(TB_PSET).evt$           = "PSET"

GUI_TB(TB_PAINT).iSrc$         = "paint.png"
GUI_TB(TB_PAINT).tip$          = "Fill with color or pattern (PAINT)"
GUI_TB(TB_PAINT).evt$          = "PAINT"

GUI_TB(TB_LINE).iSrc$          = "line.png"
GUI_TB(TB_LINE).tip$           = "Draw lines (LINE)"
GUI_TB(TB_LINE).evt$           = "LINE"

GUI_TB(TB_RECT).iSrc$          = "rect.png"
GUI_TB(TB_RECT).tip$           = "Draw rectangles (LINE B)"
GUI_TB(TB_RECT).evt$           = "LINE B"

GUI_TB(TB_CIRCLE).iSrc$        = "circle.png"
GUI_TB(TB_CIRCLE).tip$         = "Draw circles (CIRCLE)"
GUI_TB(TB_CIRCLE).evt$         = "CIRCLE"

GUI_TB(TB_RECT_FILLED).iSrc$   = "rect-filled.png"
GUI_TB(TB_RECT_FILLED).tip$    = "Draw filled rectangles (LINE BF)"
GUI_TB(TB_RECT_FILLED).evt$    = "LINE BF"

GUI_TB(TB_CIRCLE_FILLED).iSrc$ = "circle-filled.png"
GUI_TB(TB_CIRCLE_FILLED).tip$  = "Draw filled circles (CIRCLE)"
GUI_TB(TB_CIRCLE_FILLED).evt$  = "CIRCLE"

GUI_TB(TB_SELECT).iSrc$        = "select.png"
GUI_TB(TB_SELECT).tip$         = "Select a part of the image"
GUI_TB(TB_SELECT).evt$         = "SELECT"

GUI_TB(TB_MOVE).iSrc$          = "move.png"
GUI_TB(TB_MOVE).tip$           = "Move what is selected"
GUI_TB(TB_MOVE).evt$           = "MOVE"

GUI_TB(TB_POLYGON).iSrc$       = "polygon.png"
GUI_TB(TB_POLYGON).iSrcAlt$    = "polygon-fill.png"
GUI_TB(TB_POLYGON).tip$        = "Draw connected lines (LINE)"
GUI_TB(TB_POLYGON).evt$        = "POLYGON"

GUI_TB(TB_TEXT).iSrc$          = "text.png"
GUI_TB(TB_TEXT).tip$           = "Insert text"
GUI_TB(TB_TEXT).evt$           = "TEXT"

GUI_TB(TB_SAVE).iSrc$          = "save.png"
GUI_TB(TB_SAVE).tip$           = "Save your image"
GUI_TB(TB_SAVE).evt$           = "SAVE"

GUI_TB(TB_OPEN).iSrc$          = "open.png"
GUI_TB(TB_OPEN).tip$           = "Open an image"
GUI_TB(TB_OPEN).evt$           = "OPEN"

GUI_TB(TB_QB64).iSrc$          = "qb64.png"
GUI_TB(TB_QB64).tip$           = "Show QB64 source"
GUI_TB(TB_QB64).evt$           = "QB64"
