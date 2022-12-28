''
' DRAW - GUI/TOOLBAR.BI
' =============================================================================
' UDT for toolbar.
'
' @author Rick Christy <grymmjack@gmail.com>
'

CONST UI_IMAGES_DIR = "./ASSETS/THEMES/DEFAULT/"
 
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
CONST TB_RIGHT         = 308
CONST TB_LEFT          = 296

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
