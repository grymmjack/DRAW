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
CONST TB_HAND          = 14
CONST TB_PICKER        = 15
CONST TB_SPRAY         = 16
CONST TB_CROP          = 17
CONST TB_HELP          = 18
CONST TB_BRUSH         = 19
CONST TB_ZOOM          = 20
CONST TB_POLYGON_FILLED = 21
CONST TB_MARQUEE_FREEHAND = 22
CONST TB_MARQUEE_POLY    = 23
CONST TB_MARQUEE_ELLIPSE = 24
CONST TB_MARQUEE_WAND    = 25
CONST TB_ERASER          = 26
CONST TB_EXPORT_SEL      = 27
CONST TB_BTN_W         = 11
CONST TB_BTN_H         = 11
CONST TB_BTN_PADDING   = 1
CONST TB_TOP           = 0
CONST TB_COLS          = 4
CONST TB_ROWS          = 7
CONST TB_TOTAL         = 28
' TB_RIGHT, TB_CENTER and TB_LEFT are now calculated dynamically in TOOLBAR_render()
' to align toolbar to the right edge of the screen

' Map toolbar button positions to actual button constants
' 4 columns x 7 rows layout (left-to-right, top-to-bottom)
' Row 0: MOVE          | PAN           | ZOOM          | CROP
' Row 1: MARQ RECT     | MARQ FREEHAND | MARQ POLY     | MARQ ELLIPSE
' Row 2: MARQ WAND     | PICKER        | TEXT          | ERASER
' Row 3: DOT           | BRUSH         | SPRAY         | FILL
' Row 4: LINE          | POLYLINE      | POLYFILL      | SAVE
' Row 5: QB64/CODE     | RECT          | RECT FILLED   | EXPORT SEL
' Row 6: HELP          | ELLIPSE       | ELLIPSE FILL  | OPEN
DIM SHARED TOOLBAR_BUTTON_ORDER(27) AS INTEGER
' Row 0: Navigation/Transform
TOOLBAR_BUTTON_ORDER(0) = TB_MOVE
TOOLBAR_BUTTON_ORDER(1) = TB_HAND
TOOLBAR_BUTTON_ORDER(2) = TB_ZOOM
TOOLBAR_BUTTON_ORDER(3) = TB_CROP
' Row 1: Selection tools
TOOLBAR_BUTTON_ORDER(4) = TB_SELECT         ' Marquee Rect
TOOLBAR_BUTTON_ORDER(5) = TB_MARQUEE_FREEHAND
TOOLBAR_BUTTON_ORDER(6) = TB_MARQUEE_POLY
TOOLBAR_BUTTON_ORDER(7) = TB_MARQUEE_ELLIPSE
' Row 2: Selection + Utility
TOOLBAR_BUTTON_ORDER(8) = TB_MARQUEE_WAND
TOOLBAR_BUTTON_ORDER(9) = TB_PICKER
TOOLBAR_BUTTON_ORDER(10) = TB_TEXT
TOOLBAR_BUTTON_ORDER(11) = TB_ERASER
' Row 3: Drawing tools
TOOLBAR_BUTTON_ORDER(12) = TB_PSET
TOOLBAR_BUTTON_ORDER(13) = TB_BRUSH
TOOLBAR_BUTTON_ORDER(14) = TB_SPRAY
TOOLBAR_BUTTON_ORDER(15) = TB_PAINT
' Row 4: Line/Poly + Save
TOOLBAR_BUTTON_ORDER(16) = TB_LINE
TOOLBAR_BUTTON_ORDER(17) = TB_POLYGON
TOOLBAR_BUTTON_ORDER(18) = TB_POLYGON_FILLED
TOOLBAR_BUTTON_ORDER(19) = TB_SAVE
' Row 5: Code + Shapes + Export
TOOLBAR_BUTTON_ORDER(20) = TB_QB64
TOOLBAR_BUTTON_ORDER(21) = TB_RECT
TOOLBAR_BUTTON_ORDER(22) = TB_RECT_FILLED
TOOLBAR_BUTTON_ORDER(23) = TB_EXPORT_SEL
' Row 6: Help + Ellipse + Open
TOOLBAR_BUTTON_ORDER(24) = TB_HELP
TOOLBAR_BUTTON_ORDER(25) = TB_CIRCLE
TOOLBAR_BUTTON_ORDER(26) = TB_CIRCLE_FILLED
TOOLBAR_BUTTON_ORDER(27) = TB_OPEN

