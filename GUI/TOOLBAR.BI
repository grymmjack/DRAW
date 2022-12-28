''
' DRAW - GUI/TOOLBAR.BI
' =============================================================================
' UDT for toolbar.
'
' @todo
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

DIM SHARED UI_TB(13) AS GUI_CONTROL

UI_TB(TB_PSET).iSrc$          = "pset.png"
UI_TB(TB_PSET).tip$           = "Draw using points (PSET)"
UI_TB(TB_PSET).evt$           = "PSET"

UI_TB(TB_PAINT).iSrc$         = "paint.png"
UI_TB(TB_PAINT).tip$          = "Fill with color or pattern (PAINT)"
UI_TB(TB_PAINT).evt$          = "PAINT"

UI_TB(TB_LINE).iSrc$          = "line.png"
UI_TB(TB_LINE).tip$           = "Draw lines (LINE)"
UI_TB(TB_LINE).evt$           = "LINE"

UI_TB(TB_RECT).iSrc$          = "rect.png"
UI_TB(TB_RECT).tip$           = "Draw rectangles (LINE B)"
UI_TB(TB_RECT).evt$           = "LINE B"

UI_TB(TB_CIRCLE).iSrc$        = "circle.png"
UI_TB(TB_CIRCLE).tip$         = "Draw circles (CIRCLE)"
UI_TB(TB_CIRCLE).evt$         = "CIRCLE"

UI_TB(TB_RECT_FILLED).iSrc$   = "rect-filled.png"
UI_TB(TB_RECT_FILLED).tip$    = "Draw filled rectangles (LINE BF)"
UI_TB(TB_RECT_FILLED).evt$    = "LINE BF"

UI_TB(TB_CIRCLE_FILLED).iSrc$ = "circle-filled.png"
UI_TB(TB_CIRCLE_FILLED).tip$  = "Draw filled circles (CIRCLE)"
UI_TB(TB_CIRCLE_FILLED).evt$  = "CIRCLE"

UI_TB(TB_SELECT).iSrc$        = "select.png"
UI_TB(TB_SELECT).tip$         = "Select a part of the image"
UI_TB(TB_SELECT).evt$         = "SELECT"

UI_TB(TB_MOVE).iSrc$          = "move.png"
UI_TB(TB_MOVE).tip$           = "Move what is selected"
UI_TB(TB_MOVE).evt$           = "MOVE"

UI_TB(TB_POLYGON).iSrc$       = "polygon.png"
UI_TB(TB_POLYGON).tip$        = "Draw connected lines (LINE)"
UI_TB(TB_POLYGON).evt$        = "POLYGON"

UI_TB(TB_TEXT).iSrc$          = "text.png"
UI_TB(TB_TEXT).tip$           = "Insert text"
UI_TB(TB_TEXT).evt$           = "TEXT"

UI_TB(TB_SAVE).iSrc$          = "save.png"
UI_TB(TB_SAVE).tip$           = "Save your image"
UI_TB(TB_SAVE).evt$           = "SAVE"

UI_TB(TB_OPEN).iSrc$          = "open.png"
UI_TB(TB_OPEN).tip$           = "Open an image"
UI_TB(TB_OPEN).evt$           = "OPEN"

UI_TB(TB_QB64).iSrc$          = "qb64.png"
UI_TB(TB_QB64).tip$           = "Show QB64 source"
UI_TB(TB_QB64).evt$           = "QB64"