' Map toolbar button positions to tool constants
DIM SHARED TOOLBAR_BUTTON_TO_TOOL(27) AS INTEGER
' Row 0
TOOLBAR_BUTTON_TO_TOOL(0) = TOOL_MOVE
TOOLBAR_BUTTON_TO_TOOL(1) = TOOL_PAN
TOOLBAR_BUTTON_TO_TOOL(2) = TOOL_ZOOM
TOOLBAR_BUTTON_TO_TOOL(3) = TOOL_CROP
' Row 1
TOOLBAR_BUTTON_TO_TOOL(4) = TOOL_SELECT_RECT
TOOLBAR_BUTTON_TO_TOOL(5) = TOOL_SELECT_FREE
TOOLBAR_BUTTON_TO_TOOL(6) = TOOL_SELECT_POLY
TOOLBAR_BUTTON_TO_TOOL(7) = TOOL_SELECT_ELLIPSE
' Row 2
TOOLBAR_BUTTON_TO_TOOL(8) = TOOL_SELECT_WAND
TOOLBAR_BUTTON_TO_TOOL(9) = TOOL_PICKER
TOOLBAR_BUTTON_TO_TOOL(10) = TOOL_TEXT
TOOLBAR_BUTTON_TO_TOOL(11) = TOOL_ERASER
' Row 3
TOOLBAR_BUTTON_TO_TOOL(12) = TOOL_DOT
TOOLBAR_BUTTON_TO_TOOL(13) = TOOL_BRUSH
TOOLBAR_BUTTON_TO_TOOL(14) = TOOL_SPRAY
TOOLBAR_BUTTON_TO_TOOL(15) = TOOL_FILL
' Row 4
TOOLBAR_BUTTON_TO_TOOL(16) = TOOL_LINE
TOOLBAR_BUTTON_TO_TOOL(17) = TOOL_POLYGON
TOOLBAR_BUTTON_TO_TOOL(18) = TOOL_POLYGON_FILLED
TOOLBAR_BUTTON_TO_TOOL(19) = TOOL_SAVE
' Row 5
TOOLBAR_BUTTON_TO_TOOL(20) = TOOL_CODE
TOOLBAR_BUTTON_TO_TOOL(21) = TOOL_RECT
TOOLBAR_BUTTON_TO_TOOL(22) = TOOL_RECT_FILLED
TOOLBAR_BUTTON_TO_TOOL(23) = TOOL_EXPORT_SEL
' Row 6
TOOLBAR_BUTTON_TO_TOOL(24) = TOOL_HELP
TOOLBAR_BUTTON_TO_TOOL(25) = TOOL_ELLIPSE
TOOLBAR_BUTTON_TO_TOOL(26) = TOOL_ELLIPSE_FILLED
TOOLBAR_BUTTON_TO_TOOL(27) = TOOL_OPEN

GUI_TB(TB_PSET).iSrc$          = "dot.png"
GUI_TB(TB_PSET).tip$           = "Draw using points (PSET)"
GUI_TB(TB_PSET).evt$           = "PSET"

GUI_TB(TB_PAINT).iSrc$         = "fill.png"
GUI_TB(TB_PAINT).iSrcAlt$      = "fill-grid-cell.png"
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

GUI_TB(TB_SELECT).iSrc$        = "marquee-rect.png"
GUI_TB(TB_SELECT).tip$         = "Select rectangle marquee"
GUI_TB(TB_SELECT).evt$         = "SELECT"

GUI_TB(TB_MOVE).iSrc$          = "move.png"
GUI_TB(TB_MOVE).tip$           = "Move what is selected"
GUI_TB(TB_MOVE).evt$           = "MOVE"

GUI_TB(TB_POLYGON).iSrc$       = "polygon.png"
GUI_TB(TB_POLYGON).tip$        = "Draw connected lines (LINE)"
GUI_TB(TB_POLYGON).evt$        = "POLYGON"

GUI_TB(TB_POLYGON_FILLED).iSrc$ = "polygon-fill.png"
GUI_TB(TB_POLYGON_FILLED).tip$  = "Draw filled polygon"
GUI_TB(TB_POLYGON_FILLED).evt$  = "POLYGON_FILL"

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

GUI_TB(TB_HAND).iSrc$          = "hand.png"
GUI_TB(TB_HAND).tip$           = "Pan canvas (HAND)"
GUI_TB(TB_HAND).evt$           = "PAN"

GUI_TB(TB_PICKER).iSrc$        = "picker.png"
GUI_TB(TB_PICKER).tip$         = "Pick color from canvas (PICKER)"
GUI_TB(TB_PICKER).evt$         = "PICKER"

GUI_TB(TB_SPRAY).iSrc$         = "spray.png"
GUI_TB(TB_SPRAY).tip$          = "Spray paint (SPRAY)"
GUI_TB(TB_SPRAY).evt$          = "SPRAY"

GUI_TB(TB_BRUSH).iSrc$         = "brush.png"
GUI_TB(TB_BRUSH).tip$          = "Paint with brush (BRUSH)"
GUI_TB(TB_BRUSH).evt$          = "BRUSH"

GUI_TB(TB_HELP).iSrc$          = "help.png"
GUI_TB(TB_HELP).tip$           = "Show help / commands (?)"
GUI_TB(TB_HELP).evt$           = "HELP"

GUI_TB(TB_ZOOM).iSrc$          = "zoom.png"
GUI_TB(TB_ZOOM).tip$           = "Zoom (click=in, alt+click=out)"
GUI_TB(TB_ZOOM).evt$           = "ZOOM"

GUI_TB(TB_CROP).iSrc$          = "crop.png"
GUI_TB(TB_CROP).tip$           = "Crop canvas to selection"
GUI_TB(TB_CROP).evt$           = "CROP"

GUI_TB(TB_MARQUEE_FREEHAND).iSrc$ = "marquee-freehand.png"
GUI_TB(TB_MARQUEE_FREEHAND).tip$  = "Freehand selection (stub)"
GUI_TB(TB_MARQUEE_FREEHAND).evt$  = "SELECT_FREE"

GUI_TB(TB_MARQUEE_POLY).iSrc$    = "marquee-poly.png"
GUI_TB(TB_MARQUEE_POLY).tip$     = "Polygon selection (stub)"
GUI_TB(TB_MARQUEE_POLY).evt$     = "SELECT_POLY"

GUI_TB(TB_MARQUEE_ELLIPSE).iSrc$ = "marquee-ellipse.png"
GUI_TB(TB_MARQUEE_ELLIPSE).tip$  = "Ellipse selection (stub)"
GUI_TB(TB_MARQUEE_ELLIPSE).evt$  = "SELECT_ELLIPSE"

GUI_TB(TB_MARQUEE_WAND).iSrc$   = "marquee-wand.png"
GUI_TB(TB_MARQUEE_WAND).tip$    = "Magic wand selection"
GUI_TB(TB_MARQUEE_WAND).evt$    = "SELECT_WAND"

GUI_TB(TB_ERASER).iSrc$         = "eraser.png"
GUI_TB(TB_ERASER).tip$          = "Eraser (paint transparent)"
GUI_TB(TB_ERASER).evt$          = "ERASER"

GUI_TB(TB_EXPORT_SEL).iSrc$     = "export-selection.png"
GUI_TB(TB_EXPORT_SEL).tip$      = "Export selection to file"
GUI_TB(TB_EXPORT_SEL).evt$      = "EXPORT_SEL"
